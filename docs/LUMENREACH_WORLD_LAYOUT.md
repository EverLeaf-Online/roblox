# Lumenreach MMO World Layout

**Canonical world-design target:** 2200 × 1700 studs, Level 1–10 starter region.

Lumenreach is a connected MMORPG region, not a collection of showcase clearings. The player should understand where they are, where the next road goes, and what kind of activity a space supports from terrain, silhouette, road language, and landmarks before reading UI text.

## Topology

```text
                                  GLOWMERE WETLAND
                                 /                \
WAYFARER CAMP -> GREENWAY -> LUMENWOOD CROSSROADS -> EASTBRIDGE -> EAST LANDING
      |                                                           /          \
      |                                             GRAVEBONE WATCH          MOSSGLEN VALLEY
      |                                                                        /       \
      v                                                           VEILFALL RAVINE     SUNMOSS RIDGE
WAYFARER PROVING CIRCLE                                                   \             /
                                                                          SHATTERED LUMEN ARCH
                                                                                  |
                                                                             BRASSHAVEN
```

The main progression route always has at least one readable continuation, while Glowmere, Veilfall, and Sunmoss form optional/alternate loops that reconnect rather than dead-ending. The Proving Circle is deliberately detached from the leveling road so first advancement feels like returning to the starter settlement for a class milestone.

## Zone roles and level bands

| Zone | Levels | MMO role |
| --- | ---: | --- |
| Wayfarer Camp | 1–10 | Starter town, services, quest hub, social/safe spawn |
| Greenway Fields | 1–2 | First open field and basic combat/tutorial space |
| Mossling Hollow | 1–3 | Focused starter hunt pocket off the main road |
| Lumenwood Crossroads | 2–4 | Navigation hub and first meaningful route choice |
| Glowmere Wetland | 2–5 | Exploration loop, wetland combat, rare spawn |
| Gravebone Watch | 3–7 | Ruined combat pocket, early skeleton quest, later elite revisit |
| Mossglen Valley | 4–7 | Large party-capable field, Brambleback branch, field boss |
| Sunmoss Ridge | 6–9 | Elevated exploration/highland alternate route |
| Veilfall Ravine | 7–9 | Lower danger loop, Wisp combat, Whisperroot secret branch |
| Shattered Lumen Arch | 8–10 | Regional capstone, late combat, Brasshaven transition |
| Wayfarer Proving Circle | 7–10 | First-advancement/class milestone space |

## World-design rules

1. **Town first.** Wayfarer Camp must read as a settlement: safe arrival plaza, central hall, services, NPC clustering, social props, training yard, and obvious exits. Spawn must never overlap lodging, tents, service stalls, or decoration.
2. **Roads are gameplay space.** Major roads are approximately 13–20 studs wide, re-cut after terrain massing, and protected from procedural foliage/large props. They must support multiple players passing each other without camera snagging.
3. **Terrain defines boundaries.** Mountain shoulders, ravines, water, ridges, and dense forest communicate the playable edge. Invisible collision is reserved for simple local safety/collision correction, not for drawing the map boundary.
4. **Combat gets rooms, not corridors.** Monster groups and elites use broad, cleared encounter floors. Boss/elite telegraphs must remain readable and grass/props must not occupy the fighting footprint.
5. **Landmarks carry navigation.** Eastbridge, Wayfarer Hall, Glowmere water, Sunmoss highland, Veilfall waterfall, and the Shattered Arch should each create a silhouette visible before the player enters the room.
6. **Loops beat dead ends.** Side exploration should reconnect to the route network wherever practical. Long forced backtracking is reserved for intentional town-return milestones such as first advancement.
7. **Density stays outside the lane.** Forest/detail density frames roads and encounter rooms instead of filling them. Decorative variety is valuable only when it does not damage movement or combat readability.
8. **Stable assets only.** Native Terrain/Parts and approved sanitized environment prefabs are preferred. The broken paper-thin RockFace mesh, black blob replacements, raw texture paths, and cyan slab waterfall treatment must not return.
9. **Progression follows geography.** Early quests stay in Greenway/Crossroads/Glowmere/Gravebone; midgame pushes through Mossglen; late starter content expands into Sunmoss/Veilfall and finally Shattered Arch.
10. **The next region is earned spatially.** Brasshaven is reached at the far eastern capstone, not from a portal sitting beside spawn.

## Current source contract

`LumenreachWorldService.luau` owns the canonical `ROAD_NETWORK`, zone origins, protected gameplay clearings, terrain massing, routes, encounter staging, and `MMOZone` metadata. Quest exploration targets are aligned to physical route progression. `tests/lumenreach_layout_rules.luau` guards the scale, route network, town architecture, Gravebone Watch staging, zone metadata, and far-edge Shattered Arch contract.

## Studio validation still required

The source/build contract is complete, but every large world pass still requires a player-height Studio review before the map is considered visually finished. Validate terrain seams and grades, route readability from both directions, bridge approaches, spawn safety, 4+ player traversal, encounter clearance, camera behavior, StreamingEnabled pop-in, foliage/particle cost, and the sightline to each major landmark. Fix geometry/layout problems before adding more decorative density.
