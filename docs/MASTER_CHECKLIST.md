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
- [ ] Centralize remote schemas/payload validation further as systems grow.
- [ ] Add structured server logging/error categories.
- [ ] Add service initialization/dependency framework if complexity warrants it.

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
- [ ] Migration framework for destructive/future schema changes.
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

## 7. Movement / 2.5D traversal

- [x] Client 2.5D movement controller prototype.
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

- [ ] Skill-definition schema.
- [ ] Server skill execution service.
- [ ] SP spending/validation.
- [ ] Skill levels/max ranks.
- [ ] Skill prerequisites.
- [ ] Active skills.
- [ ] Passive skills.
- [ ] Buff/debuff/status-effect framework.
- [ ] MP/resource costs.
- [ ] Cooldowns.
- [ ] Targeting shapes/ranges.
- [ ] Skill animation/VFX/SFX hooks.
- [ ] Hotbar.
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
- [ ] 2.5D pursuit.
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

- [ ] Inventory persistence schema.
- [ ] Stackable items.
- [ ] Non-stackable/equipment items.
- [ ] Unique item IDs where needed.
- [ ] Equipment slots.
- [ ] Equip/unequip validation.
- [ ] Item stat aggregation.
- [ ] Level/class requirements.
- [ ] Weapon types.
- [ ] Armor/accessory types.
- [ ] Consumables.
- [ ] Inventory capacity rules.
- [ ] Item tooltips.
- [ ] Inventory UI.
- [ ] Equipment UI.
- [ ] Safe deletion/drop behavior.

## 14. NPC / interaction / quests

- [ ] Generic interactable framework.
- [ ] NPC definitions.
- [ ] NPC interaction range/server validation.
- [ ] Dialogue system.
- [ ] Quest definitions.
- [ ] Quest state persistence.
- [ ] Quest prerequisites.
- [ ] Kill quests.
- [ ] Collect quests.
- [ ] Talk/exploration quests.
- [ ] Quest reward validation.
- [ ] Quest tracker UI.
- [ ] Dialogue UI.

## 15. Shops / services

- [ ] Shop definitions.
- [ ] Server-authoritative buy flow.
- [ ] Server-authoritative sell flow.
- [ ] Price/currency validation.
- [ ] Inventory-space validation.
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
- [ ] Production HUD design system.
- [ ] HP bar.
- [ ] MP bar.
- [ ] EXP bar.
- [ ] Level display.
- [ ] Currency display.
- [ ] Hotbar.
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

- [ ] Party system.
- [ ] Party UI.
- [ ] Shared/individual reward rules.
- [ ] Instance/party teleport flow.
- [ ] Trading design decision.
- [ ] Secure trading if approved.
- [ ] Social/profile inspection.
- [ ] Achievements/titles.
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
- [ ] Verify latest `Z` basic attack end-to-end in a fresh Studio session.
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
- [ ] Decide VM auto-publish policy (never publish unvalidated commits).
- [ ] Version/build metadata.
- [ ] Staging vs production place strategy.
- [ ] Private alpha access setup.
- [ ] Closed beta gate.
- [ ] Public launch checklist.
- [ ] Rollback procedure.

## 26. Documentation / project management

- [x] `GAME_DESIGN.md` canonical design foundation.
- [x] `TOOLCHAIN.md` development environment documentation.
- [x] `ROADMAP.md` canonical phased roadmap.
- [x] `MASTER_CHECKLIST.md` canonical detailed checklist.
- [ ] Keep roadmap/checklist updated whenever a milestone lands.
- [ ] Record major design decisions so implementation does not drift.
- [ ] Add contributor workflow if/when more developers join.

---

# Current highest-priority queue

1. [ ] Verify `Z` basic attack in a **fresh** Studio play session.
2. [ ] Finish visible attack animation + hit confirmation + damage numbers.
3. [ ] Replace nearest-target prototype targeting with facing/hitbox combat.
4. [ ] Add hostile enemy aggro/pursuit/attacks.
5. [ ] Add player damage/knockback/death/respawn.
6. [ ] Lock first class-family names/requirements.
7. [ ] Start production HUD.
8. [ ] Graybox Lumenreach.
9. [ ] Build first real monster + loot + NPC + quest loop.
10. [ ] Polish levels 1–10 before scaling content to level 30.

# Definition of the first meaningful playable milestone

Do **not** call M1 complete until a fresh player can enter Studio and, without debug knowledge:

- move and jump naturally in the 2.5D field,
- understand the camera,
- visibly perform a basic attack,
- hit and kill a hostile enemy,
- see damage/reward feedback,
- take damage,
- die and respawn,
- and complete that loop without red runtime errors.
