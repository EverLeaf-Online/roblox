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
- [ ] Lumenreach 3D graybox.
- [ ] Asset import + optimization pipeline established.
- [ ] Poly Haven/approved Sketchfab material/model source policy documented.
- [ ] Foliage/wind solution audited and integrated.
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
- [x] A/D horizontal movement works in Studio.
- [x] Jumping works in Studio.
- [x] W/S depth input is constrained/recentered by current prototype behavior.
- [x] Server plane/depth sanity service.
- [x] Side-camera controller foundation.
- [x] First real Studio movement playtest completed.
- [ ] Tune camera distance/framing/responsiveness.
- [ ] Tune walk speed/acceleration/deceleration.
- [ ] Lock character facing left/right.
- [ ] Proper idle/walk/jump/fall/land animation states.
- [ ] Ladders/ropes/climb system if retained.
- [ ] Drop-through platforms if retained.
- [ ] Moving-platform support if needed.
- [ ] Edge/ledge/collision polish.
- [ ] Server movement exploit/speed sanity checks beyond depth.

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
- [ ] **PARTIAL:** latest input is bound to `Z`/R2; end-to-end Studio verification still pending.
- [ ] Attack must produce an unmistakable visible action.
- [ ] Attack animation.
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
- [x] Skill service foundation for learning, cooldowns, and MP spend; targeting/effects still pending.
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
- [x] Persistent 8-slot skill hotbar data/service foundation; production UI pending.
- [ ] Keyboard/controller bindings.
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
- [ ] Hostile enemy AI.
- [ ] Aggro acquisition.
- [ ] Aggro leash/reset.
- [x] Enemy pursuit converted to full XYZ movement foundation.
- [ ] Production pathfinding/navigation around 3D obstacles.
- [ ] Enemy attack windup/telegraph.
- [ ] Enemy damage to player.
- [ ] Enemy attack cooldowns.
- [ ] Enemy knockback/stagger resistance.
- [ ] Elite variants.
- [ ] Spawn regions/population management.
- [ ] Anti-farm/respawn tuning where needed.

## 11. Player damage / death

- [ ] Defense/damage-taken calculation.
- [ ] Enemy-to-player validated damage path.
- [ ] Invulnerability frames rules.
- [ ] Knockback on player.
- [ ] Death state.
- [ ] Respawn flow.
- [ ] Safe respawn location rules.
- [ ] Death penalties decision.
- [ ] HUD feedback for damage/death.

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
- [ ] NPC interaction range/server validation.
- [ ] Dialogue system.
- [x] Quest-definition registry foundation.
- [x] Active/completed quest persistence foundation.
- [ ] Quest prerequisites.
- [x] Defeat-objective progression foundation wired to enemy deaths.
- [ ] Collect quests.
- [ ] Talk/exploration quests.
- [x] Quest reward pipeline foundation.
- [ ] Quest tracker UI.
- [ ] Dialogue UI.

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

- [ ] World visual bible/concept direction.
- [ ] Graybox first map.
- [ ] Spawn/tutorial area.
- [ ] Field boundaries.
- [ ] Platforms/terrain.
- [ ] Camera framing zones.
- [ ] Portals/transitions.
- [ ] NPC placements.
- [ ] Monster spawn placements.
- [ ] Quest route.
- [ ] Shops/services.
- [ ] First advancement location.
- [ ] Original environment assets.
- [ ] Lighting/post-processing.
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
- [ ] Production HUD design system (client UI state/screen registry scaffold now exists).
- [ ] HP bar.
- [ ] MP bar.
- [ ] EXP bar.
- [ ] Level display.
- [ ] Currency display.
- [x] Persistent 8-slot skill hotbar data/service foundation; production UI pending.
- [ ] Buff/debuff display.
- [ ] Character/stat panel.
- [ ] Inventory/equipment UI.
- [ ] Quest UI.
- [ ] NPC dialogue UI.
- [ ] Shop UI.
- [ ] Boss HP UI.
- [ ] Notifications/toasts.
- [ ] Settings menu.
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
- [x] Server validates basic attack target/range/depth/cooldown.
- [x] Rate limiter foundation.
- [x] Data session locks.
- [ ] Audit every future remote for type/range/state validation.
- [ ] Movement speed/teleport exploit checks.
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
- [x] `Z` basic attack verified end-to-end in Studio with server damage and hit feedback.
- [ ] Add unit tests for services that can be pure-tested.
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

1. [ ] Build the production HUD shell (HP/MP/EXP/level/currency/hotbar).
2. [ ] Build inventory/equipment/character/skills/quests/settings screen shells.
3. [ ] Add physical Lumenreach graybox + world-object registration for NPCs/portals.
4. [ ] Add the first real hostile enemy using the AI/player-damage architecture.
5. [ ] Finish death/respawn presentation and safe spawn flow.
6. [ ] Add NPC dialogue + quest + shop shell using server interaction sessions.
7. [ ] Add first real skill-use/hotbar flow through `SkillEffectService`.
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
