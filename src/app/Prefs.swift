import Carbon.HIToolbox
import Foundation

/// Persistent settings, in the "io.github.onixbrave.headlessglow" preferences domain
/// (readable with `defaults read io.github.onixbrave.headlessglow`). CFPreferences is used
/// directly so that the app and the `headlessglow` command share the same domain.
enum Prefs {
    private static let domain = AppEnv.bundleID as CFString

    private static func value(_ key: String) -> Any? {
        CFPreferencesCopyAppValue(key as CFString, domain)
    }
    private static func store(_ key: String, _ value: NSNumber?) {
        CFPreferencesSetAppValue(key as CFString, value, domain)
        CFPreferencesAppSynchronize(domain)
    }
    private static func double(_ key: String, _ fallback: Double) -> Double {
        (value(key) as? NSNumber)?.doubleValue ?? fallback
    }
    private static func bool(_ key: String, _ fallback: Bool) -> Bool {
        (value(key) as? NSNumber)?.boolValue ?? fallback
    }
    private static func int(_ key: String, _ fallback: Int) -> Int {
        (value(key) as? NSNumber)?.intValue ?? fallback
    }

    static func reload() { CFPreferencesAppSynchronize(domain) }

    /// Chosen level (0…1), kept even while the backlight is off.
    static var level: Double {
        get { min(max(double("level", 1.0), 0), 1) }
        set { store("level", NSNumber(value: newValue)) }
    }
    static var enabled: Bool {
        get { bool("enabled", true) }
        set { store("enabled", NSNumber(value: newValue)) }
    }
    /// Idle shutoff delay in seconds (0 = never).
    static var idleTimeout: Double {
        get { double("idleTimeout", 60) }
        set { store("idleTimeout", NSNumber(value: newValue)) }
    }
    static var offWithDisplay: Bool {
        get { bool("offWithDisplay", true) }
        set { store("offWithDisplay", NSNumber(value: newValue)) }
    }
    static var touchBarKeys: Bool {
        get { bool("touchBarKeys", true) }
        set { store("touchBarKeys", NSNumber(value: newValue)) }
    }
    static var showHUD: Bool {
        get { bool("showHUD", true) }
        set { store("showHUD", NSNumber(value: newValue)) }
    }
    /// Touch Bar brightness (0.1…1 of its base brightness).
    static var touchBarLevel: Double {
        get { min(max(double("touchBarLevel", 1.0), 0.1), 1) }
        set { store("touchBarLevel", NSNumber(value: newValue)) }
    }
    /// The Touch Bar follows the keyboard level (but not its off state).
    static var touchBarLinked: Bool {
        get { bool("touchBarLinked", false) }
        set { store("touchBarLinked", NSNumber(value: newValue)) }
    }
    /// Touch Bar at minimum while the display sleeps.
    static var touchBarDimWithDisplay: Bool {
        get { bool("touchBarDimWithDisplay", true) }
        set { store("touchBarDimWithDisplay", NSNumber(value: newValue)) }
    }
    /// Diagnostics: copies detailed messages to ~/Library/Logs/HeadlessGlow.log.
    static var debugLog: Bool { bool("debugLog", false) }
    /// Read and written by SwiftUI (@AppStorage, same domain as the app).
    static let showMenuBarIconKey = "showMenuBarIcon"
    /// Toggle shortcut (nil = none). Defaults to ⌃⌥K.
    static var shortcut: Shortcut? {
        get {
            let code = int("shortcutKeyCode", kVK_ANSI_K)
            guard code >= 0 else { return nil }
            return Shortcut(keyCode: UInt32(code),
                            modifiers: UInt32(int("shortcutModifiers", controlKey | optionKey)))
        }
        set {
            store("shortcutKeyCode", NSNumber(value: newValue.map { Int($0.keyCode) } ?? -1))
            store("shortcutModifiers", NSNumber(value: Int(newValue?.modifiers ?? 0)))
        }
    }
}
