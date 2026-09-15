# EverLeaf Roblox — Master Checklist

**Canonical status:** 2026-09-15
**Latest gameplay checkpoint:** source-complete Level 1–30 vertical-slice systems through Belforge — Tier-2 advancement, Colossus boss lifecycle, party ready-check/group entry, Defense/Critical combat stats, full 8-slot hotbar UX/cooldowns, incoming-hit feedback, region-aware HUD, and requirement/comparison-aware equipment UI
**Purpose:** detailed implementation/status tracker for the entire project.
**Roadmap:** [`ROADMAP.md`](ROADMAP.md)

## Legend

- [x] Complete and verified at the level stated.
- [ ] Not complete.
- **PARTIAL** means meaningful implementation exists but the complete feature is not yet ready/verified.
- **DECISION** means design must be locked before implementation should proceed.

---


## PHASE 1 — complete starter vertical slice — ACTIVE

### A. Stability / no-breakage gate

- [x] Third-person movement/camera/sprint/jump/dodge Studio-verified.
- [x] Basic attack Studio-verified.
- [x] Beginner Strike on hotbar slot 1 Studio-verified.
- [x] Quest accept/progress/explicit turn-in Studio-verified.
- [x] Enemy damage/death/respawn Studio-verified.
- [x] React HUD persists correctly across respawn after persistent `ScreenGui` fix.
- [x] Main menu opens and interactive actions are Studio-verified.
- [x] Poly Haven PBR texture assets uploaded to Roblox and all 15 maps approved.
- [x] Five EverLeaf MaterialVariants can now be authored/refreshed successfully by the Studio plugin.
- [ ] No red Output errors across a complete fresh-player Phase 1 run.
- [ ] Fresh-profile/rejoin live Studio regression pass; canonical fresh-template defaults and full persisted-domain save→rejoin round trip are regression-tested in source.
- [ ] DataStore failure/session-lock stress pass.

### B. Combat / enemy feel

- [x] Server-authoritative basic attack, range/facing/LOS validation, damage, cooldown, and enemy reward handoff.
- [x] Server-authoritative Beginner Strike with MP/cooldown rollback on failed effect.
- [x] Monster floating damage numbers.
- [x] Monster hit-confirm VFX/SFX and hit-flinch presentation.
- [x] Enemy attack windup with damage applied at the impact moment.
- [x] Normal monster melee impacts now revalidate a server-owned forward hurtbox volume + vertical reach + LOS at the impact frame, so sidesteps/behind-target movement/cover can evade telegraphed swings.
- [x] Aggro leash/reset and return-to-home behavior.
- [x] Server threat tables stabilize multiplayer aggro: damage builds threat, current-target hysteresis prevents nearest-player thrash, and threat clears on leash/reset/death; live party-combat QA remains open.
- [x] PathfindingService pursuit foundation around obstacles.
- [x] Monster dodge reactions, cooldowns, brief invulnerability, and backward evade movement.
- [x] Visible world loot drops with ownership, labels, pickup prompts, and despawn timing.
- [x] Per-monster death VFX/debris/SFX foundation.
- [x] Monster attacks now apply data-driven player knockback, launch, and short stagger rules with movement-sanity grace; client incoming-hit feedback is source-complete.
- [ ] Studio-tune pathfinding, dodge rates, attack ranges, and combat feel across all Lumenreach encounters.
- [ ] Multiplayer threat/target-selection and party-combat QA.

### C. Lumenreach environment production pass

- [x] Lumenreach rebuilt as a larger 900×760 explorable region with separated destinations and connected trail network.
- [x] Wayfarer Camp, Lumenwood Crossroads, Shattered Lumen Arch, Mossglen Combat Grove, Veilfall Cascade, Glowmere Pool, and Sunmoss Overlook established.
- [x] Poly Haven PBR material pipeline is live for forest ground, mossy rock, moss wood, wood-chip path, and wood/stone pathway.
- [x] Production foliage now prefers approved imported assets only; the visible procedural sphere-tree/bush/rock fallbacks were removed from Lumenreach production placement so missing assets fail closed instead of degrading visual quality.
- [x] Production-oriented trees, ferns, deadwood, rock faces, mossy rock sets, stumps, roots, logs, mushrooms, cattails, and waystones integrated.
- [x] Oversized/unintegrated cliff meshes and black stacked-rock formations corrected and blended into terrain.
- [x] Starter camp rebuilt with larger tents, proper supplies, map table, benches, lanterns, signpost, and custom guide/NPC composition.
- [x] Production NPC grounding is shared and runtime-resolved: Lumenreach R15 NPCs use terrain foot grounding, Brasshaven named NPCs use world-floor grounding, and the old Brasshaven primitive body builders are removed.
- [x] Static enemy grounding is explicit and build-guarded: the training dummy uses measured model-to-terrain grounding, and `check.sh` rejects new direct enemy spawns that omit terrain grounding.
- [x] Lumenreach camp NPCs now use grounded R15 humanoid rigs with distinct role silhouettes, clothing layers, face/hair treatment, props, idle animation support, and terrain-only foot grounding; Studio visual QA remains.
- [x] Lumenreach NPC visual overhaul is source-complete: Ilyra, Orin, Tovin, Maela, and Seren now use a reusable stylized-character factory with rounded segmented limbs, unique hair/build silhouettes, layered clothing, and role-specific props; Studio visual QA remains.
- [x] World density pass added continuous forest bands, roadside clusters, undergrowth, deadwood, rocks, and landmark dressing.
- [x] Lumenreach macro-layout replacement is source-complete: all major zones were repositioned, Crossroads moved onto a raised west-side saddle, Veilfall moved into a lowered ravine, Sunmoss moved onto an elevated ridge, a carved Lumen Gorge now divides west/east Lumenreach, and a required bridge crossing connects the two halves; fresh Studio visual QA remains.
- [x] Interior terrain-room rebuild is source-complete: the visible perimeter hill ring was reduced to minor anchors; Camp basin, Crossroads saddle, Glowmere bowl, Veilfall canyon, east forest spine, Ruins shelf, Mossglen amphitheater, and Sunmoss highland now use interior ridge systems, exposed rock shelves, carved road passes, and mixed habitat pockets; Studio visual QA remains.
- [x] Canonical all-route clearance graph + post-generation scrub removes decorative trees, bushes, grass, rocks, deadfall, roots, ferns, and Wayfarer remnants that overlap protected travel lanes.
- [x] Camera collision stabilized so non-solid foliage/decor no longer causes view snapping.
- [x] Environmental storytelling pass adds old wayfarer remnants and hidden Whisperroot Hollow.
- [ ] Full player-height visual QA for every imported mesh, rock/cliff, root, log, and path obstruction.
- [ ] Final lighting/sky/atmosphere art-direction pass for Phase 1. Approved Anime Island Skybox `14753835117` is now loaded visual-only through `WorldVisualService`; final Studio art-direction tuning remains.
- [ ] Measure frame time, memory, streaming, and foliage-density budgets in Studio.

### D. UI / RPG shell

