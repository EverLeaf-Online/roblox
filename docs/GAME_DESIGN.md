# EverLeaf Roblox — Canonical Game Foundation

This repository is a clean, original Roblox RPG built from scratch.

## Non-negotiable direction

- Original branding, lore, names, art, audio, maps, UI, and assets.
- No copyrighted MapleStory names/assets and no copied Toolbox scripts.
- MapleStory-like *system structure* may inspire pacing/progression, but implementation and content must be original.
- Server-authoritative progression, stats, combat rewards, currency, inventory, and persistence.
- Robux monetization is cosmetic-only; no paid power.

## Progression baseline

- Level cap: 200.
- First playable vertical slice: levels 1–30.
- Core stats: Might, Finesse, Insight, Fortune.
- AP: +5 per level.
- SP: +3 per level after first advancement.
- First-family advancement occurs at level 8 or 10 depending on the eventual family.
- Later advancements: levels 30, 70, and 120.
- Damage uses mastery-based variance rather than a single deterministic roll.
- HP/MP growth, attack cadence, knockback, and aggro are first-class combat systems.
- Movement direction: 2.5D field-map traversal.

## World/content baseline

- Early world progression includes Lumenreach and Brasshaven.
- Belforge Colossus is a planned boss encounter.
- Core non-Robux currencies include Shards and Marks.

## Milestone 1

Build a secure level 1–30 vertical slice with:

1. Player data/profile lifecycle.
2. Server-owned level, EXP, AP, SP, and core stats.
3. Advancement eligibility framework without hardcoding undecided class-family names.
4. Server-owned currency ledger for Shards and Marks.
5. Networking boundary where clients request actions but never submit authoritative rewards/state.
6. 2.5D movement/combat foundations.
7. First Lumenreach/Brasshaven content scaffolds.
8. Buildable Rojo place output and repeatable VM build workflow.

## Authority rule

The client may request an action (allocate AP, use skill, attack target, interact, etc.). The server validates the request, calculates the result, mutates state, and replicates the outcome. The client never tells the server how much EXP, currency, damage, loot, or progression it earned.
