# EverLeaf Whole-Game Quality Audit

**Status:** ACTIVE quality reset — 2026-09-16  
**Purpose:** stop extending weak implementations merely because they already exist. Every major game domain is classified as **KEEP**, **REFACTOR**, or **REBUILD** before additional content expansion.

## Classification rules

- **KEEP** — underlying ownership/authority/data model is sound; continue normal feature work and QA.
- **REFACTOR** — behavior is useful, but implementation/pipeline is too monolithic, prototype-heavy, or difficult to scale safely.
- **REBUILD** — current production-facing approach is below the intended MMORPG quality bar; do not keep polishing the same foundation.
- A source/test pass is not visual or gameplay acceptance. Studio player-height verification remains mandatory for presentation-heavy systems.

## Executive finding

The server/gameplay architecture is substantially stronger than the production-facing presentation layer. Persistence, authority boundaries, inventory/equipment rules, progression, combat validation, quest state, rewards, party state, and save migrations generally have coherent ownership and regression tests. The weakest foundations are the **world-art pipeline, procedural world composition, code-built characters/monsters, UI monolith, quest objective vocabulary, disabled social/economy shells, production telemetry/operations, and live performance/QA discipline**.

The current development strategy changes from **add more content** to **replace weak foundations first, then scale content on top of accepted pipelines**.

---

## 1. Repository / toolchain — KEEP with cleanup

### Keep
- Rojo/Wally/Rokit build path.
- `check.sh` format/lint/test/build gate.
- Client/server/shared source split.
- Service-cycle test and Lune regression suite.
- Original-asset Blender → GLB → Roblox upload path introduced for Lumenreach architecture.

### Fix before scale-up
- Add CI parity for `check.sh`.
- Add release/tagging rules for playable checkpoints.
- Remove local `.bak.*` clutter from source/doc directories after confirming they are not needed; they are not tracked, but they make VM inspection noisy.
- Extend asset validation to original architecture GLBs, not only the older Poly Haven set.

**Classification: KEEP.**

---

## 2. Persistence / profile schema — KEEP, production-stress QA required

Evidence: `PlayerDataService`, schema v3, migration/reconciliation, retry/backoff, serialized saves, session locks, autosave heartbeat, save/rejoin regression coverage.

### Keep
- Current ownership model and profile schema.
- Server-only mutation path.
- Revision/session-lock discipline.

### Still required
- Live DataStore throttle/failure/budget tests.
- Multi-server lock contention/rejoin soak.
- Admin recovery/backup workflow.

**Classification: KEEP.** Do not rewrite this foundation without a concrete failure.

---

## 3. Core progression / stats / inventory / equipment — KEEP

Evidence: dedicated progression/stat/equipment/inventory services and pure rules modules; bounded inventory rules; equipment eligibility/type/comparison rules; persistent round-trip tests.

### Keep
- Might/Finesse/Insight/Fortune model.
- AP/SP progression ownership.
- Inventory/equipment transaction boundaries.
- Equipment contribution into derived combat stats.

### Improve later
- More item categories and equipment presentation.
- Better inventory UX/filtering.
- Balance/economy tuning after full vertical-slice playtests.

**Classification: KEEP.**

---

## 4. Combat authority and damage pipeline — KEEP, presentation/tuning REFACTOR

Evidence: server-owned targeting, attack cadence, hitbox math, LOS, damage, enemy rewards, contribution rules, threat, player damage, dodge authority, projectile math, cooldown stores, tests.

### Keep
- Server-authoritative attack/damage/reward model.
- Threat/contribution ownership.
- Dodge validation and movement-sanity boundaries.
- Skill targeting/effect execution ownership.

### Refactor / productionize
- Standardize hitbox/hurtbox definitions across basic attacks, skills, monsters, and bosses.
- Tune telegraphs, hit pause/impact, stagger/knockback, animation timing, and readable combat VFX in Studio.
- Decide and implement soft-target/lock-on only after camera/combat playtests justify it.

**Classification: KEEP core logic / REFACTOR presentation layer.**

---

## 5. Enemy and monster visual pipeline — REBUILD

Evidence: `MonsterTemplateService.luau` is ~2,000 lines and directly constructs the current monster roster from code-built Parts/Motors. This is the same failure mode that produced generic architecture: source complexity grows while visual quality stays tied to primitive construction.

