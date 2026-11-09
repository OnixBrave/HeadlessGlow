import AppKit
import SwiftUI

struct HeadlessGlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    // Apple's recommended pattern for MenuBarExtra(isInserted:): an @AppStorage.
    // (Binding isInserted to an ObservableObject observed by the scene creates an
    // update loop: SwiftUI writes the value back on every update.)
    @AppStorage(Prefs.showMenuBarIconKey) private var showMenuBarIcon = true

    var body: some Scene {
        MenuBarExtra(isInserted: $showMenuBarIcon) {
            MenuBarPanel()
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.window)
    }
}

/// Menu bar icon, deliberately static: on macOS Tahoe, every image change of
/// a MenuBarExtra leaves ~0.5 MB behind in the remote status item rendering
/// (measured). The state is shown in the panel and the indicator instead.
struct MenuBarLabel: View {
    var body: some View {
        Image(systemName: "light.max")
            .accessibilityLabel("HeadlessGlow")
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var termSource: DispatchSourceSignal?

    func applicationWillTerminate(_ notification: Notification) {
        MainActor.assumeIsolated { Engine.shared.restoreTouchBar() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Stopped by launchd (bootout, uninstall): restore the Touch Bar first.
        signal(SIGTERM, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        source.setEventHandler {
            MainActor.assumeIsolated { Engine.shared.restoreTouchBar() }
            exit(0)
        }
        source.resume()
        termSource = source

        let others = NSRunningApplication.runningApplications(withBundleIdentifier: AppEnv.bundleID)
            .filter { $0.processIdentifier != getpid() }

        if !others.isEmpty {
            if AppEnv.mode == .app {
                // Already running: ask that instance to show its settings.
                DistributedNotificationCenter.default().postNotificationName(
                    .headlessGlowShowSettings, object: nil, userInfo: nil, deliverImmediately: true)
                exit(0)
            }
            // Launched by launchd while a manually opened instance runs: take over.
            others.forEach { $0.terminate() }
            let deadline = Date().addingTimeInterval(3)
            while others.contains(where: { !$0.isTerminated }) && Date() < deadline {
                RunLoop.current.run(until: Date().addingTimeInterval(0.1))
            }
        }

        MainActor.assumeIsolated {
            Engine.shared.start()
            if AppEnv.mode == .app { SettingsWindow.shared.show() }
        }
    }

    /// The app was double-clicked while already running.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        MainActor.assumeIsolated { SettingsWindow.shared.show() }
        return false
    }

    /// After a permission is granted, System Settings asks the app to quit so
    /// that it takes effect: in that case, relaunch.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if let requester = Self.quitRequesterPath(), requester.contains("System Settings.app")
            || requester.localizedCaseInsensitiveContains("privacy")
            || requester.localizedCaseInsensitiveContains("security") {
            Log.info("System Settings asked to quit (permission change): relaunching")
            Relaunch.now()
        }
        return .terminateNow
    }

    /// Path of the process that sent the quit Apple event, if any.
    private static func quitRequesterPath() -> String? {
        guard let event = NSAppleEventManager.shared().currentAppleEvent,
              event.eventClass == AEEventClass(kCoreEventClass),
              event.eventID == AEEventID(kAEQuitApplication),
              let pid = event.attributeDescriptor(forKeyword: AEKeyword(keySenderPIDAttr))?.int32Value,
              pid > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: 4096)
        guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { return nil }
        return String(cString: buffer)
    }
}

/// Settings window (AppKit + SwiftUI): the app shows up in the Dock while
/// it is open, then goes back to the background.
@MainActor
final class SettingsWindow: NSObject, NSWindowDelegate {
    static let shared = SettingsWindow()
    private var window: NSWindow?

    func show() {
        Log.debug("settings shown")
        if window == nil {
            let host = NSHostingController(rootView: SettingsView())
            let window = NSWindow(contentViewController: host)
            window.title = "HeadlessGlow"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            window.setContentSize(NSSize(width: 560, height: 760))
            window.contentMinSize = NSSize(width: 560, height: 480)
            window.contentMaxSize = NSSize(width: 560, height: 1600)
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            window.setFrameAutosaveName("HeadlessGlow.settings")
            self.window = window
        }
        NSApp.setActivationPolicy(.regular)
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        Log.debug("settings closed")
        // Destroy the window and its SwiftUI hierarchy: a hidden view that stays
        // subscribed to the engine piles up updates that are never displayed.
        let closing = window
        window = nil
        DispatchQueue.main.async {
            closing?.contentViewController = nil
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