- [x] React HUD: HP, MP, EXP, level, currencies, objective tracker, and hotbar.
- [x] Out-of-combat HP/MP regeneration is server-driven with combat delays, Insight-scaled MP recovery, and percentage/floor HP recovery.
- [x] React HUD survives death/respawn.
- [x] Character AP allocation action is wired.
- [x] Inventory use/equip/unequip actions are wired.
- [x] Skill rank/assign/use actions are wired.
- [x] Quest menu shell exists.
- [x] Settings mutations are wired.
- [x] Responsive UI scaling foundation is source-complete: the React app mounts in a centered 1280×720 reference root with live viewport-driven UIScale. Common-resolution/mobile Studio QA remains open.
- [x] Controller/gamepad navigation/focus source pass: Start/B/L1/R1 menu flow, device-aware hotbar labels, initial actionable focus, and gameplay/UI input capture are implemented; live controller-only Studio QA remains in Phase 1 exit validation.
- [x] Dedicated buy/sell shop screen implemented with item selection, quantity controls, pricing, balance display, and server-authoritative transactions.
- [x] Reusable item detail card implemented for shop/inventory-facing item inspection; hover/pointer refinement remains part of final UI QA.
- [x] Notification/toast system implemented for level-up, currency/item rewards, quest acceptance/readiness/completion, shop success, and shop errors.
- [x] Server-driven world notices now explain blocked region/Belforge/Colossus travel and encounter lockout/reset reasons through the production toast system.
- [ ] Split monolithic `ReactUIController` into maintainable components after Phase 1 behavior is locked.

### E. RPG/content closure

- [x] Guide → Mossling starter quest route exists and explicit turn-in works.
- [x] Mossling spawn restored so the starter quest is completable in the rebuilt world.
- [x] Consumable architecture and server-side use path exist.
- [x] Inventory/equipment persistence foundations exist.
- [x] Visible starter loot drops/pickups implemented.
- [x] Data-driven drop tables and quantity/chance rules implemented for the current Lumenreach monster set.
- [x] Starter equipment/reward path added (`Wayfarer Scout Blade`, `Mossguard Charm`, tonics/materials).
- [x] Three camp NPCs added beyond Ilyra: Orin (quartermaster), Tovin (scout), and Maela (archive keeper).
- [x] NPC dialogue now changes with progression and quest availability.
- [x] Starter/tutorial, hunting, exploration, boss, region-unlock, and first Brasshaven quest chains added.
- [x] Quest prerequisites, Collect objectives, and Explore objectives implemented.
- [x] Landmark exploration triggers wired for Crossroads, Glowmere, Shattered Arch, Veilfall, Sunmoss, and Whisperroot Hollow.
- [x] Multi-item shops exist for Lumenreach supply/outfitter/archive vendors plus Brasshaven Foundry Supply and Belforge Mark Exchange.
- [x] Hidden Whisperroot Hollow and persistent one-time Wayfarer cache reward implemented.
- [x] First Lumenreach field boss implemented: Mosswarden, Root of the Old Grove.
- [x] Lumenreach → Brasshaven progression gate is functional and region unlock rewards are supported.
- [x] Brasshaven now has a regression-tested Level 10–30 route: Vale carries 10–20, Tamsin carries 20–24, and Rook carries 24–30 through the upper foundry to the Belforge gate.
- [x] Brasshaven Foundry Threshold starter shell is physically reachable with a working return gate.
- [x] Region travel now moves the character transactionally and updates the saved/current respawn target.
- [x] Region/Belforge travel proactively streams registered destinations server-side before teleport; group arena entry prefetches members concurrently and travel remains fail-open on stream timeout.
- [x] Dedicated full buy/sell shop screen implemented beyond dialogue preview buttons; Studio interaction/balance QA remains.
- [x] Level-up feedback is implemented and the source-authored Lumenreach 1–10 + Brasshaven 10–30 quest route has no mandatory grind gap in regression tests; Studio combat/economy tuning remains.
- [x] First advancement hook/location/quest flow implemented with Seren, the Proving Circle, The Five Paths, and five permanent family choices.
- [x] Level-30 Belforge approach is functional: Sentinel completion + Level 30 unlocks a safe antechamber/return route, Mara handles second advancement there, and the inner Colossus seal remains closed until the real boss encounter is implemented.

### F. Phase 1 exit validation

- [ ] Fresh player can complete the full starter loop with no manual developer intervention.
- [ ] Death and respawn do not break UI, controls, quest progress, resources, or hotbar state.
- [x] Deterministic save→rejoin migration regression preserves progression, stats, currencies, inventory/equipment, skills/hotbar, active/completed quests, region/spawn/unlocks/secrets, achievements, cosmetics, and settings; live rejoin soak remains open.
- [ ] Keyboard/mouse full pass.
- [ ] Gamepad/controller blocking-flow live Studio pass; source support is now implemented for movement, camera, attack, jump, sprint, dodge, all 8 skill slots, menu open/back/tab cycling, device-aware hotbar labels, and initial UI focus.
- [ ] Multi-client basic party/network smoke test; party UI, ready checks, group boss entry, and contributor rewards are source-complete but still need live multi-client verification.
- [ ] Full `./check.sh` gate passes at final Phase 1 checkpoint.
- [ ] Studio Output contains no red errors during the canonical Phase 1 run.

---

## 0. Phase A — complete architecture — COMPLETE

- [x] Versioned persistent profile schema owns all major player-state domains.
- [x] Centralized server-authoritative `GameAction` router with rate limiting.
- [x] Data-driven registries for items, skills, quests, NPCs, shops, regions, portals, bosses, achievements, and enemies.
- [x] Inventory/equipment/consumable service boundaries.
- [x] Skill/hotbar/status-effect service boundaries.
- [x] Quest/NPC/shop interaction-session service boundaries.
- [x] Region/portal/world-progression service boundaries.
- [x] Party/instance/boss runtime service boundaries.
- [x] Achievement/cosmetic/settings persistence boundaries.
- [x] Client action/catalog/profile/UI-state layers.
- [x] Reward pipeline can grant EXP, currencies, and items.
- [x] Equipment stat bonuses feed combat damage, Defense mitigation, and Critical Chance/Power.
- [x] Equipment core-stat bonuses now feed all matching derived effects as well as damage (for example Might → Max HP/Defense and Insight → Max MP).
- [x] Physical world-object registry + proximity validation for NPCs/portals.
- [x] Enemy AI state-machine + enemy-to-player damage architecture.
- [x] Generic skill targeting/effect execution architecture.
- [x] Generic boss state-machine interface.
- [x] Crafting/enhancement/storage hooks.
- [x] Party invite/accept/kick protocol.
- [x] Party client state contract carries durable snapshots/invite expiry and remains synchronized across create/join/kick/leave/leader handoff.
- [x] Instance teleport/lifecycle boundary.
- [x] Admin/recovery/audit interfaces.
- [x] Release/build/staging/production architecture.
- [x] Client screen navigation/controller shell.
- [x] Architecture-level tests for newly added pure logic.
- [x] Final dependency/cycle/security review.

## 0B. Full 3D pivot — ACTIVE

