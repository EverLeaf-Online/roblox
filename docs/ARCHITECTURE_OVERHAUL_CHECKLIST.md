# EverLeaf Whole-Game Architecture Overhaul Checklist

Status: ACTIVE — current generic/box architecture is temporary until replaced and accepted in Studio.

## Non-negotiable world-building rules

- [ ] No major building may be a plain rectangular shell with one generic gable roof.
- [ ] Every named service/quest building must have a unique silhouette readable from the road.
- [ ] Every archetype needs a purpose-readable frontage: entrance, porch/loading/service/work area, signage, props, and route connection.
- [ ] Foundations must visually meet terrain; no floating walls, exposed gaps, or buried doors.
- [ ] Roofs must have correct eaves, ridge joins, wall closure, and player/camera clearance.
- [ ] Render geometry and movement collision stay separate; collision uses explicit simple proxies.
- [ ] Districts must use regional architecture rather than recolored copies of Wayfarer buildings.
- [ ] Important structures require player-height Studio acceptance screenshots before being marked complete.
- [ ] Foliage does not count as settlement/content density.
- [ ] Repeated micro-sites must rotate among multiple structural archetypes rather than clone one hut.

## Shared architecture families

### Lumenreach frontier kit

- [ ] Wayfarer civic hall — tall center volume, offset side wing, broad entry porch, banners, landmark ridge.
- [ ] Healer/apothecary lodge — low split roof, open herb porch, drying racks, side garden/work table.
- [ ] Smithy/forge — open-sided work bay, stone forge and chimney, lean-to roof, tool/anvil yard.
- [ ] Archive/research lodge — stepped footprint, reading deck, side annex, shelves/chests/research props.
- [ ] Quartermaster/storehouse — heavy stone base, loading porch, reinforced doors, exterior storage canopy.
- [ ] Inn/rest lodge — L-shaped or long hall, deep social porch, lantern frontage, seating court.
- [ ] Croft cottage — compact asymmetrical home, lean-to storage, fenced work yard, varied roof orientation.
- [ ] Ranger/hunter cabin — narrow lodge, front deck, drying rack, weapon/tool wall, elevated lookout option.
- [ ] Watch/guard post — compact enclosed hut plus raised lookout/deck; not a cottage recolor.
- [ ] Road wayhouse — sheltered bench/service bay with partial enclosure and visible travel supplies.
- [ ] Glowmere stilt house — raised floor, stilts, dock/deck, reed canopy, waterside stairs.
- [ ] Shrine shelter — open pavilion/stone-and-timber ritual structure, readable from route.
- [ ] Frontier ruin — broken version of a recognizable real structure with missing walls/roof sections, not random blocks.
- [ ] Gatehouse — occupied defensive structure with side rooms/platforms and a true pass-through opening.
- [ ] Proving lodge — aspirant barracks/training pavilion distinct from normal town housing.

### Brasshaven / Belforge industrial kit

- [ ] Foundry administration hall — metal/brick massing, overhead service bridge, reinforced entrance.
- [ ] Machinist workshop — asymmetrical shed, open loading bay, gantry/hoist, tool yard.
- [ ] Smelter house — furnace stack, vented roof, heavy service doors, slag channel frontage.
- [ ] Boiler station — vertical tanks/stack silhouette, pipe manifolds, maintenance deck.
- [ ] Worker barracks — industrial rowhouse/bunk structure, external stairs/walkway, service yard.
- [ ] Trade/loading depot — canopy, loading platform, crane/rail interface, stacked cargo.
- [ ] Scrap market — modular covered stalls built from industrial frames, not Wayfarer fabric stalls.
- [ ] Industrial gatehouse — thick portal, control booth, catwalk, warning lights.
- [ ] Pipe bridge/gantry — traversable overhead industrial connector with rails and maintenance access.
- [ ] Refinery tower — vertical landmark with platforms, pipes, service ladder geometry.
- [ ] Belforge arena support block — staging room, marshal station, equipment bay, spectator/service structure.
- [ ] Industrial ruin — damaged factory shell with recognizable bays, broken gantries, collapsed roof sections.

