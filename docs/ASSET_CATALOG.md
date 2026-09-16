# EverLeaf Environment Asset Catalog

This catalog tracks third-party environment assets before they are allowed into production. EverLeaf now deliberately uses a curated set of **free Roblox Creator Store 3D models** for production architecture. Public free models are loaded with `AssetService:LoadAssetAsync()` only when the place has `Allow Loading Third Party Assets` enabled; Roblox returns them sandboxed, then EverLeaf strips scripts, remotes, bindables, sounds, joints/constraints, prompts, tools, humanoids/animators, package links and other behavior before registering geometry as a prefab. Every production dependency keeps source/provenance metadata and explicit collision remains server-authored.

## Current candidates

| Asset | ID | Status | Notes |
|---|---:|---|---|
| Dune Sky | `138907351102721` | Candidate | Inspect in Studio first; retain only approved visual instances. |
| Roblox Forest Pack | `6432306802` | Approved for sanitized import | Free Roblox pack containing PBR trees, bushes, flowers, rocks, logs, ground detail, particles, and wildlife. Remove all bundled scripts before use. |
| WindShake DBE | `101954362093094` | Candidate | Audit scripts before adoption; use only after review. |

## Import rules

1. Only use assets whose Creator Store page shows **Get Model** / free distribution; preserve the source URL and creator in the registry.
2. Load through `AssetService:LoadAssetAsync()` so third-party content arrives sandboxed; never use the legacy `InsertService:LoadAsset()` marketplace path.
3. Strip every executable or behavioral descendant before prefab registration: scripts, remotes/bindables, sounds, tools, humanoids/animators, joints/constraints, prompts, package links, and unexpected runtime systems.
4. Retain curated static visual data (parts, meshes, SurfaceAppearance, decals/textures) so sanitization does not destroy the asset that was selected.
5. Use EverLeaf-authored collision proxies and gameplay interactions; Creator Store models never own authority, scripts, combat, quests, doors, shops, or triggers.
6. Check scale, pivots, triangle/part count, streaming behavior, and player-height appearance in Studio before visual acceptance.
7. Prefer several coherent assets from a small approved library over random Toolbox insertion. Record attribution/credit requirements before shipping.

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

### Curated free Creator Store architecture — active replacement

The previous generated Blender architecture is **retired from production**. Those source files remain only as historical project artifacts; the runtime registry no longer points at them and the production GLB QA gate no longer counts them as active architecture.

Lumenreach now resolves its logical building roles through curated free Creator Store models. Reusing a logical role keeps the world-layout/collision code stable while the visible prefab changes.

| EverLeaf prefab role | Creator Store asset | ID | Creator / notes |
|---|---|---:|---|
| `LumenCivicHall` | Inn | `25561936` | @bevillia |
| `LumenQuartermasterDepot` / `LumenCraftWorkshop` / `LumenForgeYard` | Blacksmith Shop | `125612298` | @pielovingboy |
| `LumenArchiveLodge` / `LumenCroftCottageA` | Low Poly Medieval House | `4989402992` | @anomon — creator requests credit |
| `LumenWayfarerInn` | Medieval House | `1819167267` | @VicyX |
| `LumenHealerLodge` / `LumenCroftCottageB` | Medieval House | `2914202068` | @iiLuxIV |
| `LumenOpenStable` | Barn | `506010511` | @Q_Q; bundled script is stripped |
| `LumenProvingLodge` | Medieval House Knight Medieval Fantasy Kingdom | `103444669708339` | @KairoNull; bundled script is stripped |
| `LumenRoadWayhouse` | Medieval House 1 | `254849325` | @Naperin |
| `LumenFarmBarn` | barn | `13902499907` | @PBJohns; bundled script is stripped |
| `LumenGlowmereStiltHouse` | old house | `15413223952` | @use251name |
| `LumenMossglenRangerHall` | Medieval House | `16421571` | @Drackore |
| `LumenFrontierGatehouse` | Medieval Entrance | `4455026229` | @Canyski — creator requests credit |
| `LumenRuinedHall` | Ruins | `49387516` | @Quenty |
| `LumenGraveboneMausoleum` | Tomb | `1115559295` | @CourageousKyran; bundled scripts are stripped |
| `LumenSunmossObservatory` / `LumenShatteredFortressTower` | tower medieval | `28483443` | @sourtreemagician |
| `LumenVeilfallSanctuary` / `LumenStoneShrine` | Shrine | `270668855` | @VocSG; bundled behavior is stripped |

Additional approved free Lumenreach dressing sources are `Medieval Market Stalls` (`16263631766`, @Scripted_Kool) and `Medieval Asset Pack` (`74849899553864`, @KickPlayer_80). They are geometry sources only; EverLeaf owns placement, collision, interactions, and gameplay behavior.

### Original in-project environment props

Lumenreach also includes code-built props that have no external asset dependency: wildflower patches, grass/bush fallbacks, mushroom clusters, cattail clusters, Lumen waystones, crystals, camp furniture, lanterns, bridge pieces, ruins, fireflies, and fallback deadwood/rock geometry. These are intentionally lightweight and keep the map readable if a remote prefab fails to load.

### Curated free Creator Store Brasshaven architecture — active replacement

The generated Brasshaven V2 building kit is also **retired from production**. Current logical industrial prefabs now resolve to a small free Creator Store library and remain wrapped by EverLeaf-authored district placement/collision code.

| EverLeaf prefab role | Creator Store asset | ID | Creator / notes |
|---|---|---:|---|
| `BrassFoundryAdminHall` / `BrassBoilerStation` | Industrial Buildings | `2195158233` | @Azynus |
| `BrassMachinistWorkshop` | factory thing | `4729280834` | @ImaginaryWisp; bundled behavior stripped |
| `BrassSmelterHouse` / `BrassLoadingDepot` | Warehouse | `10694469551` | Marvel Advanced Universe |
| `BrassWorkerBarracks` | Warehouse | `655063599` | @NovaKeinPlays |
| `BrassIndustrialGatehouse` | Gate | `5037991647` | @hatortot |
| `BrassRefineryTower` | Smokestack v2 | `272953704` | @rbadam; bundled script stripped |

Approved industrial dressing sources: `Factory Assets - v0.8` (`8312679976`, @SilvixBtw) and `Pipes` (`14960685595`, @alchemist1995).

**Acceptance rule:** these selections are production *candidates wired into source*, not visual acceptance. Any model that looks wrong at player height is replaced with another free Store candidate; we do not patch a bad asset with clutter.
