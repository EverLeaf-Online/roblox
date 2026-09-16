local fs = require("@lune/fs")

local source = fs.readFile("src/server/Services/LumenreachWorldService.luau")

local builders = {
    "makeBridge",
    "makeWaystone",
    "makeLantern",
    "makeSign",
    "makeBuilding",
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

for _, name in builders do
    local body = functionBody(name)
    assert(
        string.find(body, "makeCollisionProxy(", 1, true) ~= nil,
        name .. " creates physical world geometry without an explicit collision proxy"
    )
end

local normalizer = functionBody("normalizeGeneratedCollisions")
assert(
    string.find(normalizer, "descendant.CanCollide = false", 1, true) ~= nil
        and string.find(normalizer, "descendant.CanCollide = true", 1, true) ~= nil,
    "collision normalizer must force render parts non-solid and proxies solid"
)

for _, required in
    {
        '"SignBoardCollision"',
        '"BuildingRoofCollision"',
        '"MarketCanopyCollision"',
        '"ShelterRoofCollision"',
        '"ArchRoofCollision"',
        '"ForgeAwningCollision"',
        '"StiltRoofCollision"',
        '"TownGateBeamCollision"',
    }
do
    assert(
        string.find(source, required, 1, true) ~= nil,
        "missing rigid-surface collision proxy: " .. required
    )
end

print("Lumenreach collision coverage tests passed")
