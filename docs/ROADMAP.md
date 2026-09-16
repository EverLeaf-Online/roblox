- Whole-game foundation rebuild: introduced asset-first production visual pipelines for monsters and NPCs (reviewed authored models preferred, procedural/generated visuals explicitly fallback-only), centralized quest objective progress through an extensible objective bus, and removed source-tree backup artifacts so production code is no longer mixed with iterative snapshots.
# EverLeaf Roblox Roadmap

**Canonical status:** 2026-09-15
**Repository:** `EverLeaf-Online/roblox`
**Detailed tracker:** [`MASTER_CHECKLIST.md`](MASTER_CHECKLIST.md)
**Architecture:** [`ARCHITECTURE.md`](ARCHITECTURE.md)

## Whole-game quality reset — ACTIVE 2026-09-16

The project is no longer allowed to keep extending an existing implementation merely because it already works in source. The canonical audit is [`WHOLE_GAME_QUALITY_AUDIT.md`](WHOLE_GAME_QUALITY_AUDIT.md). Major domains are now classified as **KEEP**, **REFACTOR**, or **REBUILD**. Weak production-facing foundations are replaced before new content is scaled.

Immediate reset priorities are: curated free Creator Store world architecture with strict sanitization/provenance, decomposition of the monolithic Lumenreach world generator, authored monster/NPC art pipelines, richer quest objective events, React UI decomposition, and measured Studio performance/vertical-slice acceptance. Server-authoritative persistence, progression, inventory/equipment, combat ownership, party state, security boundaries, and tested save rules remain canonical unless a concrete defect justifies replacement.

## Lumenreach starter region — SOURCE BUILT / STUDIO ACCEPTANCE NOT PASSED

- V14 architecture source pass removes the shared generic house shell from named Lumenreach structures and introduces explicit civic hall, depot, archive, inn, healer, workshop, stable, proving, wayhouse, barn, croft, wetland-stilt, and ranger archetypes. This is source progress only until Studio screenshots/walkthroughs accept the new silhouettes and placement.
- V15 responds to Studio feedback that V14 still looked like generic blocks: it adds visible structural framing/trusses/chimneys/service silhouettes and re-grades/reorients Wayfarer Camp before placement so buildings sit correctly and face actual streets/courts.
- V16 begins the actual mesh-based architecture pipeline: eight original Lumenreach building GLBs are authored in Blender, uploaded/approved as EverLeaf Roblox assets, sanitized at load, and placed as render-only MeshParts with separate collision proxies. Remaining district kits and Brasshaven/Belforge still need conversion before architecture can be accepted.
- V17 extends the original mesh pipeline into the districts: road wayhouses, barns, two croft variants, Glowmere stilt houses, Mossglen ranger halls, frontier gatehouses, and ruined halls now use approved original EverLeaf GLBs instead of visible Part-built building shells.
- V18 converts another landmark batch to original meshes: Wayfarer forge yards, Gravebone mausoleums, Sunmoss observatory, Veilfall sanctuary, Shattered Arch fortress towers, and route shrines now use approved EverLeaf GLBs with simple explicit collision proxies.
- V19 screenshot correction: rebuilt and re-uploaded all 22 Lumenreach architecture GLBs with an embedded palette texture atlas after Studio showed imported multi-material meshes washing out to pale/white. Architecture visuals are now queryable for camera/LOS while remaining non-colliding, and simplified collision sizes/offsets scale with each placed visual so camera/player geometry stays aligned. Studio acceptance remains required.
- V20 MMO-hub composition pass: Wayfarer Camp is no longer laid out as a giant empty plaza with buildings around the perimeter. The core hub is tightened into a civic square, market lane, west service court, production/stable lane, framed training court, defended east/south gatehouses, stronger street lighting/signage/carts, and a denser resident population. This is source-complete; Studio player-height acceptance remains required.

**Architecture status:** NOT ACCEPTED. The current generator still contains generic rectangular/gable building shells. A whole-game architecture replacement is now active across Lumenreach, Brasshaven/Eastworks, and Belforge. See [`ARCHITECTURE_OVERHAUL_CHECKLIST.md`](ARCHITECTURE_OVERHAUL_CHECKLIST.md) for the exact replacement matrix, regional archetypes, collision criteria, and implementation order.

