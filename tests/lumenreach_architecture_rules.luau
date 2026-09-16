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
        "missing V18 MeshPart architecture contract " .. token
    )
end

assert(
    string.find(source, "local WORLD_DESIGN_VERSION = 18", 1, true) ~= nil,
    "architecture conversion must bump world design version"
)

for _, token in
    {
        "flattenTerrain(camp, Vector3.new(300, 0, 240), 2.0",
        'makeWayfarerCivicHall(parent, "WayfarerHall", camp + Vector3.new(-46, 0, -66), math.rad(180))',
        'makeArchiveResearchLodge(parent, "ArchiveLodge", camp + Vector3.new(28, 0, -76), math.rad(180))',
        'makeQuartermasterDepot(parent, "QuartermasterHouse", camp + Vector3.new(-56, 0, 62), 0)',
        'makeWayfarerInn(parent, "WayfarerInn", camp + Vector3.new(58, 0, 62), 0)',
    }
do
    assert(
        string.find(source, token, 1, true) ~= nil,
        "missing V18 mesh architecture/placement contract: " .. token
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

print("Lumenreach architecture rules tests passed")
