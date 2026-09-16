local fs = require("@lune/fs")

local source = fs.readFile("src/server/Services/LumenreachWorldService.luau")

for _, required in
    {
        "local WORLD_WIDTH = 2200",
        "local WORLD_DEPTH = 1250",
        "local WORLD_DESIGN_VERSION = 20",
        'world:SetAttribute("WorldDesignVersion", WORLD_DESIGN_VERSION)',
        'world:SetAttribute("TerrainFirstMMOLayout", true)',
        "terrain:Clear()",
        "local ROUTES = table.freeze",
        'Id = "greenway"',
        'Id = "proving_road"',
        'Id = "glowmere_road"',
        'Id = "eastbridge_west"',
        'Id = "eastbridge_east"',
        'Id = "reedbridge_west"',
        'Id = "reedbridge_east"',
        'Id = "gravebone_road"',
        'Id = "mossglen_road"',
        'Id = "sunmoss_road"',
        'Id = "veilfall_road"',
        'Id = "ruins_main"',
        'Id = "sunmoss_return"',
        'Id = "veilfall_return"',
        '"Eastbridge"',
        '"Reedbridge"',
        '"WayfarerHall"',
        '"QuartermasterHouse"',
        '"ArchiveLodge"',
        '"WayfarerInn"',
        '"EastbridgeScoutOutpost"',
        '"WayfarerHearth"',
        '"WayfarerMarketStall"',
        '"WayfarerWatchtower"',
        '"GlowmereBoardwalkA"',
        '"GlowmereBoardwalkB"',
        '"WayfarerRuinWall"',
        '"WayfarerOverlook"',
        '"LumenPylon"',
        "local DRESSING_EXCLUSIONS = table.freeze",
        "local function scatterForestBand",
        "local function dressRouteEdges",
        '"FernPrimary"',
        '"MossyRockSet"',
        '"PineRoots"',
        '"FallenTreeTrunk"',
        '"DryBranches"',
        '"WayfarerHealerLodge"',
        '"WayfarerCraftHall"',
        '"WayfarerStable"',
        '"CrossroadsWaystation"',
        '"GlowmereKeeperHut"',
        '"EastbridgeBarracks"',
        '"GraveboneRuinedChapel"',
        '"MossglenRangerLodge"',
        '"SunmossObservatoryLodge"',
        '"VeilfallRefuge"',
        '"ShatteredArchOuterGate"',
        '"ProvingMentorLodge"',
        "local AMBIENT_RESIDENTS = table.freeze",
        "makeAmbientPopulation(world)",
        'world:SetAttribute("BespokeLumenreachArchitecture", true)',
        "local SIGNATURE = table.freeze",
        "local function makeWayfarerBanner",
        "local function makeWayfarerStreetArch",
        "local function makeWayfarerCart",
        "local function makeForgeYard",
        "local function makeLumenWell",
        "local function makeTrainingGround",
        "local function makeGlowmereStiltHouse",
        "local function makeReedDock",
        "local function makeGraveboneMausoleum",
        "local function makeMossglenRangerHall",
        "local function makeSunmossObservatory",
        "local function makeVeilfallSanctuary",
        "local function makeShatteredFortressTower",
        "local function makeProvingGrandstand",
        "local function makeFivePathMonument",
        "makeSignatureWorldContent(parent)",
        '"WayfarerLumenWell"',
        '"GreenwayOldMileArch"',
        '"GlowmereStiltHouseA"',
        '"EastbridgeFieldForge"',
        '"GraveboneMausoleumA"',
        '"MossglenRangerHall"',
        '"SunmossLumenObservatory"',
        '"VeilfallSanctuary"',
        '"ShatteredNorthTower"',
        '"FivePathMonument"',
        '"ProvingGrandEntrance"',
        "makeGreenwaySetpiece(parent)",
        "makeCrossroadsSetpiece(parent)",
        "makeGlowmereSetpiece(parent)",
        "makeEastLandingSetpiece(parent)",
        "makeGraveboneSetpiece(parent)",
        "makeMossglenSetpiece(parent)",
        "makeSunmossSetpiece(parent)",
        "makeVeilfallSetpiece(parent)",
        "makeRuinsApproach(parent)",
        '"eastbridge_landing"',
        '"EASTBRIDGE LANDING"',
        "local function clearOfTravelLanes",
        '"wayfarer_camp"',
        '"WAYFARER CAMP"',
        '"greenway_fields"',
        '"GREENWAY FIELDS"',
        '"lumenwood_crossroads"',
        '"LUMENWOOD CROSSROADS"',
        '"glowmere_wetland"',
        '"GLOWMERE WETLAND"',
        '"gravebone_watch"',
        '"GRAVEBONE WATCH"',
        '"mossglen_valley"',
        '"MOSSGLEN VALLEY"',
        '"sunmoss_ridge"',
        '"SUNMOSS RIDGE"',
        '"veilfall_ravine"',
        '"VEILFALL RAVINE"',
        '"shattered_lumen_arch"',
        '"SHATTERED LUMEN ARCH"',
        '"wayfarer_proving_circle"',
        '"WAYFARER PROVING CIRCLE"',
        '"lumenreach_start"',
        '"lumenreach_east_gate"',
        "local function registerSpawn",
        'WorldObjectService.Register(gate, "Portal", "lumenreach_to_brasshaven")',
    }
