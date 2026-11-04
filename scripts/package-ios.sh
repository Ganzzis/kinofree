#!/usr/bin/env bash
set -euo pipefail

# --no-sign produces an archive/application, not an Apple-signed export.
app=$(find src-tauri/gen/apple -type d -path '*/Products/Applications/*.app' -print -quit)
if [[ -z "$app" ]]; then
  app=$(find src-tauri/gen/apple -type d -path '*Release-iphoneos/*.app' -print -quit)
fi
[[ -n "$app" ]] || { echo 'Unsigned device .app not found' >&2; exit 1; }
test -f "$app/Info.plist"
executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app/Info.plist")
file "$app/$executable" | grep -q arm64
mkdir -p work/ios-export
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
mkdir "$stage/Payload"
ditto "$app" "$stage/Payload/$(basename "$app")"
ditto -c -k --sequesterRsrc --keepParent "$stage/Payload" work/ios-export/KinoFree-unsigned.ipa
ditto -c -k --sequesterRsrc --keepParent src-tauri/gen/apple work/ios-export/KinoFree-xcode-project.zip
cp docs/ios.md work/ios-export/README.md
