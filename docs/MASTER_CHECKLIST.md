# EverLeaf Roblox — Master Checklist

**Canonical status:** 2026-09-14
**Latest gameplay checkpoint:** source-complete Level 1–30 route + Level-30 second advancement — Belforge antechamber, Mara the Forge Oathkeeper, five deterministic Tier-2 family promotions, skills, and secure advancement flow
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
- [ ] Fresh-profile/rejoin regression pass.
- [ ] DataStore failure/session-lock stress pass.

### B. Combat / enemy feel

- [x] Server-authoritative basic attack, range/facing/LOS validation, damage, cooldown, and enemy reward handoff.
- [x] Server-authoritative Beginner Strike with MP/cooldown rollback on failed effect.
- [x] Monster floating damage numbers.
- [x] Monster hit-confirm VFX/SFX and hit-flinch presentation.
- [x] Enemy attack windup with damage applied at the impact moment.
- [x] Aggro leash/reset and return-to-home behavior.
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
- [x] Bad/fallen Creator Store tree dependency replaced with approved original/Poly Haven environment assets and procedural foliage fallbacks.
- [x] Production-oriented trees, ferns, deadwood, rock faces, mossy rock sets, stumps, roots, logs, mushrooms, cattails, and waystones integrated.
- [x] Oversized/unintegrated cliff meshes and black stacked-rock formations corrected and blended into terrain.
- [x] Starter camp rebuilt with larger tents, proper supplies, map table, benches, lanterns, signpost, and custom guide/NPC composition.
- [x] World density pass added continuous forest bands, roadside clusters, undergrowth, deadwood, rocks, and landmark dressing.
- [x] Camera collision stabilized so non-solid foliage/decor no longer causes view snapping.
- [x] Environmental storytelling pass adds old wayfarer remnants and hidden Whisperroot Hollow.
- [ ] Full player-height visual QA for every imported mesh, rock/cliff, root, log, and path obstruction.
- [ ] Final lighting/sky/atmosphere art-direction pass for Phase 1.
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
- [ ] Responsive layout pass for common desktop resolutions.
- [ ] Controller navigation/focus pass.
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
- [x] Dedicated full buy/sell shop screen implemented beyond dialogue preview buttons; Studio interaction/balance QA remains.
- [x] Level-up feedback is implemented and the source-authored Lumenreach 1–10 + Brasshaven 10–30 quest route has no mandatory grind gap in regression tests; Studio combat/economy tuning remains.
- [x] First advancement hook/location/quest flow implemented with Seren, the Proving Circle, The Five Paths, and five permanent family choices.
- [x] Level-30 Belforge approach is functional: Sentinel completion + Level 30 unlocks a safe antechamber/return route, Mara handles second advancement there, and the inner Colossus seal remains closed until the real boss encounter is implemented.

### F. Phase 1 exit validation

- [ ] Fresh player can complete the full starter loop with no manual developer intervention.
- [ ] Death and respawn do not break UI, controls, quest progress, resources, or hotbar state.
- [ ] Rejoin preserves expected profile/inventory/equipment/quest state.
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
- [x] Mouse/right-stick orbit camera foundation with camera collision.
- [x] Sprint foundation (`Shift` / L3).
- [x] Grounded jump foundation (`Space` / A).
- [x] Dodge foundation (`Q` / B).
- [x] Basic attack moved to left-click / R2.
- [x] Server targeting converted from X/Y/Z-plane gates to 3D range + facing cone + LOS.
- [x] Enemy pursuit converted to full XYZ movement.
- [x] Z-plane movement correction removed.
- [x] Modern lighting/atmosphere baseline service.
- [ ] Production hitbox/hurtbox system.
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
- [x] Retry/backoff logic.
- [x] Cross-server session locking.
- [x] Session-lock timeout/recovery behavior.
- [x] Autosave loop.
- [x] Save on player leaving.
- [x] BindToClose release/save handling.
- [x] Studio persistence can remain disabled for safe local iteration.
- [x] Versioned schema migration/reconciliation framework (`ProfileSchema`, schema v2).
- [ ] Backup/restore/admin recovery workflow.
- [ ] DataStore failure simulation tests.
- [ ] Rejoin/session-lock stress tests.

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
- [x] Basic attack produces a visible procedural swing.
- [x] Procedural basic-attack animation foundation.
- [ ] Facing-aware attack direction.
- [ ] Production hitbox/hurtbox implementation.
- [ ] Hit-confirm feedback.
- [ ] Floating damage numbers.
- [ ] Hit sound.
- [ ] Hit VFX.
- [ ] Hit-stop/impact feel.
- [ ] Knockback/stagger.
- [ ] Miss/out-of-range feedback suitable for production.
- [ ] Weapon-specific basic attacks.
- [ ] Attack speed/cadence stat rules.

## 9. Skills

