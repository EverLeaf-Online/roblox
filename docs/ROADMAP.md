# EverLeaf Roblox Roadmap

**Canonical status:** 2026-09-14
**Repository:** `EverLeaf-Online/roblox`
**Detailed tracker:** [`MASTER_CHECKLIST.md`](MASTER_CHECKLIST.md)
**Architecture:** [`ARCHITECTURE.md`](ARCHITECTURE.md)

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
- asset import/optimization/licensing pipeline; real sanitized mesh/PBR ingestion remains the next visual-quality milestone;
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


### Current verified Phase B baseline — 2026-09-14

Studio-verified today: third-person movement/camera, sprint/jump/dodge, left-click basic attack, hostile Mossling combat/player damage, React HUD/dialogue, Lumen Guide quest accept/progress/turn-in, and Rojo/Wally/React sync. Source-complete but not yet fully Studio-verified/polished: the multi-tab RPG menu shell, generic skills, party/instance/boss shells, and several backend service boundaries. The environment remains prototype-quality until sanitized mesh/PBR assets replace procedural primitives.

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

**Phase B exit:** a player can traverse a representative 3D Lumenreach slice and the intended game loop end-to-end even though content density and presentation remain incomplete.

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
