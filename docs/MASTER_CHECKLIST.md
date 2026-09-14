# EverLeaf Roblox — Master Checklist

**Canonical status:** 2026-09-14
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
- [ ] Floating damage numbers.
- [ ] Hit confirm VFX/SFX and stronger impact presentation.
- [ ] Enemy attack windup/telegraph.
- [ ] Aggro leash/reset.
- [ ] Production obstacle-aware navigation/pathfinding.
- [ ] Knockback/stagger rules for player/enemies where appropriate.
- [ ] Reward/loot presentation after kill.

### C. Lumenreach environment production pass

- [x] Terrain/grass baseline is visually acceptable enough to keep iterating.
- [x] Poly Haven PBR material pipeline is live for forest ground, mossy rock, moss wood, wood-chip path, and wood/stone pathway.
- [ ] **BLOCKER:** Replace current Creator Store tree prefab (`580221169`); it still produces fallen/visually poor trees and is not acceptable for Phase 1.
- [ ] Import/author a new upright production tree/foliage set with correct pivots, collisions, scale, and script-free sanitization.
- [ ] Replace placeholder/fake logs and stumps with production assets/materials.
- [ ] Upgrade rocks and rock clusters with production meshes/PBR.
- [ ] Upgrade ruins and camp props; remove obvious wedge/graybox shapes.
- [ ] Improve shrubs/flowers/ground clutter without blocking navigation.
- [ ] Strengthen camp, combat-grove, arch, and waterfall landmark readability.
- [ ] Final lighting/sky/atmosphere pass for Phase 1.
- [ ] Measure frame time, memory, streaming, and foliage-density budgets in Studio.

### D. UI / RPG shell

- [x] React HUD: HP, MP, EXP, level, currencies, objective tracker, and hotbar.
- [x] React HUD survives death/respawn.
- [x] Character AP allocation action is wired.
- [x] Inventory use/equip/unequip actions are wired.
- [x] Skill rank/assign/use actions are wired.
- [x] Quest menu shell exists.
- [x] Settings mutations are wired.
- [ ] Responsive layout pass for common desktop resolutions.
- [ ] Controller navigation/focus pass.
- [ ] Dedicated shop screen.
- [ ] Item/equipment tooltips.
- [ ] Notifications/toasts for rewards, quest updates, errors, and level-up.
- [ ] Split monolithic `ReactUIController` into maintainable components after Phase 1 behavior is locked.

### E. RPG/content closure

- [x] Guide → Mossling quest route exists and explicit turn-in works.
- [x] Consumable architecture and server-side use path exist.
- [x] Inventory/equipment persistence foundations exist.
- [ ] Add first visible starter loot drops/pickups.
- [ ] Add first starter equipment/reward path.
- [ ] Finish shop UI and one complete buy/use loop.
- [ ] Add level-up feedback and tune level 1–30 early EXP curve.
- [ ] First advancement hook/location/quest shell.
- [ ] Unseal/implement the Lumenreach → Brasshaven transition shell at the appropriate progression gate.
- [ ] Belforge boss-entry shell only to the extent required for Phase 1 progression continuity.

### F. Phase 1 exit validation

- [ ] Fresh player can complete the full starter loop with no manual developer intervention.
- [ ] Death and respawn do not break UI, controls, quest progress, resources, or hotbar state.
- [ ] Rejoin preserves expected profile/inventory/equipment/quest state.
- [ ] Keyboard/mouse full pass.
- [ ] Gamepad/controller blocking-flow pass.
- [ ] Multi-client basic party/network smoke test.
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
- [x] Equipment stat bonuses feed combat damage.
- [x] Physical world-object registry + proximity validation for NPCs/portals.
- [x] Enemy AI state-machine + enemy-to-player damage architecture.
- [x] Generic skill targeting/effect execution architecture.
- [x] Generic boss state-machine interface.
- [x] Crafting/enhancement/storage hooks.
- [x] Party invite/accept/kick protocol.
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
- [ ] Production enemy pathfinding/navigation.
- [x] Lumenreach 3D benchmark graybox generated from canonical source.
- [ ] **PARTIAL:** Asset import/optimization pipeline includes sanitized Creator Store prefab intake and working Poly Haven PBR material authoring; production foliage/model ingestion remains incomplete.
- [x] Poly Haven/approved Sketchfab material/model source policy documented.
- [x] Poly Haven 1K PBR source set downloaded, hash-manifested, uploaded to Roblox (15/15 approved), wired to generated asset IDs, and Studio MaterialVariants verified.
- [x] Source-controlled wind/ambient-motion foundation integrated; production foliage assets and performance tuning remain.
- [ ] Streaming/performance budgets measured in Studio.
- [ ] First production-quality environment benchmark scene.

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
- [ ] Tune/finalize EXP curve for levels 1–30.
- [ ] Define death EXP behavior, if any.
- [ ] Add level-up presentation/feedback.
- [ ] Add advancement presentation/quest flow.

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
- [ ] Finalize all stat effects and scaling curves.
- [ ] Define defense/accuracy/evasion/crit or consciously reject them.
- [ ] Add HP/MP regeneration rules.
- [ ] Add resource UI.

