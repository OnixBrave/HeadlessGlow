import AppKit
import SwiftUI

/// Single source of truth: settings, state and hardware control.
@MainActor
final class Engine: ObservableObject {
    static let shared = Engine()

    // MARK: Persisted settings

    /// Chosen level (0…1), kept while the backlight is off.
    @Published private(set) var level = Prefs.level
    @Published private(set) var enabled = Prefs.enabled
    @Published var idleTimeout = Prefs.idleTimeout {
        didSet { Prefs.idleTimeout = idleTimeout; rescheduleIdle() }
    }
    @Published var offWithDisplay = Prefs.offWithDisplay {
        didSet { Prefs.offWithDisplay = offWithDisplay }
    }
    @Published var touchBarKeys = Prefs.touchBarKeys {
        didSet { Prefs.touchBarKeys = touchBarKeys }
    }
    @Published var showIndicator = Prefs.showHUD {
        didSet { Prefs.showHUD = showIndicator }
    }
    @Published var shortcut = Prefs.shortcut {
        didSet { Prefs.shortcut = shortcut; registerHotKey() }
    }
    @Published var launchAtLogin = LoginItem.isEnabled {
        didSet { if launchAtLogin != oldValue { LoginItem.setEnabled(launchAtLogin) } }
    }
    /// The Touch Bar's own brightness (used when it isn't linked).
    @Published private(set) var touchBarLevel = Prefs.touchBarLevel
    @Published var touchBarLinked = Prefs.touchBarLinked {
        didSet {
            guard touchBarLinked != oldValue else { return }
            Prefs.touchBarLinked = touchBarLinked
            applyTouchBar()
        }
    }
    /// Touch Bar at minimum while the display sleeps.
    @Published var touchBarDimWithDisplay = Prefs.touchBarDimWithDisplay {
        didSet {
            guard touchBarDimWithDisplay != oldValue else { return }
            Prefs.touchBarDimWithDisplay = touchBarDimWithDisplay
            if displayAsleep { applyTouchBar() }
        }
    }

    // MARK: State

    @Published private(set) var hardwarePresent = true
    @Published private(set) var touchBarPresent = true
    @Published private(set) var permissionGranted = false
    @Published private(set) var hotKeyAvailable = true
    @Published private(set) var idleDimmed = false
    @Published private(set) var displayAsleep = false

    private var started = false
    private var touchBarTimer: Timer?
    /// A write was deferred (macOS was dimming the Touch Bar): keep watching until it's right.
    private var touchBarPending = false
    /// Closer watch after a wake: macOS may later restore the brightness it had
    /// saved (our display-sleep minimum).
    private var touchBarWatchUntil = Date.distantPast
    private var idleTimer: Timer?
    private var activityPoll: Timer?
    private var permissionTimer: Timer?

    private init() {}

    /// Level actually sent to the hardware.
    var outputLevel: Double {
        guard enabled, !idleDimmed, !(displayAsleep && offWithDisplay) else { return 0 }
        return level
    }
    var isLit: Bool { outputLevel > 0 }
    var percent: Int { Int((level * 100).rounded()) }

    var statusText: String {
        if !hardwarePresent { return tr("Controller not found") }
        if !enabled { return tr("Off") }
        if displayAsleep && offWithDisplay { return tr("Off · display asleep") }
        if idleDimmed { return tr("Dimmed · inactive") }
        return tr("On · \(percentText(level))")
    }

    // MARK: UI bindings

    var enabledBinding: Binding<Bool> {
        Binding(get: { self.enabled }, set: { self.setEnabled($0) })
    }
    var levelBinding: Binding<Double> {
        Binding(get: { self.enabled ? self.level : 0 }, set: { self.setLevel($0) })
    }
    var touchBarBinding: Binding<Double> {
        Binding(get: { self.touchBarTarget }, set: { self.setTouchBarLevel($0) })
    }

    // MARK: Touch Bar

