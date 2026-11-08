import Foundation

/// Translations: `Localizable.xcstrings` catalog (English is the source
/// language, French is translated), compiled into the bundle by build.sh.
enum L10n {
    /// The app bundle, even when the executable is started through a symlink
    /// (Bundle.main then doesn't point at the .app).
    static let bundle: Bundle = {
        if Bundle.main.bundleIdentifier == AppEnv.bundleID { return .main }
        if let exe = Bundle.main.executableURL?.resolvingSymlinksInPath() {
            let app = exe.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            if let bundle = Bundle(url: app), bundle.bundleIdentifier == AppEnv.bundleID { return bundle }
        }
        return .main
    }()
}

/// Translated string (for code outside SwiftUI: engine, Terminal command…).
func tr(_ key: String.LocalizationValue) -> String {
    String(localized: key, bundle: L10n.bundle)
}

/// Percentage formatted for the region ("69 %" in French, "69%" in English).
func percentText(_ value: Double) -> String {
    value.formatted(.percent.precision(.fractionLength(0)))
}
