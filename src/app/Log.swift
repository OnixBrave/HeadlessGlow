import AppKit
import os

/// Logging: everything goes to the unified log (Console app, subsystem
/// "io.github.onixbrave.headlessglow"). Only important events also go to
/// ~/Library/Logs/HeadlessGlow.log, which is capped at 512 KB.
enum Log {
    private static let logger = Logger(subsystem: AppEnv.bundleID, category: "main")
    static let fileURL = URL(fileURLWithPath: NSHomeDirectory() + "/Library/Logs/HeadlessGlow.log")
    private static let maxFileSize = 512 * 1024

    private static let stamp: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    /// Important event (startup, permission, error…).
    static func info(_ message: String) {
        logger.notice("\(message, privacy: .public)")
        append(message)
    }

    /// Detail (key presses, idle…): unified log only, unless diagnostics are
    /// enabled (`defaults write io.github.onixbrave.headlessglow debugLog -bool YES`).
    static func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
        if Prefs.debugLog { append("· " + message) }
    }

    /// Rotates the file to .1 when it exceeds the maximum size.
    static func rotateIfNeeded() {
        let fm = FileManager.default
        guard let size = (try? fm.attributesOfItem(atPath: fileURL.path))?[.size] as? Int,
              size > maxFileSize else { return }
        let old = fileURL.appendingPathExtension("1")
        try? fm.removeItem(at: old)
        try? fm.moveItem(at: fileURL, to: old)
    }

    static func reveal() {
        let console = URL(fileURLWithPath: "/System/Applications/Utilities/Console.app")
        NSWorkspace.shared.open([fileURL], withApplicationAt: console, configuration: NSWorkspace.OpenConfiguration())
    }

    private static func append(_ message: String) {
        let line = "\(stamp.string(from: Date())) [HeadlessGlow] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: fileURL)
        }
    }
}
