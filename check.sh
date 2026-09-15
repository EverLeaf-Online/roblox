#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.rokit/bin:$HOME/.cargo/bin:/opt/roblox/tools/bin:$PATH"

cd "$ROOT"

echo "[1/8] Wally dependencies"
WALLY_BIN="wally"
if [[ "$(uname -m)" == "aarch64" && -x "$HOME/.cargo/bin/wally" ]]; then
  WALLY_BIN="$HOME/.cargo/bin/wally"
fi
"$WALLY_BIN" install

echo "[2/8] StyLua format check"
stylua --check src tests

echo "[3/8] Selene lint"
selene src tests

echo "[4/8] Service dependency cycles"
python3 scripts/check_service_cycles.py

echo "[5/8] Direct enemy grounding"
python3 scripts/check_direct_enemy_grounding.py

echo "[6/8] Environment GLB textures"
python3 scripts/check_environment_glb_textures.py

echo "[7/8] Lune tests"
for test_file in tests/*.luau; do
  lune run "$test_file"
done

echo "[8/8] Rojo build"
mkdir -p build
rojo build default.project.json -o build/game.rbxlx
rojo build studio-pbr-plugin.project.json -o build/EverLeafPBRInstaller.rbxm

echo "All checks passed."
