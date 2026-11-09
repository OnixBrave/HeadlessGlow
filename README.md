<p align="center">
  <img src="docs/icon.png" width="128" alt="HeadlessGlow icon">
</p>

<h1 align="center">HeadlessGlow</h1>

<p align="center">
  Keyboard backlight and Touch Bar brightness for <b>headless</b> T2 MacBook Pros.<br>
  <a href="README.fr.md">Français</a>
</p>

<p align="center">
  <a href="https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml"><img src="https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml/badge.svg" alt="Build"></a>
</p>

---

## Why

A MacBook Pro whose display has been removed (broken screen, used as a "desktop" with an external monitor) loses its camera module, and with it the **ambient light sensor**. On T2 Macs, macOS then stops driving the keyboard backlight entirely: `corebrightnessd` keeps a phantom keyboard with no hardware behind it, the brightness keys do nothing, and the keyboard stays dark.

HeadlessGlow talks directly to the T2 chip to bring the backlight back, and adds the controls macOS no longer provides.

## Features

- **Keyboard backlight** on at login, restored after sleep, off when the display sleeps.
- **Touch Bar brightness controls** work again, with 16 steps like macOS, finer steps with <kbd>⌥</kbd><kbd>⇧</kbd>, and <kbd>⌥</kbd> to open the settings.
- **Turns off after inactivity** (5 s to 5 min, like macOS) and comes back instantly on the first key press or mouse move.
- **Toggle shortcut**, configurable (<kbd>⌃</kbd><kbd>⌥</kbd><kbd>K</kbd> by default).
- **Touch Bar brightness**: dim it (10–100 %), link it to the keyboard level, and drop it to the minimum while the display sleeps.
- **On-screen indicator**, a **menu bar panel** in the style of Control Center, and a **settings window** in the style of System Settings.
- **Terminal command** `headlessglow` for scripting.
- English and French.

## Screenshots

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/settings-dark.png">
    <img src="docs/settings-light.png" width="420" alt="Settings window">
  </picture>
  &nbsp;&nbsp;
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/menu-dark.png">
    <img src="docs/menu-light.png" width="300" alt="Menu bar panel">
  </picture>
</p>

## Compatibility

An **Intel MacBook Pro with a T2 chip** (2018–2020) running **macOS 13 Ventura or later**.

| macOS | Status |
|---|---|
| 26 Tahoe | Tested on real hardware (MacBookPro16,1, 16-inch 2019) |
| 15 Sequoia | [Automated launch tests](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml) pass; not yet tested on real hardware |
| 14 Sonoma, 13 Ventura | Builds for it; not tested |