## Lumenreach replacement matrix

### Wayfarer Camp — highest priority

- [ ] `WayfarerHall` -> bespoke civic hall archetype.
- [ ] `QuartermasterHouse` -> quartermaster/storehouse archetype with loading porch.
- [ ] `ArchiveLodge` -> archive/research lodge archetype.
- [ ] `WayfarerInn` -> social inn/rest lodge archetype.
- [ ] `WayfarerHealerLodge` -> healer/apothecary lodge archetype.
- [ ] `WayfarerCraftHall` -> dedicated crafts hall/covered workshop, not house shell.
- [ ] `WayfarerStorehouse` -> bulk warehouse/storehouse archetype.
- [ ] `WayfarerStable` -> open stable with stalls, tack shed, fenced yard.
- [ ] `PathkeeperLodge` -> mentor/proving lodge archetype.
- [ ] `WayfarerForgeYard` -> fully open smithy/forge archetype integrated into town circulation.
- [ ] Re-layout Camp so entrances face streets/courts and buildings do not overlap service props, NPCs, stalls, or shrines.
- [ ] Create one coherent central street/plaza hierarchy instead of scattered objects on open ground.

### Greenway / Crossroads

- [ ] `GreenwayWayhouse` -> road wayhouse archetype.
- [ ] `GreenwayStoreShed` -> farm storage/barn archetype.
- [ ] Greenway crofts -> at least 3 cottage/barn variants, not cloned boxes.
- [ ] `CrossroadsWaystation` -> recognizable travel station with porch, stable/loading side, notice board.
- [ ] `CrossroadsCourierHouse` -> courier depot with loading dock and dispatch canopy.
- [ ] Replace repeated patrol/wayhouse micro-sites with alternating watch-post, shrine, croft, courier, and road-service structures.

### Glowmere

- [ ] `GlowmereKeeperHut` -> stilt keeper house with deck/dock.
- [ ] `GlowmereReedHouse` -> second stilt-house silhouette, not a recolor.
- [ ] `GlowmereDrybank` settlement -> raised walkways, reed sheds, fisher structures, dock frontage.
- [ ] Reed-side micro-sites must use wetland structures, not land cottages.

### Eastbridge

- [ ] `EastbridgeBarracks` -> fortified barracks with wall-facing entrance and drill yard.
- [ ] `EastbridgeStorehouse` -> fortified supply depot/loading structure.
- [ ] `EastbridgeMedicLodge` -> field medic station with covered treatment porch.
- [ ] `EastbridgeScoutOutpost` -> ranger/scout watch structure.
- [ ] `EastbridgeGatehouse` -> true occupied defensive gatehouse with guard platforms.
- [ ] Eastbridge wards -> use frontier-fort kit, not Wayfarer cottage copies.

### Gravebone

- [ ] `GraveboneRuinedChapel` -> recognizable ruined chapel silhouette.
- [ ] `GraveboneGuardHall` -> collapsed guard hall with broken roof/wall logic.
- [ ] Mausoleums/crypts -> multiple tomb silhouettes and partial structural collapse variants.
- [ ] Gravebone roadside ruins -> actual ruined buildings/courtyards rather than isolated wall blocks.

### Mossglen

- [ ] `MossglenRangerLodge` -> ranger hall with porch/work deck.
- [ ] `MossglenHunterCabin` -> hunter cabin variant with drying/tool rack.
- [ ] `MossglenSupplyHouse` -> timber depot/supply shelter.
- [ ] Mossglen Trailhead/Woodcamp -> logging/ranger architecture with sheds and work yards.

### Sunmoss