### Replace
- Code-built production monster bodies as the default art pipeline.
- One giant monster-template service that owns every visual body.

### New pipeline
- Original low-poly rigged monster assets authored in Blender.
- Shared rig/animation conventions and import validation.
- Data definitions select visual prefab + animation set; gameplay stats remain server data.
- Keep simple code-built models only as explicit debug/test fallbacks.
- Establish triangle/material/texture budgets per common monster, elite, and boss.

**Classification: REBUILD visual pipeline; KEEP combat AI/stats/reward logic.**

---

## 6. NPC visual pipeline — REBUILD

Evidence: `StylizedNpcFactory.luau` builds character appearance from scripted segmented geometry and accessories. It is functional but not an acceptable long-term production character-art pipeline for the target visual bar.

### Replace
- Script-generated production NPC bodies as the default.

### Preserve
- NPC definitions, roles, dialogue IDs, interaction registration, grounding, quest/shop behavior.

### New pipeline
- Roblox avatar/R15 or authored rig base with controlled original clothing/hair/accessory meshes.
- Reusable body/face/hair library with role-specific authored assets.
- Animation sets and idles separated from NPC gameplay definitions.

**Classification: REBUILD visuals / KEEP gameplay contracts.**

---

## 7. Lumenreach world construction — REBUILD presentation, REFACTOR generator

Evidence: `LumenreachWorldService.luau` is over 217 KB and owns terrain, roads, foliage placement, props, structures, settlements, NPC placement, spawns, zones, encounters, labels, collision normalization, and micro-sites. Multiple V11–V16 passes fixed symptoms but demonstrated that a giant procedural world script is the wrong production-art authoring boundary.

### Keep
- Canonical zone topology and progression route where it plays well.
- Terrain macro layout ideas: Camp → Greenway → Crossroads → Glowmere/Eastbridge → Gravebone/Mossglen → Sunmoss/Veilfall → Shattered Arch.
- Separate collision-proxy policy.
- World object/zone/encounter registration concepts.
- V16 original MeshPart architecture pipeline.

### Rebuild / refactor
- Stop treating one service as the visual authoring tool for the entire region.
- Move authored structures/landmarks/settlements to modular asset/prefab definitions.
- Split terrain generation, placement data, gameplay triggers, collision, and population into separate modules/data.
- Replace remaining primitive-built visible structures with original mesh kits.
- Perform district-by-district Studio composition passes; screenshots/player-height traversal are the acceptance authority.

**Classification: REBUILD visual world / REFACTOR generator ownership.**

---

## 8. Brasshaven / Belforge world art — REBUILD

Evidence: `BrasshavenWorldService.luau` remains heavily Part/procedural and does not yet have the equivalent original industrial MeshPart kit.

### Preserve
- Level 10–30 route, quest gates, Belforge access rules, encounter service, collision authority, portals/spawns.

### Replace
- Procedural industrial shell with an original modular industrial kit: foundry buildings, gantries, furnaces, pipes, depots, gates, arena support structures, ruins.

**Classification: REBUILD presentation / KEEP progression and encounter logic.**

---

## 9. Environment asset pipeline — KEEP and expand

The move to original Blender-authored GLBs is the correct foundation.

### Keep
- Blender source generation/authorship.
- GLB manifests and reproducible source assets.
- Roblox Open Cloud upload path.
- Sanitized prefab registration.
- Render-only visible meshes + explicit simplified collision proxies.

### Expand
- Original modular architecture kits for every region.
- Original prop kits.
- Original creature/NPC meshes.
- Automated mesh budget/scale/material validation.
- LOD strategy and performance benchmark scenes.

**Classification: KEEP. This becomes the canonical production-art pipeline.**

---

## 10. Quest system — REFACTOR

Evidence: the current quest vocabulary is almost entirely three objective types: **Defeat, Collect, Explore** (32 Defeat, 26 Collect, 11 Explore definitions at audit time). That is enough for scaffolding but too narrow for an MMORPG campaign.

### Preserve
- Quest prerequisites, active/completed state, explicit turn-in, reward ownership, persistence.

### Add objective/action vocabulary
- Interact/use object.
- Talk/sequence/conversation step.
- Deliver/hand-in item without generic collection semantics.
- Escort/protect.
- Defend timed area/waves.
- Activate mechanisms in order.
- Craft/upgrade/use consumable.
- Boss/elite encounter state objective.
- Public-event contribution.
- Instance completion.

