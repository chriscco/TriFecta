#!/usr/bin/env bash
# Uses isolated Rime data; never deploys to ~/Library/Rime.
set -euo pipefail
cd "$(dirname "$0")/.."
APP="$PWD/dist/Squirrel.app"
codesign --verify --deep --strict "$APP"
"$APP/Contents/MacOS/Squirrel" --help
WORK="$(mktemp -d /tmp/trifecta-check.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
mkdir "$WORK/user"
xcrun clang -I librime/src tests/rime_smoke.c -L "$APP/Contents/Frameworks" \
  -lrime.1 -Wl,-rpath,"$APP/Contents/Frameworks" -o "$WORK/rime-smoke"
cd "$APP/Contents/SharedSupport"
"$WORK/rime-smoke" "$PWD" "$WORK/user"
