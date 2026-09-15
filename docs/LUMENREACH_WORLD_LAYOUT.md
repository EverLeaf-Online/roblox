# Lumenreach MMO World Layout — Authored MMO V4

**Canonical target:** 2350 × 1800 studs, Level 1–10 starter region.

Lumenreach V4 is a full replacement of the earlier showcase/camp composition. The runtime generator clears the previous generated model and Terrain, rebuilds macro topography from scratch, cuts the road network into the land, and only then places the authored structures, trees, NPCs, bridges, encounter spaces, landmarks, and portal required by gameplay. New work must extend this terrain-first layout; it must not stack scenery over older geometry.

## Topology

```text
                                        SUNMOSS RIDGE
                                             \
                                              \
GLOWMERE WETLAND -- REEDBRIDGE -- MOSSGLEN VALLEY ------ SHATTERED LUMEN ARCH --> BRASSHAVEN
       |                              /       \                    /
       |                             /         \                  /
WAYFARER CAMP -> GREENWAY -> LUMENWOOD CROSSROADS -> EASTBRIDGE -> EAST LANDING
      |                                                           \
      |                                                            GRAVEBONE WATCH
      v                                                                  \
WAYFARER PROVING CIRCLE                                                   VEILFALL RAVINE
                                                                               \
                                                                                +----> SHATTERED ARCH
```

The starter route is intentionally readable as geography rather than a chain of decorated rooms. The river/gorge cuts the zone into western and eastern halves. Eastbridge is the primary progression threshold; Reedbridge gives Glowmere an alternate northern connection into Mossglen. Sunmoss and Veilfall become high/low late-zone loops that reconnect at the Shattered Arch instead of dead-ending.

## Zone roles and level bands

| Zone | Levels | Role |
| --- | ---: | --- |
| Wayfarer Camp | 1–10 | Starter town, safe spawn, shops, quest services, training |
| Greenway Fields | 1–3 | First open combat field and movement/combat onboarding |
| Lumenwood Crossroads | 2–4 | Navigation hub and first major route decision |
| Glowmere Wetland | 2–5 | Exploration/wetland loop, Slimes, Royal Glowcap |
| Eastbridge Landing | 3–7 | Field outpost, Scout/Outfitter quest hub for the eastern half |
| Gravebone Watch | 3–7 | Ruined combat field, Skeletons, Gravebone Captain revisit |
| Mossglen Valley | 4–7 | Large party-capable field, Brambleback branch, Mosswarden boss |
| Sunmoss Ridge | 6–9 | Elevated highland loop and long-range landmark space |
| Veilfall Ravine | 7–9 | Low ravine loop, Wisp combat, waterfall landmark |
| Shattered Lumen Arch | 8–10 | Regional capstone, late Skeleton field, Brasshaven gate |
| Wayfarer Proving Circle | 7–10 | First advancement milestone detached from leveling traffic |

## V4 authored world identity

V4 keeps the terrain-first macro layout but finishes the region as a designed MMORPG space rather than a sparse navigation prototype. Every major subzone now has an authored silhouette, rest/observation point, or ruin language placed around — never through — its combat and traversal center.

- **Wayfarer Camp** is a permanent starter town with a social hearth plaza, four service buildings, quartermaster/archive stalls, benches, training yard, arrival signage, Lumen gate pylons, and a wide party-safe departure gate.
- **Greenway Fields** reads as the first reclaimed road outside town, with roadside ruins and a safe rest edge framing the starter combat meadow.
- **Lumenwood Crossroads** is centered on a tall Wayfarer pylon and resting seats, making the first route decision legible without a giant floating sign.
- **Glowmere Wetland** gains a shoreline boardwalk and observation deck that skirt the combat pool instead of crossing it.
- **Eastbridge Landing** is a real field outpost with a scout lodge, market stall, hearth, watchtower, and bridge-facing rest space.
- **Gravebone Watch** uses broken wall lines, grave markers, and a ruined watchtower to create cover and history around the open combat ring.
- **Mossglen Valley** gains a scout lookout, rest hearth, overlook deck, and boss-arena pylons while preserving its party-scale field.
- **Sunmoss Ridge** becomes a highland destination with an overlook deck and ascending Lumen pylons visible from lower routes.
- **Veilfall Ravine** uses a dedicated overlook, ruin fragment, and wayfinding pylons around the cascade and Wisp field.
- **Shattered Lumen Arch** now has a processional pylon avenue and broken side walls so the Level 8–10 capstone reads as a regional threshold before the portal itself.

