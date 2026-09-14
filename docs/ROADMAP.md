# EverLeaf Roblox Roadmap

**Canonical status:** 2026-09-14
**Repository:** `EverLeaf-Online/roblox`
**Build host:** `/opt/roblox/game` on the EverLeaf ARM64 VM

This roadmap is the canonical high-level plan. Detailed task status lives in [`MASTER_CHECKLIST.md`](MASTER_CHECKLIST.md).

## Status rules

- ✅ **Done** — implemented and verified at the level claimed.
- 🟨 **Partial** — meaningful implementation exists, but the complete player-facing feature is not finished or verified.
- ⬜ **Todo** — not implemented yet.
- ⛔ **Blocked** — cannot proceed without an external decision/dependency.

A backend being complete does **not** make the whole gameplay feature complete. Example: server damage calculation can be ✅ while visible attacking remains 🟨 until input, animation, feedback, hit response, and Studio testing all pass.

---

## M0 — Development foundation ✅

Goal: establish a reproducible professional Roblox workflow before content production.

- ✅ Canonical GitHub repository and `main` branch.
- ✅ Canonical VM working tree at `/opt/roblox/game`.
- ✅ Native ARM64 Rojo headless builds.
- ✅ Rokit-pinned Rojo, StyLua, and Lune.
- ✅ Native ARM64 Wally and Selene.
- ✅ `./check.sh` quality gate: format → lint → headless tests → Rojo build.
- ✅ VS Code + Rojo Studio plugin workflow tested on Windows.
- ✅ Studio successfully connected to the repository through Rojo 7.7.0.
- ✅ Server/client/shared source layout established.
- ✅ Canonical design and toolchain documentation.

**Exit:** complete.

---

## M1 — Playable combat sandbox 🟨 ACTIVE

Goal: turn the technical foundation into a visibly playable 2.5D RPG sandbox before building large maps/content.

### Movement and camera
- ✅ 2.5D left/right movement prototype.
- ✅ Jumping works in Studio.
- ✅ Client side-camera controller.
- ✅ Server combat-plane/depth sanity checks.
- 🟨 Tune camera framing, movement feel, acceleration, turning, and edge cases.
- ⬜ Add proper movement animation/state handling.
- ⬜ Add ladders/ropes/platform traversal if retained in final movement design.

### Basic combat
- ✅ Server-authoritative basic-attack remote.
- ✅ Server range/depth validation.
- ✅ Attack cooldown and remote rate limiting.
- ✅ Might-based mastery/variance damage math.
- ✅ Enemy HP/death/reward backend.
- ✅ Damage-contribution tracking.
- ✅ Training dummy registration and respawn.
- ✅ Temporary combat feedback message implementation.
- 🟨 **Player-facing basic attack loop** — backend exists; latest `Z`/R2 input path still requires end-to-end Studio verification.
- ⬜ Visible attack animation.
- ⬜ Hit reaction/hit-stop.
- ⬜ Damage-number presentation.
- ⬜ Sound/VFX feedback.
- ⬜ Direction/facing-aware attack selection.
- ⬜ Production hitboxes/hurtboxes instead of nearest-target prototype targeting.
- ⬜ Knockback and stagger.

### Enemy behavior
- ✅ Enemy registry/definition foundation.
- ⬜ Aggro acquisition and leash rules.
- ⬜ Pursuit/pathing appropriate for 2.5D fields.
- ⬜ Enemy attacks and telegraphs.
- ⬜ Player damage/death/respawn loop.
- ⬜ Enemy knockback/resistance rules.

**Exit criteria:** one player can spawn, move, jump, visibly attack, kill a hostile enemy, take damage, die/respawn, and receive a visible reward with no runtime errors.

---

## M2 — Core RPG progression 🟨

Goal: make progression, stats, advancement, inventory, and skills coherent before content scales up.

### Already established
- ✅ Server-owned profiles.
- ✅ DataStore schema reconciliation.
- ✅ Cross-server session locks.
- ✅ Autosave and release flow.
- ✅ Client-safe profile snapshots.
- ✅ Level/EXP/AP/SP foundation.
- ✅ +5 AP per level.
- ✅ +3 SP per level after first advancement.
- ✅ Level cap 200 foundation.
- ✅ Core stats: Might, Finesse, Insight, Fortune.
- ✅ Derived HP/MP math foundation.
- ✅ Shards/Marks server-owned currency ledger.
- ✅ Advancement gating framework for 8/10 → 30 → 70 → 120.
- ✅ Pure progression/damage/derived-stat headless tests.

### Remaining
- ⬜ Finalize original class-family names, identities, and first-advancement requirements.
- ⬜ Finalize base/derived stat formulas.
- ⬜ Finalize level 1–30 EXP curve.
- ⬜ Skill definitions and server-authoritative skill execution.
- ⬜ Skill points and skill-tree validation.
- ⬜ Hotbar/keybind system.
- ⬜ Inventory model and persistence.
- ⬜ Equipment slots/stat aggregation.
- ⬜ Item definitions, rarity, requirements, and tooltips.
- ⬜ Drops/loot ownership/pickup rules.
- ⬜ Consumables and cooldowns.
- ⬜ Shops/buy/sell validation.

**Exit criteria:** a level 1 character can progress to first advancement, allocate stats/skills, equip items, use consumables, earn/spend currencies, and persist everything safely.