do
    assert(
        string.find(source, required, 1, true) ~= nil,
        "missing Lumenreach v4 contract: " .. required
    )
end

assert(
    string.find(source, "terrain:Clear()", 1, true)
        < string.find(source, "makeZoneContent(world)", 1, true),
    "terrain must be rebuilt before authored world content is placed"
)
assert(
    string.find(source, 'Instance.new("Beam")', 1, true) ~= nil,
    "Veilfall should use stable water ribbons rather than opaque waterfall slabs"
)
assert(
    string.find(source, '"RockFace"', 1, true) == nil,
    "removed RockFace mesh must not return to the player-facing Lumenreach generator"
)
assert(
    string.find(source, "WayfarerTent", 1, true) == nil
        and string.find(source, "makeTent", 1, true) == nil,
    "starter town redesign must not regress to the old tent-camp composition"
)
assert(
    string.find(source, "local WORLD_WIDTH = 2350", 1, true) == nil
        and string.find(source, "local WORLD_DEPTH = 1800", 1, true) == nil
        and string.find(source, "local WORLD_DEPTH = 1700", 1, true) == nil,
    "previous map dimensions must not be restored"
)
assert(
    string.find(source, "placeTreeArc(parent, ZONES.Camp", 1, true) ~= nil
        and string.find(source, "placeTreeArc(parent, ZONES.Ruins", 1, true) ~= nil,
    "tree massing must frame zones rather than being layered randomly across gameplay lanes"
)
assert(
    string.find(source, "if clearOfTravelLanes(position, 10) then", 1, true) ~= nil,
    "zone-edge trees must preserve authored travel-lane clearance"
)

assert(
    string.find(source, "local function fillMountainRidge", 1, true) ~= nil
        and string.find(source, "local function fillMountainChain", 1, true) == nil,
    "Lumenreach boundary terrain must use ridge massing rather than giant spherical mountain chains"
)
assert(
    string.find(source, "gui.Size = UDim2.fromOffset(176, 24)", 1, true) ~= nil
        and string.find(source, "gui.MaxDistance = 105", 1, true) ~= nil,
    "floating landmark labels must stay compact at player height"
)
assert(
    string.find(source, "local TRAINING_ORIGIN = ZONES.Camp + Vector3.new(68, 0, -18)", 1, true)
        ~= nil,
    "training dummy must remain in the open side yard, not inside a town building"
)