All V4 architecture is native Roblox geometry or approved environment prefabs. No RockFace mesh, giant fallback boulders, tent-town regression, or scenery layering is allowed. The generator still clears and rebuilds the complete region on initialization.

## Hard layout rules

1. **Rebuild, never layer.** `LumenreachWorldService.Init()` must clear the previous generated Lumenreach model and `Terrain` before constructing V3.
2. **Terrain carries the map.** Large-scale boundaries, elevation changes, room separation, the gorge, the wetland, and Sunmoss height come from Terrain—not giant rock meshes or hidden wall rings.
3. **Town means town.** Wayfarer Camp uses an open stone plaza with four permanent buildings, a training side yard, core NPC services, a proper departure gate, and a separate southern Proving road. Tovin and the Scout Outfitter are deliberately moved to Eastbridge Landing so the eastern half has a field quest hub. Tents are not part of the starter-town composition.
4. **Combat rooms remain open.** Greenway, Gravebone, Mossglen, Veilfall, and Shattered Arch reserve broad encounter floors. Tree massing frames those spaces rather than filling their center.
5. **Roads are traversable MMO lanes.** Primary roads are approximately 15–22 studs wide before shoulder treatment and are authored as terrain ribbons. They must support parties and dodge movement without prop collision.
6. **Crossing water is meaningful.** The gorge is carved after road terrain so paths do not accidentally become land bridges. Only Eastbridge and Reedbridge cross it.
7. **Elevation has gameplay purpose.** Sunmoss is a real raised Terrain shelf. Veilfall is a real lowered ravine. Neither is simulated by stacking decorative rock objects around a flat floor.
8. **Stable visual assets only.** The approved primary tree prefab may frame zones. The removed RockFace mesh, black sphere fallback cliffs, raw texture references, and cyan slab waterfall treatment are prohibited.
9. **Landmarks orient the player.** Wayfarer Camp gate, Eastbridge, Reedbridge, Sunmoss shelf, Veilfall cascade, and Shattered Lumen Arch must be legible before the player reaches the encounter center.
10. **Progression follows the map.** Level 1–3 stays west of/near the gorge; Level 3–7 crosses Eastbridge; Level 6–9 branches vertically into Sunmoss/Veilfall; Level 8–10 converges on the Shattered Arch and Brasshaven gate.

## Source contract

`src/server/Services/LumenreachWorldService.luau` is the canonical V4 generator. It owns:

- `WORLD_WIDTH = 2350` and `WORLD_DEPTH = 1800`;
- zone centers and progression bands;
- the complete terrain route network;
- terrain reset/foundation, mountain belts, internal ridges, wetland, gorge, and Sunmoss shelf;
- Wayfarer Camp architecture and safe spawn;
- Eastbridge and Reedbridge;
- zone metadata (`MMOZone`), landmark labels, exploration triggers, encounter triggers;
- first-advancement space and the Lumenreach → Brasshaven portal.

`tests/lumenreach_layout_rules.luau` guards against reintroducing the previous dimensions, tent-camp composition, RockFace path, duplicate town construction, or scenery-first generation order.

## Studio validation still required

Source/build tests cannot judge visual composition. Player-height Studio QA must verify: terrain seams, road grades, bridge approaches, town doorway/roof clearance, spawn sightline, river bank escape paths, 4+ player encounter spacing, Sunmoss slope readability, Veilfall camera behavior, Shattered Arch silhouette, streaming pop-in, foliage density, and worst-case frame time. Geometry/layout problems should be fixed before any decorative-density pass.
