#!/usr/bin/env bash
# Local arm64/x86_64 build using Swift 6 tools and the macOS SDK in CLT.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
CONFIG="${1:-release}"
case "$CONFIG" in
  debug) OPT=-Onone ;;
  release) OPT=-O ;;
  *) echo 'Usage: bash scripts/build-app.sh [debug|release]' >&2; exit 2 ;;
esac
SWIFT_VERSION="$(xcrun swiftc --version)"
if ! [[ "$SWIFT_VERSION" =~ Swift\ version\ ([0-9]+) ]] || (( BASH_REMATCH[1] < 6 )); then
  echo 'Swift 6 or newer Command Line Tools are required.' >&2
  exit 1
fi
for dependency in lib/librime.1.dylib lib/rime-plugins/librime-lua.dylib \
    Frameworks/Sparkle.framework/Sparkle librime/src/rime_api_stdbool.h \
    bin/rime_deployer bin/rime_dict_manager bin/rime-install data/plum/essay.txt; do
  if [ ! -e "$dependency" ]; then
    echo "Missing $dependency; see the CLT build section in README.md for dependency requirements." >&2
    exit 1
  fi
done
WORK="$(mktemp -d /tmp/trifecta-app.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
APP="$WORK/Squirrel.app"
CONTENTS="$APP/Contents"
mkdir -p "$CONTENTS"/{MacOS,Frameworks,Resources,SharedSupport}
ARCH="$(uname -m)"
xcrun swiftc -swift-version 5 -enable-bare-slash-regex "$OPT" \
  -target "$ARCH-apple-macosx13.0" \
  -import-objc-header sources/Squirrel-Bridging-Header.h \
  -I librime/src -I librime/include -F Frameworks -L lib -lrime.1 -framework Sparkle \
  -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
  sources/*.swift -o "$CONTENTS/MacOS/Squirrel"
ditto Frameworks/Sparkle.framework "$CONTENTS/Frameworks/Sparkle.framework"
cp lib/librime.1.dylib "$CONTENTS/Frameworks/"
ditto lib/rime-plugins "$CONTENTS/Frameworks/rime-plugins"
cp bin/rime_deployer bin/rime_dict_manager bin/rime-install "$CONTENTS/MacOS/"
cp resources/RimeIcon.icns resources/rime.pdf LICENSE.txt README.md "$CONTENTS/Resources/"
ditto data/plum "$CONTENTS/SharedSupport"
ditto data/opencc "$CONTENTS/SharedSupport/opencc"
cp data/squirrel.yaml "$CONTENTS/SharedSupport/"
python3 scripts/bundle-resources.py "$ROOT" "$CONTENTS"
bash settings/scripts/build-app.sh "$CONFIG"
ditto settings/dist/TriFectaSettings.app "$CONTENTS/MacOS/TriFectaSettings.app"
# Sign nested code before its enclosing bundle, preserving framework symlinks.
xattr -cr "$APP"
# Scripts belong in Resources; retain the historical command path via a symlink.
mv "$CONTENTS/MacOS/rime-install" "$CONTENTS/Resources/rime-install"
ln -s ../Resources/rime-install "$CONTENTS/MacOS/rime-install"
while IFS= read -r -d '' binary; do
  info="$(dirname "$(dirname "$binary")")/Info.plist"
  if [ -f "$info" ] && [ "$(basename "$binary")" = "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$info")" ]; then
    continue
  fi
  if file "$binary" | grep -q 'Mach-O'; then
    codesign --force --sign - "$binary"
  fi
done < <(find "$CONTENTS" -type f -print0)
while IFS= read -r -d '' bundle; do
  codesign --force --sign - "$bundle"
done < <(find "$CONTENTS" -depth -type d \( -name '*.app' -o -name '*.xpc' -o -name '*.framework' \) -print0)
codesign --force --sign - --entitlements resources/Squirrel.entitlements "$APP"
codesign --verify --deep --strict "$APP"
"$CONTENTS/MacOS/Squirrel" --help >/dev/null
mkdir -p dist
rm -rf dist/Squirrel.app
ditto "$APP" dist/Squirrel.app
printf 'Built: %s/dist/Squirrel.app (%s, %s)\n' "$ROOT" "$ARCH" "$CONFIG"
