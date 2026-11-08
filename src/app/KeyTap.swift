import AppKit

/// Event taps, always LISTEN-ONLY: they can neither block nor modify
/// a keystroke.
///  - system keys: "illumination +/−/toggle" sent by the Touch Bar;
///  - activity: only exists during an idle shutoff, to turn the light back
///    on instantly at the first input.
enum KeyTap {
    nonisolated(unsafe) private static var systemTap: CFMachPort?
    nonisolated(unsafe) private static var activityTap: CFMachPort?
    nonisolated(unsafe) private static var activitySource: CFRunLoopSource?

    private static let systemDefined: CGEventType.RawValue = 14   // NX_SYSDEFINED

    static func startSystemKeys() -> Bool {
        if systemTap != nil { return true }
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                          options: .listenOnly, eventsOfInterest: CGEventMask(1) << systemDefined,
                                          callback: systemCallback, userInfo: nil) else { return false }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        systemTap = tap
        return true
    }

    static func startActivity() -> Bool {
        if activityTap != nil { return true }
        let types: [CGEventType.RawValue] = [
            CGEventType.keyDown.rawValue, CGEventType.flagsChanged.rawValue,
            CGEventType.leftMouseDown.rawValue, CGEventType.rightMouseDown.rawValue,
            CGEventType.otherMouseDown.rawValue, CGEventType.mouseMoved.rawValue,
            CGEventType.leftMouseDragged.rawValue, CGEventType.scrollWheel.rawValue, systemDefined,
        ]
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1) }
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .tailAppendEventTap,
                                          options: .listenOnly, eventsOfInterest: mask,
                                          callback: activityCallback, userInfo: nil) else { return false }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        activityTap = tap
        activitySource = source
        return true
    }

    static func stopActivity() {
        if let tap = activityTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source = activitySource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        activityTap = nil
        activitySource = nil
    }

    fileprivate static func reenable() {
        if let tap = systemTap { CGEvent.tapEnable(tap: tap, enable: true) }
        if let tap = activityTap { CGEvent.tapEnable(tap: tap, enable: true) }
    }
}

private func systemCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent,
                            refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        KeyTap.reenable()
    } else if type.rawValue == 14, let ns = NSEvent(cgEvent: event), ns.subtype.rawValue == 8 {
        // NX_SUBTYPE_AUX_CONTROL_BUTTONS: data1 = code << 16 | state << 8
        let code = (ns.data1 & 0xFFFF_0000) >> 16
        let state = (ns.data1 & 0x0000_FF00) >> 8
        if state == 0xA {   // key down (and repeat)
            let flags = ns.modifierFlags
            MainActor.assumeIsolated { Engine.shared.handleSystemKey(code: code, flags: flags) }
        }
    }
    return Unmanaged.passUnretained(event)
}

private func activityCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent,
                              refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        KeyTap.reenable()
    } else {
        // Deferred: the tap is removed outside of its own callback.
        let trigger: String
        if type.rawValue == 14, let ns = NSEvent(cgEvent: event) {
            trigger = "system event \(type.rawValue), subtype \(ns.subtype.rawValue), data1 \(String(ns.data1, radix: 16))"
        } else {
            trigger = "event \(type.rawValue)"
        }
        DispatchQueue.main.async { MainActor.assumeIsolated { Engine.shared.userActivity(trigger: trigger) } }
    }
    return Unmanaged.passUnretained(event)
}