---

## M3 — Lumenreach vertical slice ⬜

Goal: build the first real level 1–30 gameplay route using original content.

- ⬜ Lumenreach visual direction and graybox.
- ⬜ Spawn/tutorial area.
- ⬜ Field-map boundaries and camera volumes.
- ⬜ Platforms/footholds/traversal objects.
- ⬜ Portals/transitions.
- ⬜ First NPCs and interaction framework.
- ⬜ Quest framework and quest-state persistence.
- ⬜ Early monster roster.
- ⬜ Drop tables.
- ⬜ Shops/services.
- ⬜ First advancement location/quest.
- ⬜ HUD: HP/MP/EXP/currency/level.
- ⬜ Inventory/equipment UI.
- ⬜ Quest tracker/dialog UI.
- ⬜ Skill/hotbar UI.
- ⬜ Original environment art/audio pass.

**Exit criteria:** coherent original gameplay from new character through the early Lumenreach progression route.

---

## M4 — Brasshaven + level 30 milestone ⬜

Goal: complete the full early-game vertical slice through level 30.

- ⬜ Brasshaven graybox and visual direction.
- ⬜ Lumenreach → Brasshaven progression route.
- ⬜ Expanded monsters/quests/items/NPCs.
- ⬜ Level-30 advancement implementation.
- ⬜ First dungeon/instance framework.
- ⬜ Party-compatible encounter rules.
- ⬜ First meaningful boss loop.
- ⬜ Early-game economy tuning.
- ⬜ Level 1–30 pacing/balance pass.

**Exit criteria:** level 1–30 is content-complete enough for structured external playtesting.

---

## M5 — Belforge Colossus + combat depth ⬜

Goal: prove boss-quality combat and class identity.

- ⬜ Belforge Colossus arena and encounter.
- ⬜ Boss state machine/phases.
- ⬜ Telegraphs and avoidable mechanics.
- ⬜ Boss loot/reward tables.
- ⬜ Death/re-entry/party rules.
- ⬜ Class-specific skill rotations.
- ⬜ Status effects/buffs/debuffs.
- ⬜ Cooldowns/resource costs.
- ⬜ Combat feel pass: animation, VFX, sound, hit-stop, camera response.

---

## M6 — Multiplayer/social/economy ⬜

- ⬜ Party system.
- ⬜ Friends/invite UX where useful.
- ⬜ Chat integration appropriate to Roblox policies.
- ⬜ Trading design decision and anti-abuse model.
- ⬜ Secure player-to-player trading if approved.
- ⬜ Shared loot/party reward rules.
- ⬜ Achievements/titles.
- ⬜ Account/profile presentation.
- ⬜ Economy sinks/sources and inflation controls.

---

## M7 — Higher progression (30–120+) ⬜

- ⬜ Level-70 advancement.
- ⬜ Level-120 advancement.
- ⬜ Additional original regions.
- ⬜ Expanded item tiers and skill trees.
- ⬜ Mid/endgame dungeon and boss loops.
- ⬜ Level-cap/endgame progression plan toward 200.

---

## M8 — Production UX, accessibility, and polish ⬜

- ⬜ Final HUD/UI design system.
- ⬜ Keyboard/mouse + controller support.
- ⬜ Mobile-control design if mobile becomes a target platform.
- ⬜ Remappable controls where practical.
- ⬜ Accessibility options.
- ⬜ Tutorial/onboarding refinement.
- ⬜ Loading/teleport/error states.
- ⬜ Settings/audio/graphics UX.
- ⬜ Performance budgets and optimization.
- ⬜ Original art/audio replacement for every prototype asset.

---

## M9 — Security, QA, launch readiness ⬜

- ⬜ Full remote/exploit audit.
- ⬜ Rate-limit review for every client-callable action.
- ⬜ Economy/duplication abuse testing.
- ⬜ DataStore failure/recovery testing.
- ⬜ Multi-client Studio tests.
- ⬜ Long-session/respawn/rejoin tests.
- ⬜ Controller-only testing.
- ⬜ Network-latency simulation.
- ⬜ Performance profiling with target player counts.
- ⬜ Analytics/telemetry plan that respects player privacy.
- ⬜ Moderation/admin tooling.
- ⬜ Release/versioning/deployment workflow.
- ⬜ Roblox experience/place configuration.
- ⬜ Private alpha → closed beta → public release gates.

---

## Monetization rule — NON-NEGOTIABLE

Robux is **cosmetic-only**. Do not sell progression power, combat stats, currencies, drop-rate advantages, advancement, stronger equipment, or other pay-to-win advantages.

Potential monetization later may include original cosmetics, appearance options, emotes, cosmetic effects, and other non-power personalization after the core game is fun without purchases.

---

## Immediate execution order

1. Finish and verify the visible **basic attack** end-to-end in Studio.
2. Add enemy aggro/attacks, player damage, knockback, death, and respawn.
3. Replace prototype nearest-target combat with deliberate 2.5D hitbox/facing rules.
4. Lock first class-family design and advancement requirements.
5. Build production HUD foundations.
6. Graybox Lumenreach.
7. Add first real monster + loot + NPC + quest loop.
8. Complete a polished level 1–10 slice before expanding toward 30.