- [x] 2.5D direction retired.
- [x] Third-person camera-relative WASD/gamepad movement foundation.
- [x] Crouch movement state is source-complete: C / gamepad R3 toggle, crouch-speed clamp, camera offset, server-validated stance intent, respawn reset; Studio posture/clearance feel still needs QA.
- [x] Mouse/right-stick orbit camera foundation with camera collision.
- [x] Sprint foundation (`Shift` / L3).
- [x] Grounded jump foundation (`Space` / A).
- [x] Dodge foundation (`Q` / B).
- [x] Basic attack moved to left-click / R2.
- [x] Server targeting converted from X/Y/Z-plane gates to 3D range + facing cone + LOS.
- [x] Enemy pursuit converted to full XYZ movement.
- [x] Z-plane movement correction removed.
- [x] Modern lighting/atmosphere baseline service.
- [x] Server-authoritative melee basic attacks now use forward overlap-box hit detection against active enemy models with arc/range/LOS validation; broader skill/enemy hurtbox standardization remains.
- [ ] Lock-on / soft-target system decision and implementation.
- [x] **PARTIAL:** PathfindingService pursuit/navigation is source-complete; full Studio obstacle/edge-case tuning remains.
- [x] Lumenreach 3D benchmark graybox generated from canonical source.
- [x] Asset import/optimization pipeline supports sanitized runtime prefab intake plus approved Poly Haven PBR/model assets, manifests, fallbacks, and grounding/collision controls.
- [x] Poly Haven/approved Sketchfab material/model source policy documented.
- [x] Poly Haven 1K PBR source set downloaded, hash-manifested, uploaded to Roblox (15/15 approved), wired to generated asset IDs, and Studio MaterialVariants verified.
- [x] Source-controlled wind/ambient-motion foundation integrated; production foliage assets are in use, with performance tuning still pending.
- [ ] Streaming/performance budgets measured in Studio.
- [x] **PARTIAL:** Lumenreach environment replacement/content-density pass is substantially complete; player-height visual QA and performance verification remain.

## 1. Repository / development environment

- [x] `EverLeaf-Online/roblox` created as canonical repository.
- [x] `main` is canonical development branch.
- [x] VM working tree established at `/opt/roblox/game`.
- [x] Rojo project file established.
- [x] Headless `.rbxlx` build works on ARM64 VM.
- [x] Rokit installed and project tool versions pinned.
- [x] Rojo 7.7.0 pinned/verified.
- [x] StyLua installed/verified.
- [x] Lune installed/verified.
- [x] Native ARM64 Wally built/verified.
- [x] Native ARM64 Selene built/verified.
- [x] `check.sh` format/lint/test/build gate.
- [x] `build.sh` build-only command.
- [x] Windows repo clone/opened in VS Code.
- [x] Rojo VS Code/Studio workflow connected successfully.
- [x] Rojo-synced source visible in Studio Explorer.
- [ ] Standardize the Windows machine fully on Rokit and remove local stray Aftman configuration if still present.
- [ ] Add CI equivalent of `check.sh` when useful.
- [ ] Define release/tagging strategy for playable builds.

## 2. Architecture / authority model

- [x] Separate `client`, `server`, and `shared` source trees.
- [x] Server-authoritative progression rule documented.
- [x] Client cannot award itself EXP/currency/damage.
- [x] Shared network-name configuration.
- [x] Server bootstrap creates/owns remotes.
- [x] Client-safe profile snapshot layer.
- [x] Remote rate-limiter service foundation.
- [x] Centralized allowlisted/rate-limited `GameAction` router for safe gameplay mutations.
- [x] Audit logging foundation; richer structured production logging remains a later operations task.
- [x] Service dependencies are explicit module requires; automated cycle detection now gates builds.

## 3. Player data / persistence

- [x] Default profile schema.
- [x] Schema version field.
- [x] Schema reconciliation on load.
- [x] Roblox DataStore persistence foundation.
- [x] Retry/backoff logic with exponential delay and bounded attempts.
- [x] Cross-server session locking with stale-lock claim rules and strict save-time ownership checks.
- [x] Session-lock timeout/recovery behavior.
- [x] 60-second autosave/session-heartbeat loop with per-player save serialization and revision tracking.
- [x] PlayerRemoving/final saves are serialized against autosaves; shutdown saves run in parallel with a bounded 24-second wait window.
- [x] Save on player leaving.
- [x] BindToClose release/save handling.
- [x] Studio persistence can remain disabled for safe local iteration.
- [x] Versioned schema migration/reconciliation framework (`ProfileSchema`, schema v2).
- [ ] Backup/restore/admin recovery workflow.
- [ ] Live DataStore failure/budget/throttle simulation tests; pure save/lock ownership regressions are implemented.
- [ ] Multi-server/rejoin session-lock stress tests; pure stale/fresh/foreign lock rules are regression-tested.

## 4. Character progression

- [x] Level field and level-cap foundation (200).
- [x] EXP field.
- [x] Prototype EXP-to-next-level math.
- [x] Server-only EXP grants.
- [x] +5 AP per level.
- [x] +3 SP per level after first advancement.
- [x] Advancement tier field.
- [x] Advancement gates for first tier at 8/10 and later tiers 30/70/120.
- [x] Headless progression-math tests.
- [ ] Tune/finalize EXP curve for levels 1–30. Lumenreach 1–10 route now has a regression-tested no-grind baseline; Brasshaven 10–30 remains.
- [ ] Define death EXP behavior, if any.
- [x] Level-up toast presentation/feedback foundation.
- [x] First-advancement presentation/quest flow implemented; Studio end-to-end QA remains.

## 5. Core stats / resources

- [x] Might.
- [x] Finesse.
- [x] Insight.
- [x] Fortune.
- [x] Server-validated AP allocation service.
- [x] Derived-stat math module.
- [x] Prototype MaxHP formula.
- [x] Prototype MaxMP formula.
- [x] Runtime MP/resource state foundation.
- [x] Character stat reconciliation on profile changes/spawn.
- [x] Derived-stat headless tests.
- [ ] **PARTIAL:** Core HP/MP, Defense, and Critical scaling are source-complete and tested; broader 1–30 balance tuning still remains.
- [x] Defense and Critical rules implemented; hidden accuracy/miss RNG and passive evasion were consciously rejected in favor of active dodge, positioning, telegraphs, and monster dodge.
- [x] Out-of-combat HP/MP regeneration rules implemented with tested shared recovery math and combat-delay gating.
- [x] HP/MP resources are represented in the canonical React HUD and replicated snapshots.

## 6. Classes / advancements

