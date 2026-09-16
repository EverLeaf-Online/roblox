# Lumenreach World Layout — Source Contract (Studio Acceptance Pending)

**Canonical target:** 2200 × 1250 studs, Level 1–10 starter region.

**V9 population rule:** the playable footprint is intentionally compressed around the progression network, and inter-zone acreage is occupied by authored hamlets, patrol posts, ruined wards, farms/crofts, residents, branch roads, and service spaces. Trees/foliage do not count as world-population content.

**Acceptance status:** the topology and content below exist in source, but the current Studio presentation is still considered a prototype/blockout. Nothing in this document means the environment is visually finished until player-height Studio QA passes.

**V11 collision contract:** rendered geometry is non-colliding by default. Physical architecture/props use explicit simplified `EverLeafCollisionProxy` blockers; imported foliage stays render-only except for deliberate trunk/solid-prop proxies. Collision proxies are queryable so camera, line-of-sight, and projectile raycasts agree with movement collision.

**V13 screenshot correction:** building roof blockers stop at the exterior wall line instead of extending through the eaves; forge cloth awnings are overhead render-only; foundations extend into uneven terrain; duplicate ambient NPCs near functional NPCs are removed; and twenty authored micro-sites fill travel gaps with wayhouses, crofts, watches, shrines, carts, and ruins rather than more trees.

The terrain-first Lumenreach lineage introduced in V7 is a full replacement of the earlier showcase/camp composition. The runtime generator clears the previous generated model and Terrain, rebuilds macro topography from scratch, cuts the road network into the land, and only then places the authored structures, trees, NPCs, bridges, encounter spaces, landmarks, and portal required by gameplay. New work must extend this terrain-first layout; it must not stack scenery over older geometry.

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

## V7 bespoke-world identity

V7 treats the whole Level 1–10 region as an authored MMORPG world rather than a terrain field decorated with props. The V6 settlement layer remains, but V7 adds a bespoke EverLeaf architecture kit, signature skyline pieces, route-side points of interest, working yards/docks/carts, advancement architecture, and a much larger visible population. The forest/terrain layer is support scenery only; it is never counted as world content.

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

All V7 architecture is native Roblox geometry or approved environment prefabs. No RockFace mesh, giant fallback boulders, tent-town regression, or scenery layering is allowed. The generator still clears and rebuilds the complete region on initialization.

### V7 bespoke population and density rules

- **No generic architecture assets.** Settlement buildings, arches, banners, carts, forges, wells, training yards, stilt houses, docks, mausoleums, ranger halls, observatories, sanctuaries, fortress towers, proving stands, and the Five-Path Monument are authored EverLeaf assemblies built in Luau/native Roblox geometry. Do not replace them with Toolbox/Creator Store building packs or anonymous kitbash prefabs.
- Existing approved Poly Haven assets remain limited to natural environment dressing such as trees, ferns, roots, deadwood and mossy rocks; those are scenery, not architectural content.
- Wayfarer Camp now has a recognizable bespoke civic core: Lumen well, forge yard, guarded street arches, training ground, wagons, banners, service buildings, and resident population.
- Every progression zone has at least one signature built landmark that is visually different from every other zone: Glowmere stilt hamlet/docks, Gravebone mausoleums, Mossglen ranger hall/range, Sunmoss observatory, Veilfall sanctuary, Shattered fortress towers, and the Five-Path Proving complex.
- Travel routes use named authored POIs—shrines, carts, gates, shelters, memorials, ferries and watchtowers—so a player does not spend long stretches seeing only dirt road, grass and trees.
- Major safe hubs and advancement spaces use ambient residents to read as inhabited even when quest NPCs are not nearby.

- Wayfarer Camp now contains nine permanent buildings plus watchtowers, palisades, supply areas, service stalls, and a real arrival/departure street.
- Greenway, Crossroads, Glowmere, Eastbridge, Mossglen, Sunmoss, and Veilfall each contain built habitation or staffed travel infrastructure, not just landmarks.
- Gravebone Watch and the Shattered Lumen Arch are built as ruined settlements/fortifications with gatehouses, halls, walls, towers, memorials, and processional architecture.
- The Proving Circle has its own mentor lodge, preparation shelter, oath shrine, and five-discipline trial architecture.
- Ambient Wayfarers/guards/couriers/rangers populate major safe hubs so settlements visibly read as inhabited even when no quest NPC is nearby.

- Continuous forest belts occupy the negative space between quest/combat rooms so the 2200×1250 region no longer reads as isolated clearings in an empty field.
- Route-edge dressing uses ferns, mossy rock sets, roots, stumps, dry branches, fallen logs, and occasional trees outside the party-width travel lane.
- Spawn, training, boss, monster, bridge, and advancement spaces are explicit dressing exclusions. Density must never reduce action-combat readability.
- The biome mix changes by area: Glowmere/Veilfall favor wet understory, Gravebone/Shattered Arch favor dry deadwood/stone, and Greenway/Mossglen/Sunmoss use living forest floor.
- Streaming remains enabled; density is authored with optimized approved prefabs rather than expensive ad-hoc mesh spam.

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

`src/server/Services/LumenreachWorldService.luau` is the canonical V11 generator. It owns:

- `WORLD_WIDTH = 2200` and `WORLD_DEPTH = 1250`;
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
