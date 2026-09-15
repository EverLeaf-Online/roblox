local fs = require("@lune/fs")

local source = fs.readFile("src/server/Services/LumenreachWorldService.luau")

for _, required in
    {
        "local WORLD_WIDTH = 2350",
        "local WORLD_DEPTH = 1800",
        "local WORLD_DESIGN_VERSION = 5",
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
    string.find(source, "local WORLD_WIDTH = 2200", 1, true) == nil
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
    "V5 must fill the large dead-space woodland belts between progression rooms"
)
assert(
    string.find(source, "for index, route in ROUTES do", 1, true) ~= nil
        and string.find(source, "dressRouteEdges(parent, route, 40 + index)", 1, true) ~= nil,
    "V5 must give travel routes safe edge dressing instead of leaving long empty corridors"
)
assert(
    string.find(source, "clearOfDressingExclusions", 1, true) ~= nil,
    "dense environment dressing must preserve combat/spawn/advancement clearings"
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

print("Lumenreach terrain-first MMO redesign rules tests passed")
