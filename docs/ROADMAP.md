# EverLeaf Roblox Roadmap

## M0 — Foundation (done)
- [x] Canonical Git/Rojo project on the EverLeaf VM.
- [x] Native ARM64 headless build environment.
- [x] Rokit-pinned Rojo/StyLua/Lune toolchain.
- [x] Native ARM64 Wally and Selene builds.
- [x] Pre-push format/lint/test/build validation gate.
- [x] Server-authoritative profile, stat, and progression baseline.
- [x] Canonical game-design constraints documented.

## M1 — Level 1–30 vertical slice (active)
- [x] Profile schema and client-safe snapshots.
- [x] DataStore persistence with schema reconciliation.
- [x] Cross-server session lock and autosave/release flow.
- [x] AP allocation validation and remote rate limiting.
- [x] Server-only Shards/Marks ledger.
- [x] Advancement gating framework for 8/10, 30, 70, 120.
- [x] Mastery-based damage-roll foundation.
- [x] Server-only reward pipeline.
- [x] Pure progression/damage/derived-stat math with headless tests.
- [x] Prototype derived HP/MP growth and runtime MP state.
- [x] Server-owned enemy registry, hit validation, death, reward, and respawn prototype.
- [x] Prototype 2.5D player controller, side camera, and server depth sanity checks.
- [x] Studio-only training enemy for immediate combat playtesting.
- [ ] Finalize original first-advancement family names and requirements.
- [ ] Enemy aggro, pursuit, attacks, and knockback.
- [ ] Lumenreach graybox map.
- [ ] Brasshaven graybox map.
- [ ] Early mobs, drops, quests, NPC interaction, portals, and shops.
- [ ] First skills and hotbar.
- [ ] Inventory/equipment systems.
- [ ] Production HUD and progression UI.
- [ ] Studio playtest and exploit/remote validation.

## M2 — Content-complete early game
- Levels 1–30 tuned progression and quest flow.
- First dungeon/boss loop.
- Belforge Colossus encounter prototype.
- Itemization, crafting/economy hooks, achievements, social basics.

## M3 — Higher advancement tiers
- Level 70, 120, and endgame progression systems.
- Expanded regions and bosses.
- Long-term economy balancing and live-ops foundations.

## Monetization rule
Robux remains cosmetic-only. Progression power, combat stats, currencies, loot odds, and advancement are never sold for Robux.