- [x] Skill-definition schema foundation.
- [x] Skill learning/cooldown/MP foundation plus generic targeting/effect execution; player-facing skill flow still pending.
- [x] SP spending/validation foundation.
- [x] Skill rank/max-rank architecture.
- [ ] Skill prerequisites.
- [ ] Active skills.
- [ ] Passive skills.
- [x] Runtime status-effect framework foundation.
- [x] Skill MP/resource-cost validation foundation.
- [x] Server skill cooldown foundation.
- [ ] Targeting shapes/ranges.
- [ ] Skill animation/VFX/SFX hooks.
- [x] Persistent 8-slot skill hotbar data/service foundation with React hotbar shell, full slot-select/assign/move/clear UX, MP-cost display, low-MP state, and cooldown countdown feedback.
- [x] Keyboard and controller hotbar 1–8 skill-use bindings are source-complete; slot 1 Beginner Strike remains Studio-verified.
- [ ] Skill tree UI.

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
- [ ] Production hitbox/hurtbox and enemy knockback/stagger-resistance rules.
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
- [ ] Level/class requirements.
- [ ] Weapon types.
- [ ] Armor/accessory types.
- [x] Consumable architecture with HP/MP restoration foundation.
- [ ] Inventory capacity rules.
- [ ] Item tooltips.
- [ ] Inventory UI.
- [ ] Equipment UI.
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
- [ ] Quest journal filtering/sorting/presentation polish.
- [ ] Action-time NPC distance revalidation audit for every future interaction mutation.

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
- [ ] Dedicated shop window with item details, quantities, buy/sell tabs, and polished navigation.
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
- [x] Approved imported environment assets integrated with runtime sanitization and procedural fallbacks.
- [x] Bad oversized cliff/rock placements corrected and terrain-supported.
- [x] Camera obstruction issue from foliage/decor corrected.
- [x] Custom Ilyra guide model and three additional camp NPCs placed with interaction prompts.
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
- [x] Persistent 8-slot skill hotbar data/service foundation; React hotbar shell implemented.
- [ ] Buff/debuff display.
- [x] React character/stat menu supports server-authoritative AP allocation and now surfaces Max HP/MP, Defense, Crit Chance, and Crit Damage; polish remains.
- [x] React inventory/equipment menu exposes use/equip/unequip actions and the menu action shell is Studio-verified; dedicated UX polish remains.
- [ ] **PARTIAL:** React quest menu shell is source-complete; further filtering/polish pending.
- [x] React NPC dialogue with clickable quest/shop actions verified in Studio; visual polish remains.
- [ ] **PARTIAL:** Shop action is exposed through the React dialogue shell; dedicated shop screen pending.
- [x] Field-boss HUD implemented for nearby catalogued bosses with name, recommended level, HP, and percentage.
- [ ] **PARTIAL:** Toast framework is live for world denials, party events, rewards/quests, and skill-use failures; broader notification coverage/polish remains.
- [x] React settings controls mutate music/SFX/damage-number preferences server-side; menu action shell is Studio-verified, visual polish remains.
- [ ] Responsive layout testing.

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
- [ ] Shared/individual reward rules.
- [ ] Generic instance/party teleport flow; Belforge now has a source-complete party ready-check and synchronized group-entry path.
- [ ] Trading design decision.
- [ ] Secure trading if approved.
- [ ] Social/profile inspection.
- [x] Achievement persistence/service foundation; titles/presentation pending.
- [x] Multiplayer boss source rules implemented: six-player cap, pull lockout, participant elimination, wipe reset, contributor thresholds, individual boss rewards, and no death-rush re-entry; live multi-client QA remains.
- [x] Belforge party ready-check implemented: leader-initiated at the physical seal, all members assembled/eligible, per-member confirmation, roster lock, expiry/cancel handling, and all-ready group teleport.

## 22. Monetization

- [x] Cosmetic-only monetization rule documented.
- [x] No Robux power purchases rule documented.
- [ ] Cosmetic catalog design.
- [ ] Cosmetic ownership/equip persistence.
- [ ] Cosmetic preview UX.
- [ ] Emotes if desired.
- [ ] Cosmetic effects if desired.
- [ ] Roblox purchase receipt validation when monetization is implemented.
- [ ] Ensure no purchasable item changes combat/progression power.

## 23. Security / anti-exploit

- [x] Server owns progression mutations.
- [x] Server owns currency mutations.
- [x] Server owns combat damage calculation.
- [x] Server validates basic attack target/range/vertical tolerance/facing/LOS/cooldown.
- [x] Rate limiter foundation.
- [x] Data session locks.
- [ ] Audit every future remote for type/range/state validation.
- [x] Movement speed and displacement/teleport sanity checks foundation.
- [ ] Inventory/equipment dupe tests.
- [ ] Currency/economy abuse tests.
- [ ] Quest/reward replay abuse tests.
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
- [x] Left-click basic attack verified end-to-end in Studio with server damage and visible swing.
- [x] Added pure regression coverage for quest lifecycle, rewards, inventory/equipment rules, skills, payload bounds, profile migration, movement sanity, Defense mitigation, Critical math/caps, and combat-stat UI labels.
- [x] Added progression regression coverage for Lumenreach story → Level 8 advancement and post-trial bridge → Level 10.
- [ ] Add DataStore/session-lock test scenarios.
- [ ] Add 2+ client Studio test scenarios.
- [ ] Controller-only test pass.
- [ ] Network-latency test pass.
- [ ] Respawn/rejoin soak.
- [ ] Long-session soak.
- [ ] Performance profiling.
- [ ] Memory/listener leak checks.
- [ ] 1280×720 / common desktop viewport UX checks.

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
