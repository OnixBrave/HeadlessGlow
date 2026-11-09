#!/bin/zsh
# Builds HeadlessGlow and packages it for a GitHub release:
#   dist/HeadlessGlow-<version>.zip
#     HeadlessGlow-<version>/
#       HeadlessGlow.app   install.sh   uninstall.sh   tools/lang.zsh
#       README.md   README.fr.md   LICENSE
# The version comes from HEADLESSGLOW_VERSION (set from the git tag by the
# release workflow), 1.1 by default.
set -euo pipefail

ROOT="${0:A:h:h}"
source "$ROOT/tools/lang.zsh"
VERSION="${HEADLESSGLOW_VERSION:-1.1}"
NAME="HeadlessGlow-$VERSION"
DIST="$ROOT/dist"
STAGE="$DIST/$NAME"

"$ROOT/build.sh"

rm -rf "$STAGE" "$DIST/$NAME.zip"
mkdir -p "$STAGE/tools"
ditto "$ROOT/build/HeadlessGlow.app" "$STAGE/HeadlessGlow.app"
cp "$ROOT/install.sh" "$ROOT/uninstall.sh" "$ROOT/README.md" "$ROOT/README.fr.md" "$ROOT/LICENSE" "$STAGE/"
cp "$ROOT/tools/lang.zsh" "$STAGE/tools/"

ditto -c -k --keepParent "$STAGE" "$DIST/$NAME.zip"
say "✓ paquet : $DIST/$NAME.zip" "✓ package: $DIST/$NAME.zip"
shasum -a 256 "$DIST/$NAME.zip" | awk '{print "  SHA-256: " $1}'
