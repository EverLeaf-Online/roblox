local fs = require("@lune/fs")

local config = fs.readFile("src/server/Content/BrasshavenWorldConfig.luau")
local world = fs.readFile("src/server/Services/BrasshavenWorldService.luau")
local events = fs.readFile("src/server/Content/PublicEventDefinitions.luau")

for _, token in
    {
        "Origin = origin",
        "BelforgeAntechamberOrigin",
        "BelforgeArenaOrigin",
        "ScrapLanes = origin + Vector3.new(-22, 0, -56)",
        "BlueglassAnnex = origin + Vector3.new(-72, 0, 235)",
        "AuthorityHall = origin + Vector3.new(-12, 0, 325)",
        'GeneratedWorldName = "EverLeafGeneratedBrasshaven"',
        'GroundSurfaceName = "BrasshavenGroundCollision"',
    }
do
    assert(string.find(config, token, 1, true), "Brasshaven spatial config missing " .. token)
end
assert(
    string.find(world, "BrasshavenWorldConfig.EncounterCenters", 1, true)
        and string.find(world, "ENCOUNTERS.ScrapLanes", 1, true)
        and string.find(world, "ENCOUNTERS.BlueglassAnnex", 1, true)
        and string.find(world, "ENCOUNTERS.AuthorityHall", 1, true),
    "Brasshaven encounter dressing must consume canonical encounter anchors"
)
assert(
    string.find(events, "BrasshavenWorldConfig", 1, true)
        and string.find(events, "Center = BRASS.ScrapLanes", 1, true)
        and string.find(events, "Center = BRASS.BlueglassAnnex", 1, true)
        and string.find(events, "Center = BRASS.AuthorityHall", 1, true),
    "Brasshaven public events must use canonical map anchors"
)

print("Brasshaven world config rules tests passed")