for _, combatPocket in
    {
        "ZONES.Greenway + Vector3.new(0, 0, 72)",
        "ZONES.Glowmere + Vector3.new(-90, 0, 70)",
        "ZONES.Gravebone + Vector3.new(70, 0, 70)",
        "ZONES.Mossglen + Vector3.new(-20, 0, -90)",
        "ZONES.Mossglen + Vector3.new(-10, 0, 100)",
        "ZONES.Veilfall + Vector3.new(0, 0, -80)",
        "ZONES.Ruins + Vector3.new(88, 0, 55)",
    }
do
    assert(
        string.find(source, combatPocket, 1, true) ~= nil,
        "action-combat pocket drifted back onto a through-road: " .. combatPocket
    )
end

assert(
    string.find(source, "scatterForestBand(parent, Vector3.new(-790, 0, 430)", 1, true) ~= nil
        and string.find(source, "scatterForestBand(parent, Vector3.new(670, 0, -585)", 1, true)
            ~= nil,
    "V7 must fill the large dead-space woodland belts between progression rooms"
)
assert(
    string.find(source, "for index, route in ROUTES do", 1, true) ~= nil
        and string.find(source, "dressRouteEdges(parent, route, 40 + index)", 1, true) ~= nil,
    "V7 must give travel routes safe edge dressing instead of leaving long empty corridors"
)
assert(
    string.find(source, "clearOfDressingExclusions", 1, true) ~= nil,
    "dense environment dressing must preserve combat/spawn/advancement clearings"
)

assert(
    string.find(source, "local function makeTown(parent)", 1, true) ~= nil
        and string.find(source, "makeWorldSettlements(parent)", 1, true) ~= nil,
    "V7 must populate the region with actual settlements and structures, not only foliage dressing"
)
assert(
    string.find(source, '"ShatteredArchOuterGate"', 1, true) ~= nil
        and string.find(source, '"GraveboneRuinedChapel"', 1, true) ~= nil,
    "late Lumenreach must contain fortress/ruin architecture"
)
assert(
    string.find(source, "AmbientResident", 1, true) ~= nil,
    "V7 settlements must include non-interactive ambient residents so inhabited spaces do not feel abandoned"
)

assert(
    string.find(source, "makeSignatureWorldContent(parent)", 1, true) ~= nil
        and string.find(
                source,
                'world:SetAttribute("BespokeLumenreachArchitecture", true)',
                1,
                true
            )
            ~= nil,
    "V7 must wire the bespoke EverLeaf architecture pass into the generated world"
)

for _, signatureName in
    {
        "WayfarerLumenWell",
        "WayfarerForgeYard",
        "GreenwayOldMileArch",
        "GlowmereStiltHouseA",
        "GlowmereWestDock",
        "EastbridgeFieldForge",
        "GraveboneMausoleumA",
        "MossglenRangerHall",
        "SunmossLumenObservatory",
        "VeilfallSanctuary",
        "ShatteredNorthTower",
        "ProvingGrandEntrance",
        "FivePathMonument",
        "RuinsReturnWatchtower",
    }
do
    assert(
        string.find(source, '"' .. signatureName .. '"', 1, true) ~= nil,
        "missing bespoke Lumenreach signature asset: " .. signatureName
    )
end

local bespokeFunctionCount = 0
for _ in string.gmatch(source, "local function make[%w]+") do
    bespokeFunctionCount += 1
end
assert(bespokeFunctionCount >= 35, "V7 should retain a broad custom world-construction kit")

local ambientResidentCount = 0
local ambientStart = string.find(source, "local AMBIENT_RESIDENTS = table.freeze", 1, true)
local ambientEnd = string.find(source, "local function makeAmbientResident", ambientStart, true)
assert(ambientStart ~= nil and ambientEnd ~= nil, "ambient resident table must exist")
local ambientBlock = string.sub(source, ambientStart, ambientEnd)
for _ in string.gmatch(ambientBlock, 'Name%s*=%s*"') do
    ambientResidentCount += 1
