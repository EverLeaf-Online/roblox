local fs = require("@lune/fs")

local grounding = fs.readFile("src/server/Services/WorldGroundingService.luau")
local spawner = fs.readFile("src/server/Services/EnemySpawnerService.luau")
local events = fs.readFile("src/server/Services/PublicEventService.luau")

assert(
    string.find(grounding, "options.IncludeInstances", 1, true)
        and string.find(grounding, 'groundSource = "world_surface"', 1, true),
    "world grounding must support explicit authored floor surfaces"
)
assert(
    string.find(grounding, 'groundSource = "terrain"', 1, true),
    "terrain grounding must remain the default"
)
assert(
    string.find(spawner, "options.GroundInclude", 1, true)
        and string.find(spawner, "IncludeInstances = options.GroundInclude", 1, true),
    "enemy spawner must forward explicit world-surface grounding"
)
assert(
    string.find(events, "GroundSurfaceName", 1, true)
        and string.find(events, "GroundInclude = state.GroundInclude", 1, true),
    "public events must use explicit authored floor surfaces outside terrain regions"
)

print("world grounding surface rules tests passed")
