<div align="center">

<img src="docs/icon.png" width="128" alt="HeadlessGlow icon">

# HeadlessGlow

**Keyboard backlight and Touch Bar brightness for headless T2 MacBook Pros.**<br>
The screen is gone. Your keyboard doesn't have to go dark.

[![Build](https://img.shields.io/github/actions/workflow/status/OnixBrave/HeadlessGlow/build.yml?branch=main&style=flat-square&logo=githubactions&logoColor=white&label=build)](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/OnixBrave/HeadlessGlow?style=flat-square&color=2ea44f&label=release)](https://github.com/OnixBrave/HeadlessGlow/releases/latest)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111111?style=flat-square&logo=apple&logoColor=white)](#compatibility)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/OnixBrave/HeadlessGlow?style=flat-square&logo=github&label=stars&color=e3b341)](https://github.com/OnixBrave/HeadlessGlow/stargazers)
[![Donate](https://img.shields.io/badge/donate-crypto-f7931a?style=flat-square&logo=bitcoin&logoColor=white)](#support)

[![Download for macOS](https://img.shields.io/badge/Download_for_macOS-2ea44f?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/OnixBrave/HeadlessGlow/releases/latest)

[Features](#features) · [Install](#installation) · [Usage](#usage) · [How it works](#how-it-works) · [Support](#support) · [Français](README.fr.md)

<br>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/settings-dark.png">
  <img src="docs/settings-light.png" width="420" alt="Settings window">
</picture>
&nbsp;&nbsp;
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/menu-dark.png">
  <img src="docs/menu-light.png" width="300" alt="Menu bar panel">
</picture>

</div>

## Why

Take the display off a T2 MacBook Pro (a broken screen, a laptop turned into a desktop) and the camera module goes with it, taking the **ambient light sensor** along. macOS then gives up on the keyboard backlight: `corebrightnessd` keeps a phantom keyboard with no hardware behind it, the brightness keys do nothing, and the keys stay dark.

HeadlessGlow talks to the T2 chip directly to bring the light back, and adds the controls macOS no longer offers.

## Features

<table>
<tr>
<td width="50%" valign="top">

💡 **A backlight that just works**<br>
On at login, restored after sleep, off when the display sleeps.

</td>
<td width="50%" valign="top">

⌨️ **Touch Bar brightness keys**<br>
16 steps like macOS, finer steps with <kbd>⌥</kbd><kbd>⇧</kbd>, and <kbd>⌥</kbd> opens the settings.

</td>
</tr>
<tr>
<td valign="top">

🌙 **Turns off when you're away**<br>
After 5 s to 5 min of inactivity, back on instantly at the first key press or mouse move.

</td>
<td valign="top">

⚡ **Toggle shortcut**<br>
<kbd>⌃</kbd><kbd>⌥</kbd><kbd>K</kbd> by default, configurable.

</td>
</tr>
<tr>
<td valign="top">

🎚️ **Touch Bar dimming**<br>
10–100 %, linkable to the keyboard level, minimum while the display sleeps.

</td>
<td valign="top">

🖥️ **Feels native**<br>
Control Center-style menu bar panel, System Settings-style window, on-screen indicator.

</td>
</tr>
<tr>
<td valign="top">

🧑‍💻 **Command line**<br>
`headlessglow` for scripts and automations.

</td>
<td valign="top">

🌍 **English and French**<br>
Follows your system language.

</td>
</tr>
</table>

## Compatibility

An **Intel MacBook Pro with a T2 chip** (2018–2020) running **macOS 13 Ventura or later**.

| macOS | Status |
|---|---|
| 26 Tahoe | ✅ Tested on real hardware (MacBookPro16,1, 16-inch 2019) |
| 15 Sequoia | 🧪 [Automated launch tests](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml) pass; not yet tested on real hardware |
| 14 Sonoma, 13 Ventura | ⚪ Builds for it; not tested |

Other T2 MacBook Pros most likely expose the same interface. Tried it on an untested setup? Please [open an issue](https://github.com/OnixBrave/HeadlessGlow/issues) to say whether it works.

## Installation

### Option 1: download a release (no Xcode needed)

1. Download the latest `HeadlessGlow-<version>.zip` from the [Releases page](https://github.com/OnixBrave/HeadlessGlow/releases/latest) and open it.
2. In Terminal:

```sh
cd ~/Downloads/HeadlessGlow-<version> && ./install.sh
```

> [!NOTE]
> HeadlessGlow isn't notarized (that requires a paid Apple Developer account), so `install.sh` removes the quarantine flag from the app it installs; otherwise macOS would refuse to start it. With a release build, macOS asks for the Input Monitoring permission again after each update.

### Option 2: build from source

Requires **Xcode 26** (the macOS 26 SDK gives the app its Tahoe look; it still runs on macOS 13). It doesn't need to be the selected Xcode: the build script uses `/Applications/Xcode.app` directly.

```sh
git clone https://github.com/OnixBrave/HeadlessGlow.git
cd HeadlessGlow
./tools/setup-signing.sh   # optional, recommended (see below)
./install.sh               # builds and installs for the current user
```

> [!IMPORTANT]
> Then allow **HeadlessGlow** in *System Settings → Privacy & Security → Input Monitoring*. It's only needed for the Touch Bar brightness keys: HeadlessGlow listens to them **read-only** and never sees or modifies anything else you type. The app relaunches itself once the permission is granted.

<details>
<summary><b>What gets installed</b> (everything in your home folder, no <code>sudo</code>)</summary>
<br>

| What | Where |
|---|---|
| App | `~/Applications/HeadlessGlow.app` |
| Command | `~/.local/bin/headlessglow` |
| Login service | `~/Library/LaunchAgents/io.github.onixbrave.headlessglow.plist` |
| Settings | `defaults read io.github.onixbrave.headlessglow` |
| Log | `~/Library/Logs/HeadlessGlow.log` and the Console app |

</details>

<details>
<summary><b>Why <code>setup-signing.sh</code>?</b></summary>
<br>

Without a signing identity the app is signed *ad hoc*, so its identity changes with every build and macOS asks for the Input Monitoring permission again after each update. The script creates a self-signed code signing certificate in your login keychain (valid on this Mac only, usable only by `codesign`), so the permission survives updates. `uninstall.sh` removes it.

</details>

## Usage

| Where | How |
|---|---|
| **Touch Bar** | The keyboard brightness controls in the Control Strip work again. Hold <kbd>⌥</kbd><kbd>⇧</kbd> for finer steps, <kbd>⌥</kbd> to open the settings. |
| **Menu bar** | Click the icon for quick controls; *HeadlessGlow Settings…* opens the full settings. |
| **Shortcut** | <kbd>⌃</kbd><kbd>⌥</kbd><kbd>K</kbd> toggles the backlight (configurable). |
| **Terminal** | See below. |

```text
headlessglow get                  show the status
headlessglow set <0-100>          set the level (0 turns it off)
headlessglow on | off | toggle
headlessglow touchbar <10-100 | link | unlink>
headlessglow reload               re-read the settings after a `defaults write`
```

> [!TIP]
> If you hide the menu bar icon, open HeadlessGlow from Spotlight or Launchpad to get back to the settings.

## How it works

The T2 exposes the backlight hardware as vendor HID interfaces of the `05AC:8102` device ("Touch Bar Backlight"). HeadlessGlow opens them non-exclusively and sends feature reports, the same ones the Linux `hid-apple` driver uses. Nothing is written permanently: a restart puts the hardware back to its defaults, and HeadlessGlow needs no SIP changes, kernel extensions or root access.

<details>
<summary><b>Under the hood</b></summary>
<br>

| Interface | Report | Content |
|---|---|---|
| `0xFF00:0x0F` (keyboard) | ID 1 | brightness `u32` (100…14660), fade `u32` (ms) |
| | ID 3 | power `u8` (0/1), fade `u32` (ms) |
| `0xFF12:0x01` (Touch Bar) | ID 1 | state, dimming step, brightness factor `u32` (0…1000) |

Without the ambient light sensor, the Touch Bar's base brightness is fixed by macOS; the factor can only dim it (values above 1000 are accepted but have no visible effect). macOS also rewrites the factor when it dims the Touch Bar on its own, so HeadlessGlow re-applies the setting after each wake.

The idle detection uses the system's `HIDIdleTime`, and the brightness keys are caught with a listen-only event tap.

</details>

## Uninstall

```sh
./uninstall.sh
```

This removes the app, the command, the login service, the settings, the permission, the signing certificate and the logs. The Touch Bar goes back to its normal brightness. You may also remove the leftover entry from *Input Monitoring* with the "−" button.

<details>
<summary><b>Troubleshooting</b></summary>
<br>

- `headlessglow get` shows what the T2 reports.
- The settings window has a *Status* section (permission, controllers) and a button that opens the log in Console.
- For detailed logs: `defaults write io.github.onixbrave.headlessglow debugLog -bool YES`, then `headlessglow reload`.

</details>

<details>
<summary><b>Development</b></summary>
<br>

- `./build.sh` builds `build/HeadlessGlow.app`; `./tools/package.sh` makes the release zip in `dist/`. Pushing a `v*` tag builds, tests and publishes a release through GitHub Actions. With `HEADLESSGLOW_DEBUG_BUILD=1`, the build can be inspected with `heap`, `leaks` and `malloc_history`.
- `./tools/update-strings.sh` syncs the string catalog (`src/app/Localizable.xcstrings`) with the code, like Xcode does, and lists missing French translations.
- `headlessglow --snapshot <folder>` renders the app's windows to PNG (add `-AppleLanguages '(fr)'` for French).
- `src/core/kbhw.c` holds the hardware access in C; the app itself is Swift and SwiftUI.

</details>

## Credits

- The keyboard report format comes from the Linux `hid-apple` driver (`apple_magic_backlight`) and the [t2linux](https://t2linux.org) community. The Touch Bar factor was found by reading the T2's reports on macOS.
- [KBPulse](https://github.com/EthanRDoesMC/KBPulse) by EthanRDoesMC, for showing the way with CoreBrightness's `KeyboardBrightnessClient` (which, on a headless Mac, only drives a phantom keyboard).

## Support

HeadlessGlow is free and open source. If it brought your keyboard back to life and you'd like to say thanks, donations are welcome:

| Currency | Network | Address |
|---|---|---|
| Bitcoin (BTC) | Bitcoin | `bc1qsmpzq2hzruf2lgpexz4wtg0p0c0t8uxujnckfw` |
| ETH, USDC, USDT | Ethereum, Base, Arbitrum or Optimism | `0x2860E6465E03E714e4eCa092DcaeCCE2CE601D1C` |
| Litecoin (LTC) | Litecoin | `LeDfGzBNgJGJURon1LCizT9n8LshTThBjD` |

Check the network in your wallet before sending. On Base, Arbitrum or Optimism, fees are a fraction of a cent.

Not into crypto? A ⭐ on the repository and a word on how HeadlessGlow works on your Mac help a lot too.

## Disclaimer

> [!WARNING]
> HeadlessGlow uses undocumented hardware interfaces and has been tested on a single model: use it at your own risk. It is not affiliated with or endorsed by Apple. MacBook Pro, Touch Bar and macOS are trademarks of Apple Inc.

## License

[MIT](LICENSE) © 2026 OnixBrave
