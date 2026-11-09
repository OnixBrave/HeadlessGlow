<div align="center">

<img src="docs/icon.png" width="128" alt="HeadlessGlow-Symbol">

# HeadlessGlow

Tastaturbeleuchtung und Touch-Bar-Helligkeit für MacBook Pro mit T2-Chip ohne Display.

[![Build](https://img.shields.io/github/actions/workflow/status/OnixBrave/HeadlessGlow/build.yml?branch=main&style=flat-square&logo=githubactions&logoColor=white&label=build)](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/OnixBrave/HeadlessGlow?style=flat-square&color=2ea44f&label=release)](https://github.com/OnixBrave/HeadlessGlow/releases/latest)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111111?style=flat-square&logo=apple&logoColor=white)](#kompatibilität)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/OnixBrave/HeadlessGlow?style=flat-square&logo=github&label=stars&color=e3b341)](https://github.com/OnixBrave/HeadlessGlow/stargazers)
[![Donate](https://img.shields.io/badge/donate-crypto-f7931a?style=flat-square&logo=bitcoin&logoColor=white)](#unterstützen)

[Download](https://github.com/OnixBrave/HeadlessGlow/releases/latest) · [Installation](#installation) · [Verwendung](#verwendung) · [Unterstützen](#unterstützen)

[English](README.md) · [Français](README.fr.md) · [Español](README.es.md) · Deutsch · [Italiano](README.it.md) · [Português](README.pt-BR.md) · [Русский](README.ru.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md)

<br>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/settings-dark.png">
  <img src="docs/settings-light.png" width="420" alt="Einstellungsfenster">
</picture>
&nbsp;&nbsp;
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/menu-dark.png">
  <img src="docs/menu-light.png" width="300" alt="Menüleistenfenster">
</picture>

</div>

## Warum

Wer das Display eines MacBook Pro mit T2-Chip entfernt, entfernt auch den Umgebungslichtsensor, der auf der Kameraplatine sitzt. macOS steuert die Tastaturbeleuchtung dann nicht mehr: Die Helligkeitstasten tun nichts, und die Tastatur bleibt dunkel. HeadlessGlow steuert die Beleuchtung direkt über den T2-Chip.

## Funktionen

- Beleuchtung beim Anmelden an, nach dem Ruhezustand wiederhergestellt, aus, wenn das Display in den Ruhezustand geht
- Helligkeitstasten der Touch Bar: 16 Stufen, <kbd>⌥</kbd><kbd>⇧</kbd> für feinere Stufen, <kbd>⌥</kbd> öffnet die Einstellungen
- Schaltet sich nach einer Zeit ohne Aktivität aus und beim ersten Tastendruck oder bei der ersten Mausbewegung wieder ein
- Tastenkürzel zum Ein- und Ausschalten (standardmäßig <kbd>⌃</kbd><kbd>⌥</kbd><kbd>K</kbd>)
- Abdunkeln der Touch Bar, optional an die Tastaturhelligkeit gekoppelt
- Menüleistenfenster, Einstellungsfenster und Bildschirmanzeige
- Befehlszeilenwerkzeug `headlessglow`
- Mehrsprachig

## Kompatibilität

Intel-MacBook Pro mit T2-Chip (2018–2020), macOS 13 oder neuer.

| macOS | Status |
|---|---|
| 26 | Getestet auf einem MacBookPro16,1 (16 Zoll, 2019) |
| 15 | [Automatische Starttests](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml) bestanden |
| 13, 14 | Kompiliert, nicht getestet |

Ergebnisse von anderen Modellen sind in den [Issues](https://github.com/OnixBrave/HeadlessGlow/issues) willkommen.

## Installation

Aus einem Release: Lade das Zip von der [Release-Seite](https://github.com/OnixBrave/HeadlessGlow/releases/latest) herunter, öffne es und führe dann aus:

```sh
cd ~/Downloads/HeadlessGlow-<version> && ./install.sh
```

Aus dem Quellcode (Xcode 26 erforderlich):

```sh
git clone https://github.com/OnixBrave/HeadlessGlow.git && cd HeadlessGlow
./tools/setup-signing.sh   # optional: behält die Berechtigung über Updates hinweg
./install.sh
```

Erlaube HeadlessGlow anschließend unter *Systemeinstellungen → Datenschutz & Sicherheit → Eingabeüberwachung*. Das ist nur für die Touch-Bar-Tasten nötig, die ausschließlich mitgelesen werden.

> [!NOTE]
> Die App ist nicht notarisiert, deshalb entfernt `install.sh` das Quarantäne-Attribut der App, die es installiert. Releases sind ad hoc signiert: macOS fragt nach jedem Update erneut nach der Berechtigung.

<details>
<summary>Was installiert wird</summary>
<br>

Alles landet in deinem Benutzerordner, ohne `sudo`.

| Was | Wo |
|---|---|
| App | `~/Applications/HeadlessGlow.app` |
| Befehl | `~/.local/bin/headlessglow` |
| Anmeldedienst | `~/Library/LaunchAgents/io.github.onixbrave.headlessglow.plist` |
| Einstellungen | `defaults read io.github.onixbrave.headlessglow` |
| Protokoll | `~/Library/Logs/HeadlessGlow.log` |

`setup-signing.sh` erstellt ein selbstsigniertes Codesignatur-Zertifikat in deinem Anmeldeschlüsselbund, damit die App über Builds hinweg dieselbe Identität behält. `uninstall.sh` entfernt es.

</details>

## Verwendung

Verwende die Tastaturhelligkeitstasten der Touch Bar, das Menüleistensymbol, das Tastenkürzel oder die Befehlszeile:

```text
headlessglow get                  zeigt den Status
headlessglow set <0-100>          setzt die Helligkeit (0 schaltet aus)
headlessglow on | off | toggle
headlessglow touchbar <10-100 | link | unlink>
headlessglow reload               liest die Einstellungen nach einem `defaults write` neu ein
```

Wenn du das Menüleistensymbol ausblendest, öffne HeadlessGlow über Spotlight, um zu den Einstellungen zu gelangen.

## Funktionsweise

Der T2 stellt die Beleuchtung als herstellerspezifische HID-Schnittstellen des Geräts `05AC:8102` bereit. HeadlessGlow sendet ihnen Feature-Reports, dieselben, die der Linux-Treiber `hid-apple` verwendet. Nichts wird dauerhaft geschrieben, und es braucht weder eine SIP-Änderung noch eine Kernel-Erweiterung oder Administratorrechte.

<details>
<summary>Details</summary>
<br>

| Schnittstelle | Report | Inhalt |
|---|---|---|
| `0xFF00:0x0F` (Tastatur) | ID 1 | Helligkeit `u32` (100…14660), Überblendung `u32` (ms) |
| | ID 3 | Ein/Aus `u8` (0/1), Überblendung `u32` (ms) |
| `0xFF12:0x01` (Touch Bar) | ID 1 | Zustand, Dimmstufe, Helligkeitsfaktor `u32` (0…1000) |

Der Touch-Bar-Faktor kann sie nur abdunkeln; macOS überschreibt ihn auch, wenn es die Touch Bar selbst abdunkelt, daher wendet HeadlessGlow die Einstellung nach jedem Aufwachen erneut an. Die Inaktivitätserkennung nutzt `HIDIdleTime`, und die Helligkeitstasten werden über einen reinen Lese-Event-Tap erfasst.

</details>

## Deinstallation

```sh
./uninstall.sh
```

Entfernt die App, den Befehl, den Anmeldedienst, die Einstellungen, die Berechtigung, das Signaturzertifikat und die Protokolle.

<details>
<summary>Fehlerbehebung</summary>
<br>

- `headlessglow get` zeigt, was der T2 meldet.
- Der Abschnitt *Status* in den Einstellungen zeigt die Berechtigung und den Zustand der Controller und öffnet das Protokoll.
- Ausführliches Protokoll: `defaults write io.github.onixbrave.headlessglow debugLog -bool YES`, dann `headlessglow reload`.

</details>

<details>
<summary>Entwicklung</summary>
<br>

- `./build.sh` baut die App; `./tools/package.sh` erstellt das Release-Zip. Das Pushen eines `v*`-Tags baut, testet und veröffentlicht ein Release über GitHub Actions.
- `./tools/update-strings.sh` gleicht den Übersetzungskatalog mit dem Code ab.
- `headlessglow --snapshot <Ordner>` speichert die Fenster der App als PNG.
- Der Hardwarezugriff liegt in `src/core/kbhw.c`; die App ist in Swift und SwiftUI geschrieben.

</details>

## Danksagung

- Format der Tastatur-Reports: der Linux-Treiber `hid-apple` und die [t2linux](https://t2linux.org)-Community.
- [KBPulse](https://github.com/EthanRDoesMC/KBPulse) von EthanRDoesMC, für die Vorarbeit zu CoreBrightness.

## Unterstützen

HeadlessGlow ist kostenlos. Spenden sind willkommen:

| Währung | Netzwerk | Adresse |
|---|---|---|
| Bitcoin | Bitcoin | `bc1qsmpzq2hzruf2lgpexz4wtg0p0c0t8uxujnckfw` |
| ETH, USDC, USDT | Ethereum, Base, Arbitrum, Optimism | `0x2860E6465E03E714e4eCa092DcaeCCE2CE601D1C` |
| Litecoin | Litecoin | `LeDfGzBNgJGJURon1LCizT9n8LshTThBjD` |

Prüfe das Netzwerk vor dem Senden. Ein Stern für das Repository hilft auch.

## Haftungsausschluss

HeadlessGlow nutzt undokumentierte Hardwareschnittstellen und wurde nur an einem Modell getestet. Nutzung auf eigene Gefahr. Nicht mit Apple verbunden.

## Lizenz

[MIT](LICENSE) © 2026 OnixBrave
