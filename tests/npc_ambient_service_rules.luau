local fs = require("@lune/fs")

local service = fs.readFile("src/server/Services/NpcAmbientService.luau")
local bootstrap = fs.readFile("src/server/bootstrap.server.luau")
local world = fs.readFile("src/server/Services/LumenreachWorldService.luau")

assert(
    string.find(service, "PathfindingService:CreatePath", 1, true),
    "ambient NPCs must navigate paths, not tween blindly through buildings"
)
assert(
    string.find(service, "AgentCanJump = false", 1, true),
    "ambient routes must stay on walkable ground"
)
assert(
    string.find(service, "params.IgnoreWater = true", 1, true),
    "ambient land NPCs must not choose water surfaces"
)
assert(
    string.find(service, "root.Anchored = true", 1, true),
    "ambient NPC roots must remain server-authoritative"
)
assert(
    string.find(service, "root.CanCollide = false", 1, true),
    "ambient NPCs must not body-block players"
)
assert(
    string.find(service, 'AmbientActivityState", "Walking"', 1, true),
    "ambient NPC walking state missing"
)
assert(string.find(service, "MAX_PATH_WAYPOINTS", 1, true), "ambient route length must be bounded")
assert(
    string.find(bootstrap, "NpcAmbientService.Init()", 1, true),
    "ambient NPC service is not initialized"
)
assert(
    string.find(world, 'model:SetAttribute("AmbientResident", true)', 1, true),
    "world residents must opt into ambient activity"
)
print("NPC ambient activity rules tests passed")