- [ ] `SunmossObservatoryLodge` -> research lodge integrated with observatory deck/tower.
- [ ] `SunmossKeeperHouse` -> ridge keeper shelter with windbreak/porch.
- [ ] `SunmossObservatory` -> stronger landmark silhouette, layered platforms and visible research equipment.
- [ ] Ascent camps -> pilgrimage/research shelters, not ordinary cottages.

### Veilfall

- [ ] `VeilfallRefuge` -> protected refuge compound with sheltered courtyard.
- [ ] `VeilfallSurveyHut` -> cliff survey station/deck.
- [ ] `VeilfallSanctuary` -> distinct sanctuary pavilion integrated into ravine geometry.
- [ ] Upper/West refuge micro-sites -> storm/ravine shelters with retaining walls and covered entries.

### Proving Circle

- [ ] `ProvingMentorLodge` -> aspirant/mentor training lodge.
- [ ] `ProvingAspirantWard` -> barracks/training-yard architecture, not hamlet cottages.
- [ ] Grandstands/monument/support structures must read as one designed advancement complex.

### Shattered Lumen Arch

- [ ] `ShatteredForwardCamp` -> military frontier camp with command shelter, supply bay, watch platform.
- [ ] `ShatteredBarracksRuins` -> ruined barracks with readable room/bay structure.
- [ ] Fortress towers/arch ruins -> consistent fortress kit with damaged variants and believable connections.
- [ ] Arch micro-sites -> checkpoints, collapsed guard rooms, ruined supply courts, not generic huts.

## Brasshaven / Belforge replacement matrix

### Brasshaven Foundry Threshold / Eastworks

- [ ] Replace flat threshold presentation with an authored industrial street frontage.
- [ ] Build a Foundry Administration Hall.
- [ ] Build a Machinist Workshop.
- [ ] Build a Smelter House.
- [ ] Build a Boiler Station.
- [ ] Build Worker Barracks.
- [ ] Build Trade/Loading Depot.
- [ ] Replace generic vendor counters with industrial market/depot stalls.
- [ ] Convert isolated forge towers into a coherent skyline/industrial block system.
- [ ] Add traversable gantries/pipe bridges between key buildings where useful.
- [ ] Ensure encounter areas sit inside believable industrial yards rather than empty floors with props.

### Gearworks / Cinder / Sootworks / Dynamo / Rail / Blueglass / Flux / Authority / Runoff

- [ ] Gearworks Yard -> machinery workshop + service shed + gantry.
- [ ] Cinder Ducts -> boiler/vent station + maintenance shelter.
- [ ] Sootworks -> worker/service block + damaged shift building.
- [ ] Dynamo Gallery -> power-house structure around coils instead of freestanding effects.
- [ ] Eastworks Rail Yard -> depot/loading platform/control hut/crane support.
- [ ] Blueglass Annex -> research/refinery structure around lenses.
- [ ] Upper Flux Vaults -> secured industrial vault building.
- [ ] Authority Hall -> real civic/security building, not columns only.
- [ ] Molten Runoff -> foundry channel control building and catwalks.
- [ ] Upper Bellows Court -> bellows/piston house rather than isolated cylinders.

### Belforge

- [ ] `BelforgeEntrance` -> full industrial gatehouse/control structure.
- [ ] `BelforgeAntechamber` -> authored staging hall with machinery/service rooms.
- [ ] `BelforgeColossusArena` -> arena architecture with spectator/service/support structures.
- [ ] Add marshal/oathkeeper staging spaces and readable arena circulation.
- [ ] Add industrial ruin/damage variants around late-game encounter routes.

## World placement and composition audit

- [ ] Audit every building against nearby NPCs, stalls, shrines, carts, fences, roads, combat spaces, and interactables.
- [ ] Remove duplicate/overlapping structures and duplicate ambient NPC placements.
- [ ] Entrances must face logical streets or courtyards.
- [ ] Keep minimum clear pedestrian lane around doors and service prompts.
- [ ] Keep dodge/combat areas free of decorative collision clutter.
- [ ] Building groups need believable yards/courts instead of arbitrary spacing.
- [ ] Major routes should reveal landmarks/buildings in layers rather than all structures sitting on one plane.
- [ ] No building should sit visibly unsupported on slope edges; use stepped stone bases, retaining walls, stilts, or terrain pads.

