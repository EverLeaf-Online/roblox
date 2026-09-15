# EverLeaf Roblox Roadmap

**Canonical status:** 2026-09-15
**Repository:** `EverLeaf-Online/roblox`
**Detailed tracker:** [`MASTER_CHECKLIST.md`](MASTER_CHECKLIST.md)
**Architecture:** [`ARCHITECTURE.md`](ARCHITECTURE.md)

## Lumenreach starter region — SOURCE BUILT / STUDIO ACCEPTANCE NOT PASSED

- The 2350×1800 Level 1–10 topology, combat spaces, settlements, crossings, quest route, and custom EverLeaf structure set exist in source, but **the current Studio world is not accepted as production-quality**. It still requires a player-height environment rebuild/QA pass and must not be described as finished merely because the generator/tests pass.
- Generic Toolbox/Creator Store architecture remains prohibited. Approved external nature assets are scenery only; foliage density is not a substitute for architecture, gameplay content, or environmental storytelling.
- Functional MMO world activity is now being added on top of the existing systems: gathering, crafting, rest points, persistent caches, additional regional NPCs, and optional side quests. The next acceptance gate is a fresh-player Studio session that actually feels like an MMORPG, not another source-only map milestone.

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

Studio-verified gameplay foundations remain third-person movement/camera, sprint/jump/dodge, basic combat, hostile enemy damage, React HUD/dialogue, quest accept/progress/turn-in, and Rojo/Wally/React sync. Lumenreach has now been **fully replaced** by the terrain-first V3 generator: 2350×1800 studs, permanent Wayfarer town, terrain-authored roads, two real gorge bridges, wetland/highland/ravine macro spaces, party-scale encounter floors, natural Terrain boundaries, and the Brasshaven gate at the far-east capstone. The generator clears the previous world before building V3, so future map work must refine this layout instead of stacking scenery over older geometry. Player-height art/collision/multiplayer/performance QA is the current Studio priority. The canonical contract is `docs/LUMENREACH_WORLD_LAYOUT.md`.

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
13. Confirm the full 2350×1800 starter region remains readable, traversable, performant, and free of placeholder/broken environment assets.

Phase 1 production priorities, in order:

- **P1-A — Stability:** no red errors, no broken respawn/UI state, no invalid material/plugin dependencies, no remote-authority regressions.
- **P1-B — Combat feel:** hit feedback, damage numbers, enemy telegraphs, leash/reset, knockback/stagger where appropriate, and production attack presentation.
- **P1-C — MMO starter-zone world:** Studio-validate the terrain-first 2350×1800 Lumenreach V3 layout, town hub, natural terrain boundaries, road grades, landmark silhouettes, encounter-room scale, foliage density, and far-edge Brasshaven transition; fix any player-height composition issue before adding more decorative density.
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
