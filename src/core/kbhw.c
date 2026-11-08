#include "kbhw.h"

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOMessage.h>
#include <IOKit/hid/IOHIDKeys.h>
#include <IOKit/hid/IOHIDManager.h>
#include <IOKit/pwr_mgt/IOPMLib.h>
#include <stdlib.h>

#define KB_VID 0x05AC
#define KB_PID 0x8102
#define KB_USAGE_PAGE 0xFF00
#define KB_USAGE 0x0F
#define RID_BRIGHTNESS 1
#define RID_POWER 3
#define BR_MIN 100
#define BR_MAX 14660

#define TB_USAGE_PAGE 0xFF12
#define TB_USAGE 0x01
#define TB_RID 1
#define TB_FACTOR_MIN 100
#define TB_FACTOR_MAX 1000

static IOHIDManagerRef g_manager;
static IOHIDManagerRef g_tb_manager;
static kb_callbacks g_cb;
static io_connect_t g_root_port;
static bool g_display_on = true;

// ---------- HID ----------

static IOHIDManagerRef create_manager(int usage_page, int usage) {
    IOHIDManagerRef m = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    CFMutableDictionaryRef match = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
        &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    const int values[4] = {KB_VID, KB_PID, usage_page, usage};
    const CFStringRef keys[4] = {CFSTR(kIOHIDVendorIDKey), CFSTR(kIOHIDProductIDKey),
                                 CFSTR(kIOHIDPrimaryUsagePageKey), CFSTR(kIOHIDPrimaryUsageKey)};
    for (int i = 0; i < 4; i++) {
        CFNumberRef n = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &values[i]);
        CFDictionarySetValue(match, keys[i], n);
        CFRelease(n);
    }
    IOHIDManagerSetDeviceMatching(m, match);
    CFRelease(match);
    return m;
}

static IOHIDManagerRef manager(void) {
    if (!g_manager) g_manager = create_manager(KB_USAGE_PAGE, KB_USAGE);
    return g_manager;
}

static IOHIDManagerRef tb_manager(void) {
    if (!g_tb_manager) g_tb_manager = create_manager(TB_USAGE_PAGE, TB_USAGE);
    return g_tb_manager;
}

static IOHIDDeviceRef copy_device_from(IOHIDManagerRef m) {
    CFSetRef set = IOHIDManagerCopyDevices(m);
    if (!set) return NULL;
    IOHIDDeviceRef dev = NULL;
    CFIndex n = CFSetGetCount(set);
    if (n > 0) {
        const void **items = malloc(sizeof(void *) * (size_t)n);
        CFSetGetValues(set, items);
        dev = (IOHIDDeviceRef)CFRetain(items[0]);   // a single interface is expected
        free(items);
    }
    CFRelease(set);
    return dev;
}

static IOHIDDeviceRef copy_device(void) { return copy_device_from(manager()); }

static void put32(uint8_t *p, uint32_t v) {
    p[0] = v & 0xff; p[1] = (v >> 8) & 0xff; p[2] = (v >> 16) & 0xff; p[3] = (v >> 24) & 0xff;
}

static uint32_t get32(const uint8_t *p) {
    return p[0] | (p[1] << 8) | (p[2] << 16) | ((uint32_t)p[3] << 24);
}

int kb_hw_set(double level, int fade_ms) {
    if (level < 0) level = 0;
    if (level > 1) level = 1;
    if (fade_ms < 0) fade_ms = 0;
    if (fade_ms > 65535) fade_ms = 65535;

    IOHIDDeviceRef dev = copy_device();
    if (!dev) return -2;
    int rc = -1;
    // Non-exclusive open, only for as long as it takes to send the reports.
    if (IOHIDDeviceOpen(dev, kIOHIDOptionsTypeNone) == kIOReturnSuccess) {
        uint8_t power[6] = {RID_POWER, level > 0 ? 1 : 0};
        put32(power + 2, (uint32_t)fade_ms);
        rc = IOHIDDeviceSetReport(dev, kIOHIDReportTypeFeature, RID_POWER, power, sizeof power) == kIOReturnSuccess ? 0 : -1;
        if (rc == 0 && level > 0) {
            uint8_t bright[9] = {RID_BRIGHTNESS};
            put32(bright + 1, BR_MIN + (uint32_t)((BR_MAX - BR_MIN) * level + 0.5));
            put32(bright + 5, (uint32_t)fade_ms);
            rc = IOHIDDeviceSetReport(dev, kIOHIDReportTypeFeature, RID_BRIGHTNESS, bright, sizeof bright) == kIOReturnSuccess ? 0 : -1;
        }
        IOHIDDeviceClose(dev, kIOHIDOptionsTypeNone);
    }
    CFRelease(dev);
    return rc;
}

int kb_hw_get(double *level) {
    IOHIDDeviceRef dev = copy_device();
    if (!dev) return -2;
    int rc = -1;
    if (IOHIDDeviceOpen(dev, kIOHIDOptionsTypeNone) == kIOReturnSuccess) {
        uint8_t buf[9] = {RID_BRIGHTNESS};
        CFIndex len = sizeof buf;
        if (IOHIDDeviceGetReport(dev, kIOHIDReportTypeFeature, RID_BRIGHTNESS, buf, &len) == kIOReturnSuccess && len >= 5) {
            uint32_t v = get32(buf + 1);
            if (v < BR_MIN) v = BR_MIN;
            if (v > BR_MAX) v = BR_MAX;
            if (level) *level = (double)(v - BR_MIN) / (BR_MAX - BR_MIN);
            rc = 0;
        }
        IOHIDDeviceClose(dev, kIOHIDOptionsTypeNone);
    }
    CFRelease(dev);
    return rc;
}

