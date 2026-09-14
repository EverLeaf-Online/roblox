# EverLeaf Roblox — Architecture

**Status:** Phase A complete
**Principle:** build the complete game structure before content density and polish.

## Authority boundary

The client requests actions and renders state. The server validates gameplay mutations, calculates results, owns persistence, and replicates safe snapshots. No client request may directly award EXP, currency, loot, damage, quest completion, advancement, ownership, or world access.

## Persistent profile domains

Schema version 2 owns:

- identity/meta and session-lock information;
- level, EXP, AP, SP, advancement tier/family;
- Might, Finesse, Insight, Fortune;
- Shards and Marks;
- inventory and equipment;
- learned skills and hotbar assignments;
- active/completed quests;
- current/unlocked world regions;
- achievements;
- cosmetic ownership/equips;
- player settings.

`server/Data/ProfileSchema.luau` is the canonical schema/migration/reconciliation layer. `PlayerDataService` owns DataStore/session lifecycle.

## Server system layers

### Core/player

- PlayerDataService / ProfileSchema
- SnapshotService
- ProgressionService / AdvancementService / StatService
- DerivedStatsService / ResourceService / CharacterStatsService
- DeathService / PlayerDamageService

### Combat

- CombatService / DamageService / TargetingService
- EnemyService / EnemySpawnerService / EnemyAIService
- SkillService / SkillEffectService / StatusEffectService
- BossService backed by the shared generic StateMachine

### Items/economy

- InventoryService / EquipmentService / EquipmentVisualService / ConsumableService
- CurrencyService / RewardService / ShopService
- CraftingService
- EnhancementService and StorageService hooks (disabled until their designs are approved)

### Content/progression/world

- QuestService
- InteractionService / InteractionSessionService
- WorldObjectService for physical actor registration/proximity
- RegionService / PortalService / WorldTravelService
- CatalogService
- AchievementService / CosmeticService

### Multiplayer/runtime

- PartyService with invite/accept/decline/kick/leader-transfer lifecycle
- InstanceService / InstanceTeleportService
- Boss encounter instances
- TradeService hook (disabled until trading is approved)

### Platform/security/operations

- RateLimiterService
- PayloadValidationService
- MovementSanityService
- ActionService
- AdminService / AuditLogService / ProfileRecoveryService
- ReleaseService / BuildInfo
- TelemetryService hook; no external telemetry is sent until a privacy-conscious plan is explicitly chosen

## Content registries

Server-owned content is data-driven under `server/Content/`:

- EnemyDefinitions
- ItemDefinitions
- SkillDefinitions
- QuestDefinitions
- NpcDefinitions
- ShopDefinitions
- RegionDefinitions
- PortalDefinitions
- BossDefinitions
- AchievementDefinitions
- RecipeDefinitions

The public client catalog is produced by `CatalogService`; clients do not require direct access to authoritative server definitions.

## Networking

Deterministic remotes are declared in `default.project.json` and named in `shared/Net.luau`.

- profile ready/change replication;
- party runtime events;
- profile request;
- AP allocation;
- basic attack;
- public catalog request;
- centralized `GameAction` router.

Every client-callable RemoteFunction is rate-limited. `GameAction` uses an explicit allowlist plus bounded payload validation. Shop/quest mutation requires a server-created interaction session. NPC/portal interaction architecture requires registered physical world objects and server-side proximity checks.

## Client layers

- Controllers: movement, camera, combat, React UI root, screen navigation.
- Presentation: family-aware combat pose/projectile/impact effects remain client-only while attack eligibility, targeting, cooldown, and damage remain server authoritative.
- Services: validated action client and public catalog client.
- State: profile store, party event store, UI store.
- Production UI: React Lua + ReactRoblox mounted once under `PlayerGui`; HUD/dialogue are the first migrated surfaces, with character, inventory, equipment, skills, quests, shop, party, settings, and boss screens following the same component tree.
- Custom UI capture is explicit: opening an interactive React surface releases the mouse and suppresses camera/movement/combat input until the surface closes.

Controllers are fault-isolated at startup so one stalled subsystem cannot block unrelated systems.

## Runtime and release boundaries

- World place and instance place IDs are explicit config and currently fail closed while unset.
- Instance teleports use reserved-server `TeleportAsync` only after an instance place is configured.
- Automatic production publishing is disabled.
- Development → staging → production rules are documented in `DEPLOYMENT.md`.
- Build/protocol/content versions are separate from persistent profile schema version.

## Architecture quality gates

`./check.sh` now enforces:

1. StyLua formatting;
2. Selene linting;
3. automated server-service require-cycle detection;
4. all Lune tests (currently gameplay math + state-machine regression tests);
5. Rojo headless place build.

The current dependency checker reports 66 server services with no cycles; Selene reports zero warnings/errors, the Lune regression suite passes, and both Rojo outputs build successfully.

## Phase A completion rule

Phase A means every major game domain has a canonical home, explicit authority boundary, persistent/runtime ownership model, and defined connection to neighboring systems. It **does not** mean the content, UI, balance, animation, map art, or gameplay polish is complete. Those belong to Phases B–E.


## 3D physical gameplay layer

The canonical physical layer is full 3D. There is no fixed combat plane and no Z-axis correction.

- `ThirdPersonController` owns camera-relative locomotion, sprint, jump, and dodge input.
- `CameraController` owns the scriptable orbit camera, collision pull-in, mouse/right-stick look, and cursor lock during gameplay.
- `CombatController` maps left-click/R2 to server-authoritative attacks and aligns the avatar with camera intent before melee.
- `TargetingService` performs server-side 3D range, facing-cone, vertical-tolerance, and optional line-of-sight selection.
- `EnemyAIService` pursues targets in XYZ space; production enemies will graduate to pathfinding/navigation as maps become nontrivial.
- `MovementSanityService` enforces locomotion limits without constraining players to a plane.
- World art must assume StreamingEnabled-scale construction, modular environment kits, collision proxies, and measured mesh/material budgets.
