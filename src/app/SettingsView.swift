import SwiftUI

struct SettingsView: View {
    @ObservedObject var engine = Engine.shared
    @AppStorage(Prefs.showMenuBarIconKey) private var showMenuBarIcon = true

    private let idleChoices: [(LocalizedStringKey, Double)] = [
        ("Never", 0), ("5 seconds", 5), ("10 seconds", 10),
        ("30 seconds", 30), ("1 minute", 60), ("5 minutes", 300),
    ]

    var body: some View {
        Form {
            Section {
                HeaderView(engine: engine)
            }

            Section {
                Toggle("Keyboard backlight", isOn: engine.enabledBinding)
                LabeledContent("Brightness") {
                    HStack(spacing: 10) {
                        Image(systemName: "light.min").foregroundStyle(.secondary)
                        Slider(value: engine.levelBinding, in: 0...1)
                            .frame(minWidth: 160)
                        Image(systemName: "light.max").foregroundStyle(.secondary)
                        Text(verbatim: engine.enabled ? percentText(engine.level) : "—")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 44, alignment: .trailing)
                    }
                }
            } header: {
                Text("Backlight")
            }

            Section {
                Toggle("Link to keyboard brightness", isOn: $engine.touchBarLinked)
                LabeledContent("Brightness") {
                    HStack(spacing: 10) {
                        Image(systemName: "sun.min").foregroundStyle(.secondary)
                        Slider(value: engine.touchBarBinding, in: 0.1...1)
                            .frame(minWidth: 160)
                        Image(systemName: "sun.max").foregroundStyle(.secondary)
                        Text(verbatim: percentText(engine.touchBarTarget))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 44, alignment: .trailing)
                    }
                }
                .disabled(engine.touchBarLinked || !engine.touchBarPresent)
                Toggle("Dim to minimum when the display sleeps", isOn: $engine.touchBarDimWithDisplay)
            } header: {
                Text("Touch Bar")
            } footer: {
                Group {
                    if engine.touchBarLinked {
                        Text("The Touch Bar follows the keyboard level, but stays on when the keyboard is off.")
                    } else {
                        Text("Without an ambient light sensor, the Touch Bar can't get brighter than its current level: this setting can only dim it.")
                    }
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)   // leading on every macOS version
            }

            Section {
                Picker("Turn off after inactivity", selection: $engine.idleTimeout) {
                    ForEach(idleChoices, id: \.1) { choice in
                        Text(choice.0).tag(choice.1)
                    }
                }
                Toggle("Turn off when the display sleeps", isOn: $engine.offWithDisplay)
            } header: {
                Text("Turn Off Automatically")
            } footer: {
                Text("The backlight comes back on as soon as you use the keyboard, trackpad or mouse.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)   // leading on every macOS version
            }

            Section {
                Toggle("Touch Bar brightness controls", isOn: $engine.touchBarKeys)
                LabeledContent("Turn on or off") {
                    VStack(alignment: .trailing, spacing: 4) {
                        ShortcutRecorder(shortcut: $engine.shortcut)
                        if !engine.hotKeyAvailable {
                            Text("Shortcut already used by another app")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                Toggle("Show on-screen indicator", isOn: $engine.showIndicator)
            } header: {
                Text("Keys and Shortcuts")
            } footer: {
                Text("Hold ⌥⇧ while tapping a brightness control for finer steps, or ⌥ to open these settings.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)   // leading on every macOS version
            }

            Section {
                Toggle("Show in menu bar", isOn: $showMenuBarIcon)
                Toggle("Open at login", isOn: $engine.launchAtLogin)
                    .disabled(!LoginItem.isInstalled)
            } header: {
                Text("General")
            } footer: {
                Text("If the icon is hidden, open HeadlessGlow from Spotlight or Launchpad to get back to these settings.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)   // leading on every macOS version
            }

            Section {
                LabeledContent("Input Monitoring") {
                    if engine.permissionGranted {
                        StatusLabel(text: "Allowed", symbol: "checkmark.circle.fill", color: .green)
                    } else {
                        HStack(spacing: 8) {
                            StatusLabel(text: "Required", symbol: "exclamationmark.triangle.fill", color: .orange)
                            Button("Open Settings…") { Permission.openSettings() }
                        }
                    }
                }
                LabeledContent("Backlight controller") {
                    if engine.hardwarePresent {
                        StatusLabel(text: "T2 chip", symbol: "checkmark.circle.fill", color: .green)
                    } else {
                        StatusLabel(text: "Not found", symbol: "xmark.octagon.fill", color: .red)
                    }
                }
                LabeledContent("Touch Bar control") {
                    if engine.touchBarPresent {
                        StatusLabel(text: "Available", symbol: "checkmark.circle.fill", color: .green)
                    } else {
                        StatusLabel(text: "Not found", symbol: "xmark.octagon.fill", color: .red)
                    }
                }
                LabeledContent("Log") {
                    Button("Show in Console…") { Log.reveal() }
                }
            } header: {
                Text("Status")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("HeadlessGlow \(AppEnv.version) · drives the T2 controller directly, without modifying the system.")
                        .foregroundStyle(.tertiary)
                    // The link target is localized too: the French README has its own section.
                    if let url = URL(string: tr("https://github.com/OnixBrave/HeadlessGlow#support")) {
                        Link("Support HeadlessGlow", destination: url)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)   // leading on every macOS version
            }
        }
        .formStyle(.grouped)
        .frame(width: 560)
        .frame(minHeight: 480, idealHeight: 760)
    }
}

/// System Settings-style header: icon, name, live status.
private struct HeaderView: View {
    @ObservedObject var engine: Engine

    var body: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: "HeadlessGlow")
                    .font(.title2.weight(.semibold))
                Text("Keyboard backlight for T2 MacBook Pro")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    StatusPill(text: engine.statusText, color: pillColor)
                    if !engine.permissionGranted {
                        StatusPill(text: tr("Keys inactive"), color: .orange)
                    }
                }
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private var pillColor: Color {
        if !engine.hardwarePresent { return .red }
        if engine.isLit { return .green }
        if engine.enabled { return .blue }   // dimmed (idle / display asleep)
        return .secondary
    }
}

/// Status pill (text already localized).
private struct StatusPill: View {
    var text: String
    var color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(verbatim: text)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.14)))
    }
}

private struct StatusLabel: View {
    var text: LocalizedStringKey
    var symbol: String
    var color: Color

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: symbol).foregroundStyle(color)
        }
    }
}