## Collision/QA acceptance for every archetype

- [ ] Foundation collision matches visible base.
- [ ] Wall collision matches actual wall sections and door openings.
- [ ] Roof collision starts at/inside wall line; decorative eaves never create invisible blockers.
- [ ] Roof/wall gaps are visually closed.
- [ ] Porches/decks/steps are traversable.
- [ ] Canopies above walkways have full R15 avatar + camera clearance.
- [ ] Props use either intentional simple collision or render-only behavior; never accidental Part defaults.
- [ ] NPC spawn/idle positions are clear of all structural proxies.
- [ ] Camera raycasts and player movement agree on solid geometry.
- [ ] Water remains swimmable and is never used as grounding surface.
- [ ] Player-height Studio walkthrough completed for all sides/entrances of the archetype.

## Implementation order

### Phase A — architecture framework

- [x] V16: switched the first eight major Lumenreach archetypes from visible Part-built shells to original EverLeaf GLB/MeshPart assets produced in Blender and uploaded as approved Roblox model assets.
- [x] V16: major MeshPart architecture uses render-only imported geometry plus explicit simplified server collision proxies.
- [x] V16: added a reproducible original-asset generator and committed source GLBs/upload manifests so architecture is not dependent on generic Marketplace packs.
- [x] V17: converted district-scale wayhouses, barns, crofts (2 silhouettes), Glowmere stilt houses, Mossglen ranger halls, frontier gatehouses, and ruined halls to original approved MeshPart assets with separate collision proxies.
- [x] V18: converted forge yards, Gravebone mausoleums, Sunmoss observatory, Veilfall sanctuary, Shattered Arch fortress towers, and stone shrines to original approved MeshPart assets with separate simplified collision proxies.
- [x] V19: screenshot-driven fix for pale/white imported buildings and camera/interior clipping: embedded palette atlas on all 22 architecture GLBs, queryable render meshes, and scale-aligned collision proxies.
- [x] V20: rebuilt Wayfarer Camp composition around MMO-hub principles: compact civic square, market lane, service and production courts, defended gatehouse thresholds, readable services, denser residents, carts/cargo and street rhythm. Studio acceptance remains required.
- [x] Introduce explicit Lumenreach archetype builders instead of direct generic `makeBuilding` use for named structures.
- [ ] Introduce explicit Brasshaven industrial building builders.
- [x] Add tests that reject new named service buildings built only through the generic box builder.
- [x] Remove the obsolete generic `makeBuilding` shell entirely; low-importance support structures use purpose-specific primitive builders instead.

### Phase B — starter-region conversion

- [x] SOURCE PASS V14: rebuild Wayfarer Camp core buildings with explicit civic hall, depot, archive, inn, healer, workshop, stable, and proving archetypes. Studio visual acceptance remains.
- [x] SOURCE PASS V14: rebuild Greenway/Crossroads named buildings and district cottages with wayhouse/barn/croft archetypes. Studio visual acceptance remains.
- [x] SOURCE PASS V14: named Glowmere houses now use the stilt-house architecture path instead of the generic cottage shell. Studio visual acceptance remains.
- [x] SOURCE PASS V14: named Eastbridge barracks/storehouse/medic/scout structures now use explicit service/outpost archetypes. Gatehouse refinement still has its own checklist item.
- [ ] Rebuild Gravebone.
- [x] SOURCE PASS V14: Mossglen ranger lodge/hunter/supply structures use ranger/croft/barn archetypes. Studio visual acceptance remains.
- [x] SOURCE PASS V14: Sunmoss lodge/keeper structures use research/croft archetypes; observatory landmark refinement remains tracked separately.
- [x] SOURCE PASS V14: Veilfall refuge/survey structures use wayhouse/research archetypes; sanctuary refinement remains tracked separately.
- [x] SOURCE PASS V14: Proving mentor/support lodge uses the dedicated proving architecture path; full aspirant complex refinement remains tracked separately.
- [ ] Rebuild Shattered Arch frontier/ruins.
- [ ] Replace cloned district/micro-site structures with regional variants.

