# EverLeaf Environment Asset Catalog

This catalog tracks third-party environment assets before they are allowed into production. Untrusted marketplace assets are never loaded dynamically during live gameplay. EverLeaf-owned assets produced from reviewed CC0 source files may be runtime-loaded from Roblox by asset ID after sanitization. Every production dependency must have source/license provenance and a bounded import path.

## Current candidates

| Asset | ID | Status | Notes |
|---|---:|---|---|
| Dune Sky | `138907351102721` | Candidate | Inspect in Studio first; retain only approved visual instances. |
| Roblox Forest Pack | `6432306802` | Approved for sanitized import | Free Roblox pack containing PBR trees, bushes, flowers, rocks, logs, ground detail, particles, and wildlife. Remove all bundled scripts before use. |
| WindShake DBE | `101954362093094` | Candidate | Audit scripts before adoption; use only after review. |

## Import rules

1. Insert through Studio/Creator Store into an isolated inspection place or folder.
2. Remove every Script, LocalScript, ModuleScript, remote, loader, analytics object, or unexpected dependency unless explicitly reviewed and approved.
3. Check triangle count, material count, texture resolution, collisions, pivots, scale, and streaming behavior.
4. Prefer reusable modular pieces over giant combined meshes.
5. Record attribution/license requirements before shipping.
6. Never call `InsertService:LoadAsset()` for marketplace environment content during live gameplay.

## Phase 1 Pine Forest kit — active

Source collection: Poly Haven **Pine Forest** (CC0). The downloaded high/working source files are not committed; `assets/polyhaven/forest_model_manifest.json` records reproducible source URLs and Roblox asset IDs.

| EverLeaf role | Poly Haven source | Roblox asset ID | Status |
|---|---|---:|---|
| `TreePrimary` | `pine_sapling_small` | `124246481535142` | Approved, optimized textured GLB |
| `TreeStump` | `tree_stump_01` | `108442673083674` | Approved |
| `FallenTreeTrunk` | `dead_tree_trunk` | `119607451904702` | Approved |
| `PineRoots` | `pine_roots` | `103715602023577` | Approved |

All four models are EverLeaf-owned Roblox uploads sourced from CC0 files. The loader sanitizes them before prefab registration. `TreePrimary` replaces the broken Creator Store tree `580221169`; that old asset is no longer an active Lumenreach dependency. Procedural geometry remains only as a fail-safe when a trusted prefab cannot be loaded.
