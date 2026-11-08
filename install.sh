#!/bin/zsh
# Builds and installs HeadlessGlow for the current user (no sudo, nothing outside $HOME).
#   ./install.sh [level 0-100]
#
# - app      : ~/Applications/HeadlessGlow.app (Spotlight, Launchpad)
# - command  : ~/.local/bin/headlessglow
# - service  : ~/Library/LaunchAgents/io.github.onixbrave.headlessglow.plist (at login)
# - settings : "io.github.onixbrave.headlessglow" preferences domain
# - log      : ~/Library/Logs/HeadlessGlow.log (+ Console app, subsystem io.github.onixbrave.headlessglow)
#
# The Touch Bar keys need the Input Monitoring permission. With the local
# certificate (tools/setup-signing.sh) it survives updates; otherwise macOS
# asks for it again after every build (the app relaunches itself once it is
# granted).
set -euo pipefail

ROOT="${0:A:h}"
source "$ROOT/tools/lang.zsh"
LABEL=io.github.onixbrave.headlessglow
DEST="$HOME/Applications/HeadlessGlow.app"
EXE="$DEST/Contents/MacOS/HeadlessGlow"
LINK="$HOME/.local/bin/headlessglow"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/Library/Logs/HeadlessGlow.log"
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
DOMAIN="gui/$(id -u)"

"$ROOT/build.sh"
BUILT="$ROOT/build/HeadlessGlow.app"

# Code identity (designated requirement): this is what macOS remembers along
# with the permission. Stable with the local certificate, different on every ad hoc build.
# (for ad hoc signatures, codesign prints it as a comment: "# designated => cdhash …")
requirement() { [[ -d "$1" ]] && codesign -d -r- "$1" 2>&1 | sed -nE 's/^#? *designated => //p' || true; }
OLD_REQ=$(requirement "$DEST")
NEW_REQ=$(requirement "$BUILT")

say "→ arrêt de l'ancienne version" "→ stopping the previous version"
launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
pkill -f "HeadlessGlow.app/Contents/MacOS/HeadlessGlow" 2>/dev/null || true
sleep 0.5

say "→ installation dans ~/Applications" "→ installing to ~/Applications"
mkdir -p "$HOME/Applications" "$HOME/.local/bin" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
rm -rf "$DEST"
ditto "$BUILT" "$DEST"
"$LSREGISTER" -f "$DEST" 2>/dev/null || true
# A wrapper script rather than a symlink: run from its real path, the binary
# finds the app bundle (and therefore its translations).
rm -f "$LINK"
print -r -- '#!/bin/sh' > "$LINK"
print -r -- "exec \"$EXE\" \"\$@\"" >> "$LINK"
chmod +x "$LINK"

if [[ -z "$OLD_REQ" ]]; then
    say "  première installation : macOS va demander l'autorisation « Surveillance de l'entrée »" \
        "  first install: macOS will ask for the Input Monitoring permission"
elif [[ "$OLD_REQ" != "$NEW_REQ" ]]; then
    tccutil reset ListenEvent "$LABEL" >/dev/null 2>&1 || true
    say "  identité de code modifiée : macOS va redemander l'autorisation « Surveillance de l'entrée »" \
        "  code identity changed: macOS will ask again for the Input Monitoring permission"
else
    say "  identité de code inchangée : l'autorisation est conservée" \
        "  code identity unchanged: the permission is kept"
fi

[[ $# -ge 1 ]] && "$EXE" set "$1" >/dev/null

say "→ service d'ouverture de session" "→ login service"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>AssociatedBundleIdentifiers</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$EXE</string>
        <string>daemon</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <!-- Restarted only after a crash or a deliberate relaunch (exit code ≠ 0):
         "Quit HeadlessGlow" is honored until the next login. -->
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>ThrottleInterval</key>
    <integer>5</integer>
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>LimitLoadToSessionType</key>
    <string>Aqua</string>
    <key>StandardErrorPath</key>
    <string>$LOG</string>
    $( [[ -n "${HEADLESSGLOW_DEBUG_BUILD:-}" ]] && echo "<key>EnvironmentVariables</key><dict><key>MallocStackLogging</key><string>lite</string></dict>" )
</dict>
</plist>
EOF
plutil -lint "$PLIST" >/dev/null
launchctl enable "$DOMAIN/$LABEL" 2>/dev/null || true
launchctl bootstrap "$DOMAIN" "$PLIST"

INSTALLED_VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$DEST/Contents/Info.plist")
say "✓ HeadlessGlow $INSTALLED_VERSION installé" "✓ HeadlessGlow $INSTALLED_VERSION installed"
"$EXE" get || true