- [x] Generic family/tier architecture avoids hardcoding unfinished class names.
- [x] Advancement eligibility service foundation.
- [x] First families finalized: Ironbloom, Thornrunner, Lumenweaver, Veilstrider, Brasshand.
- [x] Level gates locked: Ironbloom/Thornrunner/Veilstrider at 8; Lumenweaver/Brasshand at 10.
- [x] Primary stat/role identities defined for all five first families; deeper secondary-stat scaling remains for later tuning.
- [x] First-family starter weapons defined and granted: Rootsteel Bastion Blade, Briarstring Fieldbow, Prismatic Lumen Focus, Veilglass Twin Knives, and Rivethead Forge Maul.
- [x] Equipped weapon presentation is server-replicated with distinct blade, bow, focus, twin-knife, and maul silhouettes; Studio pose/alignment QA remains.
- [x] First advancement requires The Five Paths trial: Wayfarer Proving Circle + Gravebone Captain, after Mosswarden progression.
- [x] First advancement implemented with server validation, permanent family binding, +3 starting SP, starter skill grant/hotbar assignment, family-aware basic attacks, and starter-weapon delivery.
- [x] First families now have distinct basic-attack profiles: ranged Thornrunner/Lumenweaver, fast Veilstrider cadence, heavy Ironbloom/Brasshand melee, with matching client presentation.
- [x] Equipment family/tier/level restrictions are validated server-side.
- [x] Level-30 second advancement implemented: Mara in the Belforge antechamber promotes each existing family to a deterministic Tier-2 title, grants its Tier-2 technique/+3 SP, and rejects respec/cross-family/repeat attempts server-side.
- [ ] Implement level-70 advancements.
- [ ] Implement level-120 advancements.

## 7. Movement / 3D traversal

- [x] Original 2.5D controller prototype retired after 3D pivot.
- [x] Full 3D camera-relative movement controller foundation.
- [x] Full camera-relative WASD movement works in Studio.
- [x] Crouch toggle implemented with server-authoritative stance state and crouch speed; Studio visual/clearance tuning remains.
- [x] Jumping works in Studio.
- [x] Free 3D forward/back/strafe movement is active; old depth-plane behavior is retired.
- [x] Server movement sanity enforces speed plus horizontal/vertical displacement limits with teleport grace.
- [x] Third-person orbit camera foundation with collision.
- [x] First real Studio movement playtest completed.
- [ ] Tune camera distance/framing/responsiveness.
- [ ] Tune walk speed/acceleration/deceleration.
- [ ] Lock character facing left/right.
- [ ] Proper idle/walk/jump/fall/land animation states.
- [ ] Ladders/ropes/climb system if retained.
- [ ] Drop-through platforms if retained.
- [ ] Moving-platform support if needed.
- [ ] Edge/ledge/collision polish.
- [x] Server horizontal speed plus horizontal/vertical displacement sanity checks with explicit teleport grace.

## 8. Combat — player attack

- [x] Thornrunner/Lumenweaver basic attacks use server-simulated projectile travel with per-frame sphere/segment casts, terrain blocking, miss/target-loss outcomes, and presentation-only client projectiles; Studio feel/timing QA remains.

### Backend
- [x] Basic-attack client controller exists.
- [x] Basic-attack remote exists.
- [x] Server-authoritative attack validation.
- [x] Cooldown validation.
- [x] Remote rate limiting.
- [x] Range validation.
- [x] Full 3D range/facing/line-of-sight validation.
- [x] Might-based damage foundation.
- [x] Mastery/variance damage roll.
- [x] Pure damage-math headless tests.

### Player-facing attack loop
- [x] Left-click / R2 basic attack verified end-to-end in Studio.
- [ ] Rig-aware player basic-attack pose layer is source-complete for default, Ironbloom, Thornrunner, Lumenweaver, Veilstrider, and Brasshand; live Studio visual verification is pending after replacing the ineffective old joint tween.
- [x] Procedural basic-attack animation foundation now drives R6/R15 shoulders, R15 elbows, and torso through a post-animation additive pose layer.
- [x] Basic attacks and active skills now share a camera-facing attack lock: facing is applied immediately, held through the cast/attack pose, and safely overridden by dodge/stagger; live Studio visual QA remains.
- [x] Player melee basics and active melee skills use server-owned overlap hitboxes with range/arc/LOS validation; enemy hurtbox/attack standardization remains.
- [x] Projectile basics are server-simulated over travel time; terrain can block shots and moving targets can evade the fired line.
- [x] Confirmed basics and skills provide client hit confirmation plus family-specific impact presentation; critical hits are called out separately.
- [x] Server-owned monster floating damage numbers are emitted for confirmed hits, including critical formatting.
- [x] Server-owned monster hit-confirm sound plays at the struck enemy with spatial rolloff.
- [x] Server hit burst/highlight plus family-specific client slash/burst impact VFX are wired to confirmed hits.
- [x] Confirmed hits now trigger a short local camera/FOV impact impulse scaled by family/critical weight without freezing authoritative server simulation; Studio intensity tuning remains.
- [x] Player basic attacks and damaging skills now apply server-owned monster knockback/launch/stagger data with normal/elite/boss resistance tiers and per-monster override support; Studio feel tuning remains.
- [x] Basic attacks and active skills surface no-target/out-of-range/projectile-blocked/missed/target-lost/timeout/cancelled feedback with local spam suppression.
- [x] Equipped WeaponType now authoritatively controls basic-attack melee/projectile geometry, projectile properties, cadence modifier, and reaction profile while family stats/mastery remain class-specific; client presentation uses the same shared profile.
- [x] Server-owned basic-attack cadence now scales from capped AttackSpeed equipment/passive bonuses with a hard cooldown floor; effective AttackSpeed is exposed in snapshots/UI and regression-tested.

## 9. Skills

- [x] Skill-definition schema foundation.
- [x] Skill learning/cooldown/MP foundation plus generic targeting/effect execution; player-facing skill flow still pending.
- [x] SP spending/validation foundation.
- [x] Skill rank/max-rank architecture.
- [x] Skill prerequisites are server-enforced through shared progression rules; prerequisite targets/ranks and cycles are regression-validated.
- [x] Active-skill framework and current family/Tier-2 active roster are implemented with SP ranks, MP costs, cooldowns, server effects, and hotbar use; broader roster expansion remains content work.
- [x] Active damage skills use the same authoritative combat geometry as basic attacks: melee overlap volumes or server-simulated projectiles with committed miss/block outcomes and presentation-only client VFX.
- [x] Passive-skill framework is implemented with Steady Footing plus five Tier-1 family passives feeding real HP/MP/Defense/Crit/Attack derived stats.
- [x] Runtime status-effect framework foundation.
- [x] Skill MP/resource-cost validation foundation.
- [x] Server skill cooldown foundation.
- [x] Active-skill targeting shapes/ranges are server-owned and explicit: projectile single-target, forward cone/box, and radial AoE with validated target caps/LOS; current melee roster uses multi-target shapes while projectile skills remain physically simulated single-target shots; Studio tuning remains.
- [x] Skill animation/VFX/SFX hooks are data-driven per active skill: animation style/speed, cast pulse, projectile kind, impact style/weight, and cast/impact sound cues feed client-only presentation while server hit authority stays unchanged; final original production VFX/SFX library remains open.
- [x] Persistent 8-slot skill hotbar data/service foundation with React hotbar shell, full slot-select/assign/move/clear UX, MP-cost display, low-MP state, and cooldown countdown feedback.
- [x] Keyboard and controller hotbar 1–8 skill-use bindings are source-complete; slot 1 Beginner Strike remains Studio-verified.
- [x] Skill tree UI is source-complete with Wayfarer/Foundation + family lanes, real prerequisite connectors, learned/learnable/locked node states, SP/MP/cooldown metadata, and exact unlock requirements; Studio visual QA remains.