### Design requirement
Quest objectives should be event-driven through a common objective bus rather than every new activity manually pretending to be Collect/Explore.

**Classification: REFACTOR objective framework; KEEP lifecycle/persistence.**

---

## 11. Content flow / onboarding — REFACTOR

The current level route exists, but source completeness has outrun moment-to-moment onboarding quality.

### Rework first 20–30 minutes around
- movement/combat/dodge tutorial activity;
- first meaningful loot/equip decision;
- service interaction and crafting/rest;
- one dynamic defense/event encounter;
- clearer landmark-driven navigation;
- distinct safe hub versus dangerous field rhythm;
- first advancement as a memorable authored sequence, not just another objective chain.

**Classification: REFACTOR experience flow.**

---

## 12. UI architecture — REFACTOR

Evidence: `ReactUIController.luau` is ~161 KB and contains HUD, dialogue, character, inventory, skills, quests, settings, menus, death overlay, notification logic, and application state wiring. This is now a maintenance bottleneck.

### Keep
- React/ReactRoblox foundation.
- Profile/UI stores.
- Existing server action contracts.
- Responsive reference-scale approach.

### Refactor
- Split HUD, dialogue, menu shell, character, inventory, equipment, skills, quests, settings, notifications, and controller navigation into focused modules/components.
- Centralize shared visual tokens/components.
- Separate view state from profile-diff notification logic.
- Perform keyboard/mouse, controller, ultrawide, 16:9, low-resolution, and mobile-touch evaluation before calling the shell production-ready.

**Classification: REFACTOR, not rewrite.**

---

## 13. Party / multiplayer — KEEP, live QA required

Evidence: party lifecycle, invites, ready checks, snapshots, boss entry and contribution reward logic exist and are tested in source.

### Required
- Multi-client Studio/live smoke tests.
- Latency/disconnect/leader-leave behavior.
- Party UI/readability at real gameplay pace.
- Cross-server strategy only when actual content requires it.

**Classification: KEEP.**

---

## 14. Instances / bosses — REFACTOR before expansion

The generic instance/teleport boundary is clean, but `InstanceService` is intentionally minimal/in-memory and the instance place may be unconfigured. Belforge has a specialized encounter lifecycle.

### Keep
- Reserved-server boundary.
- Fail-closed config behavior.
- Boss state-machine concept and Belforge access rules.

### Refactor before multiple dungeons
- Define durable encounter/session metadata requirements.
- Reconcile generic `BossService` with specialized Belforge lifecycle so two competing boss architectures do not grow independently.
- Add reconnect/party-member-loss semantics.

**Classification: REFACTOR before adding many instances.**

---

## 15. Storage / trading / enhancement — DECIDE before implementation

Evidence: `StorageService` and `TradeService` are deliberately disabled stubs; this is safer than half-implementing an economy-sensitive feature.

### Current status
- Storage: disabled.
- Trading: disabled.
- Enhancement: architecture exists but should not expand until economy design is locked.

### Requirement
Do not mark these domains complete simply because interfaces exist. Decide economy/isolation/abuse rules first, then implement transactionally with dupe tests.

**Classification: KEEP disabled until design approval; then BUILD properly.**

---

## 16. Security / networking — KEEP and continue adversarial QA

Evidence: server-authoritative mutations, rate limits, payload validation, movement sanity, interaction sessions, proximity validation, purchase safety rules, dupe/reward regressions.

### Continue
- exploit-oriented remote review after each new action type;
- economy transaction invariants;
- movement false-positive testing under latency;
- instance/party race testing;
- purchase receipt idempotency.

**Classification: KEEP.**

---

## 17. Telemetry / operations — BUILD

Evidence: `TelemetryService.Record` is intentionally a no-op hook and `ReleaseService.CanPublishAutomatically()` returns false.

### Needed before beta
- privacy-conscious gameplay/error telemetry decision;
- structured server error/critical event logging;
- performance metrics for frame time, memory, streaming stalls, and long sessions;
- release tags/build IDs surfaced in bug reports;
- rollback process and deploy checklist.

**Classification: BUILD before external beta.**

---

## 18. Performance / streaming — REFACTOR discipline, not code-only

The project targets a large streaming world but currently lacks measured production budgets.