- The 2200×1250 Level 1–10 topology, combat spaces, settlements, crossings, quest route, and custom EverLeaf structure set exist in source, but **the current Studio world is not accepted as production-quality**. It still requires a player-height environment rebuild/QA pass and must not be described as finished merely because the generator/tests pass.
- Random Toolbox insertion remains prohibited, but curated **free Creator Store 3D architecture is now the production direction**. Every selected model is provenance-tracked, loaded sandboxed with `AssetService:LoadAssetAsync()`, stripped to static visuals, and wrapped by EverLeaf collision/gameplay code. Foliage or prop density is still not a substitute for authored MMO district layout.
- Lumenreach V11 now uses an explicit proxy-only collision contract: visible environment geometry cannot accidentally become physical, solid world objects receive simple authored blockers, and those blockers participate in camera/LOS queries. This is source-tested but still requires full Studio walk/dodge/camera traversal before acceptance.
- Functional MMO world activity is now being added on top of the existing systems: gathering, crafting, rest points, persistent caches, additional regional NPCs, and optional side quests. The next acceptance gate is a fresh-player Studio session that actually feels like an MMORPG, not another source-only map milestone.
- V13 responds directly to Studio screenshots: structural eave collision is separated from visual overhangs, malformed/low forge sheltering is corrected, duplicate ambient NPC placements are removed, foundations seat into uneven terrain, and 20 small authored wayhouses/crofts/watches/ruins fill inter-zone dead space. This is still awaiting player-height Studio acceptance.
- V21 whole-map MMO composition pass: rebuilt the spatial hierarchy beyond Wayfarer across Greenway, Crossroads, Glowmere, Eastbridge, Gravebone, Mossglen, Sunmoss, Veilfall, Shattered Arch, Proving, plus Brasshaven/Eastworks/Belforge district courts. Each major area now has authored approach lanes, courts, thresholds, lighting/service rhythm, and region-specific activity framing instead of isolated objects in open terrain. This remains source-complete only until Studio player-height acceptance.

## Development strategy


### 3D pivot decision — 2026-09-14

EverLeaf is now a full 3D third-person action RPG/MMO. The earlier 2.5D movement/camera/depth-plane approach is retired. Phase A persistence, progression, inventory, skills, quests, economy, party, boss, security, admin, and deployment architecture is preserved.

Immediate 3D priorities:

- third-person movement/camera foundation is live; anti-teleport displacement checks now complement velocity caps;
- left-click/R2 basic combat with spatial targeting;
- sprint/dodge/jump/interact controls;
- true XYZ enemy pursuit and navigation;
- Lumenreach 3D benchmark graybox — source-generated foundation landed 2026-09-14;
- lighting/atmosphere/terrain/foliage quality baseline;
- asset import/optimization/licensing pipeline; Poly Haven PBR materials are uploaded/wired and the Studio material authoring path is working; production foliage/model replacement remains active;
- first production-quality environmental benchmark area.

We are building structure first. Do not stop to fully polish one feature while major game domains are still missing.

### Phase A — Complete architecture — COMPLETE

Build every major subsystem, establish server/client ownership, and connect the systems with placeholder/test content.

Already established or scaffolded:

- repository/toolchain/build/test architecture;
- versioned persistent player profile + migrations/reconciliation;
- progression/stats/resources/advancement;
- server-authoritative combat/damage/enemy/reward pipeline;
- movement/camera/depth sanity;
- inventory/equipment/consumables;
- skills/hotbar/status effects;
- quests/NPC interaction sessions;
- shops/currencies/rewards/item rewards;
- regions/portals;
- parties/instances;
- boss registry/encounter-instance entry point;
- achievements/cosmetics/settings;
- death event layer;
- centralized validated game-action router;
- client profile/catalog/action/UI-state layers;
- security/rate-limit boundaries;
- telemetry hook with external collection intentionally disabled.

Architecture closure completed:

- physical world-object registry and NPC/portal proximity validation;
- hostile-enemy AI state-machine and enemy-to-player damage boundary;
- generic server-owned skill targeting/effect execution;
- reusable state-machine foundation used by boss encounters;
- crafting plus disabled-by-design enhancement/storage/trading hooks;
- party create/invite/accept/decline/kick/leave protocol;
- instance lifecycle and fail-closed reserved-server teleport boundary;
- admin authorization, audit-log, and loaded-profile recovery interfaces;
- release/build metadata and staging/production deployment rules;
- client screen registry/navigation controller;
- pure state-machine regression tests;
- bounded action payload validation and rate limits on all client-callable RemoteFunctions;
- automated service dependency-cycle check (51 services at closure).

