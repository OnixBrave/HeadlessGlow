import SwiftUI

/// Panel container: its content (subscribed to the engine) only exists while
/// the panel is open. When hidden, SwiftUI keeps the window alive, and the
/// content would otherwise pile up updates that are never displayed.
struct MenuBarPanel: View {
    @State private var isOpen = false

    var body: some View {
        Group {
            if isOpen {
                MenuBarView()
            } else {
                Color.clear.frame(width: 300, height: 210)
            }
        }
        .onAppear { isOpen = true; Log.debug("panel opened") }
        .onDisappear { isOpen = false; Log.debug("panel closed") }
    }
}

/// Menu bar panel, in the spirit of Control Center modules.
struct MenuBarView: View {
    @ObservedObject var engine = Engine.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ToggleBubble(isOn: engine.enabled) { engine.toggle(showIndicator: false) }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Keyboard Backlight")
                        .font(.system(size: 13, weight: .semibold))
                    Text(verbatim: engine.statusText)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            ControlSlider(value: engine.levelBinding)

            if engine.touchBarPresent {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("Touch Bar")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if engine.touchBarLinked {
                            Label("Linked to keyboard", systemImage: "link")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    ControlSlider(value: engine.touchBarBinding, minimum: 0.1,
                                  symbolOn: "sun.max", symbolOff: "sun.min",
                                  accessibilityName: "Touch Bar Brightness")
                        .disabled(engine.touchBarLinked)
                        .opacity(engine.touchBarLinked ? 0.55 : 1)
                }
            }

            if !engine.permissionGranted {
                Button {
                    Permission.openSettings()
                    dismiss()
                } label: {
                    Label("Allow Touch Bar brightness keys…", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
            }

            Divider()

            VStack(spacing: 0) {
                MenuRow(title: "HeadlessGlow Settings…") {
                    dismiss()
                    SettingsWindow.shared.show()
                }
                MenuRow(title: "Quit HeadlessGlow") { NSApp.terminate(nil) }
            }
            .padding(.horizontal, -6)
        }
        .padding(14)
        .frame(width: 300)
    }
}

/// Control Center-style round bubble: accent tint when on.
struct ToggleBubble: View {
    var isOn: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isOn ? "light.max" : "light.min")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isOn ? Color.white : Color.primary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(isOn ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary)))
        }
        .buttonStyle(.plain)
        .help(isOn ? LocalizedStringKey("Turn backlight off") : LocalizedStringKey("Turn backlight on"))
        .accessibilityLabel(Text("Keyboard Backlight"))
        .accessibilityValue(isOn ? Text("On") : Text("Off"))
    }
}

/// Thick Control Center-style slider with a built-in icon.
struct ControlSlider: View {
    @Binding var value: Double
    var minimum: Double = 0
    var symbolOn = "light.max"
    var symbolOff = "light.min"
    var accessibilityName: LocalizedStringKey = "Keyboard Brightness"
    private let height: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.1))
                Capsule()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.18), radius: 1.5, y: 0.5)
                    .frame(width: value > 0 ? max(height, width * value) : 0)
                Image(systemName: value > minimum ? symbolOn : symbolOff)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(value > 0 ? Color.black.opacity(0.55) : Color.secondary)
                    .padding(.leading, 9)
            }
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
            .contentShape(Capsule())
            .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                value = min(max(drag.location.x / width, minimum), 1)
            })
        }
        .frame(height: height)
        .accessibilityRepresentation {
            Slider(value: $value, in: minimum...1) { Text(accessibilityName) }
        }
    }
}

/// Menu-style clickable row with a hover highlight.
struct MenuRow: View {
    var title: LocalizedStringKey
    var action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).font(.system(size: 13))
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(hovering ? Color.primary.opacity(0.09) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