## 10. Enemies

- [x] Enemy definition/config table foundation with editable HP, damage, speed, ranges, cooldowns, dodge, leash, and respawn stats.
- [x] Enemy registration/tagging, Humanoid HP setup, target validation, damage contribution tracking, death callback, rewards, and respawn foundation.
- [x] Runtime `ServerStorage/Monsters` templates generated for current monster families.
- [x] Training Dummy, Lumen Mossling, Gravebone Skeleton, Glowcap Slime, and Suncrest Ridgebeak implemented.
- [x] New Lumenreach families implemented: Brambleback and Lumen Wisp.
- [x] Elite variants implemented: Gravebone Captain and Royal Glowcap.
- [x] First field boss implemented: Mosswarden, Root of the Old Grove.
- [x] Idle/pursue/attack/hit/dodge/death AI state integration.
- [x] Range-based nearest-player aggro acquisition.
- [x] Aggro leash/reset and return-to-home behavior.
- [x] Full XYZ pursuit with PathfindingService navigation foundation.
- [x] Enemy attack windup/impact timing and attack cooldowns.
- [x] Enemy-to-player damage path integrated.
- [x] Monster dodge chance/cooldown/invulnerability/backstep behavior.
- [x] Authored code-driven keyframe clips for starter monster idle/walk/attack/hit/dodge/death states.
- [x] Ground-spawn wave system with underground emergence, dust/debris, invulnerability, stagger, and trigger-state machine.
- [x] Spawn trigger states: Idle → Triggered → Spawning → Active → Cooldown.
- [x] Wave cooldown requires players to leave and re-enter before retriggering.
- [x] Spawn regions placed for the current Lumenreach roster plus Brasshaven Rivet Scuttlers, Slagmites, Gearjaw Hounds, Cindercoils, Pressure Bastion, Furnace Husks, Arc Siphons, Railbreaker, Blueflame Sentries, Foundry Reavers, and Smelter Golem.
- [x] Production combat geometry/reaction foundation is standardized: player melee/skills and monster swings use server-owned hit volumes, while enemy knockback/stagger is resolved through normal/elite/boss resistance tiers; Studio tuning remains.
- [ ] Studio tune pathfinding, spawn density, anti-farm timing, and multiplayer target behavior.
- [ ] Replace any remaining simple/procedural monster visuals that fail the final art-quality bar.

## 11. Player damage / death

- [x] Deterministic Defense/damage-taken calculation with diminishing returns and minimum positive-hit floor.
- [x] Enemy-to-player validated damage path.
- [x] Prototype 0.15s player damage i-frame exists; tuning remains.
- [x] Monster/boss hits apply player knockback, launch, and short stagger with movement-sanity grace; Studio tuning remains.
- [x] Death state and timed respawn loop Studio-verified.
- [x] Safe-spawn respawn flow + death overlay Studio-verified; presentation polish remains.
- [x] Region-aware safe respawn is assigned server-side for Lumenreach and Brasshaven, including portal/rejoin synchronization.
- [ ] Death penalties decision.
- [x] React death overlay is Studio-verified; incoming hit feedback now shows HP loss, Defense mitigation, source, heavy-hit edge flash, and strong-stagger emphasis.

## 12. Rewards / currencies / loot

- [x] Server-only reward service foundation.
- [x] Shards ledger.
- [x] Marks ledger.
- [x] Add/spend/can-afford currency operations.
- [x] Enemy rewards can grant EXP/currency.
- [x] Quest rewards can grant EXP, currencies, items, and region unlocks.
- [x] Item drop definitions for current Lumenreach monsters.
- [x] Drop chance/min/max quantity rules.
- [x] Winner-owned visible loot drops.
- [x] Pickup prompts, inventory validation, quest Collect progress, and timed cleanup.
- [x] Loot presentation uses labeled glowing world orbs with type-based visual colors.
- [x] Shards have an active early-game sink path through Lumenreach shops and Brasshaven Foundry Supply; broader late-game economy tuning remains.
- [x] Marks now have a dedicated Belforge exchange with gated equipment rewards; later boss/event sink expansion remains.
- [x] Party/boss loot ownership rules defined: ordinary enemies remain winner-owned; qualifying boss contributors receive individual owner-locked drops and rewards.
- [ ] Rare-drop presentation and loot-notification polish.

## 13. Inventory / equipment / items

- [x] Inventory persistence schema foundation.
- [x] Stackable item architecture with stack limits.
- [x] Non-stackable/equipment item architecture.
- [ ] Unique item IDs where needed.
- [x] Equipment slot architecture.
- [x] Server equip/unequip validation foundation.
- [x] Equipment stat aggregation feeds AttackPower, core stats, Defense, Crit Chance, and Crit Power.
- [x] Level/family/advancement-tier equipment requirements are server-enforced and surfaced in inventory/item UI.
- [x] Weapon types are explicit data (`Blade`, `Bow`, `Focus`, `TwinBlades`, `Maul`) with shared combat profiles, catalog exposure, item-card display, and starter-family consistency validation.
- [x] Armor/accessory taxonomy is explicit and validated: `LightArmor`/`HeavyArmor` for armor slots and `Charm`/`Ring` for accessory slots, with catalog/UI exposure and cross-category misuse tests.
- [x] Consumable architecture with HP/MP restoration foundation.
- [x] Inventory capacity rules are server-enforced through stack/capacity validation and regression-tested.
- [x] Item detail cards/tooltips show item type, stats/effects, sell value, and equipment requirements.
- [x] React inventory UI uses a capacity-aware 6-column grid with occupied/empty cells, quantities, lock states, selection, consumable/equipment actions, and detailed comparison; Studio polish/QA remains.
- [x] React equipment UI shows equipped slots, supports unequip, exposes requirement-aware equip flow, and compares candidate stats against the currently equipped item; Studio polish/QA remains.
- [ ] Safe deletion/drop behavior.

## 14. NPC / interaction / quests

- [x] Generic registered world-object interaction framework for NPCs/portals.
- [x] NPC-definition registry foundation.
- [x] NPC interaction range/server validation on interaction start.
- [x] React NPC dialogue system foundation.
- [x] Progression-aware NPC dialogue text and visible quest offers.
- [x] Quest-definition registry foundation.
- [x] Active/completed quest persistence foundation.
- [x] Quest prerequisite validation.
- [x] Defeat-objective progression wired to enemy deaths.
- [x] Collect-objective progression wired to loot pickup.
- [x] Explore-objective progression wired to landmark triggers.
- [x] Quest reward pipeline supports EXP/currency/items/region unlocks.
- [x] React objective tracker foundation.
- [x] React dialogue UI with quest/shop actions.
- [x] Lumenreach starter/tutorial quest chain.
- [x] Lumenreach hunting quest chain.
- [x] Lumenreach exploration quest chain including Whisperroot Hollow.
- [x] Mosswarden field-boss quest.
- [x] Brasshaven passage/unlock quest.
- [ ] Talk-objective type if future quest design needs it.
- [x] Quest journal filtering/sorting/presentation is source-complete with Active / Ready / Completed filters, counts, ready-first sorting, level metadata, and full-width objective cards; Studio polish/QA remains.
- [x] Active NPC/shop sessions revalidate the registered world object and live player distance on every quest/shop/advancement mutation; future interaction types must use the same validation path.