**Phase A exit passed:** every major game domain now has a canonical module/service boundary and a defined connection to neighboring systems. Feature completeness is deliberately deferred.


### Current verified Phase B baseline — 2026-09-15

Studio-verified gameplay foundations remain third-person movement/camera, sprint/jump/dodge, basic combat, hostile enemy damage, React HUD/dialogue, quest accept/progress/turn-in, and Rojo/Wally/React sync. Lumenreach uses the current 2200×1250 terrain-first generator with permanent town, authored roads, two gorge bridges, wetland/highland/ravine macro spaces, encounter floors, natural Terrain boundaries, and the Brasshaven gate at the far-east capstone. **This does not mean the region is visually complete:** its generic building family is now explicitly scheduled for replacement by bespoke regional architecture. Player-height art/collision/multiplayer/performance QA remains the acceptance gate. The canonical layout contract is `docs/LUMENREACH_WORLD_LAYOUT.md`; the architecture replacement contract is `docs/ARCHITECTURE_OVERHAUL_CHECKLIST.md`.

### Phase B — 3D foundation + complete game shell — ACTIVE

Build the production-direction 3D gameplay foundation, then make every major player-facing route exist with placeholder content:

- full 3D third-person locomotion/camera/sprint/dodge/interact foundation;
- 3D combat targeting, hitbox/hurtbox, enemy navigation, and spatial encounter foundation;
- graphics/environment pipeline for optimized meshes, PBR materials, lighting, atmosphere, foliage, wind, and streaming;
- character start/onboarding;
- HUD and all major menus;
- class/advancement flow;
- inventory/equipment/skills/hotbar;
- NPC dialogue/quests/shops;
- map transitions/portals/instances;
- parties/social shell;
- hostile enemies/player damage/death/respawn;
- boss entry/completion loop;
- Lumenreach → Brasshaven progression shell.

**Phase B / Phase 1 exit:** a fresh player can complete the canonical Phase 1 vertical slice end-to-end in Studio, with stable respawn/UI state, working combat/quest/reward/inventory interactions, no blocking Output errors, and a starter environment that no longer reads as placeholder.


## Phase 1 vertical slice — canonical execution target

Phase 1 is the first complete playable EverLeaf slice. It is not considered complete until a fresh player can complete the entire starter loop without console errors or broken state transitions.

Required end-to-end loop:

1. Spawn safely in the Wayfarer Camp town plaza and orient from the hub landmarks/services.
2. Move, sprint, jump, dodge, use the third-person camera, and interact with the starter NPC cluster.
3. Accept the first quest from Ilyra and leave town through the signed Greenway road.
4. Fight Mosslings in the open Greenway starter field without combat spilling into the road.
5. Return/turn in, use the Quartermaster shop, and verify inventory/equipment/consumable actions.
6. Reach Lumenwood Crossroads and understand the regional route choices from sightlines/signage alone.
7. Explore Glowmere Wetland and cross the central gorge/Eastbridge into the mid-zone.
8. Clear Gravebone Watch, then progress through Mossglen hunts, Brambleback Trail, and the Mosswarden field-boss space before the late-zone loops.
9. Explore the Sunmoss highland and Veilfall ravine late-zone loops without forced linear backtracking.
10. Complete the Wayfarer Proving Circle / first advancement flow.
11. Take damage, die if necessary, and respawn cleanly at Camp without losing HUD/menu/hotbar/progression state.
12. Reach Level 10, complete the Brasshaven passage requirements, and travel through the far-edge Shattered Lumen Arch gate.
13. Confirm the full 2200×1250 starter region remains readable, traversable, performant, and free of placeholder/broken environment assets.

Phase 1 production priorities, in order:

