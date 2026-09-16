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
        terrain_grounded = "GroundToTerrain = true" in window
        surface_grounded = "GroundInclude =" in window and "GroundToTerrain =" in window
        if not terrain_grounded and not surface_grounded:
            violations.append(f"{path.relative_to(ROOT)}:{index + 1}")

if violations:
    print("direct enemy spawns must explicitly opt into terrain or authored-surface grounding:")
    for violation in violations:
        print(" -", violation)
    sys.exit(1)
print("direct enemy spawn grounding check passed")
