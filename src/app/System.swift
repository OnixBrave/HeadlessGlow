import AppKit

/// Input Monitoring permission (needed to listen to the Touch Bar's
/// brightness keys).
enum Permission {
    static func preflight() -> Bool { CGPreflightListenEventAccess() }

    /// Shows the system prompt (once per binary).
    static func request() { _ = CGRequestListenEventAccess() }

    /// CGPreflightListenEventAccess() caches its first answer for the lifetime
    /// of the process, so ask through a fresh process instead.
    static func freshCheck() -> Bool {
        guard let path = Bundle.main.executablePath else { return false }
        let argv: [UnsafeMutablePointer<CChar>?] = [strdup(path), strdup("--check-permission"), nil]
        defer { argv.forEach { free($0) } }
        var pid: pid_t = 0
        guard posix_spawn(&pid, path, nil, nil, argv, environ) == 0 else { return false }
        var status: Int32 = 0
        guard waitpid(pid, &status, 0) == pid else { return false }
        return (status & 0x7f) == 0 && ((status >> 8) & 0xff) == 0   // exited normally with code 0
    }

    static func openSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }
}

enum Relaunch {
    /// Cleanly relaunches the app (e.g. after the permission is granted).
    static func now() -> Never {
        if AppEnv.mode == .agent {
            exit(75)   // non-zero code: launchd restarts the service right away
        }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "sleep 1; /usr/bin/open \"$0\"", Bundle.main.bundlePath]
        try? task.run()
        exit(0)
    }
}

/// Open at login = the "io.github.onixbrave.headlessglow" launchd service
/// (installed by install.sh), enabled or disabled with launchctl.
enum LoginItem {
    private static var domain: String { "gui/\(getuid())" }
    private static var plist: String { NSHomeDirectory() + "/Library/LaunchAgents/\(AppEnv.bundleID).plist" }

    static var isInstalled: Bool { FileManager.default.fileExists(atPath: plist) }

    static var isEnabled: Bool {
        guard isInstalled else { return false }
        for line in launchctl(["print-disabled", domain]).split(separator: "\n")
        where line.contains("\"\(AppEnv.bundleID)\"") {
            return !(line.contains("disabled") || line.contains("=> true"))
        }
        return true
    }

    static func setEnabled(_ enabled: Bool) {
        guard isInstalled else { return }
        _ = launchctl([enabled ? "enable" : "disable", "\(domain)/\(AppEnv.bundleID)"])
        Log.info(enabled ? "open at login enabled" : "open at login disabled")
    }

    private static func launchctl(_ args: [String]) -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        do { try task.run() } catch { return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        return String(decoding: data, as: UTF8.self)
    }
}