    /// Touch Bar target level: when linked, it follows the keyboard's chosen level
    /// (kept even when the keyboard is off, so the Touch Bar stays usable).
    var touchBarTarget: Double {
        min(max(touchBarLinked ? level : touchBarLevel, 0.1), 1)
    }

    /// Display asleep and option enabled: the Touch Bar is forced to its minimum.
    private var touchBarAsleep: Bool { displayAsleep && touchBarDimWithDisplay }

    func setTouchBarLevel(_ value: Double) {
        guard !touchBarLinked else { return }
        touchBarLevel = min(max(value, 0.1), 1)
        Prefs.touchBarLevel = touchBarLevel
        applyTouchBar()
    }

    /// Applies the target level; while it is below 100%, a lightweight check
    /// reapplies it after macOS turns the Touch Bar back on (macOS resets it to 100%).
    func applyTouchBar() {
        guard started else { return }
        let asleep = touchBarAsleep
        let result = kb_tb_set_factor(asleep ? 0.1 : touchBarTarget, asleep)
        let present = result != -2
        if present != touchBarPresent {
            touchBarPresent = present
            Log.info(present ? "Touch Bar control found" : "Touch Bar control not found")
        }
        if !asleep && result == 1 { touchBarPending = true }   // deferred: macOS is dimming it
        updateTouchBarWatch()
    }

    /// Periodic check while the target is below 100%, while a write is
    /// pending, or right after a wake.
    private func updateTouchBarWatch() {
        let needsWatch = touchBarPresent && !touchBarAsleep
            && (touchBarTarget < 0.995 || touchBarPending || Date() < touchBarWatchUntil)
        if needsWatch && touchBarTimer == nil {
            let timer = Timer(timeInterval: 1, repeats: true) { _ in
                MainActor.assumeIsolated { Engine.shared.checkTouchBar() }
            }
            timer.tolerance = 0.3   // lets the system coalesce wake-ups
            RunLoop.main.add(timer, forMode: .common)
            touchBarTimer = timer
        } else if !needsWatch {
            touchBarTimer?.invalidate()
            touchBarTimer = nil
        }
    }

    private func checkTouchBar() {
        guard !touchBarAsleep else { return }
        var step: Int32 = 0
        var factor = 0.0
        guard kb_tb_get(&step, &factor) == 0, step == 1 else { return }   // macOS is dimming it: wait
        if abs(factor - touchBarTarget) > 0.005 {
            Log.debug("Touch Bar set to \(Int(factor * 100))% by macOS → \(Int(touchBarTarget * 100))%")
            _ = kb_tb_set_factor(touchBarTarget, false)
        } else {
            touchBarPending = false
            updateTouchBarWatch()   // at 100% and past the wake period: the watch stops
        }
    }

    /// After a wake (display or system), watch the Touch Bar for a few seconds.
    private func touchBarAfterWake() {
        touchBarWatchUntil = Date().addingTimeInterval(15)
        touchBarPending = true
        applyTouchBar()
    }

    /// Restores the Touch Bar's normal brightness (when the app quits).
    func restoreTouchBar() {
        touchBarTimer?.invalidate()
        touchBarTimer = nil
        _ = kb_tb_set_factor(1, false)
    }

    // MARK: Startup

    func start() {
        guard !started else { return }
        started = true
        Log.rotateIfNeeded()
        reloadFromPrefs(applyNow: false)
        Log.info("start v\(AppEnv.version) (\(AppEnv.mode.rawValue)), level \(percent)%, \(enabled ? "on" : "off")")

        kb_watch_start(kb_callbacks(
            device_arrived: { MainActor.assumeIsolated { Engine.shared.deviceArrived() } },
            system_did_wake: { MainActor.assumeIsolated { Engine.shared.systemWoke() } },
            display_did_sleep: { MainActor.assumeIsolated { Engine.shared.displaySlept() } },
            display_did_wake: { MainActor.assumeIsolated { Engine.shared.displayWoke() } }
        ))
        apply(fade: 500)
        applyTouchBar()
        setUpKeyListening()
        registerHotKey()
        rescheduleIdle()

        let center = DistributedNotificationCenter.default()
        center.addObserver(forName: .headlessGlowChanged, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { Engine.shared.reloadFromPrefs(applyNow: true) }
        }
        center.addObserver(forName: .headlessGlowShowSettings, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { SettingsWindow.shared.show() }
        }
    }