bool kb_hw_present(void) {
    IOHIDDeviceRef dev = copy_device();
    if (!dev) return false;
    CFRelease(dev);
    return true;
}

// ---------- Touch Bar ----------

static int tb_read(IOHIDDeviceRef dev, uint8_t report[11]) {
    report[0] = TB_RID;
    CFIndex len = 11;
    if (IOHIDDeviceGetReport(dev, kIOHIDReportTypeFeature, TB_RID, report, &len) != kIOReturnSuccess || len < 11)
        return -1;
    return 0;
}

int kb_tb_get(int *step, double *factor) {
    IOHIDDeviceRef dev = copy_device_from(tb_manager());
    if (!dev) return -2;
    int rc = -1;
    if (IOHIDDeviceOpen(dev, kIOHIDOptionsTypeNone) == kIOReturnSuccess) {
        uint8_t report[11] = {0};
        if (tb_read(dev, report) == 0) {
            if (step) *step = report[2];
            if (factor) *factor = get32(report + 7) / 1000.0;
            rc = 0;
        }
        IOHIDDeviceClose(dev, kIOHIDOptionsTypeNone);
    }
    CFRelease(dev);
    return rc;
}

int kb_tb_set_factor(double factor, bool force) {
    uint32_t value = (uint32_t)(factor * 1000 + 0.5);
    if (value < TB_FACTOR_MIN) value = TB_FACTOR_MIN;
    if (value > TB_FACTOR_MAX) value = TB_FACTOR_MAX;

    IOHIDDeviceRef dev = copy_device_from(tb_manager());
    if (!dev) return -2;
    int rc = -1;
    if (IOHIDDeviceOpen(dev, kIOHIDOptionsTypeNone) == kIOReturnSuccess) {
        uint8_t report[11] = {0};
        if (tb_read(dev, report) == 0) {
            if (report[2] != 1 && !force) {
                rc = 1;   // macOS is dimming it (idle): leave it alone
            } else if (get32(report + 7) == value) {
                rc = 0;   // already at the right level
            } else {
                put32(report + 7, value);   // only the factor changes
                rc = IOHIDDeviceSetReport(dev, kIOHIDReportTypeFeature, TB_RID, report, sizeof report) == kIOReturnSuccess ? 0 : -1;
            }
        }
        IOHIDDeviceClose(dev, kIOHIDOptionsTypeNone);
    }
    CFRelease(dev);
    return rc;
}

// ---------- idle time ----------

double kb_idle_seconds(void) {
    io_service_t hid = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"));
    if (!hid) return 0;
    CFTypeRef prop = IORegistryEntryCreateCFProperty(hid, CFSTR("HIDIdleTime"), kCFAllocatorDefault, 0);
    IOObjectRelease(hid);
    if (!prop) return 0;
    int64_t ns = 0;
    if (CFGetTypeID(prop) == CFNumberGetTypeID()) {
        CFNumberGetValue((CFNumberRef)prop, kCFNumberSInt64Type, &ns);
    } else if (CFGetTypeID(prop) == CFDataGetTypeID() && CFDataGetLength((CFDataRef)prop) >= (CFIndex)sizeof ns) {
        CFDataGetBytes((CFDataRef)prop, CFRangeMake(0, sizeof ns), (UInt8 *)&ns);
    }
    CFRelease(prop);
    return (double)ns / 1e9;
}

// ---------- notifications ----------

static void on_device(void *ctx, IOReturn result, void *sender, IOHIDDeviceRef device) {
    if (g_cb.device_arrived) g_cb.device_arrived();
}

static void on_system_power(void *refcon, io_service_t service, natural_t type, void *arg) {
    switch (type) {
    case kIOMessageCanSystemSleep:
    case kIOMessageSystemWillSleep:
        IOAllowPowerChange(g_root_port, (long)arg);
        break;
    case kIOMessageSystemHasPoweredOn:
        g_display_on = true;
        if (g_cb.system_did_wake) g_cb.system_did_wake();
        break;
    }
}

static void on_display_power(void *refcon, io_service_t service, natural_t type, void *arg) {
    if (type == kIOMessageDeviceWillPowerOff && g_display_on) {
        g_display_on = false;
        if (g_cb.display_did_sleep) g_cb.display_did_sleep();
    } else if (type == kIOMessageDeviceHasPoweredOn && !g_display_on) {
        g_display_on = true;
        if (g_cb.display_did_wake) g_cb.display_did_wake();
    }
}

void kb_watch_start(kb_callbacks callbacks) {
    g_cb = callbacks;
    CFRunLoopRef rl = CFRunLoopGetMain();

    // The T2 re-enumerates its internal devices after sleep.
    IOHIDManagerRegisterDeviceMatchingCallback(manager(), on_device, NULL);
    IOHIDManagerScheduleWithRunLoop(manager(), rl, kCFRunLoopCommonModes);

    IONotificationPortRef sys_port;
    io_object_t sys_notifier;
    g_root_port = IORegisterForSystemPower(NULL, &sys_port, on_system_power, &sys_notifier);
    if (g_root_port)
        CFRunLoopAddSource(rl, IONotificationPortGetRunLoopSource(sys_port), kCFRunLoopCommonModes);

    io_service_t wrangler = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IODisplayWrangler"));
    if (wrangler) {
        IONotificationPortRef disp_port = IONotificationPortCreate(kIOMainPortDefault);
        io_object_t disp_notifier;
        if (IOServiceAddInterestNotification(disp_port, wrangler, kIOGeneralInterest,
                                             on_display_power, NULL, &disp_notifier) == KERN_SUCCESS)
            CFRunLoopAddSource(rl, IONotificationPortGetRunLoopSource(disp_port), kCFRunLoopCommonModes);
        IOObjectRelease(wrangler);
    }
}
