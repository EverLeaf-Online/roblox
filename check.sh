#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.rokit/bin:$HOME/.cargo/bin:/opt/roblox/tools/bin:$PATH"

cd "$ROOT"

echo "[1/6] Wally dependencies"
WALLY_BIN="wally"
if [[ "$(uname -m)" == "aarch64" && -x "$HOME/.cargo/bin/wally" ]]; then
  WALLY_BIN="$HOME/.cargo/bin/wally"
fi
"$WALLY_BIN" install

echo "[2/6] StyLua format check"
stylua --check src tests

echo "[3/6] Selene lint"
selene src tests

echo "[4/6] Service dependency cycles"
python3 scripts/check_service_cycles.py

echo "[5/6] Lune tests"
for test_file in tests/*.luau; do
  lune run "$test_file"
done

echo "[6/6] Rojo build"
mkdir -p build
rojo build default.project.json -o build/game.rbxlx
rojo build studio-pbr-plugin.project.json -o build/EverLeafPBRInstaller.rbxm

echo "All checks passed."