    /// Re-reads the preferences (at startup, or after `headlessglow …` / `defaults write` + `headlessglow reload`).
    func reloadFromPrefs(applyNow: Bool) {
        Prefs.reload()
        level = Prefs.level
        enabled = Prefs.enabled
        if idleTimeout != Prefs.idleTimeout { idleTimeout = Prefs.idleTimeout }
        if offWithDisplay != Prefs.offWithDisplay { offWithDisplay = Prefs.offWithDisplay }
        if touchBarKeys != Prefs.touchBarKeys { touchBarKeys = Prefs.touchBarKeys }
        if showIndicator != Prefs.showHUD { showIndicator = Prefs.showHUD }
        if shortcut != Prefs.shortcut { shortcut = Prefs.shortcut }
        touchBarLevel = Prefs.touchBarLevel
        if touchBarLinked != Prefs.touchBarLinked { touchBarLinked = Prefs.touchBarLinked }
        if touchBarDimWithDisplay != Prefs.touchBarDimWithDisplay { touchBarDimWithDisplay = Prefs.touchBarDimWithDisplay }
        guard applyNow else { return }
        endIdleDim()
        apply(fade: 300)
        applyTouchBar()
        rescheduleIdle()
    }

    /// Fake state for screenshots (touches neither the hardware nor the preferences).
    func preview(level: Double, enabled: Bool) {
        self.level = level
        self.enabled = enabled
        permissionGranted = true
        hardwarePresent = true
        touchBarPresent = true
    }

    // MARK: Hardware

    func apply(fade: Int) {
        let result = kb_hw_set(outputLevel, Int32(fade))
        let present = result != -2
        if present != hardwarePresent {
            hardwarePresent = present
            Log.info(present ? "backlight controller found" : "backlight controller not found")
        }
        if result == -1 { Log.info("communication with the backlight controller failed") }
    }

    // MARK: Actions

    func setEnabled(_ on: Bool, fade: Int = 250, showIndicator indicator: Bool = false) {
        enabled = on
        Prefs.enabled = on
        if on && level <= 0 { level = 0.5; Prefs.level = level }
        userDidSomething()
        apply(fade: fade)
        if touchBarLinked { applyTouchBar() }
        if indicator { showIndicatorIfNeeded() }
    }

    func toggle(showIndicator indicator: Bool) {
        setEnabled(!enabled, showIndicator: indicator)
        Log.debug("toggle → \(enabled ? "on" : "off")")
    }

    /// Slider: 0 turns it off, anything else sets the level and turns it on.
    func setLevel(_ value: Double, fade: Int = 60) {
        if value <= 0.005 {
            if enabled { enabled = false; Prefs.enabled = false }
        } else {
            level = min(value, 1)
            Prefs.level = level
            if !enabled { enabled = true; Prefs.enabled = true }
        }
        userDidSomething()
        apply(fade: fade)
        if touchBarLinked { applyTouchBar() }
    }

    /// Key step: 16 steps like macOS, 64 with ⌥⇧.
    func step(_ direction: Int, fine: Bool) {
        let steps = fine ? 64.0 : 16.0
        let current = enabled ? level : 0
        let index = min(max((current * steps).rounded() + Double(direction), 0), steps)
        if index == 0 {
            enabled = false
            Prefs.enabled = false
        } else {
            level = index / steps
            Prefs.level = level
            enabled = true
            Prefs.enabled = true
        }
        userDidSomething()
        apply(fade: 120)
        if touchBarLinked { applyTouchBar() }
        showIndicatorIfNeeded()
        Log.debug("step \(direction > 0 ? "+" : "−")\(fine ? " (fine)" : "") → \(enabled ? "\(percent)%" : "off")")
    }