Other T2 MacBook Pros most likely expose the same interface. If you try HeadlessGlow on an untested setup, please [open an issue](https://github.com/OnixBrave/HeadlessGlow/issues) to say whether it works.

## Installation

### From a release (no Xcode needed)

1. Download the latest `HeadlessGlow-<version>.zip` from the [Releases page](https://github.com/OnixBrave/HeadlessGlow/releases) and open it.
2. In Terminal: `cd ~/Downloads/HeadlessGlow-<version> && ./install.sh`

The app isn't notarized (that requires a paid Apple Developer account), so `install.sh` removes the quarantine flag from the app it installs; otherwise macOS would refuse to start it. With a release build, macOS asks for the Input Monitoring permission again after each update.

### From source

Requires **Xcode 26** (the macOS 26 SDK gives the app its Tahoe look; the app still runs on macOS 13). It doesn't need to be the selected Xcode: the build script uses `/Applications/Xcode.app` directly.

```sh
git clone https://github.com/OnixBrave/HeadlessGlow.git
cd HeadlessGlow
./tools/setup-signing.sh   # optional, recommended (see below)
./install.sh               # builds and installs for the current user
```

### Then

Allow **HeadlessGlow** in *System Settings → Privacy & Security → Input Monitoring*. This is only needed for the Touch Bar brightness keys: HeadlessGlow listens to them **read-only** and never sees or modifies anything else you type. The app relaunches itself once the permission is granted.

Everything is installed in your home folder, without `sudo`:

| What | Where |
|---|---|
| App | `~/Applications/HeadlessGlow.app` |
| Command | `~/.local/bin/headlessglow` |
| Login service | `~/Library/LaunchAgents/io.github.onixbrave.headlessglow.plist` |
| Settings | `defaults read io.github.onixbrave.headlessglow` |
| Log | `~/Library/Logs/HeadlessGlow.log` and the Console app |

**Why `setup-signing.sh`?** Without a signing identity the app is signed *ad hoc*, so its identity changes with every build and macOS asks for the Input Monitoring permission again after each update. The script creates a self-signed code signing certificate in your login keychain (valid on this Mac only, usable only by `codesign`), so the permission survives updates. `uninstall.sh` removes it.

## Usage

- **Touch Bar**: the keyboard brightness controls in the Control Strip work again. Hold <kbd>⌥</kbd><kbd>⇧</kbd> for finer steps, or <kbd>⌥</kbd> to open the settings.
- **Menu bar**: click the icon for quick controls; *HeadlessGlow Settings…* opens the full settings.
- **Shortcut**: <kbd>⌃</kbd><kbd>⌥</kbd><kbd>K</kbd> toggles the backlight (configurable).
- **Terminal**:

```text
headlessglow get                  show the status
headlessglow set <0-100>          set the level (0 turns it off)
headlessglow on | off | toggle
headlessglow touchbar <10-100 | link | unlink>
headlessglow reload               re-read the settings after a `defaults write`
```

If you hide the menu bar icon, open HeadlessGlow from Spotlight or Launchpad to get back to the settings.

## How it works

The T2 exposes the backlight hardware as vendor HID interfaces of the `05AC:8102` device ("Touch Bar Backlight"). HeadlessGlow opens them non-exclusively and sends feature reports, the same ones the Linux `hid-apple` driver uses:

| Interface | Report | Content |
|---|---|---|
| `0xFF00:0x0F` (keyboard) | ID 1 | brightness `u32` (100…14660), fade `u32` (ms) |
| | ID 3 | power `u8` (0/1), fade `u32` (ms) |
| `0xFF12:0x01` (Touch Bar) | ID 1 | state, dimming step, brightness factor `u32` (0…1000) |

Without the ambient light sensor, the Touch Bar's base brightness is fixed by macOS; the factor can only dim it (values above 1000 are accepted but have no visible effect). macOS also rewrites the factor when it dims the Touch Bar on its own, so HeadlessGlow re-applies the setting after each wake.

Nothing is written permanently: a restart puts the hardware back to its defaults. HeadlessGlow doesn't need SIP changes, kernel extensions or root access. The idle detection uses the system's `HIDIdleTime`, and the brightness keys are caught with a listen-only event tap.

## Uninstall

```sh
./uninstall.sh
```

This removes the app, the command, the login service, the settings, the permission, the signing certificate and the logs. The Touch Bar goes back to its normal brightness. You may also remove the leftover entry from *Input Monitoring* with the "−" button.

## Troubleshooting

- `headlessglow get` shows what the T2 reports.
- The settings window has a *Status* section (permission, controllers) and a button that opens the log in Console.
- For detailed logs: `defaults write io.github.onixbrave.headlessglow debugLog -bool YES`, then `headlessglow reload`.

## Development

- `./build.sh` builds `build/HeadlessGlow.app`; `./tools/package.sh` makes the release zip in `dist/`. Pushing a `v*` tag builds, tests and publishes a release through GitHub Actions. With `HEADLESSGLOW_DEBUG_BUILD=1`, the build can be inspected with `heap`, `leaks` and `malloc_history`.
- `./tools/update-strings.sh` syncs the string catalog (`src/app/Localizable.xcstrings`) with the code, like Xcode does, and lists missing French translations.
- `headlessglow --snapshot <folder>` renders the app's windows to PNG (add `-AppleLanguages '(fr)'` for French).
- `src/core/kbhw.c` holds the hardware access in C; the app itself is Swift and SwiftUI.

## Credits

- The keyboard report format comes from the Linux `hid-apple` driver (`apple_magic_backlight`) and the [t2linux](https://t2linux.org) community. The Touch Bar factor was found by reading the T2's reports on macOS.
- [KBPulse](https://github.com/EthanRDoesMC/KBPulse) by EthanRDoesMC, for showing the way with CoreBrightness's `KeyboardBrightnessClient` (which, on a headless Mac, only drives a phantom keyboard).

## Disclaimer

HeadlessGlow uses undocumented hardware interfaces. It has been tested on a single model; use it at your own risk. It is not affiliated with or endorsed by Apple. MacBook Pro, Touch Bar and macOS are trademarks of Apple Inc.

## Support

HeadlessGlow is free and open source. If it brought your keyboard back to life and you'd like to say thanks, donations are welcome:

| Currency | Network | Address |
|---|---|---|
| Bitcoin (BTC) | Bitcoin | `bc1qsmpzq2hzruf2lgpexz4wtg0p0c0t8uxujnckfw` |
| ETH, USDC, USDT | Ethereum, Base, Arbitrum or Optimism | `0x2860E6465E03E714e4eCa092DcaeCCE2CE601D1C` |
| Litecoin (LTC) | Litecoin | `LeDfGzBNgJGJURon1LCizT9n8LshTThBjD` |

Check the network in your wallet before sending. On Base, Arbitrum or Optimism, fees are a fraction of a cent. Starring the repository and reporting how HeadlessGlow works on your Mac help a lot too.

## License

[MIT](LICENSE) © 2026 OnixBrave
