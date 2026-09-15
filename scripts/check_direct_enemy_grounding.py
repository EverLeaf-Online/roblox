#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
violations = []
for path in (ROOT / "src/server/Services").glob("*.luau"):
    if path.name in {"EnemySpawnerService.luau", "MonsterSpawnService.luau"}:
        continue
    lines = path.read_text().splitlines()
    for index, line in enumerate(lines):
        if "EnemySpawnerService.Spawn(" not in line:
            continue
        window = "\n".join(lines[index:index + 14])
        if "GroundToTerrain = true" not in window:
            violations.append(f"{path.relative_to(ROOT)}:{index + 1}")

if violations:
    print("direct enemy spawns must explicitly opt into terrain grounding:")
    for violation in violations:
        print(" -", violation)
    sys.exit(1)
print("direct enemy spawn grounding check passed")