### Required benchmark gates
- device classes: low PC, typical PC, mobile target if supported;
- client frame time and server heartbeat;
- instance count;
- mesh/texture memory;
- streaming arrival latency;
- NPC/monster count scaling;
- foliage overdraw/shadows;
- combat VFX spikes;
- UI memory/update cost.

No world-art pipeline is accepted until it passes a benchmark scene.

**Classification: REFACTOR process / MEASURE immediately.**

---

# Priority reset

## P0 — stop extending weak foundations

1. **World art:** continue the original MeshPart pipeline; no new production buildings from procedural wall/roof Parts.
2. **World generator:** split visual placement/data from gameplay registration and collision.
3. **Monster art:** begin authored low-poly creature pipeline; keep existing code monsters only as temporary gameplay carriers.
4. **NPC art:** replace scripted primitive-body production path with controlled authored/R15 assets.
5. **UI:** freeze large new menu additions until the React monolith is split.
6. **Quest framework:** add richer objective events before writing large new quest chains.

## P1 — make the starter slice feel like a game

1. Finish Lumenreach architecture kit and district conversions.
2. Recompose Wayfarer Camp and first-route landmarks in Studio at player height.
3. Build first authored monster/NPC visual benchmark.
4. Build training/tutorial interaction objectives and one dynamic event.
5. Split core UI surfaces enough to iterate safely.
6. Run a complete fresh-player 1–10 Studio pass and fix every blocking issue before expanding content.

## P2 — then scale content

1. Brasshaven/Belforge original industrial kit.
2. Level 10–30 environment/content polish.
3. Additional dungeons/bosses only after generic instance lifecycle is reconciled.
4. Storage/trading only after economy design and transactional abuse tests are approved.

# Acceptance rule going forward

A system can be **source-complete** without being **game-complete**. Production-facing systems require the appropriate acceptance evidence:

- visual world/art → Studio screenshots + traversal + performance;
- combat feel → live play timing/tuning;
- multiplayer → multi-client test;
- persistence → rejoin/throttle/session-lock test;
- UI → resolution/input-device pass;
- economy → transactional abuse/dupe tests;
- release → deploy/rollback exercise.

No future checklist item should use plain “complete” when only source implementation has been verified.

## Rebuild execution update — 2026-09-16

The rebuild has moved beyond roadmap classification. Production monster and NPC factories now prefer explicitly reviewed authored templates and tag procedural/generated models as fallback-only. Quest progress is routed through a common objective bus supporting Defeat, Collect, Explore, Interact, Craft, Use, Reach, Escort, and Survive. Source-tree iterative `.bak` snapshots were removed and ignored so the repository reflects production source rather than editing debris. The next visual milestone is replacing fallback monster/NPC visuals with reviewed original assets and continuing district/hero-architecture replacement under player-height Studio QA.

- Production monster visual rebuild batch 1: five original authored starter creatures (Lumen Mossling, Glowcap Slime, Suncrest Ridgebeak, Brambleback, Lumen Wisp) now have approved Roblox model assets and are loaded through a sanitized asset-to-Humanoid rig path. Their old code-built Part creatures remain fallback only. Studio visual/animation acceptance remains required.

- V24 hero architecture rebuild: replaced the eight core Lumenreach service buildings with a second-generation individually authored kit (civic hall, quartermaster depot, archive, inn, healer, workshop, stable, proving lodge). These no longer share the old box-shell/gable recipe: each has distinct massing, footprint, roof logic, frontage and role silhouette. Collision proxies were reshaped to match the new footprints. Roblox approval is complete; Studio player-height visual acceptance remains pending.

- V25 district architecture replacement: replaced the remaining 14 Lumenreach district/landmark production meshes with individually authored V2 assets (wayhouse, barn, two crofts, Glowmere stilt house, ranger hall, gatehouse, ruined hall, forge yard, mausoleum, observatory, sanctuary, fortress tower, shrine). All uploaded assets are Roblox-approved; Studio player-height acceptance is still required.

- Quest experience rebuild: live gameplay now records Interact, Craft, Use, and Reach objectives in addition to Defeat/Collect/Explore; early Lumenreach quests use the new objective vocabulary and the HUD renders player-facing verbs instead of raw objective type names.

- Hero NPC visual replacement: Ilyra, Orin, Tovin, Maela, and Seren now have original reviewed model assets loaded onto a hidden Roblox R15 animation skeleton. The generated R15 character factory remains only as a fallback for NPCs without authored production art. Studio visual/animation acceptance is still required.
