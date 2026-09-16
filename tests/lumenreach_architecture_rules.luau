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
        '"EntryTowerCollision"',
        '"LoadingPorchCollision"',
        '"ReadingDeckCollision"',
        '"InnPorchCollision"',
        '"HerbPorchCollision"',
        '"WorkshopPostCollision"',
        '"StablePostCollision"',
        '"PavilionPostCollision"',
        '"WayhouseOpenPostCollision"',
        '"BarnLeanPostCollision"',
        '"CottagePorchCollision"',
    }
do
    assert(
        string.find(source, token, 1, true) ~= nil,
        "missing archetype collision contract " .. token
    )
end

assert(
    string.find(source, "local WORLD_DESIGN_VERSION = 14", 1, true) ~= nil,
    "architecture conversion must bump world design version"
)
print("Lumenreach architecture rules tests passed")