## 6. Classes / advancements

- [x] Generic family/tier architecture avoids hardcoding unfinished class names.
- [x] Advancement eligibility service foundation.
- [ ] **DECISION:** finalize original first-advancement class-family names.
- [ ] **DECISION:** determine which families advance at level 8 vs 10.
- [ ] Define each family’s primary/secondary stat identity.
- [ ] Define starting weapons/equipment identities.
- [ ] Define first advancement requirements/quests.
- [ ] Implement first advancement.
- [ ] Implement level-30 advancements.
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
- [x] Depth-plane validation.
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
- [x] Persistent 8-slot skill hotbar data/service foundation with React hotbar shell; binding/use UX remains pending.
- [ ] **PARTIAL:** Keyboard hotbar 1–8 skill-use bindings are source-complete and slot 1 Beginner Strike is Studio-verified; controller bindings remain pending.
- [ ] Skill tree UI.

## 10. Enemies

- [x] Enemy definition table foundation.
- [x] Enemy registration/tagging.
- [x] Enemy Humanoid HP setup.
- [x] Server target validity checks.
- [x] Damage contribution tracking.
- [x] Death callback.
- [x] Reward handoff on death.
- [x] Respawn callback foundation.
- [x] Studio training dummy prototype.
- [x] Hostile enemy AI foundation (idle/pursue/attack) is integrated; production navigation/telegraphs remain.
- [x] Range-based aggro acquisition foundation.
- [ ] Aggro leash/reset.
- [x] Enemy pursuit converted to full XYZ movement foundation.
- [ ] Production pathfinding/navigation around 3D obstacles.
- [ ] Enemy attack windup/telegraph.
- [x] Enemy-to-player damage path is integrated.
- [x] Enemy attack cooldown foundation.
- [ ] Enemy knockback/stagger resistance.
- [ ] Elite variants.
- [ ] Spawn regions/population management.
- [ ] Anti-farm/respawn tuning where needed.

## 11. Player damage / death

- [ ] Defense/damage-taken calculation.
- [x] Enemy-to-player validated damage path.
- [x] Prototype 0.15s player damage i-frame exists; tuning remains.
- [ ] Knockback on player.
- [x] Death state and timed respawn loop Studio-verified.
- [x] Safe-spawn respawn flow + death overlay Studio-verified; presentation polish remains.
- [x] Lumenreach Wayfarer Camp safe respawn is assigned server-side.
- [ ] Death penalties decision.
- [x] React death overlay appears during the Studio-verified death/respawn flow; damage-feedback polish remains.

## 12. Rewards / currencies / loot

- [x] Server-only reward service foundation.
- [x] Shards ledger.
- [x] Marks ledger.
- [x] Add/spend/can-afford currency operations.
- [x] Enemy reward can grant EXP/currency.
- [ ] Finalize purpose/source/sink for Shards.
- [ ] Finalize purpose/source/sink for Marks.
- [ ] Item drop definitions.
- [ ] Drop chance/quantity rules.
- [ ] Loot ownership rules.
- [ ] Pickup behavior.
- [ ] Party loot behavior.
- [ ] Loot presentation.

## 13. Inventory / equipment / items

- [x] Inventory persistence schema foundation.
- [x] Stackable item architecture with stack limits.
- [x] Non-stackable/equipment item architecture.
- [ ] Unique item IDs where needed.
- [x] Equipment slot architecture.
- [x] Server equip/unequip validation foundation.
- [x] Equipment stat aggregation foundation; AttackPower feeds basic damage.
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

- [ ] Generic interactable framework.
- [x] NPC-definition registry foundation.
- [x] NPC interaction range/server validation on interaction start; action-time distance revalidation still pending.
- [x] React NPC dialogue system foundation.
- [x] Quest-definition registry foundation.
- [x] Active/completed quest persistence foundation.
- [ ] Quest prerequisites.
- [x] Defeat-objective progression foundation wired to enemy deaths.
- [ ] Collect quests.
- [ ] Talk/exploration quests.
- [x] Quest reward pipeline foundation.
- [x] React objective tracker foundation.
- [x] React dialogue UI with quest/shop actions.

## 15. Shops / services

- [x] Shop-definition registry foundation.
- [x] Server-authoritative buy-flow foundation with interaction-session requirement.
- [x] Server-authoritative sell-flow foundation with interaction-session requirement.
- [x] Shop price/currency validation foundation.
- [x] Inventory-space validation foundation.
- [ ] Shop UI.
- [ ] Storage/bank design decision.
- [ ] Enhancement/crafting design decision.

## 16. World — Lumenreach