## 15. Shops / services

- [x] Shop-definition registry foundation.
- [x] Server-authoritative buy-flow foundation with interaction-session requirement.
- [x] Server-authoritative sell-flow foundation with interaction-session requirement.
- [x] Shop price/currency validation foundation.
- [x] Inventory-space validation foundation.
- [x] Lumen Supply inventory expanded beyond one hardcoded tonic.
- [x] Mossglen Scout Outfitter shop added.
- [x] Wayfarer Archive Exchange shop added.
- [x] Dialogue shop UI can display and purchase multiple configured items.
- [x] Dedicated shop window implemented with item details, quantities, buy/sell tabs, balances, and polished navigation; Studio interaction/balance QA remains.
- [ ] Storage/bank design decision.
- [ ] Enhancement/crafting design decision.

## 16. World — Lumenreach

- [x] World visual bible/concept direction.
- [x] Lumenreach rebuilt into a 900×760 full 3D first region.
- [x] Wayfarer Camp spawn/tutorial area rebuilt and populated.
- [x] Lumenwood Crossroads navigation hub.
- [x] Shattered Lumen Arch destination/ruins.
- [x] Mossglen Combat Grove encounter zone.
- [x] Veilfall Cascade waterfall/wetland destination.
- [x] Glowmere Pool bridge/wetland destination.
- [x] Sunmoss Overlook northern loop destination.
- [x] Connected trail network and route beacons/waystones.
- [x] Forest-density and roadside environmental dressing pass.
- [x] Region topology rebuilt around distinct macro geography: compact west-basin Camp, separate Proving Circle pocket, climbing approach to raised Crossroads, central gorge/river, bridge transition to east-side Ruins/Mossglen, north Glowmere loop, lowered Veilfall route, and ascending Sunmoss highland loop; Studio visual QA remains.
- [x] Interior terrain massing rebuilt around seven authored rooms with interior ridges/valleys instead of border hills; roads are re-cut as safe passes after terrain generation, and non-tree habitat pockets/rock faces now fill the mid-map spaces; Studio visual QA remains.
- [x] Opening-route composition pass rebuilt Camp/Crossroads signs, path lantern scale/placement, clearing edges, terrain banks, and authored woodland framing; the obsolete repeated trail-pebble system was removed; Studio player-height review remains open.
- [x] Approved imported environment assets integrated with runtime sanitization; free script-free Forest Trees `13913287259` can populate sanitized tree variants, while the old visible primitive fallbacks are disabled for production placement.
- [x] Bad oversized cliff/rock placements corrected and terrain-supported.
- [x] Camera obstruction issue from foliage/decor corrected.
- [x] Ilyra, Orin, Tovin, Maela, and Seren use distinct grounded R15 NPC presentations with interaction prompts; final Studio visual QA remains.
- [x] Training dummy and full first-region monster/wave placement.
- [x] Hidden Whisperroot Hollow added with persistent one-time cache reward.
- [x] Wayfarer environmental-story remnants added around the region.
- [x] Major landmark exploration triggers wired into quests.
- [x] Brasshaven portal world object is active and gated by profile region unlock/minimum-level rules.
- [x] First advancement location: Wayfarer Proving Circle with Seren the Pathkeeper and The Five Paths trial.
- [ ] Full player-height collision/asset-placement QA across the entire rebuilt region.
- [ ] Final lighting/atmosphere tuning.
- [ ] Ambient audio/music.
- [ ] Minimap/map UX decision.
- [ ] Performance/streaming/density profiling in Studio.

## 17. World — Brasshaven

- [x] Industrial-fantasy visual direction established in source: basalt/brick/metal, brass trim, heat/arc emissives, smoke, foundry machinery, and distinct district silhouettes.
- [x] Playable procedural graybox/content shell expanded through the full Level 10–30 route; Studio player-height art/collision QA remains.
- [x] Functional Lumenreach connection with transactional travel and saved regional respawn behavior.
- [x] Workspace instance streaming policy is explicit (`64` min / `1024` target, `PauseOutsideLoadedArea`, opportunistic stream-out); Studio memory/streaming budget profiling remains open.
- [x] Foundry roads, service spine, district floors/walls, encounter yards, vents, rails, dynamos, crucibles, flux vaults, runoff channels, and upper-foundry structures implemented.
- [x] Lumenreach return transition plus gated Belforge antechamber/return transition implemented.
- [x] Brasshaven progression NPCs/services implemented: Vale, Tamsin, Rook, Nera, and Cale.
- [x] Level 10–30 Brasshaven monster roster and spawn pockets implemented, including multiple elites.
- [x] Sequential Level 10–30 Brasshaven quest route implemented and regression-tested for level-gate continuity.
- [x] Foundry Supply and Belforge Mark Exchange implemented as Shard/Mark sinks.
- [x] Level-30 progression destination implemented as the Belforge antechamber with inner Colossus seal.
- [ ] Replace/augment procedural Brasshaven props with final original/approved production environment assets and add regional audio/music.

## 18. Boss — Belforge Colossus

- [x] Encounter concept locked around a Level-30 Tier-2 Belforge arena fight.
- [x] Dedicated arena and gated antechamber entry implemented.
- [x] Procedural Colossus model/rig implemented in the authoritative enemy pipeline.
- [x] Boss phase runtime implemented on top of normal enemy AI/combat.
- [x] Telegraph-based Steam Burst and Hammerfall special attacks implemented.
- [x] Floor telegraphs and server-authoritative AoE damage/knockback implemented.
- [x] Three phases implemented: Pressure Rising, Furnace Breach, Critical Overheat.
- [x] Encounter attempt lifecycle implemented: six-player cap, pull lockout, death/exit elimination, no death-rush re-entry, full-wipe reset, and normal victory cooldown.
- [x] Boss contributor rewards now grant qualifying participants individual reward/quest credit and owner-locked loot.
- [x] Reward/drop path implemented: Colossus Core, Shards, Marks, EXP, Colossus Emblem quest reward.
- [x] Arena death returns players to the Belforge antechamber; leaving Belforge restores Brasshaven respawn; wipe resets do not grant boss rewards.
- [ ] Final VFX/SFX/music pass.
- [ ] Studio balance/playtest pass.

## 19. UI / HUD / UX

