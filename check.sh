#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.rokit/bin:$HOME/.cargo/bin:/opt/roblox/tools/bin:$PATH"

cd "$ROOT"

echo "[1/5] StyLua format check"
stylua --check src tests

echo "[2/5] Selene lint"
selene src tests

echo "[3/5] Service dependency cycles"
python3 scripts/check_service_cycles.py

echo "[4/5] Lune tests"
for test_file in tests/*.luau; do
  lune run "$test_file"
done

echo "[5/5] Rojo build"
mkdir -p build
rojo build default.project.json -o build/game.rbxlx

echo "All checks passed."
