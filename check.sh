#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.rokit/bin:$HOME/.cargo/bin:/opt/roblox/tools/bin:$PATH"

cd "$ROOT"

echo "[1/4] StyLua format check"
stylua --check src tests

echo "[2/4] Selene lint"
selene src tests

echo "[3/4] Lune tests"
lune run tests/math.luau

echo "[4/4] Rojo build"
mkdir -p build
rojo build default.project.json -o build/game.rbxlx

echo "All checks passed."
