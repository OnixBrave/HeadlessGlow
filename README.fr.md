<p align="center">
  <img src="docs/icon.png" width="128" alt="Icône de HeadlessGlow">
</p>

<h1 align="center">HeadlessGlow</h1>

<p align="center">
  Rétroéclairage du clavier et luminosité de la Touch Bar pour les MacBook Pro à puce T2 <b>sans écran</b>.<br>
  <a href="README.md">English</a>
</p>

<p align="center">
  <a href="https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml"><img src="https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml/badge.svg" alt="Build"></a>
</p>

---

## Pourquoi

Un MacBook Pro dont l’écran a été retiré (écran cassé, utilisation en « fixe » avec un moniteur externe) perd aussi son module caméra, et avec lui le **capteur de lumière ambiante**. Sur les Mac à puce T2, macOS cesse alors complètement de piloter le rétroéclairage du clavier : `corebrightnessd` garde un clavier fantôme sans matériel derrière, les touches de luminosité ne font plus rien et le clavier reste éteint.

HeadlessGlow s’adresse directement à la puce T2 pour rallumer le rétroéclairage, et ajoute les réglages que macOS ne propose plus.

## Fonctions

- **Rétroéclairage du clavier** allumé à l’ouverture de session, rétabli après la veille, éteint quand l’écran se met en veille.
- **Commandes de luminosité de la Touch Bar** de nouveau fonctionnelles : 16 paliers comme macOS, paliers fins avec <kbd>⌥</kbd><kbd>⇧</kbd>, et <kbd>⌥</kbd> pour ouvrir les réglages.
- **Extinction après inactivité** (de 5 s à 5 min, comme macOS) et rallumage instantané à la première touche ou au premier mouvement de souris.
- **Raccourci de bascule** configurable (<kbd>⌃</kbd><kbd>⌥</kbd><kbd>K</kbd> par défaut).
- **Luminosité de la Touch Bar** : atténuation (10–100 %), liaison au niveau du clavier, minimum pendant la veille de l’écran.
- **Indicateur à l’écran**, **panneau dans la barre des menus** façon Centre de contrôle et **fenêtre de réglages** façon Réglages Système.
- **Commande Terminal** `headlessglow` pour les scripts.
- En français et en anglais.

## Captures

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/fr/settings-dark.png">
    <img src="docs/fr/settings-light.png" width="420" alt="Fenêtre de réglages">
  </picture>
  &nbsp;&nbsp;
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/fr/menu-dark.png">
    <img src="docs/fr/menu-light.png" width="300" alt="Panneau de la barre des menus">
  </picture>
</p>

## Compatibilité

Un **MacBook Pro Intel à puce T2** (2018–2020) sous **macOS 13 Ventura ou plus récent**.

| macOS | État |
|---|---|
| 26 Tahoe | Testé sur un vrai Mac (MacBookPro16,1, 16 pouces 2019) |
| 15 Sequoia | [Tests de lancement automatiques](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml) réussis ; pas encore testé sur un vrai Mac |
| 14 Sonoma, 13 Ventura | Compilé pour eux ; non testé |

