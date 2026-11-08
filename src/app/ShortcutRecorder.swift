import Carbon.HIToolbox
import SwiftUI

/// Shortcut recorder: click, then type the key combination.
/// ⎋ cancels, ⌫ removes the shortcut.
struct ShortcutRecorder: View {
    @Binding var shortcut: Shortcut?
    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 6) {
            Button(action: { recording ? stop() : start() }) {
                label
                    .font(.system(size: 13, weight: recording ? .regular : .medium))
                    .foregroundStyle(recording ? .secondary : .primary)
                    .frame(minWidth: 132)
            }
            .help(recording ? LocalizedStringKey("Type the key combination (⎋ to cancel)")
                            : LocalizedStringKey("Click to record a new shortcut"))

            if shortcut != nil && !recording {
                Button { shortcut = nil } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Remove shortcut")
            }
        }
        .onDisappear { stop() }
    }

    @ViewBuilder private var label: some View {
        if recording {
            Text("Type shortcut…")
        } else if let shortcut {
            Text(verbatim: shortcut.display)
        } else {
            Text("None")
        }
    }

    private func start() {
        HotKey.unregister()   // so the old shortcut doesn't fire while recording
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
            let code = UInt32(event.keyCode)
            if code == UInt32(kVK_Escape) && modifiers.isEmpty {
                stop()
            } else if (code == UInt32(kVK_Delete) || code == UInt32(kVK_ForwardDelete)) && modifiers.isEmpty {
                shortcut = nil
                stop()
            } else if Shortcut.isFunctionKey(code) || !modifiers.subtracting(.shift).isEmpty {
                shortcut = Shortcut(keyCode: code, modifiers: Shortcut.carbonModifiers(modifiers))
                stop()
            } else {
                NSSound.beep()   // requires ⌘, ⌥ or ⌃ (except for F-keys)
            }
            return nil
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        if recording {
            recording = false
            Engine.shared.registerHotKey()
        }
    }
}
