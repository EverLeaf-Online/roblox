local fs = require("@lune/fs")

local source = fs.readFile("src/server/Services/LumenreachWorldService.luau")

local requiredArchetypes = {
    "makeWayfarerCivicHall",
    "makeQuartermasterDepot",
    "makeArchiveResearchLodge",
    "makeWayfarerInn",
    "makeHealerApothecary",
    "makeCraftWorkshop",
    "makeOpenStable",
    "makeProvingLodge",
    "makeRoadWayhouse",
    "makeFarmBarn",
    "makeCroftCottage",
    "makeGlowmereStiltHouse",
    "makeMossglenRangerHall",
}
for _, archetype in requiredArchetypes do
    assert(
        string.find(source, "local function " .. archetype, 1, true) ~= nil,
        archetype .. " is missing"
    )
end

local genericCalls = 0
for _ in string.gmatch(source, "makeBuilding%(") do
    genericCalls += 1
end
assert(
    genericCalls == 0,
    "generic makeBuilding shell must be removed once explicit archetypes own named structures"
)

for _, token in
    {
        "local function placeArchitectureBuilding",
        'wrapper:SetAttribute("EverLeafArchitecture", true)',
        'wrapper:SetAttribute("ArchitecturePrefab", prefabName)',
        '"ArchitectureCollision" .. index',
        "EnvironmentPrefabService.Place(",
        '"LumenCivicHall"',
        '"LumenQuartermasterDepot"',
        '"LumenArchiveLodge"',
        '"LumenWayfarerInn"',
        '"LumenHealerLodge"',
        '"LumenCraftWorkshop"',
        '"LumenOpenStable"',
        '"LumenProvingLodge"',
        '"LumenRoadWayhouse"',
        '"LumenFarmBarn"',
        '"LumenCroftCottageA"',
        '"LumenCroftCottageB"',
        '"LumenGlowmereStiltHouse"',
        '"LumenMossglenRangerHall"',
        '"LumenFrontierGatehouse"',
        '"LumenRuinedHall"',
    }
do
    assert(
        string.find(source, token, 1, true) ~= nil,
        "missing V24 MeshPart architecture contract " .. token
    )
end

assert(
    string.find(source, "local WORLD_DESIGN_VERSION = 24", 1, true) ~= nil,
    "architecture conversion must bump world design version"
)

for _, token in
    {
        "flattenTerrain(camp, Vector3.new(300, 0, 240), 2.0",
        'makeWayfarerCivicHall(parent, "WayfarerHall", camp + Vector3.new(-30, 0, -62), math.rad(180))',
        'makeArchiveResearchLodge(parent, "ArchiveLodge", camp + Vector3.new(33, 0, -61), math.rad(180))',
        '"QuartermasterHouse"',
        "camp + Vector3.new(-64, 0, 34)",
        'makeWayfarerInn(parent, "WayfarerInn", camp + Vector3.new(65, 0, 35), math.rad(-22))',
    }
do
    assert(
        string.find(source, token, 1, true) ~= nil,
        "missing V24 mesh architecture/placement contract: " .. token
    )
end

local townAt = assert(string.find(source, "local function makeTown(parent)", 1, true))
local gradeAt =
    assert(string.find(source, "flattenTerrain(camp, Vector3.new(300, 0, 240), 2.0", townAt, true))
local hallAt =
    assert(string.find(source, 'makeWayfarerCivicHall(parent, "WayfarerHall"', townAt, true))
assert(
    gradeAt < hallAt,
    "Wayfarer Camp terrain must be graded before buildings sample their ground height"
)

assert(
    string.find(source, "local function setArchitectureVisual", 1, true),
    "V24 architecture query helper missing"
)
assert(
    string.find(source, "descendant.CanQuery = true", 1, true),
    "architecture visuals must participate in camera/LOS queries"
)
assert(
    string.find(source, "spec.Size * architectureScale", 1, true),
    "architecture collision size must scale with the visual"
)
assert(
    string.find(source, "spec.Offset * architectureScale", 1, true),
    "architecture collision offsets must scale with the visual"
)

for _, token in
    {
        '"WayfarerEastGate"',
        '"WayfarerSouthGate"',
        '"MarketArch"',
        '"MarketCart"',
        '"ArrivalCart"',
        '"WayfarerSquareWell"',
        '"MARKET LANE"',
        '"HEALER / STOREHOUSE"',
    }
do
    assert(string.find(source, token, 1, true) ~= nil, "missing V24 MMO hub composition: " .. token)
end

print("Lumenreach architecture rules tests passed")
