#!/bin/zsh
# Builds HeadlessGlow.app into ./build. Requires Xcode 26 (macOS 26 SDK, for the
# Tahoe look); the app itself runs on macOS 13 Ventura and later. Does not change
# the global Xcode selection (xcode-select).
set -euo pipefail

ROOT="${0:A:h}"
source "$ROOT/tools/lang.zsh"
BUILD="$ROOT/build"
APP="$BUILD/HeadlessGlow.app"
OBJ="$BUILD/obj"
VERSION="${HEADLESSGLOW_VERSION:-1.1}"   # set by the release workflow from the git tag
TARGET="x86_64-apple-macos13.0"   # runs on macOS 13 Ventura and later

if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
SDK_VERSION=$(xcrun --sdk macosx --show-sdk-version)
if (( ${SDK_VERSION%%.*} < 26 )); then
    say "SDK macOS 26 requis (Xcode 26), trouvé : $SDK_VERSION" "macOS 26 SDK required (Xcode 26), found: $SDK_VERSION" >&2
    exit 1
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$OBJ"

say "→ cœur C" "→ C core"
xcrun clang -O2 -Wall -target "$TARGET" -c "$ROOT/src/core/kbhw.c" -o "$OBJ/kbhw.o"

say "→ application (Swift / SwiftUI, SDK $SDK_VERSION)" "→ app (Swift / SwiftUI, SDK $SDK_VERSION)"
xcrun swiftc -O -swift-version 5 -target "$TARGET" \
    -import-objc-header "$ROOT/src/core/kbhw.h" \
    "$ROOT"/src/app/*.swift "$OBJ/kbhw.o" \
    -framework IOKit -framework Carbon \
    -o "$APP/Contents/MacOS/HeadlessGlow"

say "→ traductions (anglais, français)" "→ translations (English, French)"
xcrun xcstringstool compile "$ROOT/src/app/Localizable.xcstrings" --output-directory "$APP/Contents/Resources" >/dev/null

say "→ icône" "→ icon"
if [[ ! -f "$OBJ/AppIcon.icns" || "$ROOT/tools/make-icon.swift" -nt "$OBJ/AppIcon.icns" ]]; then
    xcrun swiftc -O "$ROOT/tools/make-icon.swift" -o "$OBJ/make-icon"   # build tool: host architecture
    rm -rf "$OBJ/AppIcon.iconset"
    "$OBJ/make-icon" "$OBJ/AppIcon.iconset"
    iconutil -c icns "$OBJ/AppIcon.iconset" -o "$OBJ/AppIcon.icns"
fi
cp "$OBJ/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>           <string>io.github.onixbrave.headlessglow</string>
    <key>CFBundleName</key>                 <string>HeadlessGlow</string>
    <key>CFBundleDisplayName</key>          <string>HeadlessGlow</string>
    <key>CFBundleExecutable</key>           <string>HeadlessGlow</string>
    <key>CFBundleIconFile</key>             <string>AppIcon</string>
    <key>CFBundlePackageType</key>          <string>APPL</string>
    <key>CFBundleShortVersionString</key>   <string>$VERSION</string>
    <key>CFBundleVersion</key>              <string>$VERSION</string>
    <key>CFBundleDevelopmentRegion</key>    <string>en</string>
    <key>CFBundleLocalizations</key>        <array><string>en</string><string>fr</string></array>
    <key>LSMinimumSystemVersion</key>       <string>13.0</string>
    <key>LSApplicationCategoryType</key>    <string>public.app-category.utilities</string>
    <key>LSUIElement</key>                  <true/>
    <key>NSHumanReadableCopyright</key>     <string>Keyboard backlight for T2 MacBook Pro</string>
</dict>
</plist>
EOF

# Signing: stable local certificate if present (see tools/setup-signing.sh),
# otherwise ad hoc (the Input Monitoring permission will then be requested
# again after every build).
IDENTITY=$(security find-identity -p codesigning 2>/dev/null | awk '/"HeadlessGlow local signing"/ {print $2; exit}')
if [[ -n "$IDENTITY" ]]; then
    SIGN_WITH="$IDENTITY"; SIGN_LABEL=$(say "certificat « HeadlessGlow local signing »" "certificate “HeadlessGlow local signing”")
else
    SIGN_WITH="-"; SIGN_LABEL=$(say "ad hoc (voir tools/setup-signing.sh)" "ad hoc (see tools/setup-signing.sh)")
fi
# HEADLESSGLOW_DEBUG_BUILD=1: diagnostic build, inspectable with heap/leaks/malloc_history.
ENTITLEMENTS=()
if [[ -n "${HEADLESSGLOW_DEBUG_BUILD:-}" ]]; then
    /usr/libexec/PlistBuddy -c "Add :com.apple.security.get-task-allow bool true" "$OBJ/debug.entitlements" >/dev/null 2>&1 || true
    ENTITLEMENTS=(--entitlements "$OBJ/debug.entitlements")
    SIGN_LABEL="$SIGN_LABEL$(say ", version de diagnostic" ", diagnostic build")"
fi
codesign --force --sign "$SIGN_WITH" "${ENTITLEMENTS[@]}" "$APP" 2>"$OBJ/codesign.log" || { cat "$OBJ/codesign.log" >&2; exit 1; }
say "→ signé : $SIGN_LABEL" "→ signed: $SIGN_LABEL"
print -r -- "✓ $APP"
