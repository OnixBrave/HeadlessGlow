<div align="center">

<img src="docs/icon.png" width="128" alt="Icône de HeadlessGlow">

# HeadlessGlow

**Rétroéclairage du clavier et luminosité de la Touch Bar pour les MacBook Pro à puce T2 sans écran.**<br>
L’écran n’est plus là. Votre clavier n’a pas à rester dans le noir.

[![Build](https://img.shields.io/github/actions/workflow/status/OnixBrave/HeadlessGlow/build.yml?branch=main&style=flat-square&logo=githubactions&logoColor=white&label=build)](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/OnixBrave/HeadlessGlow?style=flat-square&color=2ea44f&label=version)](https://github.com/OnixBrave/HeadlessGlow/releases/latest)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111111?style=flat-square&logo=apple&logoColor=white)](#compatibilité)
[![Licence MIT](https://img.shields.io/badge/licence-MIT-blue?style=flat-square)](LICENSE)
[![Étoiles](https://img.shields.io/github/stars/OnixBrave/HeadlessGlow?style=flat-square&logo=github&label=%C3%A9toiles&color=e3b341)](https://github.com/OnixBrave/HeadlessGlow/stargazers)
[![Faire un don](https://img.shields.io/badge/don-crypto-f7931a?style=flat-square&logo=bitcoin&logoColor=white)](#soutenir-le-projet)

[![Télécharger pour macOS](https://img.shields.io/badge/T%C3%A9l%C3%A9charger_pour_macOS-2ea44f?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/OnixBrave/HeadlessGlow/releases/latest)

[Fonctions](#fonctions) · [Installation](#installation) · [Utilisation](#utilisation) · [Fonctionnement](#fonctionnement) · [Soutenir](#soutenir-le-projet) · [English](README.md)

<br>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/fr/settings-dark.png">
  <img src="docs/fr/settings-light.png" width="420" alt="Fenêtre de réglages">
</picture>
&nbsp;&nbsp;
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/fr/menu-dark.png">
  <img src="docs/fr/menu-light.png" width="300" alt="Panneau de la barre des menus">
</picture>

</div>

## Pourquoi

Retirez l’écran d’un MacBook Pro à puce T2 (écran cassé, portable transformé en Mac de bureau) et le module caméra part avec lui, emportant le **capteur de lumière ambiante**. macOS abandonne alors le rétroéclairage du clavier : `corebrightnessd` garde un clavier fantôme sans matériel derrière, les touches de luminosité ne font plus rien et le clavier reste éteint.

HeadlessGlow s’adresse directement à la puce T2 pour rallumer la lumière, et ajoute les réglages que macOS ne propose plus.

## Fonctions

<table>
<tr>
<td width="50%" valign="top">

💡 **Un rétroéclairage qui fonctionne, tout simplement**<br>
Allumé à l’ouverture de session, rétabli après la veille, éteint quand l’écran se met en veille.

</td>
<td width="50%" valign="top">

⌨️ **Touches de luminosité de la Touch Bar**<br>
16 paliers comme macOS, paliers fins avec <kbd>⌥</kbd><kbd>⇧</kbd>, et <kbd>⌥</kbd> ouvre les réglages.

</td>
</tr>
<tr>
<td valign="top">

🌙 **S’éteint quand vous n’êtes pas là**<br>
Après 5 s à 5 min d’inactivité, rallumage instantané à la première touche ou au premier mouvement de souris.

</td>
<td valign="top">

⚡ **Raccourci de bascule**<br>
<kbd>⌃</kbd><kbd>⌥</kbd><kbd>K</kbd> par défaut, configurable.

</td>
</tr>
<tr>
<td valign="top">

🎚️ **Atténuation de la Touch Bar**<br>
10–100 %, liable au niveau du clavier, minimum pendant la veille de l’écran.

</td>
<td valign="top">

🖥️ **Comme une app d’Apple**<br>
Panneau façon Centre de contrôle, fenêtre façon Réglages Système, indicateur à l’écran.

</td>
</tr>
<tr>
<td valign="top">

🧑‍💻 **Ligne de commande**<br>
`headlessglow` pour les scripts et les automatisations.

</td>
<td valign="top">

🌍 **Français et anglais**<br>
Suit la langue du système.

</td>
</tr>
</table>

## Compatibilité

Un **MacBook Pro Intel à puce T2** (2018–2020) sous **macOS 13 Ventura ou plus récent**.

| macOS | État |
|---|---|
| 26 Tahoe | ✅ Testé sur un vrai Mac (MacBookPro16,1, 16 pouces 2019) |
| 15 Sequoia | 🧪 [Tests de lancement automatiques](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml) réussis ; pas encore testé sur un vrai Mac |
| 14 Sonoma, 13 Ventura | ⚪ Compilé pour eux ; non testé |

Les autres MacBook Pro T2 exposent très probablement la même interface. Vous l’avez essayé sur une configuration non testée ? Merci d’[ouvrir une issue](https://github.com/OnixBrave/HeadlessGlow/issues) pour dire si ça fonctionne.

## Installation

### Option 1 : télécharger une release (sans Xcode)

1. Téléchargez le dernier `HeadlessGlow-<version>.zip` sur la [page des releases](https://github.com/OnixBrave/HeadlessGlow/releases/latest) et ouvrez-le.
2. Dans le Terminal :

```sh
cd ~/Downloads/HeadlessGlow-<version> && ./install.sh
```

> [!NOTE]
> HeadlessGlow n’est pas notarisé (il faudrait un compte développeur Apple payant) : `install.sh` retire donc l’attribut de quarantaine de l’app qu’il installe, sans quoi macOS refuserait de la lancer. Avec une release, macOS redemande l’autorisation « Surveillance de l’entrée » après chaque mise à jour.

### Option 2 : compiler depuis le code source

Nécessite **Xcode 26** (le SDK macOS 26 donne à l’app l’apparence de Tahoe ; elle fonctionne quand même dès macOS 13). Il n’a pas besoin d’être le Xcode sélectionné : le script utilise directement `/Applications/Xcode.app`.

```sh
git clone https://github.com/OnixBrave/HeadlessGlow.git
cd HeadlessGlow
./tools/setup-signing.sh   # facultatif, recommandé (voir plus bas)
./install.sh               # compile et installe pour l’utilisateur courant
```

> [!IMPORTANT]
> Autorisez ensuite **HeadlessGlow** dans *Réglages Système → Confidentialité et sécurité → Surveillance de l’entrée*. Ce n’est utile que pour les touches de luminosité de la Touch Bar : HeadlessGlow les écoute **en lecture seule** et ne voit ni ne modifie rien d’autre de ce que vous tapez. L’app se relance d’elle-même une fois l’autorisation accordée.

<details>
<summary><b>Ce qui est installé</b> (tout dans votre dossier personnel, sans <code>sudo</code>)</summary>
<br>

| Quoi | Où |
|---|---|
| App | `~/Applications/HeadlessGlow.app` |
| Commande | `~/.local/bin/headlessglow` |
| Service d’ouverture de session | `~/Library/LaunchAgents/io.github.onixbrave.headlessglow.plist` |
| Réglages | `defaults read io.github.onixbrave.headlessglow` |
| Journal | `~/Library/Logs/HeadlessGlow.log` et l’app Console |

</details>

<details>
<summary><b>Pourquoi <code>setup-signing.sh</code> ?</b></summary>
<br>

Sans identité de signature, l’app est signée « ad hoc » : son identité change à chaque compilation et macOS redemande l’autorisation « Surveillance de l’entrée » après chaque mise à jour. Le script crée un certificat de signature de code auto-signé dans votre trousseau de session (valable uniquement sur ce Mac, utilisable uniquement par `codesign`), ce qui permet de conserver l’autorisation. `uninstall.sh` le supprime.

</details>

## Utilisation

| Où | Comment |
|---|---|
| **Touch Bar** | Les commandes de luminosité du clavier de la Control Strip fonctionnent de nouveau. Maintenez <kbd>⌥</kbd><kbd>⇧</kbd> pour un réglage fin, <kbd>⌥</kbd> pour ouvrir les réglages. |
| **Barre des menus** | Cliquez sur l’icône pour les réglages rapides ; *Réglages de HeadlessGlow…* ouvre la fenêtre complète. |
| **Raccourci** | <kbd>⌃</kbd><kbd>⌥</kbd><kbd>K</kbd> allume ou éteint le rétroéclairage (configurable). |
| **Terminal** | Voir ci-dessous. |

```text
headlessglow get                  affiche l’état
headlessglow set <0-100>          règle le niveau (0 éteint)
headlessglow on | off | toggle
headlessglow touchbar <10-100 | lier | délier>
headlessglow reload               relit les réglages après un `defaults write`
```

> [!TIP]
> Si vous masquez l’icône de la barre des menus, ouvrez HeadlessGlow depuis Spotlight ou le Launchpad pour retrouver les réglages.

## Fonctionnement

Le T2 expose le matériel de rétroéclairage sous forme d’interfaces HID propriétaires du périphérique `05AC:8102` (« Touch Bar Backlight »). HeadlessGlow les ouvre sans exclusivité et envoie des rapports Feature, les mêmes que ceux du driver Linux `hid-apple`. Rien n’est écrit de façon permanente : un redémarrage remet le matériel dans son état par défaut, et HeadlessGlow ne demande ni modification de SIP, ni extension noyau, ni droits administrateur.

<details>
<summary><b>Sous le capot</b></summary>
<br>

| Interface | Rapport | Contenu |
|---|---|---|
| `0xFF00:0x0F` (clavier) | ID 1 | luminosité `u32` (100…14660), fondu `u32` (ms) |
| | ID 3 | alimentation `u8` (0/1), fondu `u32` (ms) |
| `0xFF12:0x01` (Touch Bar) | ID 1 | état, palier d’atténuation, facteur de luminosité `u32` (0…1000) |

Sans capteur de lumière, la luminosité de base de la Touch Bar est fixée par macOS ; le facteur permet seulement de l’atténuer (au-delà de 1000, il est accepté mais sans effet visible). macOS réécrit aussi ce facteur quand il atténue lui-même la Touch Bar : HeadlessGlow réapplique donc le réglage après chaque réveil.

La détection d’inactivité utilise le `HIDIdleTime` du système, et les touches de luminosité sont captées par une écoute d’événements en lecture seule.

</details>

## Désinstallation

```sh
./uninstall.sh
```

Le script retire l’app, la commande, le service, les réglages, l’autorisation, le certificat de signature et les journaux. La Touch Bar revient à sa luminosité normale. Vous pouvez aussi retirer l’entrée restante de *Surveillance de l’entrée* avec le bouton « − ».

<details>
<summary><b>Dépannage</b></summary>
<br>

- `headlessglow get` affiche ce que rapporte le T2.
- La fenêtre de réglages comporte une section *État* (autorisation, contrôleurs) et un bouton qui ouvre le journal dans Console.
- Pour un journal détaillé : `defaults write io.github.onixbrave.headlessglow debugLog -bool YES`, puis `headlessglow reload`.

</details>

<details>
<summary><b>Développement</b></summary>
<br>

- `./build.sh` compile `build/HeadlessGlow.app` ; `./tools/package.sh` crée le zip de release dans `dist/`. Pousser une étiquette `v*` compile, teste et publie une release via GitHub Actions. Avec `HEADLESSGLOW_DEBUG_BUILD=1`, la version produite est inspectable avec `heap`, `leaks` et `malloc_history`.
- `./tools/update-strings.sh` synchronise le catalogue de traductions (`src/app/Localizable.xcstrings`) avec le code, comme Xcode, et liste les traductions françaises manquantes.
- `headlessglow --snapshot <dossier>` enregistre les fenêtres de l’app en PNG (ajoutez `-AppleLanguages '(en)'` pour l’anglais).
- `src/core/kbhw.c` contient l’accès au matériel en C ; l’app elle-même est en Swift et SwiftUI.

</details>

## Crédits

- Le format des rapports du clavier vient du driver Linux `hid-apple` (`apple_magic_backlight`) et de la communauté [t2linux](https://t2linux.org). Le facteur de la Touch Bar a été trouvé en lisant les rapports du T2 sous macOS.
- [KBPulse](https://github.com/EthanRDoesMC/KBPulse) d’EthanRDoesMC, pour avoir ouvert la voie avec le `KeyboardBrightnessClient` de CoreBrightness (qui, sur un Mac sans écran, ne pilote qu’un clavier fantôme).

## Soutenir le projet

HeadlessGlow est gratuit et open source. S’il a rallumé votre clavier et que vous voulez dire merci, les dons sont les bienvenus :

| Monnaie | Réseau | Adresse |
|---|---|---|
| Bitcoin (BTC) | Bitcoin | `bc1qsmpzq2hzruf2lgpexz4wtg0p0c0t8uxujnckfw` |
| ETH, USDC, USDT | Ethereum, Base, Arbitrum ou Optimism | `0x2860E6465E03E714e4eCa092DcaeCCE2CE601D1C` |
| Litecoin (LTC) | Litecoin | `LeDfGzBNgJGJURon1LCizT9n8LshTThBjD` |

Vérifiez le réseau dans votre portefeuille avant d’envoyer. Sur Base, Arbitrum ou Optimism, les frais coûtent une fraction de centime.

Pas de crypto ? Une ⭐ sur le dépôt et un mot sur le fonctionnement de HeadlessGlow sur votre Mac aident beaucoup aussi.

## Avertissement

> [!WARNING]
> HeadlessGlow utilise des interfaces matérielles non documentées et n’a été testé que sur un seul modèle : utilisez-le à vos risques. Il n’est ni affilié à Apple ni approuvé par Apple. MacBook Pro, Touch Bar et macOS sont des marques d’Apple Inc.

## Licence

[MIT](LICENSE) © 2026 OnixBrave
