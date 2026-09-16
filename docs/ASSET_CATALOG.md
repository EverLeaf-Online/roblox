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

## Phase 1 forest kit — active

Primary source: Poly Haven CC0 forest assets, including the **Pine Forest** collection and compatible individual nature models. High/working source files are not committed; `assets/polyhaven/forest_model_manifest.json` records reproducible source URLs, optimized GLB metadata, and Roblox asset IDs.

| EverLeaf role | Poly Haven source | Roblox asset ID | Status |
|---|---|---:|---|
| `TreePrimary` | `pine_sapling_small` | `124246481535142` | Approved, optimized textured GLB |
| `TreeStump` | `tree_stump_01` | `111453055456477` | Approved, optimized textured GLB |
| `FallenTreeTrunk` | `dead_tree_trunk` | `76250166585487` | Approved, optimized textured GLB |
| `PineRoots` | `pine_roots` | `71542327988536` | Approved, optimized textured GLB |
| `FernPrimary` | `fern_02` | `83253621583897` | Approved, 6.2K-triangle textured GLB |
| `DryBranches` | `dry_branches_medium_01` | `139771786412178` | Approved, 16.8K-triangle textured GLB |
| `MossyRockSet` | `rock_moss_set_01` | `124462747468201` | Approved, six-rock set decimated to 28K triangles |
| `RockFace` | `rock_face_02` | `94934760591384` | Approved, cliff-face mesh decimated to 28K triangles |
| `TreeStump2` | `tree_stump_02` | `131840024158767` | Approved, second stump variant decimated to 28K triangles |
| `FallenTreeTrunk2` | `dead_tree_trunk_02` | `87429317329728` | Approved, second fallen-log variant decimated to 28K triangles |

These models are EverLeaf-owned Roblox uploads derived from CC0 source files. The loader sanitizes every imported model before prefab registration. The old broken Creator Store tree `580221169` is not an active Lumenreach dependency. Procedural geometry remains as a fail-safe where practical.

### Original EverLeaf Lumenreach architecture kit — active

These are **original EverLeaf-authored stylized low-poly meshes**, generated from the reproducible Blender source script `scripts/generate_lumenreach_architecture.py`, exported as GLB, uploaded to the EverLeaf Roblox creator account, and sanitized before placement. They replace Part-built block shells for major Lumenreach buildings while retaining simple server-authored collision proxies.

| Prefab | Roblox asset ID | Approx source tris | Purpose |
|---|---:|---:|---|
| `LumenCivicHall` | `133556360685406` | 1,768 | Wayfarer civic/quest landmark |
| `LumenQuartermasterDepot` | `137239183865764` | 1,652 | storehouse/loading depot |
| `LumenArchiveLodge` | `137267951808879` | 1,468 | archive/research lodge |
| `LumenWayfarerInn` | `71957319643364` | 1,736 | inn/social building |
| `LumenHealerLodge` | `120378183892930` | 1,792 | healer/apothecary |
| `LumenCraftWorkshop` | `131833611058968` | 680 | open craft workshop |
| `LumenOpenStable` | `85851512665594` | 548 | open stable |
| `LumenProvingLodge` | `119304858476581` | 1,520 | training/proving lodge |
| `LumenRoadWayhouse` | `98034643639937` | 868 | road-service shelter |
| `LumenFarmBarn` | `89701830913140` | 912 | farm storage/barn |
| `LumenCroftCottageA` | `132542848015613` | 1,440 | croft cottage variant A |
| `LumenCroftCottageB` | `116174241850482` | 1,472 | croft cottage variant B |
| `LumenGlowmereStiltHouse` | `139234768601269` | 1,220 | wetland stilt-house |
| `LumenMossglenRangerHall` | `106301394317624` | 1,748 | ranger/hunter hall |
| `LumenFrontierGatehouse` | `120621904681287` | 560 | frontier defensive gatehouse |
| `LumenRuinedHall` | `70784355192049` | 440 | recognizable ruined hall |
| `LumenForgeYard` | `123625015286607` | 484 | open forge/smithy |
| `LumenGraveboneMausoleum` | `84123705929702` | 324 | Gravebone tomb structure |
| `LumenSunmossObservatory` | `106886408516548` | 652 | highland observatory landmark |
| `LumenVeilfallSanctuary` | `136210017750290` | 524 | ravine sanctuary landmark |
| `LumenShatteredFortressTower` | `111947348903814` | 572 | Shattered Arch fortress landmark |
| `LumenStoneShrine` | `120864356034791` | 264 | route/shrine landmark |

All 22 current architecture assets returned Roblox moderation state `Approved` on the V19 upload. The V19 GLBs bake the stylized flat-color palette into an embedded texture atlas so Roblox does not collapse the authored materials to pale/white surfaces. Source GLBs and generation metadata live under `assets/original/lumenreach_architecture/`; canonical uploaded IDs live in `assets/roblox/lumenreach_architecture_asset_ids.json`.

### Original in-project environment props

Lumenreach also includes code-built props that have no external asset dependency: wildflower patches, grass/bush fallbacks, mushroom clusters, cattail clusters, Lumen waystones, crystals, camp furniture, lanterns, bridge pieces, ruins, fireflies, and fallback deadwood/rock geometry. These are intentionally lightweight and keep the map readable if a remote prefab fails to load.

### Original EverLeaf Brasshaven industrial architecture kit — active

These are original EverLeaf-authored stylized low-poly industrial MeshParts generated by `scripts/generate_brasshaven_architecture.py`. They use an embedded flat-color atlas and separate simple collision proxies.

| Prefab | Roblox asset ID | Purpose |
|---|---:|---|
| `BrassFoundryAdminHall` | `85296622746361` | civic/foundry administration |
| `BrassMachinistWorkshop` | `133204573945623` | machine/workshop block |
| `BrassSmelterHouse` | `110764557535204` | smelter/furnace building |
| `BrassBoilerStation` | `130754611285486` | boiler/maintenance station |
| `BrassWorkerBarracks` | `132013178216030` | worker housing/shift block |
| `BrassLoadingDepot` | `103716454867226` | freight/loading depot |
| `BrassIndustrialGatehouse` | `123786283006636` | industrial gate/control block |
| `BrassRefineryTower` | `93415297640992` | refinery/power landmark |

All eight returned Roblox moderation state `Approved` on upload. Source GLBs, palette, manifest and upload results are under `assets/original/brasshaven_architecture/`; canonical IDs are in `assets/roblox/brasshaven_architecture_asset_ids.json`.
