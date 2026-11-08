import Foundation

/// The `headlessglow` Terminal command (~/.local/bin/headlessglow wrapper).
enum CLI {
    static var usage: String {
        [
            tr("usage: headlessglow <command>"),
            "  get                     " + tr("show the backlight status"),
            "  set <0-100>             " + tr("set the level in percent (0 turns it off)"),
            "  on | off                " + tr("turn on / off (the level is kept)"),
            "  toggle                  " + tr("toggle on / off"),
            "  touchbar <10-100 | link | unlink>",
            "                          " + tr("Touch Bar brightness, or link it to the keyboard level"),
            "  reload                  " + tr("re-read the settings (after `defaults write io.github.onixbrave.headlessglow …`)"),
            tr("Without a command, opens the settings."),
        ].joined(separator: "\n")
    }

    static func run(_ args: [String]) -> Int32 {
        switch args[0] {
        case "get":
            var value = 0.0
            let result = kb_hw_get(&value)
            guard result == 0 else { return fail(result) }
            print(tr("backlight: \(Prefs.enabled ? tr("on") : tr("off"))"))
            print(tr("chosen level: \(percentText(Prefs.level))"))
            print(tr("level programmed in the T2: \(percentText(value))"))
            var step: Int32 = 0
            var factor = 0.0
            if kb_tb_get(&step, &factor) == 0 {
                let mode = Prefs.touchBarLinked ? tr("linked to keyboard") : tr("set to \(percentText(Prefs.touchBarLevel))")
                print(step == 1 ? tr("Touch Bar: \(mode), currently \(percentText(factor))")
                                : tr("Touch Bar: \(mode), currently \(percentText(factor)) (dimmed by macOS)"))
            }
            return 0
        case "set":
            guard args.count >= 2,
                  let percent = Double(args[1].replacingOccurrences(of: ",", with: ".")) else {
                print(usage); return 2
            }
            let level = min(max(percent, 0), 100) / 100
            if level > 0 {
                Prefs.level = level
                Prefs.enabled = true
            } else {
                Prefs.enabled = false
            }
        case "on":
            Prefs.enabled = true
        case "off":
            Prefs.enabled = false
        case "toggle":
            Prefs.enabled.toggle()
        case "touchbar":
            guard args.count >= 2 else { print(usage); return 2 }
            switch args[1] {
            case "link", "lier":
                Prefs.touchBarLinked = true
            case "unlink", "délier", "delier":
                Prefs.touchBarLinked = false
            default:
                guard let percent = Double(args[1].replacingOccurrences(of: ",", with: ".")) else {
                    print(usage); return 2
                }
                Prefs.touchBarLinked = false
                Prefs.touchBarLevel = min(max(percent, 10), 100) / 100
            }
            let target = Prefs.touchBarLinked ? Prefs.level : Prefs.touchBarLevel
            let result = kb_tb_set_factor(max(target, 0.1), false)
            notifyApp()
            return result >= 0 ? 0 : fail(result)
        case "reload":   // after a `defaults write io.github.onixbrave.headlessglow …`
            notifyApp()
            return 0
        case "help", "-h", "--help":
            print(usage); return 0
        default:
            print(usage); return 2
        }

        let result = kb_hw_set(Prefs.enabled ? Prefs.level : 0, 500)
        notifyApp()
        return result == 0 ? 0 : fail(result)
    }

    private static func notifyApp() {
        DistributedNotificationCenter.default().postNotificationName(
            .headlessGlowChanged, object: nil, userInfo: nil, deliverImmediately: true)
    }

    private static func fail(_ code: Int32) -> Int32 {
        let message = code == -2 ? tr("backlight interface (05AC:8102) not found")
                                 : tr("communication with the controller failed")
        FileHandle.standardError.write(Data("headlessglow: \(message)\n".utf8))
        return 1
    }
}