### Phase C — mid/late-game conversion

- [ ] Build Brasshaven industrial kit.
- [ ] Recompose Foundry Threshold/Eastworks around actual buildings.
- [ ] Rebuild each Brasshaven encounter district around an authored industrial destination.
- [ ] Rebuild Belforge gate/antechamber/arena support architecture.

### Phase D — whole-game acceptance

- [ ] Walk every current region at player height in Studio.
- [ ] Verify no generic placeholder building remains in a named hub/quest/service/district location.
- [ ] Capture acceptance screenshots for every major settlement/district.
- [ ] Verify traversal/collision/camera around every new archetype.
- [ ] Verify performance/part counts after replacement.
- [ ] Only then mark architecture overhaul complete.

- [x] SOURCE PASS V15: screenshot feedback showed V14 still read as flat block architecture. Added exposed truss/gable framing, door hoods, facade timber grids, chimneys, cargo hoists/beacons/loft faces, and corrected Wayfarer Camp grading + plaza-facing placement. Studio acceptance remains required.

## Current acceptance status

- Lumenreach topology/gameplay source: implemented, visual architecture overhaul NOT complete.
- Wayfarer Camp: NOT accepted; generic building family still present.
- Lumenreach outlying districts: NOT accepted; many still derive from generic building family.
- Brasshaven/Eastworks: NOT accepted; industrial environment lacks complete building architecture.
- Belforge: NOT accepted; encounter shell exists but architectural support pass remains.

- V21 whole-map MMO composition pass: rebuilt the spatial hierarchy beyond Wayfarer across Greenway, Crossroads, Glowmere, Eastbridge, Gravebone, Mossglen, Sunmoss, Veilfall, Shattered Arch, Proving, plus Brasshaven/Eastworks/Belforge district courts. Each major area now has authored approach lanes, courts, thresholds, lighting/service rhythm, and region-specific activity framing instead of isolated objects in open terrain. This remains source-complete only until Studio player-height acceptance.

- [x] V22: stopped using the V21 district-court overlay as a substitute for layout. Actual Lumenreach buildings were repositioned to form readable streets/compounds in every major district; secondary hamlets, patrol posts and ruins were restructured the same way. Brasshaven received an original eight-asset industrial MeshPart kit and actual building blocks instead of gantry/canopy clutter layered over encounter props. Fresh Studio screenshots are still required before visual acceptance.

- V23 water regression fix: rebuilt gorge water generation as a two-pass carve/rock then channel/water operation. The previous interleaved rock/water loop allowed later rock samples to overwrite earlier water, leaving the river visually dry. Studio verification remains pending.

- V24 hero architecture rebuild: replaced the eight core Lumenreach service buildings with a second-generation individually authored kit (civic hall, quartermaster depot, archive, inn, healer, workshop, stable, proving lodge). These no longer share the old box-shell/gable recipe: each has distinct massing, footprint, roof logic, frontage and role silhouette. Collision proxies were reshaped to match the new footprints. Roblox approval is complete; Studio player-height visual acceptance remains pending.

- V25 district architecture replacement: replaced the remaining 14 Lumenreach district/landmark production meshes with individually authored V2 assets (wayhouse, barn, two crofts, Glowmere stilt house, ranger hall, gatehouse, ruined hall, forge yard, mausoleum, observatory, sanctuary, fortress tower, shrine). All uploaded assets are Roblox-approved; Studio player-height acceptance is still required.