    func handleSystemKey(code: Int, flags: NSEvent.ModifierFlags) {
        guard touchBarKeys else { return }
        let option = flags.contains(.option), shift = flags.contains(.shift)
        switch code {
        case 21, 22:   // NX_KEYTYPE_ILLUMINATION_UP / DOWN
            if option && !shift {   // ⌥ + key: opens the settings (like macOS)
                SettingsWindow.shared.show()
                return
            }
            step(code == 21 ? 1 : -1, fine: option && shift)
        case 23:       // NX_KEYTYPE_ILLUMINATION_TOGGLE
            toggle(showIndicator: true)
        default:
            break
        }
    }

    func registerHotKey() {
        hotKeyAvailable = HotKey.register(shortcut)
    }

    private func showIndicatorIfNeeded() {
        guard showIndicator else { return }
        Indicator.shared.show(level: enabled ? level : 0)
    }

    // MARK: Permission and key listening

    private func setUpKeyListening() {
        if Permission.preflight() {
            permissionGranted = true
            if !KeyTap.startSystemKeys() { Log.info("cannot listen to brightness keys") }
            return
        }
        permissionGranted = false
        Log.info("Input Monitoring permission missing: brightness keys inactive until granted")
        Permission.request()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            MainActor.assumeIsolated {
                guard Permission.freshCheck() else { return }
                Log.info("Input Monitoring permission granted: relaunching")
                Relaunch.now()
            }
        }
    }

    // MARK: Idle

    /// Any explicit user action turns the light back on and restarts the countdown.
    private func userDidSomething() {
        endIdleDim()
        rescheduleIdle()
    }

    func rescheduleIdle() {
        idleTimer?.invalidate()
        idleTimer = nil
        guard started, idleTimeout > 0, enabled, !idleDimmed, !displayAsleep else { return }
        let remaining = max(0.5, idleTimeout - kb_idle_seconds())
        idleTimer = Timer.scheduledTimer(withTimeInterval: remaining, repeats: false) { _ in
            MainActor.assumeIsolated { Engine.shared.idleCheck() }
        }
    }

    private func idleCheck() {
        guard idleTimeout > 0, enabled, !idleDimmed, !displayAsleep else { return }
        let idle = kb_idle_seconds()
        guard idle >= idleTimeout - 0.3 else {
            Log.debug(String(format: "idle: %.1f s / %.0f s, waiting", idle, idleTimeout))
            rescheduleIdle()
            return
        }
        idleDimmed = true
        Log.debug(String(format: "idle: %.1f s → backlight off", idle))
        apply(fade: 1500)
        if !KeyTap.startActivity() {
            // Without an event tap, poll the system idle time instead.
            Log.debug("cannot listen for activity: polling instead")
            activityPoll = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                MainActor.assumeIsolated { if kb_idle_seconds() < 1 { Engine.shared.userActivity(trigger: "system idle time") } }
            }
        }
    }

    /// First input after an idle shutoff.
    func userActivity(trigger: String) {
        guard idleDimmed else { return }
        Log.debug("wake (\(trigger))")
        endIdleDim()
        apply(fade: 250)
        rescheduleIdle()
    }

    private func endIdleDim() {
        guard idleDimmed else { return }
        idleDimmed = false
        KeyTap.stopActivity()
        activityPoll?.invalidate()
        activityPoll = nil
    }

    // MARK: System events

    private func deviceArrived() {
        apply(fade: 300)
        applyTouchBar()
    }

    private func systemWoke() {
        displayAsleep = false
        endIdleDim()
        apply(fade: 500)
        touchBarAfterWake()
        rescheduleIdle()
    }

    private func displaySlept() {
        displayAsleep = true
        idleTimer?.invalidate()
        endIdleDim()
        apply(fade: 500)
        applyTouchBar()   // forced to minimum if the option is on
        Log.debug("display asleep")
    }

    private func displayWoke() {
        displayAsleep = false
        apply(fade: 500)
        touchBarAfterWake()
        rescheduleIdle()
        Log.debug("display awake")
    }
}
