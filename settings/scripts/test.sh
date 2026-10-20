#!/usr/bin/env bash
# Swift Testing 在 CLT 中的 framework 搜索路径也必须传给 SwiftPM 生成的 runner。
set -euo pipefail
cd "$(dirname "$0")/.."

DEVELOPER="${DEVELOPER_DIR:-$(xcode-select -p)}"
FW="$DEVELOPER/Library/Developer/Frameworks"
LIB="$DEVELOPER/Library/Developer/usr/lib"
if [ -d "$FW/Testing.framework" ] && [ -f "$LIB/lib_TestingInterop.dylib" ]; then
  exec swift test \
    -Xswiftc -F -Xswiftc "$FW" \
    -Xlinker -F -Xlinker "$FW" \
    -Xlinker -rpath -Xlinker "$FW" \
    -Xlinker -rpath -Xlinker "$LIB" "$@"
fi

exec swift test "$@"
