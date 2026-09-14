# EverLeaf Roblox — Canonical Game Foundation

This repository is a clean, original Roblox RPG built from scratch.

## Non-negotiable direction

- Original branding, lore, names, art, audio, maps, UI, and assets.
- No copyrighted MapleStory names/assets and no copied Toolbox scripts.
- MapleStory-like *system structure* may inspire pacing/progression, but implementation and content must be original.
- Server-authoritative progression, stats, combat rewards, currency, inventory, and persistence.
- Robux monetization is cosmetic-only; no paid power.

## Progression baseline

- Level cap: 200.
- First playable vertical slice: levels 1–30, with Lumenreach closing the starter/first-advancement chapter and Brasshaven carrying the rest of the slice.
- Core stats: Might, Finesse, Insight, Fortune.
- AP: +5 per level.
- SP: +3 per level after first advancement.
- First-family advancement occurs at level 8 or 10 depending on family:
  - Ironbloom — Level 8, Might, frontline.
  - Thornrunner — Level 8, Finesse, ranged skirmisher.
  - Lumenweaver — Level 10, Insight, Lumen caster.
  - Veilstrider — Level 8, Fortune, agile skirmisher.
  - Brasshand — Level 10, Might, close-range bruiser/battlecraft path.
- Later advancements: levels 30, 70, and 120.
- Damage uses mastery-based variance rather than a single deterministic roll.
- HP/MP growth, attack cadence, knockback, and aggro are first-class combat systems.
- Movement direction: full 3D third-person traversal with camera-relative WASD/gamepad movement.

## World/content baseline

- Early world progression is structured as Lumenreach roughly levels 1–10, then Brasshaven roughly levels 10–30.
- Belforge Colossus is a planned boss encounter.
- Core non-Robux currencies include Shards and Marks.

## Milestone 1

Build a secure level 1–30 vertical slice with:

1. Player data/profile lifecycle.
2. Server-owned level, EXP, AP, SP, and core stats.
3. Data-driven five-family first-advancement system with mentor trial, permanent family binding, starter skills, and later-tier extension points.
4. Server-owned currency ledger for Shards and Marks.
5. Networking boundary where clients request actions but never submit authoritative rewards/state.
6. Full 3D third-person movement/combat foundations.
7. First Lumenreach/Brasshaven content scaffolds.
8. Buildable Rojo place output and repeatable VM build workflow.

## Authority rule

The client may request an action (allocate AP, use skill, attack target, interact, etc.). The server validates the request, calculates the result, mutates state, and replicates the outcome. The client never tells the server how much EXP, currency, damage, loot, or progression it earned.


## 3D world and visual direction

EverLeaf is a full 3D stylized-realism action RPG/MMO. The visual target is dense, atmospheric fantasy rather than blocky prototype presentation or photorealism.

- Third-person orbit camera with mouse/right-stick control.
- Camera-relative WASD/gamepad movement, sprint, jump, dodge, and interaction controls.
- 3D melee cones/arcs, line-of-sight checks, hitboxes/hurtboxes, knockback, and spatial enemy AI.
- Lumenreach: lush high-fantasy wilderness, layered foliage, ruins, cliffs, water, fog, wind, and strong landmark silhouettes.
- Brasshaven: industrial fantasy, stone/metal architecture, furnaces, smoke, emissive materials, machinery, and vertical spaces.
- PBR-capable materials and optimized meshes are preferred where they materially improve the scene.
- Large-world content must be built for streaming, modular reuse, collision proxies, sensible mesh density, and LOD/performance discipline.

The completed Phase A server/gameplay architecture remains canonical; only the physical movement, camera, targeting, AI traversal, map construction, and presentation layers changed with the 3D pivot.
