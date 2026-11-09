<div align="center">

<img src="docs/icon.png" width="128" alt="HeadlessGlow icon">

# HeadlessGlow

Keyboard backlight and Touch Bar brightness for T2 MacBook Pros without a display.

[![Build](https://img.shields.io/github/actions/workflow/status/OnixBrave/HeadlessGlow/build.yml?branch=main&style=flat-square&logo=githubactions&logoColor=white&label=build)](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/OnixBrave/HeadlessGlow?style=flat-square&color=2ea44f&label=release)](https://github.com/OnixBrave/HeadlessGlow/releases/latest)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111111?style=flat-square&logo=apple&logoColor=white)](#compatibility)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/OnixBrave/HeadlessGlow?style=flat-square&logo=github&label=stars&color=e3b341)](https://github.com/OnixBrave/HeadlessGlow/stargazers)
[![Donate](https://img.shields.io/badge/donate-crypto-f7931a?style=flat-square&logo=bitcoin&logoColor=white)](#support)

[Download](https://github.com/OnixBrave/HeadlessGlow/releases/latest) · [Install](#installation) · [Usage](#usage) · [Support](#support)

English · [Français](README.fr.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Italiano](README.it.md) · [Português](README.pt-BR.md) · [Русский](README.ru.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md)

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

Removing the display of a T2 MacBook Pro also removes the ambient light sensor, which sits on the camera board. macOS then stops driving the keyboard backlight: the brightness keys do nothing and the keyboard stays dark. HeadlessGlow controls the backlight through the T2 chip directly.

## Features

- Backlight on at login, restored after sleep, off when the display sleeps
- Touch Bar brightness keys: 16 steps, <kbd>⌥</kbd><kbd>⇧</kbd> for finer steps, <kbd>⌥</kbd> to open the settings
- Turns off after a period of inactivity, back on at the first key press or mouse move
- Toggle shortcut (<kbd>⌃</kbd><kbd>⌥</kbd><kbd>K</kbd> by default)
- Touch Bar dimming, optionally linked to the keyboard level
- Menu bar panel, settings window and on-screen indicator
- `headlessglow` command line tool
- English and French

## Compatibility

Intel MacBook Pro with a T2 chip (2018–2020), macOS 13 or later.

| macOS | Status |
|---|---|
| 26 | Tested on a MacBookPro16,1 (16-inch, 2019) |
| 15 | [Automated launch tests](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml) pass |
| 13, 14 | Builds, untested |

Results from other models are welcome in the [issues](https://github.com/OnixBrave/HeadlessGlow/issues).

## Installation

From a release: download the zip from the [Releases page](https://github.com/OnixBrave/HeadlessGlow/releases/latest), open it, then run:

```sh
cd ~/Downloads/HeadlessGlow-<version> && ./install.sh
```

From source (requires Xcode 26):

```sh
git clone https://github.com/OnixBrave/HeadlessGlow.git && cd HeadlessGlow
./tools/setup-signing.sh   # optional: keeps the permission across updates
./install.sh
```

Then allow HeadlessGlow in *System Settings → Privacy & Security → Input Monitoring*. This is only needed for the Touch Bar keys, which are read in listen-only mode.

> [!NOTE]
> The app isn't notarized, so `install.sh` removes the quarantine flag from the app it installs. Release builds are signed ad hoc: macOS asks for the permission again after each update.

<details>
<summary>What gets installed</summary>
<br>

Everything goes in your home folder, without `sudo`.

| What | Where |
|---|---|
| App | `~/Applications/HeadlessGlow.app` |
| Command | `~/.local/bin/headlessglow` |
| Login service | `~/Library/LaunchAgents/io.github.onixbrave.headlessglow.plist` |
| Settings | `defaults read io.github.onixbrave.headlessglow` |
| Log | `~/Library/Logs/HeadlessGlow.log` |

`setup-signing.sh` creates a self-signed code signing certificate in your login keychain, so the app keeps the same identity across builds. `uninstall.sh` removes it.

</details>

## Usage

Use the keyboard brightness controls in the Touch Bar, the menu bar icon, the shortcut, or the command line:

```text
headlessglow get                  show the status
headlessglow set <0-100>          set the level (0 turns it off)
headlessglow on | off | toggle
headlessglow touchbar <10-100 | link | unlink>
headlessglow reload               re-read the settings after a `defaults write`
```

If you hide the menu bar icon, open HeadlessGlow from Spotlight to get back to the settings.

## How it works

The T2 exposes the backlight as vendor HID interfaces of the `05AC:8102` device. HeadlessGlow sends them feature reports, the same ones the Linux `hid-apple` driver uses. Nothing is written permanently, and no SIP change, kernel extension or root access is needed.

<details>
<summary>Details</summary>
<br>

| Interface | Report | Content |
|---|---|---|
| `0xFF00:0x0F` (keyboard) | ID 1 | brightness `u32` (100…14660), fade `u32` (ms) |
| | ID 3 | power `u8` (0/1), fade `u32` (ms) |
| `0xFF12:0x01` (Touch Bar) | ID 1 | state, dimming step, brightness factor `u32` (0…1000) |

The Touch Bar factor can only dim it; macOS also rewrites it when it dims the Touch Bar itself, so HeadlessGlow re-applies the setting after each wake. Idle detection uses `HIDIdleTime`, and the brightness keys are read with a listen-only event tap.

</details>

## Uninstall

```sh
./uninstall.sh
```

Removes the app, the command, the login service, the settings, the permission, the signing certificate and the logs.

<details>
<summary>Troubleshooting</summary>
<br>

- `headlessglow get` shows what the T2 reports.
- The *Status* section of the settings shows the permission and controller state, and opens the log.
- Detailed logs: `defaults write io.github.onixbrave.headlessglow debugLog -bool YES`, then `headlessglow reload`.

</details>

<details>
<summary>Development</summary>
<br>

- `./build.sh` builds the app; `./tools/package.sh` makes the release zip. Pushing a `v*` tag builds, tests and publishes a release with GitHub Actions.
- `./tools/update-strings.sh` syncs the string catalog with the code.
- `headlessglow --snapshot <folder>` renders the app's windows to PNG.
- Hardware access is in `src/core/kbhw.c`; the app is Swift and SwiftUI.

</details>

## Credits

- Keyboard report format: the Linux `hid-apple` driver and the [t2linux](https://t2linux.org) community.
- [KBPulse](https://github.com/EthanRDoesMC/KBPulse) by EthanRDoesMC, for the CoreBrightness groundwork.

## Support

HeadlessGlow is free. Donations are welcome:

| Currency | Network | Address |
|---|---|---|
| Bitcoin | Bitcoin | `bc1qsmpzq2hzruf2lgpexz4wtg0p0c0t8uxujnckfw` |
| ETH, USDC, USDT | Ethereum, Base, Arbitrum, Optimism | `0x2860E6465E03E714e4eCa092DcaeCCE2CE601D1C` |
| Litecoin | Litecoin | `LeDfGzBNgJGJURon1LCizT9n8LshTThBjD` |

Check the network before sending. Starring the repository helps too.

## Disclaimer

HeadlessGlow uses undocumented hardware interfaces and has been tested on one model. Use it at your own risk. Not affiliated with Apple.

## License

[MIT](LICENSE) © 2026 OnixBrave
