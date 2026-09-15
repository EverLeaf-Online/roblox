local fs = require("@lune/fs")

local source = fs.readFile("src/server/Services/LumenreachWorldService.luau")

for _, required in
    {
        "local WORLD_WIDTH = 2200",
        "local WORLD_DEPTH = 1700",
        "local STARTER_FIELD_ORIGIN",
        "local BRAMBLE_TRAIL_ORIGIN",
        "local ROAD_NETWORK",
        "local function makeWayfarerHall",
        "local function makeServiceStall",
        "GREENWAY FIELDS",
        "MOSSGLEN VALLEY",
        "VEILFALL RAVINE",
        "SHATTERED LUMEN ARCH",
    }
do
    assert(
        string.find(source, required, 1, true) ~= nil,
        "missing redesigned Lumenreach contract: " .. required
    )
end

for _, routeId in
    {
        "greenway",
        "proving_spur",
        "moss_hollow",
        "eastbridge",
        "gravebone_watch",
        "mossglen",
        "glowmere_out",
        "glowmere_return",
        "sunmoss_up",
        "ruins_main",
        "veilfall_down",
        "veilfall_return",
        "sunmoss_return",
    }
do
    assert(
        string.find(source, 'Id = "' .. routeId .. '"', 1, true) ~= nil,
        "missing MMO route: " .. routeId
    )
end

assert(
    string.find(source, "local WORLD_WIDTH = 900", 1, true) == nil,
    "old showcase map width returned"
)
assert(
    string.find(source, "local WORLD_DEPTH = 760", 1, true) == nil,
    "old showcase map depth returned"
)
assert(
    string.find(source, "makeRuins(world, WORLD_ZONES.Ruins)", 1, true) ~= nil,
    "far-edge Shattered Arch / Brasshaven capstone must remain authored"
)
assert(
    string.find(source, "for _, route in ROAD_NETWORK do", 1, true) ~= nil,
    "terrain/travel logic must consume the canonical road network"
)
assert(
    string.find(source, 'CollectionService:AddTag(marker, "MMOZone")', 1, true) ~= nil,
    "redesigned subzones expose MMOZone metadata for future map/UI systems"
)
assert(
    string.find(source, 'makeZoneMarker(\n        world,\n        "gravebone_watch"', 1, true)
        ~= nil,
    "midgame Gravebone Watch subzone remains authored"
)
assert(
    string.find(
        source,
        'Id = "gravebone_captain",\n        Center = GRAVEBONE_WATCH_ORIGIN + Vector3.new(30, 0, -20)',
        1,
        true
    ) ~= nil,
    "Gravebone Captain protection must follow the midgame Gravebone Watch encounter"
)
assert(
    string.find(
        source,
        "local ARRIVAL_SPAWN_ORIGIN = WORLD_ZONES.Camp + Vector3.new(-100, 0, 15)",
        1,
        true
    ) ~= nil,
    "town arrival must remain isolated from lodging/tent footprints"
)

local quests = fs.readFile("src/server/Content/QuestDefinitions.luau")
assert(
    string.find(quests, 'Target = "gravebone_watch"', 1, true) ~= nil
        and string.find(quests, 'Target = "eastbridge_crossing"', 1, true) ~= nil
        and string.find(quests, 'Target = "mossglen_valley"', 1, true) ~= nil,
    "early exploration progression must follow the redesigned MMO route"
)

print("Lumenreach MMO layout rules tests passed")