end
assert(ambientResidentCount >= 25, "V7 must visibly populate safe hubs with a larger ambient cast")

assert(
    string.find(source, "MarketplaceService", 1, true) == nil
        and string.find(source, "InsertService", 1, true) == nil,
    "Lumenreach architecture must not depend on generic Marketplace/Toolbox assets"
)

local townCalls = 0
for _ in string.gmatch(source, "makeTown%(%w+%)") do
    townCalls += 1
end
assert(
    townCalls == 2,
    "makeTown should have exactly one definition call-site plus its function declaration context"
)

local portals = fs.readFile("src/server/Content/PortalDefinitions.luau")
assert(
    string.find(portals, 'TargetSpawnId = "lumenreach_east_gate"', 1, true) ~= nil,
    "Brasshaven return travel must arrive at the eastern Lumenreach gate, not starter spawn"
)

local quests = fs.readFile("src/server/Content/QuestDefinitions.luau")
for _, target in { "gravebone_watch", "eastbridge_crossing", "mossglen_valley", "glowmere_pool" } do
    assert(
        string.find(quests, 'Target = "' .. target .. '"', 1, true) ~= nil,
        "quest progression missing redesigned geography target: " .. target
    )
end

assert(
    string.find(source, '"ArchRoof"', 1, true) ~= nil
        and string.find(source, '"ArchEave"', 1, true) == nil,
    "street arches must use continuous roof planes, not detached wedge plates"
)
assert(
    string.find(source, "local slopeLength = halfRun / math.cos(pitch)", 1, true) ~= nil,
    "building roofs must derive panel length from span"
)
assert(
    string.find(source, "base * CFrame.new(0, 8.45, 0)", 1, true) ~= nil,
    "market canopy must clear player/camera height"
)

assert(
    string.find(source, "local function scatterWorldFiller", 1, true) ~= nil
        and string.find(source, "local cellSize = 105", 1, true) ~= nil
        and string.find(source, "scatterWorldFiller(parent)", 1, true) ~= nil,
    "Lumenreach must fill barren inter-zone acreage without touching authored zone cores"
)
assert(
    string.find(source, "math.floor(length / 40)", 1, true) ~= nil,
    "route-edge dressing must be frequent enough to avoid long barren road stretches"
)

local ridgeStart = assert(string.find(source, "local function fillMountainRidge", 1, true))
local ridgeEnd = assert(string.find(source, "local function carveGorge", ridgeStart, true))
local ridgeSource = string.sub(source, ridgeStart, ridgeEnd - 1)
assert(
    string.find(ridgeSource, "terrain:FillBlock", 1, true) == nil
        and string.find(ridgeSource, "terrain:FillBall", 1, true) ~= nil,
    "mountain ridges must use overlapping natural terrain masses, not rectangular cliff slabs"
)
assert(
    string.find(
        source,
        'registerSpawn(parent, "LumenreachSpawn", "lumenreach_start", ARRIVAL_ORIGIN, math.rad(-90))',
        1,
        true
    ) ~= nil,
    "starter spawn must face east into Wayfarer Camp instead of west toward the world boundary"
)
assert(
    string.find(source, "local zoneCoreRadius = 135", 1, true) ~= nil,
    "world filler must reach zone outskirts instead of leaving giant barren rings"
)

assert(
    string.find(source, "local function makeLumenreachDistrictNetwork", 1, true) ~= nil
        and string.find(source, '"WayfarerLowerWard"', 1, true) ~= nil
        and string.find(source, '"GreenwayCrofts"', 1, true) ~= nil
        and string.find(source, '"GlowmereDrybank"', 1, true) ~= nil
        and string.find(source, '"MossglenWoodcamp"', 1, true) ~= nil
        and string.find(source, '"ShatteredBarracksRuins"', 1, true) ~= nil,
    "V9 must populate the inter-zone world with authored districts rather than foliage-only filler"
)
assert(
    string.find(source, "makeOccupiedHamlet", 1, true) ~= nil
        and string.find(source, "makePatrolPost", 1, true) ~= nil
        and string.find(source, "makeRuinedDistrict", 1, true) ~= nil
        and string.find(source, "makeCroftPlot", 1, true) ~= nil,
    "V9 inter-zone population must include inhabited hamlets, patrol posts, ruins, and working crofts"
)
assert(
    string.find(source, "local WORLD_DEPTH = 1250", 1, true) ~= nil,
    "Lumenreach footprint must not retain the oversized empty 1800-stud north-south acreage"
)

