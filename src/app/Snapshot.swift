import AppKit
import SwiftUI

/// Development tool: renders the app's views in off-screen windows and
/// saves them as PNG (light and dark). Only captures its own windows.
@MainActor
enum Snapshot {
    static func run(directory: String) -> Never {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.accessory)
        let dir = URL(fileURLWithPath: directory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        Engine.shared.preview(level: 0.5625, enabled: true)
        for (name, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            capture(SettingsView(), size: NSSize(width: 560, height: 1520), titled: true,
                    appearance: appearance, to: dir.appendingPathComponent("settings-\(name).png"))
            capture(MenuBarView(), size: NSSize(width: 300, height: 250), titled: false,
                    appearance: appearance, to: dir.appendingPathComponent("menu-\(name).png"))
        }
        exit(0)
    }

    private static func capture<V: View>(_ view: V, size: NSSize, titled: Bool,
                                         appearance: NSAppearance.Name, to url: URL) {
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
        host.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: host.frame,
                              styleMask: titled ? [.titled, .fullSizeContentView] : [.borderless],
                              backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: appearance)
        window.titlebarAppearsTransparent = true
        window.contentView = host
        window.setFrameOrigin(NSPoint(x: -20000, y: -20000))   // off screen
        window.orderFrontRegardless()
        RunLoop.current.run(until: Date().addingTimeInterval(0.8))

        var image = compositedImage(of: window.windowNumber)
        if image == nil {
            // AppKit's own rendering: layout only (SwiftUI forms may come out blank).
            FileHandle.standardError.write(Data("snapshot: composited capture unavailable, using AppKit rendering\n".utf8))
            if let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) {
                host.cacheDisplay(in: host.bounds, to: rep)
                image = rep.cgImage
            }
        }
        if let image {
            try? NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])?.write(to: url)
        }
        window.orderOut(nil)
    }

    /// Real composited rendering of one of our own windows. CGWindowListCreateImage
    /// is no longer exposed by the SDK, so it is called dynamically; it can block
    /// (e.g. waiting for a screen recording permission in a CI virtual machine),
    /// so it runs on a background thread and is abandoned after 5 seconds.
    private static func compositedImage(of windowNumber: Int) -> CGImage? {
        typealias CreateImage = @convention(c) (CGRect, UInt32, UInt32, UInt32) -> Unmanaged<CGImage>?
        guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CGWindowListCreateImage") else { return nil }
        let create = unsafeBitCast(symbol, to: CreateImage.self)
        final class Box: @unchecked Sendable { var image: CGImage? }
        let box = Box()
        let done = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            box.image = create(.null, 1 << 3, UInt32(windowNumber), (1 << 0) | (1 << 3))?.takeRetainedValue()
            done.signal()
        }
        return done.wait(timeout: .now() + 5) == .success ? box.image : nil
    }
}