- **P1-A — Stability:** no red errors, no broken respawn/UI state, no invalid material/plugin dependencies, no remote-authority regressions.
- **P1-B — Combat feel:** hit feedback, damage numbers, enemy telegraphs, leash/reset, knockback/stagger where appropriate, and production attack presentation.
- **P1-C — MMO starter-zone world:** Studio-validate the terrain-first 2200×1250 Lumenreach V3 layout, town hub, natural terrain boundaries, road grades, landmark silhouettes, encounter-room scale, foliage density, and far-edge Brasshaven transition; fix any player-height composition issue before adding more decorative density.
- **P1-D — RPG shell:** finish responsive HUD/menu UX, inventory/equipment/skills/quests/settings usability, dedicated shop presentation, and notifications/reward feedback.
- **P1-E — Content closure:** complete the first quest/reward/shop loop, starter loot, first advancement hook, Brasshaven transition shell, and Belforge entry shell only as far as required for Phase 1 continuity.
- **P1-F — QA:** repeatable fresh-profile, death/respawn, rejoin, combat, quest, inventory, controller, and performance passes.

### Phase 1 definition of done

Phase 1 is complete only when all of the following are true:

- the full starter loop above is Studio-verified;
- the main playable route has no obvious placeholder/fallen environment assets;
- all normal gameplay tests run without red Output errors;
- the full `check.sh` gate passes;
- core state survives death/respawn and normal rejoin;
- keyboard/mouse is complete and controller has no blocking gaps;
- basic combat, Beginner Strike, quest turn-in, rewards, consumables, inventory/equipment, and shop interactions are usable by a normal player;
- Lumenreach has acceptable frame-time/memory behavior at the Phase 1 content density.

### Phase C — Content production

Fill the shell with original EverLeaf content:

- class families and advancement branches;
- Lumenreach and Brasshaven maps;
- monsters, drops, items, quests, NPCs, shops;
- skills and equipment tiers;
- dungeons/instances;
- Belforge Colossus;
- level 1–30 progression first, then 70/120/200 expansion.

### Phase D — Polish

- animation and combat feel;
- production hitboxes/hurtboxes;
- VFX/SFX/music;
- final HUD/UI design;
- accessibility/input refinement;
- responsive layouts;
- camera/movement feel;
- balance/economy tuning;
- original art replacement for every prototype asset.

### Phase E — QA, security, and launch

- exploit/remote audit;
- dupe/economy/reward abuse testing;
- DataStore failure/recovery tests;
- multi-client/network latency tests;
- controller/device passes;
- performance/memory/long-session soak;
- moderation/admin operations;
- staging → private alpha → closed beta → public release;
- rollback/versioning/deployment runbooks.

## Non-negotiable monetization rule

Robux remains cosmetic-only. Do not sell progression power, combat stats, currencies, drop-rate advantages, advancement, stronger equipment, or other pay-to-win advantages.

Current implementation follows that rule: the Founder pass grants recognition/cosmetics, the repeatable support product grants no gameplay power, and Membership is kept inactive until its recurring non-power benefits are complete and verified.

- V22 real building-layout pass: removed the V21 Lumenreach/Brasshaven court-overlay clutter approach and moved the actual buildings. Greenway, Crossroads, Glowmere, Eastbridge, Gravebone, Mossglen, Sunmoss, Veilfall, Shattered Arch and Proving now use street/compound/boardwalk/fort layouts where buildings face shared routes and public spaces. Secondary hamlets, patrol posts and ruin districts were also re-laid out around readable streets rather than four-corner pads. Brasshaven/Eastworks/Belforge now use an original eight-piece industrial MeshPart kit arranged into actual administration, workshop, boiler, barracks, loading, refinery, smelter and gatehouse blocks. Studio player-height acceptance remains required.

- V23 water regression fix: rebuilt gorge water generation as a two-pass carve/rock then channel/water operation. The previous interleaved rock/water loop allowed later rock samples to overwrite earlier water, leaving the river visually dry. Studio verification remains pending.

- Production monster visual rebuild batch 1: five original authored starter creatures (Lumen Mossling, Glowcap Slime, Suncrest Ridgebeak, Brambleback, Lumen Wisp) now have approved Roblox model assets and are loaded through a sanitized asset-to-Humanoid rig path. Their old code-built Part creatures remain fallback only. Studio visual/animation acceptance remains required.