- [x] World visual bible/concept direction.
- [x] Source-generated 3D benchmark graybox.
- [x] Wayfarer Camp spawn/tutorial area foundation.
- [x] Benchmark field boundaries and traversable ground.
- [x] Placeholder ground/path/pond/ruin composition.
- [ ] Camera obstruction/framing review in finished environment geometry.
- [ ] **PARTIAL:** Brasshaven portal world object placed/registered; transition remains sealed.
- [x] Lumen Guide physical NPC placement + interaction prompt.
- [x] Training dummy + Lumen Mossling spawn placements.
- [x] First quest route: guide → Mossglen combat grove.
- [x] Lumen Guide supply-shop interaction shell.
- [ ] First advancement location.
- [ ] **BLOCKER:** Creator Store tree prefab (`580221169`) sanitizes/loads, but its current orientation/visual result is unacceptable (fallen trees); replace it rather than polishing this prefab further.
- [x] Lighting/atmosphere/post-processing baseline integrated and exercised in Studio; final art-direction tuning remains.
- [ ] Ambient audio/music.
- [ ] Minimap/map UX decision.

## 17. World — Brasshaven

- [ ] Visual direction.
- [ ] Graybox.
- [ ] Lumenreach connection.
- [ ] Platforms/terrain.
- [ ] Portals/transitions.
- [ ] NPCs.
- [ ] Monsters.
- [ ] Quests.
- [ ] Shops/services.
- [ ] Level-30 progression destination.
- [ ] Original environment assets/audio.

## 18. Boss — Belforge Colossus

- [ ] Encounter concept lock.
- [ ] Arena.
- [ ] Boss model/art.
- [ ] Boss state machine.
- [ ] Attack patterns.
- [ ] Telegraphs.
- [ ] Phases.
- [ ] Enrage/failure conditions if used.
- [ ] Party scaling rules if used.
- [ ] Rewards/drop table.
- [ ] Death/respawn/re-entry rules.
- [ ] VFX/SFX/music.
- [ ] Balance/playtest pass.

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
- [x] React character/stat menu supports server-authoritative AP allocation and menu actions are Studio-verified; polish remains.
- [x] React inventory/equipment menu exposes use/equip/unequip actions and the menu action shell is Studio-verified; dedicated UX polish remains.
- [ ] **PARTIAL:** React quest menu shell is source-complete; further filtering/polish pending.
- [x] React NPC dialogue with clickable quest/shop actions verified in Studio; visual polish remains.
- [ ] **PARTIAL:** Shop action is exposed through the React dialogue shell; dedicated shop screen pending.
- [ ] Boss HP UI.
- [ ] Notifications/toasts.
- [x] React settings controls mutate music/SFX/damage-number preferences server-side; menu action shell is Studio-verified, visual polish remains.
- [ ] Responsive layout testing.

## 20. Art / animation / audio

- [ ] Original EverLeaf Roblox visual style bible.
- [ ] Character animation set.
- [ ] Weapon animation sets.
- [ ] Enemy animation sets.
- [ ] Boss animation set.
- [ ] Combat VFX language.
- [ ] Environment VFX.
- [ ] UI iconography.
- [ ] Original SFX library.
- [ ] Original music direction/tracks.
- [ ] Replace every prototype/placeholder asset before release.

## 21. Social / multiplayer

- [x] Runtime party-state foundation (create/add/leave/leader handoff).
- [ ] Party UI.
- [ ] Shared/individual reward rules.
- [ ] Instance/party teleport flow.
- [ ] Trading design decision.
- [ ] Secure trading if approved.
- [ ] Social/profile inspection.
- [x] Achievement persistence/service foundation; titles/presentation pending.
- [ ] Multiplayer boss rules.

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
- [x] Added pure regression coverage for quest lifecycle, rewards, inventory/equipment rules, skills, payload bounds, profile migration, and movement sanity.
- [ ] Add regression tests for progression curves.
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

---

# Current highest-priority queue — Phase B game shell

1. [ ] **PARTIAL:** React HUD shell is Studio-verified; responsive/final visual polish pending.
2. [ ] **PARTIAL:** Character/inventory/equipment/skills/quests/settings React menu interactions are source-complete; verify all screens in Studio.
3. [x] Add physical Lumenreach benchmark graybox + NPC/portal world-object registration.
4. [x] Hostile Lumen Mossling combat/AI/player-damage loop has been exercised in Studio; production navigation/telegraphs remain.
5. [ ] **PARTIAL:** Safe respawn + React death overlay are source-complete; Studio verification/polish pending.
6. [x] Lumen Guide dialogue, quest accept/progress/turn-in, and shop-action shell are Studio-verified; dedicated shop UI/polish remain.
7. [ ] **PARTIAL:** Starter Beginner Strike is learned/assigned to slot 1 and keyboard 1–8 invokes `SkillEffectService`; Studio verification/controller binding pending.
8. [ ] Add party UI/invite flow and a private-instance shell.
9. [ ] Add Belforge boss-entry/encounter shell using the generic state machine.
10. [ ] Make the Lumenreach → Brasshaven route traversable with placeholder content.

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