Les autres MacBook Pro T2 exposent très probablement la même interface. Si vous essayez HeadlessGlow sur une configuration non testée, merci d’[ouvrir une issue](https://github.com/OnixBrave/HeadlessGlow/issues) pour dire si ça fonctionne.

## Installation

### Depuis une release (sans Xcode)

1. Téléchargez le dernier `HeadlessGlow-<version>.zip` sur la [page des releases](https://github.com/OnixBrave/HeadlessGlow/releases) et ouvrez-le.
2. Dans le Terminal : `cd ~/Downloads/HeadlessGlow-<version> && ./install.sh`

L’app n’est pas notarisée (il faudrait un compte développeur Apple payant) : `install.sh` retire donc l’attribut de quarantaine de l’app qu’il installe, sans quoi macOS refuserait de la lancer. Avec une release, macOS redemande l’autorisation « Surveillance de l’entrée » après chaque mise à jour.

### Depuis le code source

Nécessite **Xcode 26** (le SDK macOS 26 donne à l’app l’apparence de Tahoe ; elle fonctionne quand même dès macOS 13). Il n’a pas besoin d’être le Xcode sélectionné : le script utilise directement `/Applications/Xcode.app`.

```sh
git clone https://github.com/OnixBrave/HeadlessGlow.git
cd HeadlessGlow
./tools/setup-signing.sh   # facultatif, recommandé (voir plus bas)
./install.sh               # compile et installe pour l’utilisateur courant
```

### Ensuite

Autorisez **HeadlessGlow** dans *Réglages Système → Confidentialité et sécurité → Surveillance de l’entrée*. Ce n’est utile que pour les touches de luminosité de la Touch Bar : HeadlessGlow les écoute **en lecture seule** et ne voit ni ne modifie rien d’autre de ce que vous tapez. L’app se relance d’elle-même une fois l’autorisation accordée.

Tout est installé dans votre dossier personnel, sans `sudo` :

| Quoi | Où |
|---|---|
| App | `~/Applications/HeadlessGlow.app` |
| Commande | `~/.local/bin/headlessglow` |
| Service d’ouverture de session | `~/Library/LaunchAgents/io.github.onixbrave.headlessglow.plist` |
| Réglages | `defaults read io.github.onixbrave.headlessglow` |
| Journal | `~/Library/Logs/HeadlessGlow.log` et l’app Console |

**Pourquoi `setup-signing.sh` ?** Sans identité de signature, l’app est signée « ad hoc » : son identité change à chaque compilation et macOS redemande l’autorisation « Surveillance de l’entrée » après chaque mise à jour. Le script crée un certificat de signature de code auto-signé dans votre trousseau de session (valable uniquement sur ce Mac, utilisable uniquement par `codesign`), ce qui permet de conserver l’autorisation. `uninstall.sh` le supprime.

## Utilisation

- **Touch Bar** : les commandes de luminosité du clavier de la Control Strip fonctionnent de nouveau. Maintenez <kbd>⌥</kbd><kbd>⇧</kbd> pour un réglage fin, ou <kbd>⌥</kbd> pour ouvrir les réglages.
- **Barre des menus** : cliquez sur l’icône pour les réglages rapides ; *Réglages de HeadlessGlow…* ouvre la fenêtre complète.
- **Raccourci** : <kbd>⌃</kbd><kbd>⌥</kbd><kbd>K</kbd> allume ou éteint le rétroéclairage (configurable).
- **Terminal** :

```text
headlessglow get                  affiche l’état
headlessglow set <0-100>          règle le niveau (0 éteint)
headlessglow on | off | toggle
headlessglow touchbar <10-100 | lier | délier>
headlessglow reload               relit les réglages après un `defaults write`
```

Si vous masquez l’icône de la barre des menus, ouvrez HeadlessGlow depuis Spotlight ou le Launchpad pour retrouver les réglages.

## Fonctionnement

Le T2 expose le matériel de rétroéclairage sous forme d’interfaces HID propriétaires du périphérique `05AC:8102` (« Touch Bar Backlight »). HeadlessGlow les ouvre sans exclusivité et envoie des rapports Feature, les mêmes que ceux du driver Linux `hid-apple` :

| Interface | Rapport | Contenu |
|---|---|---|
| `0xFF00:0x0F` (clavier) | ID 1 | luminosité `u32` (100…14660), fondu `u32` (ms) |
| | ID 3 | alimentation `u8` (0/1), fondu `u32` (ms) |
| `0xFF12:0x01` (Touch Bar) | ID 1 | état, palier d’atténuation, facteur de luminosité `u32` (0…1000) |

Sans capteur de lumière, la luminosité de base de la Touch Bar est fixée par macOS ; le facteur permet seulement de l’atténuer (au-delà de 1000, il est accepté mais sans effet visible). macOS réécrit aussi ce facteur quand il atténue lui-même la Touch Bar : HeadlessGlow réapplique donc le réglage après chaque réveil.

Rien n’est écrit de façon permanente : un redémarrage remet le matériel dans son état par défaut. HeadlessGlow ne demande ni modification de SIP, ni extension noyau, ni droits administrateur. La détection d’inactivité utilise le `HIDIdleTime` du système, et les touches de luminosité sont captées par une écoute d’événements en lecture seule.

## Désinstallation

```sh
./uninstall.sh
```

Le script retire l’app, la commande, le service, les réglages, l’autorisation, le certificat de signature et les journaux. La Touch Bar revient à sa luminosité normale. Vous pouvez aussi retirer l’entrée restante de *Surveillance de l’entrée* avec le bouton « − ».

## Dépannage

- `headlessglow get` affiche ce que rapporte le T2.
- La fenêtre de réglages comporte une section *État* (autorisation, contrôleurs) et un bouton qui ouvre le journal dans Console.
- Pour un journal détaillé : `defaults write io.github.onixbrave.headlessglow debugLog -bool YES`, puis `headlessglow reload`.

## Développement

- `./build.sh` compile `build/HeadlessGlow.app` ; `./tools/package.sh` crée le zip de release dans `dist/`. Pousser une étiquette `v*` compile, teste et publie une release via GitHub Actions. Avec `HEADLESSGLOW_DEBUG_BUILD=1`, la version produite est inspectable avec `heap`, `leaks` et `malloc_history`.
- `./tools/update-strings.sh` synchronise le catalogue de traductions (`src/app/Localizable.xcstrings`) avec le code, comme Xcode, et liste les traductions françaises manquantes.
- `headlessglow --snapshot <dossier>` enregistre les fenêtres de l’app en PNG (ajoutez `-AppleLanguages '(en)'` pour l’anglais).
- `src/core/kbhw.c` contient l’accès au matériel en C ; l’app elle-même est en Swift et SwiftUI.

## Crédits

- Le format des rapports du clavier vient du driver Linux `hid-apple` (`apple_magic_backlight`) et de la communauté [t2linux](https://t2linux.org). Le facteur de la Touch Bar a été trouvé en lisant les rapports du T2 sous macOS.
- [KBPulse](https://github.com/EthanRDoesMC/KBPulse) d’EthanRDoesMC, pour avoir ouvert la voie avec le `KeyboardBrightnessClient` de CoreBrightness (qui, sur un Mac sans écran, ne pilote qu’un clavier fantôme).

## Avertissement

HeadlessGlow utilise des interfaces matérielles non documentées. Il a été testé sur un seul modèle ; utilisez-le à vos risques. Il n’est ni affilié à Apple ni approuvé par Apple. MacBook Pro, Touch Bar et macOS sont des marques d’Apple Inc.

## Soutenir le projet

HeadlessGlow est gratuit et open source. S’il a rallumé votre clavier et que vous voulez dire merci, les dons sont les bienvenus :

| Monnaie | Réseau | Adresse |
|---|---|---|
| Bitcoin (BTC) | Bitcoin | `bc1qsmpzq2hzruf2lgpexz4wtg0p0c0t8uxujnckfw` |
| ETH, USDC, USDT | Ethereum, Base, Arbitrum ou Optimism | `0x2860E6465E03E714e4eCa092DcaeCCE2CE601D1C` |
| Litecoin (LTC) | Litecoin | `LeDfGzBNgJGJURon1LCizT9n8LshTThBjD` |

Vérifiez le réseau dans votre portefeuille avant d’envoyer. Sur Base, Arbitrum ou Optimism, les frais coûtent une fraction de centime. Mettre une étoile au dépôt et dire comment HeadlessGlow fonctionne sur votre Mac aide beaucoup aussi.

## Licence

[MIT](LICENSE) © 2026 OnixBrave
