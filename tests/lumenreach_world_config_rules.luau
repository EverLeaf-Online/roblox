local fs = require("@lune/fs")

local config = fs.readFile("src/server/Content/LumenreachWorldConfig.luau")
local world = fs.readFile("src/server/Services/LumenreachWorldService.luau")
local gameplay = fs.readFile("src/server/Services/LumenreachGameplayService.luau")
local events = fs.readFile("src/server/Content/PublicEventDefinitions.luau")

for _, token in
    {
        "WorldWidth = 2200",
        "WorldDepth = 1250",
        "DesignVersion = 29",
        "Camp = Vector3.new(-950, 2, 0)",
        "Greenway = Vector3.new(-720, 1, 40)",
        "Crossroads = Vector3.new(-480, 4, 50)",
        "Glowmere = Vector3.new(-420, -4, 430)",
        "EastLanding = Vector3.new(-120, 6, 90)",
        "Gravebone = Vector3.new(120, 6, -220)",
        "Mossglen = Vector3.new(130, 6, 300)",
        "Sunmoss = Vector3.new(500, 34, 430)",
        "Veilfall = Vector3.new(420, -18, -360)",
        "Ruins = Vector3.new(900, 10, 60)",
        "Proving = Vector3.new(-930, 4, -330)",
        'Id = "greenway"',
        'Id = "eastbridge_west"',
        'Id = "reedbridge_east"',
        "GorgePoints = gorgePoints",
        "DressingExclusions = dressingExclusions",
    }
do
    assert(string.find(config, token, 1, true), "canonical Lumenreach config missing " .. token)
end

for name, source in
    {
        WorldService = world,
        GameplayService = gameplay,
        PublicEvents = events,
    }
do
    assert(
        string.find(source, "LumenreachWorldConfig", 1, true),
        name .. " must consume the canonical Lumenreach spatial contract"
    )
end

assert(
    not string.find(gameplay, "Camp = Vector3.new(-950, 2, 0)", 1, true),
    "gameplay service must not duplicate canonical zone coordinates"
)
assert(
    not string.find(events, "Center = Vector3.new(-720, 2, 40)", 1, true)
        and not string.find(events, "Center = Vector3.new(-420, 0, 430)", 1, true)
        and not string.find(events, "Center = Vector3.new(-120, 8, 90)", 1, true),
    "public event centers must derive from canonical zone coordinates"
)
assert(
    string.find(events, "Center = ZONES.Greenway + Vector3.new(0, 1, 0)", 1, true)
        and string.find(events, "Center = ZONES.Glowmere + Vector3.new(0, 4, 0)", 1, true)
        and string.find(events, "Center = ZONES.EastLanding + Vector3.new(0, 2, 0)", 1, true),
    "public events must stay spatially attached to their authored zone anchors"
)

print("Lumenreach world config rules tests passed")