assert(
    string.find(source, "local function normalizeGeneratedCollisions", 1, true) ~= nil
        and string.find(
            source,
            'descendant:GetAttribute("EverLeafCollisionProxy") == true',
            1,
            true
        ) ~= nil
        and string.find(source, "descendant.CanQuery = true", 1, true) ~= nil,
    "V12 must use explicit queryable collision proxies instead of incidental visual-part collision"
)
assert(
    string.find(source, "part.CanCollide = false", 1, true) ~= nil
        and string.find(source, "wedge.CanCollide = false", 1, true) ~= nil
        and string.find(source, "part.CanCollide = true", 1, true) ~= nil,
    "generated render geometry must default non-collidable while explicit collision proxies stay solid"
)
for _, requiredProxy in
    {
        '"ArchitectureCollision"',
        '"BenchCollision"',
        '"HearthCollision"',
        '"MarketCounterCollision"',
        '"WatchtowerPostCollision"',
        '"FenceCollision"',
        '"DockCollision"',
        '"RuinWallCollision"',
        '"SupplyStackCollision"',
        '"CartBodyCollision"',
        '"WellCollision"',
        '"TrainingPostCollision"',
        '"GrandstandTierCollision"',
        '"MonumentDaisCollision"',
        '"RingStoneCollision"',
        '"PathDisciplinePlinthCollision"',
        '"ArchPillarCollision"',
        '"GraveMarkerCollision"',
        '"SignBoardCollision"',
        '"MarketPostCollision"',
        '"MarketCanopyCollision"',
        '"ShelterRoofCollision"',
        '"ArchBeamCollision"',
        '"ArchRoofCollision"',
    }
do
    assert(
        string.find(source, requiredProxy, 1, true) ~= nil,
        "missing current collision coverage: " .. requiredProxy
    )
end
assert(
    string.find(source, 'prefabName == "MossyRockSet"', 1, true) ~= nil
        and string.find(source, 'prefabName == "FallenTreeTrunk"', 1, true) ~= nil
        and string.find(source, 'prefabName == "PineRoots"', 1, true) ~= nil,
    "large imported dressing must receive simple collision proxies rather than remain ghost geometry"
)
assert(
    string.find(source, "local function findTreeTrunkPart", 1, true) ~= nil
        and string.find(
                source,
                "local trunkPosition = if trunk then trunk.Position else ground",
                1,
                true
            )
            ~= nil,
    "tree collision must align to the imported trunk rather than assuming the prefab pivot is centered"
)
assert(
    string.find(source, "normalizeGeneratedCollisions(world)", 1, true) ~= nil
        and string.find(source, "makeNpc(world, npcId)", 1, true) ~= nil
        and string.find(source, "normalizeGeneratedCollisions(world)", 1, true)
            < string.find(source, "makeNpc(world, npcId)", 1, true),
    "world collision normalization must run before NPC/enemy models are created"
)

assert(
    string.find(source, "local function resolveStaticNpcPosition", 1, true) ~= nil
        and string.find(source, "staticNpcPositionIsClear", 1, true) ~= nil
        and string.find(source, 'part:GetAttribute("EverLeafCollisionProxy") == true', 1, true) ~= nil
        and string.find(source, 'part.Name == "HumanoidRootPart"', 1, true) ~= nil,
    "V12 static NPCs must be nudged away from physical world proxies and other humanoids instead of overlapping"
)

