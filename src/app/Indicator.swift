import AppKit
import SwiftUI

/// On-screen indicator (the system OSDManager API is ignored by macOS Tahoe
/// for third-party apps). Floating, non-activating, click-through window.
@MainActor
final class Indicator {
    static let shared = Indicator()
    static let size = NSSize(width: 260, height: 52)
    private static let visibleSeconds = 1.5
    private static let fadeSeconds = 0.3

    private let model = IndicatorModel()
    private var panel: NSPanel?
    private var generation = 0

    func show(level: Double) {
        let panel = self.panel ?? makePanel()
        self.panel = panel
        withAnimation(.smooth(duration: 0.18)) { model.level = level }
        position(panel)
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        generation += 1
        let current = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.visibleSeconds) { [weak self] in
            guard let self, current == self.generation else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = Self.fadeSeconds
                panel.animator().alphaValue = 0
            }, completionHandler: {
                MainActor.assumeIsolated {
                    if current == self.generation { panel.orderOut(nil) }
                }
            })
        }
    }

    private func makePanel() -> NSPanel {
        let frame = NSRect(origin: .zero, size: Self.size)
        let panel = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.overlayWindow)))
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]

        // System blur that follows light / dark mode, masked to a capsule.
        let effect = NSVisualEffectView(frame: frame)
        effect.material = .popover
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.maskImage = Self.capsuleMask(height: frame.height)

        let host = NSHostingView(rootView: IndicatorView(model: model))
        host.frame = frame
        host.autoresizingMask = [.width, .height]
        effect.addSubview(host)
        panel.contentView = effect
        return panel
    }

    /// Top right of the screen under the pointer, below the menu bar.
    private func position(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) })
                ?? NSScreen.main ?? NSScreen.screens.first else { return }
        let area = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(x: area.maxX - Self.size.width - 12,
                                     y: area.maxY - Self.size.height - 12))
    }

    private static func capsuleMask(height: CGFloat) -> NSImage {
        let radius = height / 2
        let side = radius * 2 + 1
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }
}

@MainActor
final class IndicatorModel: ObservableObject {
    @Published var level: Double = 0
}

struct IndicatorView: View {
    @ObservedObject var model: IndicatorModel

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: model.level > 0 ? "light.max" : "light.min")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 24)
                .contentTransition(.symbolEffect(.replace))
            LevelBar(level: model.level)
        }
        .padding(.horizontal, 18)
        .frame(width: Indicator.size.width, height: Indicator.size.height)
    }
}

/// Thin gauge: translucent track + proportional fill.
struct LevelBar: View {
    var level: Double
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.primary.opacity(0.16))
                Capsule().fill(.primary)
                    .frame(width: level > 0 ? max(height, geo.size.width * level) : 0)
            }
        }
        .frame(height: height)
    }
}