- V24 hero architecture rebuild: replaced the eight core Lumenreach service buildings with a second-generation individually authored kit (civic hall, quartermaster depot, archive, inn, healer, workshop, stable, proving lodge). These no longer share the old box-shell/gable recipe: each has distinct massing, footprint, roof logic, frontage and role silhouette. Collision proxies were reshaped to match the new footprints. Roblox approval is complete; Studio player-height visual acceptance remains pending.

- V25 district architecture replacement: replaced the remaining 14 Lumenreach district/landmark production meshes with individually authored V2 assets (wayhouse, barn, two crofts, Glowmere stilt house, ranger hall, gatehouse, ruined hall, forge yard, mausoleum, observatory, sanctuary, fortress tower, shrine). All uploaded assets are Roblox-approved; Studio player-height acceptance is still required.

- Quest experience rebuild: live gameplay now records Interact, Craft, Use, and Reach objectives in addition to Defeat/Collect/Explore; early Lumenreach quests use the new objective vocabulary and the HUD renders player-facing verbs instead of raw objective type names.

- Hero NPC visual replacement: Ilyra, Orin, Tovin, Maela, and Seren now have original reviewed model assets loaded onto a hidden Roblox R15 animation skeleton. The generated R15 character factory remains only as a fallback for NPCs without authored production art. Studio visual/animation acceptance is still required.

- Persistent storage is now implemented and enabled: schema v4 adds 96-slot storage, server-authoritative deposit/withdraw actions use rollback-safe profile transactions and inventory stack rules, and a dedicated Storage menu provides single-item/stack transfers. Trading remains disabled until its two-player atomic transaction/session design is completed.

- Production asset QA gate: CI now parses every current authored architecture/creature/NPC GLB and rejects collapsed geometry, extreme proportions, suspicious scale, over-budget triangle counts, invalid GLB headers, and external image dependencies before Rojo builds pass. This prevents technically valid but obviously malformed model exports from silently becoming production assets.

- Brasshaven V4 architecture replacement: replaced the first industrial kit with eight individually re-authored V2 buildings/landmarks (administration hall, machinist workshop, smelter, boiler station, worker barracks, loading depot, industrial gatehouse, refinery tower). All eight uploads are Roblox-approved; Studio player-height acceptance is still required.

- Ambient MMO population pass: Lumenreach ambient residents now use bounded server-authoritative pathfinding routines with idle/walk states, ground sampling, non-blocking collision, and staggered movement timing instead of standing permanently in place. Functional quest/shop NPCs remain stationary. Studio crowd-motion acceptance is still required.

- 2026-09-16 secure player trading: replaced the disabled trade stub with a nearby/same-region server-authoritative exchange flow. Offers are rebuilt from server inventory state, item/shard amounts are revalidated before lock and confirmation, both detached profiles are validated before a no-yield dual commit, partner changes reset approval, player departure cancels the session, and a React trade overlay now handles requests/offers/lock/confirm/cancel. Full Studio two-client UX/latency testing remains required.

- 2026-09-16 Lumenreach monster art wave 2: authored and Roblox-approved original models now cover Gravebone Skeleton, Gravebone Captain, Royal Glowcap, and the Mosswarden boss. Together with the starter batch, every production Lumenreach combat monster except the intentionally utilitarian training dummy now resolves through reviewed authored model assets before procedural fallback. Studio animation/scale/combat readability review remains required.

- 2026-09-16 named NPC art wave 2: authored and Roblox-approved role-specific models now cover Eira, Sella, Aven, Neris, Nera, Cale, Tamsin, Mara, Rook, and Vale. With the first hero batch, all 15 named quest/service NPC definitions now resolve through reviewed authored model assets before the generated R15 fallback. The shared animated R15 skeleton remains intentional; silhouettes, apparel, tools, and role props are individually authored. Studio player-height/animation review remains required.

- 2026-09-16 public-event foundation: added the server-authoritative Greenway Breach public defense event with three escalating waves, contribution-based participation, shared region notices, event HUD/countdown, reconnect/join snapshot support, event rewards, and a real `PublicEvent` quest objective used by Ilyra's optional Hold the Greenway quest. Event enemies do not auto-respawn and only eligible combat contributors receive the completion reward. Multiplayer Studio pacing/UX verification remains required.

