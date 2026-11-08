import Foundation

/// How the process was launched.
enum RunMode: String {
    case agent   // by launchd at login ("daemon" argument)
    case app     // manually (Finder, Spotlight, Launchpad…)
}

enum AppEnv {
    nonisolated(unsafe) static var mode: RunMode = .app
    static let bundleID = "io.github.onixbrave.headlessglow"
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }
}

extension Notification.Name {
    /// Settings changed by another process (e.g. the `headlessglow set` command).
    static let headlessGlowChanged = Notification.Name("io.github.onixbrave.headlessglow.changed")
    /// Asks the running instance to show its settings.
    static let headlessGlowShowSettings = Notification.Name("io.github.onixbrave.headlessglow.show-settings")
}