- [x] Temporary client profile state store.
- [x] Temporary combat feedback label.
- [x] React Lua + ReactRoblox established as the canonical production UI stack.
- [x] Wally dependency manifest/lockfile + Rojo `ReplicatedStorage.Packages` mapping.
- [x] Custom UI-capture contract releases cursor and suppresses camera/movement/combat while interactive UI is open.
- [x] React production HUD renders HP/MP/EXP/level/currencies/objective/hotbar and persists across respawn in Studio; final responsive/visual polish remains.
- [x] React HP bar verified in Studio; polish/scalability remains.
- [x] React MP bar verified in Studio; polish/scalability remains.
- [x] React EXP bar verified in Studio; polish/scalability remains.
- [x] React level display verified in Studio; polish/scalability remains.
- [x] React currency display verified in Studio; polish/scalability remains.
- [x] Persistent 8-slot skill hotbar data/service foundation with full React slot-select/assign/move/clear editor, MP-cost/low-MP state, and live cooldown countdown feedback.
- [x] Live buff/debuff strip is wired to server status snapshots with local duration countdown, buff/debuff visual tone, status metadata validation, respawn clearing, and incoming stagger represented as a real timed debuff; Studio visual QA remains.
- [x] React character/stat menu supports server-authoritative AP allocation and now surfaces Max HP/MP, Defense, Crit Chance, and Crit Damage; polish remains.
- [x] React inventory/equipment menu exposes a 48-capacity visual grid, use/equip/unequip actions, level/tier/family lock states, and candidate-vs-equipped stat deltas; Studio polish/QA remains.
- [ ] **PARTIAL:** React quest menu shell is source-complete; further filtering/polish pending.
- [x] React NPC dialogue with clickable quest/shop actions verified in Studio; visual polish remains.
- [x] Dedicated React buy/sell shop screen is implemented beyond dialogue preview actions, with item selection, quantity controls, prices, balances, and server-authoritative transactions; Studio interaction/balance QA remains.
- [x] Field-boss HUD implemented for nearby catalogued bosses with name, recommended level, HP, and percentage.
- [x] Toast/notification framework is live for world denials, party events, level-up/rewards/quests, shop outcomes, and skill-use failures; final visual/timing polish remains.
- [x] React settings controls mutate music/SFX/damage-number preferences server-side; menu action shell is Studio-verified, visual polish remains.
- [ ] Responsive layout live testing remains: source-level UIScale support is implemented, but desktop/landscape-mobile viewport QA is still required.

## 20. Art / animation / audio

- [ ] Original EverLeaf Roblox visual style bible finalized.
- [ ] Player character animation set.
- [ ] Weapon animation sets.
- [x] **PARTIAL:** Starter/current monster families have authored code-driven idle/walk/attack/hit/dodge/death clips; production animation polish and future families remain.
- [x] **PARTIAL:** Monster hit/death VFX/SFX language exists with per-family color/debris differences; full production effects library remains.
- [ ] Boss-specific production animation set beyond the shared Mosswarden quadruped rig.
- [ ] Environment VFX production pass.
- [ ] UI iconography.
- [ ] Original SFX library.
- [ ] Original music direction/tracks.
- [ ] Replace every remaining prototype/placeholder asset before release.

## 21. Social / multiplayer

- [x] Runtime party-state foundation (create/add/leave/leader handoff).
- [x] Production party UI implemented: incoming invites, create/accept/decline/invite/kick/leave controls, live member roster, leader state, and compact live-HP party HUD.
- [x] Shared/individual combat reward rules: normal/elites use contribution-qualified, damage-weighted EXP/currency sharing with exact pool conservation and top-contributor loot ownership; bosses retain threshold-qualified full personal rewards and personal loot rolls; AFK/no-contribution party leeching is not rewarded.
- [x] Generic same-server party-instance travel foundation: data-driven entry/destination/return spawns, min/max roster rules, assembly radius, ready-check timing, concurrent destination prefetch, group move, and rollback-on-partial-failure; Belforge is the first consumer. Cross-server reserved-place teleporting remains future expansion if needed.
- [ ] Trading design decision.
- [ ] Secure trading if approved.
- [x] Same-server social/profile inspection is server-curated and available from the party roster, exposing identity, level/family/tier, combat summary, equipped gear, equipped cosmetics, recognition, and achievement count while keeping inventory contents, currencies, quests, settings, secrets, and entitlement internals private.
- [x] Achievement persistence/service foundation, Roblox badge awarding, join-time repair, Level 10/First Victory hooks, and entitlement-aware player title/nameplate presentation implemented.
- [x] Multiplayer boss source rules implemented: six-player cap, pull lockout, participant elimination, wipe reset, contributor thresholds, individual boss rewards, and no death-rush re-entry; live multi-client QA remains.
- [x] Belforge party ready-check implemented: leader-initiated at the physical seal, all members assembled/eligible, per-member confirmation, roster lock, expiry/cancel handling, and all-ready group teleport.

## 22. Monetization

- [x] Cosmetic-only monetization rule documented.
- [x] No Robux power purchases rule documented.
- [x] Live Creator Hub IDs centralized for the Founder pass, support developer product, membership subscription, and five launch badges; disabled membership now skips client/server subscription API calls until explicitly enabled.
- [x] Founder pass ownership is checked server-side; ownership grants the EverLeaf Founder badge plus permanent Founder title and Founder's Lumen aura cosmetics.
- [x] Repeatable Support EverLeaf developer product uses server-owned `ProcessReceipt` handling with durable purchase-ID idempotency and audit logging.
- [x] Subscription entitlement/status hooks are server-owned; membership sales are now enabled in-game for deliberate Creator Hub activation; first live subscription purchase/rejoin verification remains pending.
- [x] Membership renewal state is replicated to the client, active subscribers can open Roblox's cancellation/renewal-management prompt from the EverLeaf Store, and entitlement refresh requests are server-rate-limited.
- [x] September 2026 membership cosmetic reward path is implemented as a permanent, non-power Lumen Trail collectible and is only granted to an active subscriber.
- [x] Cosmetic catalog design foundation is data-driven, replicated through the public catalog, slot-validated, and entitlement-aware.
- [x] Cosmetic ownership/equip persistence is schema-backed and included in full save→rejoin regression coverage.
- [x] Founder recognition presentation implemented through custom player nameplates, party recognition, and Character-panel title/aura toggles.
- [x] General cosmetic collection/equip UX implemented with an owned-cosmetics browser, slot/source metadata, equipped state, and equip/unequip actions.
- [ ] Dedicated live avatar preview/try-on UX beyond equipping the cosmetic on the player character.
- [ ] Emotes if desired.
- [x] Initial cosmetic effects implemented: Founder's Lumen aura and Founding Month member Lumen Trail.
- [x] Roblox purchase receipt validation/idempotency implemented for the live developer product.
- [x] Current paid offerings do not grant combat stats, progression, currencies, drop-rate advantages, advancement, or stronger equipment.
- [x] In-game EverLeaf Store uses Roblox product/subscription metadata for displayed prices rather than hard-coded regional prices.
- [ ] Creator Hub cleanup before public release: rename `Support EverLeaf – 50` and replace any icon text that hard-codes `50 Robux`, because Managed Pricing can show a lower regional price.
- [x] Paid-item gifting/trading remain disabled; regional Price Level validation groundwork exists before either feature can ever be enabled.

