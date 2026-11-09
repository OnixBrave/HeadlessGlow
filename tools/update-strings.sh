#!/bin/zsh
# Updates the translation catalog (src/app/Localizable.xcstrings) with the
# strings used in the code, the way Xcode does it: the Swift compiler
# extracts them, then xcstringstool merges them. New strings show up
# untranslated in every language (listed at the end); strings that are no
# longer used are marked "stale".
# Translations can then be edited in Xcode or directly in the JSON.
set -euo pipefail

ROOT="${0:A:h:h}"
source "$ROOT/tools/lang.zsh"
[[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app ]] && export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

xcrun swiftc -swift-version 5 -target x86_64-apple-macos13.0 -wmo -module-name HeadlessGlow \
    -import-objc-header "$ROOT/src/core/kbhw.h" "$ROOT"/src/app/*.swift \
    -c -o "$TMP/app.o" -emit-localized-strings -emit-localized-strings-path "$TMP"
xcrun xcstringstool sync "$ROOT/src/app/Localizable.xcstrings" --stringsdata "$TMP"/*.stringsdata

python3 -I - "$ROOT/src/app/Localizable.xcstrings" "$KBD_FR" <<'EOF'
import json, sys
catalog = json.load(open(sys.argv[1], encoding="utf-8"))
strings = catalog["strings"]
fr = sys.argv[2] == "1"
langs = sorted({l for v in strings.values() for l in v.get("localizations", {})} - {catalog["sourceLanguage"]})
print(f"{len(strings)} chaînes, langues : {', '.join(langs)}" if fr
      else f"{len(strings)} strings, languages: {', '.join(langs)}")
for lang in langs:
    todo = [k for k, v in strings.items()
            if lang not in v.get("localizations", {}) and v.get("shouldTranslate", True)]
    if todo:
        print(f"{lang} : {len(todo)} sans traduction" if fr else f"{lang}: {len(todo)} untranslated")
        for key in todo: print("  -", key)
EOF