assert(
    string.find(source, "local function makeWorldMicroSites", 1, true) ~= nil
        and string.find(source, "makeWorldMicroSites(parent)", 1, true) ~= nil,
    "V13 must populate inter-zone acreage with authored micro-sites, not more foliage"
)
local microSiteStart = string.find(source, "local function makeWorldMicroSites", 1, true)
local microSiteEnd =
    string.find(source, "local function makeTown(parent)", microSiteStart or 1, true)
assert(microSiteStart and microSiteEnd, "V13 micro-site section must be present")
local microSiteBody = string.sub(source, microSiteStart, microSiteEnd - 1)
local microSiteCount = 0
for _ in string.gmatch(microSiteBody, 'Name = "') do
    microSiteCount += 1
end
assert(microSiteCount >= 20, "V13 must add at least twenty authored micro-sites across Lumenreach")
assert(
    string.find(source, 'Name = "Wayfarer Healer"', 1, true) == nil
        and string.find(source, 'Name = "Glowmere Keeper"', 1, true) == nil
        and string.find(source, 'Name = "Sunmoss Researcher"', 1, true) == nil
        and string.find(source, 'Name = "Veilfall Refugee"', 1, true) == nil,
    "functional regional NPCs must not have overlapping ambient duplicates"
)

assert(
    string.find(source, "local function makeWayfarerCivicHall", 1, true) ~= nil
        and string.find(source, "local function makeQuartermasterDepot", 1, true) ~= nil
        and string.find(source, "local function makeArchiveResearchLodge", 1, true) ~= nil
        and string.find(source, "local function makeWayfarerInn", 1, true) ~= nil
        and string.find(source, "local function makeHealerApothecary", 1, true) ~= nil
        and string.find(source, "local function makeCraftWorkshop", 1, true) ~= nil
        and string.find(source, "local function makeOpenStable", 1, true) ~= nil
        and string.find(source, "local function makeProvingLodge", 1, true) ~= nil
        and string.find(source, "local function makeRoadWayhouse", 1, true) ~= nil
        and string.find(source, "local function makeFarmBarn", 1, true) ~= nil
        and string.find(source, "local function makeCroftCottage", 1, true) ~= nil,
    "V20 must preserve explicit frontier architecture archetypes while moving major buildings to authored MeshParts"
)

local genericBuildingCallCount = 0
for _ in string.gmatch(source, "makeBuilding%(") do
    genericBuildingCallCount += 1
end
assert(
    genericBuildingCallCount == 0,
    "named Lumenreach architecture must no longer call the generic makeBuilding helper"
)

for _, namedBuilding in
    {
        '"WayfarerHall"',
        '"QuartermasterHouse"',
        '"ArchiveLodge"',
        '"WayfarerInn"',
        '"WayfarerHealerLodge"',
        '"WayfarerCraftHall"',
        '"WayfarerStable"',
        '"PathkeeperLodge"',
        '"GlowmereKeeperHut"',
        '"EastbridgeBarracks"',
        '"MossglenRangerLodge"',
        '"SunmossObservatoryLodge"',
        '"VeilfallRefuge"',
        '"ProvingMentorLodge"',
    }
do
    assert(
        string.find(source, namedBuilding, 1, true) ~= nil,
        "missing V20 architecture conversion: " .. namedBuilding
    )
end

for _, token in
    {
        'Name = "Wayfarer Merchant"',
        'Name = "Wayfarer Artisan"',
        'Name = "Wayfarer Patrol"',
        'Name = "Wayfarer Scholar"',
        'Name = "Wayfarer Recruit"',
        '"WayfarerEastGate"',
        '"MarketArch"',
        '"TRAINING COURT"',
    }
do
    assert(
        string.find(source, token, 1, true) ~= nil,
        "missing V20 Wayfarer MMO-hub content: " .. token
    )
end

print("Lumenreach terrain-first MMO redesign rules tests passed")
