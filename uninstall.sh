#!/bin/zsh
# Fully uninstalls HeadlessGlow: service, app, command, settings, permission,
# local signing certificate and logs. The Touch Bar goes back to its normal
# brightness; the keyboard backlight stays as it is until the next
# restart.
set -uo pipefail

source "${0:A:h}/tools/lang.zsh"
LABEL=io.github.onixbrave.headlessglow
DEST="$HOME/Applications/HeadlessGlow.app"
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

# SIGTERM: the app resets the Touch Bar to 100% before quitting.
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null && say "→ service arrêté" "→ service stopped"
pkill -f "HeadlessGlow.app/Contents/MacOS/HeadlessGlow" 2>/dev/null
tccutil reset ListenEvent "$LABEL" >/dev/null 2>&1 && say "→ autorisation retirée" "→ permission removed"
[[ -d "$DEST" ]] && "$LSREGISTER" -u "$DEST" 2>/dev/null
defaults delete "$LABEL" >/dev/null 2>&1 && say "→ réglages effacés" "→ settings deleted"
security delete-identity -c "HeadlessGlow local signing" "$HOME/Library/Keychains/login.keychain-db" >/dev/null 2>&1 \
    && say "→ certificat de signature supprimé du trousseau" "→ signing certificate removed from the keychain"
rm -rf "$DEST" "$HOME/Library/Saved Application State/$LABEL.savedState"
rm -f  "$HOME/Library/LaunchAgents/$LABEL.plist" \
       "$HOME/.local/bin/headlessglow" \
       "$HOME/Library/Logs/HeadlessGlow.log" "$HOME/Library/Logs/HeadlessGlow.log.1"
say "✓ HeadlessGlow désinstallé" "✓ HeadlessGlow uninstalled"
