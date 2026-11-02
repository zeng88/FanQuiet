#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$ROOT_DIR/dist/FanQuiet.app"
mkdir -p "$ROOT_DIR/.build/clang-module-cache" "$APP_DIR/Contents/MacOS"
swiftc -module-cache-path "$ROOT_DIR/.build/clang-module-cache" \
  -target x86_64-apple-macosx10.15 \
  "$ROOT_DIR"/Sources/FanQuietCore/*.swift \
  "$ROOT_DIR"/Sources/FanQuietApp/*.swift \
  -framework AppKit \
  -o "$APP_DIR/Contents/MacOS/FanQuiet"
cp "$ROOT_DIR/Sources/FanQuietApp/Info.plist" "$APP_DIR/Contents/Info.plist"
