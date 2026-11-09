Keyboard backlight and Touch Bar brightness for headless (screenless) T2 MacBook Pros.

### Compatibility

Intel MacBook Pro with a T2 chip (2018–2020), macOS 13 Ventura or later.

| macOS | Status |
|---|---|
| 26 Tahoe | Tested on real hardware (MacBookPro16,1) |
| 15 Sequoia | Automated launch tests pass; not yet tested on real hardware |
| 14 Sonoma, 13 Ventura | Builds for it; not tested |

If you run it on an untested setup, please [open an issue](https://github.com/OnixBrave/HeadlessGlow/issues) to say whether it works.

### Install

1. Download **HeadlessGlow-{{VERSION}}.zip** below and open it.
2. In Terminal: `cd ~/Downloads/HeadlessGlow-{{VERSION}} && ./install.sh`
3. Allow **HeadlessGlow** in *System Settings → Privacy & Security → Input Monitoring* (needed only for the Touch Bar brightness keys).

The app isn't notarized (that requires a paid Apple Developer account), so `install.sh` removes the quarantine flag from the app it installs. You can also build it from source: see the README.

SHA-256 of the zip: `{{SHA256}}`

Like it? See [Support](https://github.com/OnixBrave/HeadlessGlow#support) for donation addresses.

---

**Français** : téléchargez le zip, ouvrez-le, puis dans le Terminal : `cd ~/Downloads/HeadlessGlow-{{VERSION}} && ./install.sh`, et autorisez HeadlessGlow dans *Réglages Système → Confidentialité et sécurité → Surveillance de l’entrée*. Détails dans le [README en français](https://github.com/OnixBrave/HeadlessGlow/blob/main/README.fr.md).
