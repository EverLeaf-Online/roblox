# EverLeaf 3D Art Pipeline

**Status:** canonical after the 2026-09-14 full-3D pivot.

## Visual target

EverLeaf targets stylized realism: high-quality fantasy environments, readable combat silhouettes, atmospheric lighting, PBR-capable materials, dense but optimized foliage, and strong region identity.

## Asset sources

Preferred source order:

1. Original EverLeaf assets.
2. CC0/public-domain assets with clear provenance.
3. Commercially usable attributed assets after license review.
4. Roblox Creator Store assets only after source/script audit.

Current reference sources include Poly Haven, properly licensed Sketchfab downloads, and selected Roblox Creator Store packages. Every imported third-party asset must have its source URL, author/license where applicable, and any required attribution recorded before production use.

Do not ship assets whose license is unclear, non-commercial, editorial-only, or otherwise incompatible with the game.

## Import pipeline

`source asset -> Blender cleanup -> export -> Roblox import -> material/collision/LOD validation -> performance test -> production`.

For each imported mesh:

- normalize scale and orientation;
- fix pivots/origins;
- remove hidden/unneeded geometry;
- simplify excessive topology;
- merge or reduce material slots where practical;
- validate UVs and texture resolution;
- create simple collision proxies when detailed collision is unnecessary;
- preserve a lower-detail option for distant use where the asset warrants it;
- use PBR maps only where the visual return justifies memory/bandwidth cost.

## Environment rules

- Build regions from modular reusable kits rather than one-off giant meshes.
- Prefer material/texture reuse with tint/scale variation.
- Keep distant silhouettes strong while reducing distant geometric detail.
- Use terrain for large natural landforms and meshes for authored landmarks/details.
- Foliage must be tested as a system, not asset-by-asset; overdraw and shadow cost matter.
- Wind/vegetation packages must be source-audited before scripts are allowed into production.
- World construction must remain compatible with instance streaming.

## Performance gates

Every benchmark scene must be profiled before its quality bar becomes the standard for the rest of the world. Track at minimum:

- client frame time/FPS;
- instance count;
- mesh/texture memory pressure;
- draw/scene complexity;
- shadow-heavy areas;
- foliage density and overdraw;
- streaming transitions;
- collision/pathfinding cost;
- low/medium/high graphics scalability behavior.

Visual quality that cannot survive the target performance budget is not production quality.