## 23. Security / anti-exploit

- [x] Server owns progression mutations.
- [x] Server owns currency mutations.
- [x] Server owns combat damage calculation.
- [x] Server validates basic attack target/range/vertical tolerance/facing/LOS/cooldown.
- [x] Rate limiter foundation.
- [x] Data session locks.
- [x] Atomic profile-mutation helper now protects reward grants, shop buy/sell, equipment swaps, and crafting from partial-success item/currency/profile corruption.
- [x] Consumables remove the owned item before applying HP/MP effects, preventing free-effect failures.
- [x] NPC/shop interaction sessions fail closed on expiry, ID mismatch, stale world objects, and out-of-range actions.
- [x] Current remote/action surface audited: `GameAction` now enforces strict per-action field allowlists, required/optional types, integer/range/string bounds, settings value contracts, and finite cosmetic slots before downstream state validation; repeat this audit for every future remote.
- [x] Removed the unused legacy `AllocateStat` RemoteFunction so AP mutations have one authoritative `GameAction` path; remaining direct no-argument remotes reject extra args and `MovementIntent` rejects unexpected fields.
- [x] Movement speed and displacement/teleport sanity checks foundation.
- [x] Inventory/equipment dupe invariant tests cover capacity/stack failures, over-removal, equip swap conservation, full-inventory unequip rollback, thrown transaction rollback, and deterministic add/remove fuzzing.
- [x] Currency/economy abuse regressions cover finite integer balances, overflow caps, corrupted-balance fail-closed behavior, overspend rejection, same-currency shop no-arbitrage, and repeated buy/sell sink conservation.
- [x] Quest/reward replay abuse regressions cover atomic reward+completion turn-in, failed-reward rollback, completed-quest replay rejection, and one-time Whisperroot claim conservation.
- [ ] Trading dupe/rollback tests if trading exists.
- [ ] Client tampering tests.
- [ ] Multi-client exploit test plan.

## 24. Testing / QA

- [x] Headless math test harness with Lune.
- [x] StyLua formatting gate.
- [x] Selene lint gate.
- [x] Rojo headless build gate.
- [x] First Studio Rojo sync test.
- [x] First movement/jump Studio test.
- [x] Left-click basic attack/server damage path is Studio-verified; the replacement rig-aware visible player attack animation is source-complete and still needs fresh Studio visual verification.
- [x] Added pure regression coverage for quest lifecycle, rewards, inventory/equipment rules, skills, payload bounds, profile migration, movement sanity, Defense mitigation, Critical math/caps, combat-stat UI labels, atomic profile transactions, interaction-session validation, and cross-content reference integrity.
- [x] Added progression regression coverage for Lumenreach story → Level 8 advancement and post-trial bridge → Level 10.
- [x] Production retry/backoff policy is shared and deterministically fault-injected in tests: transient throttles recover, exhaustion returns the terminal error, exponential delays are verified, and no terminal sleep occurs.
- [x] Pure two-server session-lock handoff simulation covers fresh-lock blocking, stale takeover, old-owner save rejection, and post-takeover anti-steal behavior; live multi-server stress remains open.
- [x] Save revision simulation verifies mutations arriving during an in-flight snapshot remain dirty until a later successful save.
- [ ] Add 2+ client Studio test scenarios.
- [ ] Controller-only test pass.
- [ ] Network-latency test pass.
- [ ] Respawn/rejoin soak.
- [ ] Long-session soak.
- [ ] Performance profiling.
- [ ] Memory/listener leak checks.
- [ ] 1280×720 / common desktop / landscape-mobile viewport UX checks; responsive UIScale source support is implemented but not yet live-verified across target sizes.

## 25. Roblox experience / deployment

- [ ] Create/finalize the Roblox experience identity/name.
- [ ] Create/finalize Universe/Place IDs.
- [ ] Configure private development place(s).
- [ ] Open Cloud publishing credentials/workflow if desired.
- [x] VM auto-publish policy: disabled/fail-closed; publishing requires an explicit validated release workflow.
- [x] Build/protocol/content metadata foundation (`BuildInfo`, `ReleaseService`).
- [x] Development → staging → production environment boundary documented; actual Place IDs still pending.
- [ ] Private alpha access setup.
- [ ] Closed beta gate.
- [ ] Public launch checklist.
- [ ] Rollback procedure.

## 26. Documentation / project management

- [x] `GAME_DESIGN.md` canonical design foundation.
- [x] `TOOLCHAIN.md` development environment documentation.
- [x] `ROADMAP.md` canonical phased roadmap.
- [x] `MASTER_CHECKLIST.md` canonical detailed checklist.
- [x] `ARCHITECTURE.md` canonical system-boundary documentation.
- [x] `DEPLOYMENT.md` environment/release architecture.
- [ ] Keep roadmap/checklist updated whenever a milestone lands.
- [ ] Record major design decisions so implementation does not drift.
- [ ] Add contributor workflow if/when more developers join.
- [x] Ignored timestamp backup clutter removed from the working tree; source-of-truth changes now live in Git history instead of local `.bak.*` files.

---

# Current highest-priority queue — Phase 1 closure / QA

1. [ ] Full in-Studio walk-through of the rebuilt Lumenreach from player height; fix floating, buried, oversized, incomplete, or obstructive assets.
2. [ ] Exercise every monster wave/elite/boss trigger in Studio, including emergence height, pathfinding, attack timing, dodge, leash, death, cooldown, and leave/re-enter behavior.
3. [ ] Complete a fresh-profile Studio run from Lumenreach spawn through first advancement, Brasshaven Level 10–30 progression, Sentinel turn-in, and Belforge antechamber without developer intervention.
4. [ ] Verify visible loot pickup, Collect objectives, equipment rewards, Lumenreach + Brasshaven shops, Whisperroot cache, and regional/Belforge travel across death/rejoin.
5. [ ] Multiplayer smoke test: target selection, damage ownership, loot ownership, simultaneous trigger activation, and party/network behavior.
6. [x] Dedicated shop UX, item detail cards, reward/quest/level-up notifications, and field-boss HUD implemented; complete Studio UX QA remains.
7. [x] Five first families, Seren the Pathkeeper, Wayfarer Proving Circle, The Five Paths trial, permanent family selection, and starter-skill grants implemented; Studio UX/progression QA remains.
8. [ ] Source-authored Level 1–30 pacing and Shard/Mark sinks are regression-tested; perform Studio tuning for monster stats, spawn density, drop rates, time-to-kill, currency flow, and elite rewards.
9. [ ] Performance profile the dense Lumenreach build for frame time, memory, streaming, and listener leaks.
10. [ ] Complete keyboard/mouse + controller blocking-flow QA and the full no-red-Output Phase 1 run.

# Definition of the first meaningful playable milestone

Do **not** call M1 complete until a fresh player can enter Studio and, without debug knowledge:

- move, sprint, jump, and dodge naturally in the 3D world,
- understand the camera,
- visibly perform a basic attack,
- hit and kill a hostile enemy,
- see damage/reward feedback,
- take damage,
- die and respawn,
- and complete that loop without red runtime errors.