- 2026-09-16 authored monster rig hierarchy fix: production monster accessories now support explicit parent-segment hierarchy instead of every visual part being motorized directly to HumanoidRootPart. Eyes, armor, horns, caps, claws, weapons, foliage, and similar attachments now follow the animated head/body/limb they belong to, preventing detached/malformed visuals during movement and attacks.
- 2026-09-16 Brasshaven/Belforge monster-art completion: all 17 industrial-region combat enemies now have original Roblox-approved authored model assets, including every elite plus the Belforge Sentinel and Colossus. Combined with the Lumenreach batches, every production combat monster except the intentional training dummy now prefers reviewed authored art. Industrial humanoid heavies use segmented humanoid animation rigs and authored accessory-parent hierarchies; Studio scale/animation/combat-readability acceptance remains required.
- 2026-09-16 monster-template architecture cleanup: the 60+ KB procedural monster body builders were removed from the production asset loader and isolated in `LegacyMonsterFallbackFactory`. `MonsterTemplateService` is now a small authored-asset loader/sanitizer/rig assembler that iterates the full monster catalog; procedural bodies exist only behind an explicit fallback boundary.
- 2026-09-16 public-event expansion: the world-event system now rotates three distinct Lumenreach events—Greenway Breach, Glowmere Surge, and Eastbridge Assault—with separate locations, wave compositions, rewards, and region-specific announcement/success/failure copy instead of replaying one hard-coded Greenway encounter forever.
- 2026-09-16 NPC-factory architecture cleanup: the generated hair/face/clothing geometry path was removed from `StylizedNpcFactory` and isolated in `GeneratedNpcFallbackFactory`. The production NPC factory is now centered on reviewed authored assets, R15 attachment, grounding and animation; generated character dressing remains only behind an explicit fallback boundary.
- 2026-09-16 UI decomposition pass: extracted the main HUD/hotbar/status/objective presentation, quest log, settings screen, shared visual primitives, shared color theme, and shared objective/region text helpers from `ReactUIController`. The controller dropped from ~167 KB to ~116 KB in this first structural pass; character/inventory/skills/main-menu orchestration still remain to be split.
- 2026-09-16 Lumenreach world-service decomposition pass 1: extracted terrain clearing, zone-floor shaping, road terrain, mountain belts, gorge/water generation, wetland generation, and bridge-approach terrain into `LumenreachTerrainBuilder`. `LumenreachWorldService` now orchestrates that module and reuses its public terrain helpers for settlement/district shaping instead of owning the macro terrain implementation directly.
- 2026-09-16 canonical Lumenreach spatial contract: moved region dimensions/version, zone centers, bridge anchors, spawn/combat origins, road routes, gorge path, and dressing exclusions into `LumenreachWorldConfig`. World generation, gameplay activities, and rotating public events now consume the same coordinates so future map rebuilds cannot silently leave events/interactions at stale locations.
- 2026-09-16 Brasshaven public-event expansion: added canonical Brasshaven encounter anchors plus three level-gated rotating events (Foundry Scrap Surge, Eastworks Grid Break, Upper Foundry Lockdown). Public-event rotation now skips regions without eligible players, parents event runtime folders to the correct generated world, and can ground enemies against an explicit authored floor collision surface instead of requiring Terrain.
- 2026-09-16 public-event navigation polish: the shared event HUD now measures the local player against the authoritative event center and displays live distance in studs beside wave/hostile progress, so events are discoverable without guessing where the fight spawned.

- 2026-09-16 Creator Store architecture reset: retired the generated Blender Lumenreach/Brasshaven building kits from the production registry, enabled third-party free asset loading through the modern sandboxed AssetService path, curated free medieval/industrial building sources for all current logical architecture roles, hardened static-visual sanitization, and preserved EverLeaf-authored collision/layout/gameplay authority. Studio player-height review remains the visual acceptance gate.

- Creator Store architecture rollout versions: Lumenreach V26 and Brasshaven V5 advertise `CreatorStoreArchitecture=true`; Brasshaven skyline forge towers now prefer the curated free Smokestack v2 model with EverLeaf collision fallback.

- 2026-09-16 Studio screenshot correction: retired the malformed/tilted Bevillia Inn Creator Store model, replaced Wayfarer civic/inn visuals with a newer coherent free medieval pair, reduced their target scale, and expanded sanitization to remove Message/Hint/BillboardGui/SurfaceGui/ScreenGui/LayerCollector/GuiObject credit overlays from imported free models.
