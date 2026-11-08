import AppKit

// Entry point: Terminal command, launchd service, or manually opened app.
let arguments = Array(CommandLine.arguments.dropFirst())

switch arguments.first {
case "daemon":
    AppEnv.mode = .agent
    HeadlessGlowApp.main()
case "--check-permission":   // internal use (see Permission.freshCheck)
    exit(CGPreflightListenEventAccess() ? 0 : 1)
case "--snapshot":           // UI screenshots (development)
    MainActor.assumeIsolated { Snapshot.run(directory: arguments.dropFirst().first ?? ".") }
case let command? where !command.hasPrefix("-"):
    exit(CLI.run(arguments))
default:                     // Finder, Spotlight, Launchpad (system "-…" arguments are ignored)
    AppEnv.mode = .app
    HeadlessGlowApp.main()
}
