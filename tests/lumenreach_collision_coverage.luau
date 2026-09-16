local fs = require("@lune/fs")

local source = fs.readFile("src/server/Services/LumenreachWorldService.luau")

local builders = {
    "makeBridge",
    "makeWaystone",
    "makeLantern",
    "makeSign",
    "makeRoadWayhouse",
    "makeFarmBarn",
    "makeCroftCottage",
    "makeBench",
    "makeHearth",
    "makeMarketStall",
    "makeWatchtower",
    "makeBoardwalk",
    "makeRuinWall",
    "makeOverlookDeck",
    "makeLumenPylon",
    "makeFenceLine",
    "makeSupplyStack",
    "makeRoadsideShelter",
    "makeStoneShrine",
    "makeRuinedHall",
    "makeGatehouse",
    "makeSignatureCrystal",
    "makeWayfarerBanner",
    "makeWayfarerStreetArch",
    "makeWayfarerCart",
    "makeForgeYard",
    "makeLumenWell",
    "makeTrainingGround",
    "makeGlowmereStiltHouse",
    "makeReedDock",
    "makeGraveboneMausoleum",
    "makeMossglenRangerHall",
    "makeSunmossObservatory",
    "makeVeilfallSanctuary",
    "makeShatteredFortressTower",
    "makeProvingGrandstand",
    "makeFivePathMonument",
    "makeCroftPlot",
    "makeTown",
    "makeStoneCircle",
    "makeProvingCircle",
    "makeRuins",
    "makeGraveboneSetpiece",
}

local function functionBody(name)
    local startAt = assert(
        string.find(source, "local function " .. name .. "(", 1, true),
        "missing builder: " .. name
    )
    local nextAt = string.find(source, "\nlocal function ", startAt + 1, true)
    if not nextAt then
        nextAt = #source + 1
    end
    return string.sub(source, startAt, nextAt - 1)
end

local meshArchitectureBuilders = {
    makeWayfarerCivicHall = true,
    makeQuartermasterDepot = true,
    makeArchiveResearchLodge = true,
    makeWayfarerInn = true,
    makeHealerApothecary = true,
    makeCraftWorkshop = true,
    makeOpenStable = true,
    makeProvingLodge = true,
    makeRoadWayhouse = true,
    makeFarmBarn = true,
    makeCroftCottage = true,
    makeGlowmereStiltHouse = true,
    makeMossglenRangerHall = true,
    makeRuinedHall = true,
    makeGatehouse = true,
    makeStoneShrine = true,
    makeForgeYard = true,
    makeGraveboneMausoleum = true,
    makeSunmossObservatory = true,
    makeVeilfallSanctuary = true,
    makeShatteredFortressTower = true,
}

for _, name in builders do
    local body = functionBody(name)
    local ownsProxy = string.find(body, "makeCollisionProxy(", 1, true) ~= nil
    local delegatesToMeshProxy = meshArchitectureBuilders[name] == true
        and string.find(body, "placeArchitecturePrefabBuilding", 1, true) ~= nil
    assert(
        ownsProxy or delegatesToMeshProxy,
        name .. " creates physical world geometry without an explicit collision proxy"
    )
end

local architecturePlacement = functionBody("placeArchitecturePrefabBuilding")
assert(
    string.find(architecturePlacement, "makeCollisionProxy(", 1, true) ~= nil
        and string.find(architecturePlacement, '"ArchitectureCollision" .. index', 1, true)
            ~= nil,
    "MeshPart architecture must remain render-only and use explicit simple collision proxies"
)

local normalizer = functionBody("normalizeGeneratedCollisions")
assert(
    string.find(normalizer, "descendant.CanCollide = false", 1, true) ~= nil
        and string.find(normalizer, "descendant.CanCollide = true", 1, true) ~= nil,
    "collision normalizer must force render parts non-solid and proxies solid"
)

for _, required in
    {
        '"SignBoardCollision"',
        '"MarketCanopyCollision"',
        '"ShelterRoofCollision"',
        '"ArchRoofCollision"',
        '"TownGateBeamCollision"',
    }
do
    assert(
        string.find(source, required, 1, true) ~= nil,
        "missing rigid-surface collision proxy: " .. required
    )
end

assert(
    string.find(source, "placeArchitecturePrefabBuilding", 1, true) ~= nil
        and string.find(source, '"ArchitectureCollision" .. index', 1, true) ~= nil,
    "MeshPart architecture must keep visible geometry render-only and use explicit simple collision proxies"
)
assert(
    string.find(source, '"ForgeAwningCollision"', 1, true) == nil
        and string.find(
                functionBody("makeForgeYard"),
                "placeArchitecturePrefabBuilding",
                1,
                true
            )
            ~= nil,
    "forge visible awning/roof must remain render-only under the MeshPart architecture collision contract"
)

print("Lumenreach collision coverage tests passed")
