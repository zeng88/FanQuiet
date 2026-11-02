#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$ROOT_DIR/.build/clang-module-cache"
swiftc -module-cache-path "$ROOT_DIR/.build/clang-module-cache" \
  "$ROOT_DIR"/Sources/FanQuietCore/*.swift \
  "$ROOT_DIR"/Tests/FanQuietCoreTests/*.swift \
  -o "$ROOT_DIR/.build/FanQuietSelfTests"
exec "$ROOT_DIR/.build/FanQuietSelfTests" "$@"
