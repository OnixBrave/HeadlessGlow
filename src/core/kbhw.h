// kbhw — low-level access to the keyboard backlight of T2 MacBook Pros.
//
// The T2 exposes a "magic backlight" HID interface (VID 0x05AC, PID 0x8102
// "Touch Bar Backlight", usage 0xFF00:0x0F). Feature report format, the same
// as in the Linux hid-apple driver (apple_magic_backlight):
//   ID 1: [0x01][brightness u32 LE, 100…14660][fade ms u32 LE]
//   ID 3: [0x03][power u8, 0/1]               [fade ms u32 LE]
// Nothing is written permanently to the T2.
#pragma once
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Callbacks invoked on the main run loop by kb_watch_start().
typedef struct {
    void (*device_arrived)(void);      // interface (re)appeared, e.g. after sleep
    void (*system_did_wake)(void);     // system woke from sleep
    void (*display_did_sleep)(void);   // the display dims / turns off
    void (*display_did_wake)(void);    // the display turns back on
} kb_callbacks;

/// Sets the backlight. level: 0…1 (0 = off), fade_ms: fade duration.
/// Returns 0 on success, -1 on a communication error, -2 if the interface is missing.
int kb_hw_set(double level, int fade_ms);

/// Reads the brightness programmed in the T2 (0…1). Same return codes.
int kb_hw_get(double *level);

/// True if the T2 backlight interface is present.
bool kb_hw_present(void);

/// Seconds since the last keyboard / mouse / trackpad input.
double kb_idle_seconds(void);

// ---------- Touch Bar ----------
// T2 HID interface 05AC:8102, usage 0xFF12:0x01 (which macOS treats as the
// ambient light sensor). Feature report 1:
//   [0x01][state u8][step u8 (1 normal, 2-3 dimmed by macOS)][u32][factor u32 0…1000]
// The factor scales the Touch Bar's base brightness; values above 1000 are
// accepted but have no visible effect (it can only be dimmed).

/// Reads macOS's dimming step (1 = normal) and the factor (0…1). Same return codes as kb_hw_*.
int kb_tb_get(int *step, double *factor);

/// Sets the factor (clamped to 0.1…1). Without `force`, only writes when the Touch Bar
/// is at the normal step, so macOS's own dimming isn't overridden (returns 1 otherwise).
int kb_tb_set_factor(double factor, bool force);

/// Starts watching for device, system sleep and display sleep events.
void kb_watch_start(kb_callbacks callbacks);

#ifdef __cplusplus
}
#endif
