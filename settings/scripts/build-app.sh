#!/usr/bin/env bash
#
# build-app.sh — 构建 TriFectaSettings.app
#
# 用法：bash scripts/build-app.sh [release|debug]   （默认 release）
# 产物：settings/dist/TriFectaSettings.app（ad-hoc 签名）
#
# 说明：
#  - 主构建走 SwiftPM（Command Line Tools 环境也可构建；xcodeproj 供 Xcode 用户）。
#  - 仓库可能位于 iCloud 同步目录（~Documents）：codesign 拒绝 fileprovider/provenance
#    等扩展属性，因此构建与签名全部在 /tmp 完成后才拷贝回 dist/。
#
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
ROOT="$(pwd)"
SCRATCH="${SCT_SCRATCH:-/tmp/trifecta-settings-build-$(id -u)}"
WORK="$(mktemp -d /tmp/TriFectaSettings-build.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
STAGE="$WORK/TriFectaSettings.app"

mkdir -p "$STAGE/Contents/MacOS" "$STAGE/Contents/Resources"

swift build -c "$CONFIG" --scratch-path "$SCRATCH" >/dev/null
BIN="$(swift build -c "$CONFIG" --scratch-path "$SCRATCH" --show-bin-path)/TriFectaSettings"

cp "$BIN" "$STAGE/Contents/MacOS/TriFectaSettings"
cp "Sources/TriFectaSettings/Resources/Info.plist" "$STAGE/Contents/Info.plist"

cp "$ROOT/../resources/RimeIcon.icns" "$STAGE/Contents/Resources/AppIcon.icns"

# 在 /tmp 内完成签名（远离 iCloud 属性戳）
xattr -cr "$STAGE" 2>/dev/null || true
codesign --force -s - "$STAGE"
codesign --verify --deep "$STAGE"

# 同步回 dist/
OUT="$ROOT/dist/TriFectaSettings.app"
rm -rf "$OUT"
mkdir -p "$(dirname "$OUT")"
cp -R "$STAGE" "$OUT"

echo "构建完成：$OUT"
echo "版本：$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$OUT/Contents/Info.plist")"
echo "签名：$(codesign -dv "$OUT" 2>&1 | grep -m1 'Authority\|Signature=' || echo 'ad-hoc')"
