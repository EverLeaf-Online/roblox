#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.rokit/bin:$HOME/.cargo/bin:/opt/roblox/tools/bin:$PATH"
cd "$ROOT"
WALLY_BIN="wally"
if [[ "$(uname -m)" == "aarch64" && -x "$HOME/.cargo/bin/wally" ]]; then
  WALLY_BIN="$HOME/.cargo/bin/wally"
fi
"$WALLY_BIN" install
mkdir -p "$ROOT/build"
rojo build "$ROOT/default.project.json" -o "$ROOT/build/game.rbxlx"
echo "Built: $ROOT/build/game.rbxlx"
