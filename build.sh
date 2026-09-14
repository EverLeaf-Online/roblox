#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROJO="/opt/roblox/tools/bin/rojo"
mkdir -p "$ROOT/build"
"$ROJO" build "$ROOT/default.project.json" -o "$ROOT/build/game.rbxlx"
echo "Built: $ROOT/build/game.rbxlx"
