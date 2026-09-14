#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.rokit/bin:$HOME/.cargo/bin:/opt/roblox/tools/bin:$PATH"
mkdir -p "$ROOT/build"
rojo build "$ROOT/default.project.json" -o "$ROOT/build/game.rbxlx"
echo "Built: $ROOT/build/game.rbxlx"
