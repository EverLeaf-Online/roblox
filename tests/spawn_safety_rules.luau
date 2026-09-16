local fs = require("@lune/fs")

local travel = fs.readFile("src/server/Services/WorldTravelService.luau")
local bootstrap = fs.readFile("src/server/bootstrap.server.luau")
local lumenreach = fs.readFile("src/server/Services/LumenreachWorldService.luau")
local brasshaven = fs.readFile("src/server/Services/BrasshavenWorldService.luau")

assert(string.find(travel, "resolveSafeSpawnCFrame", 1, true), "safe spawn floor resolver missing")
assert(
    string.find(travel, "Workspace:Raycast", 1, true),
    "safe spawn must raycast the actual floor"
)
assert(
    string.find(travel, "humanoid.HipHeight", 1, true),
    "safe spawn must account for avatar HipHeight"
)
assert(
    string.find(travel, "SAFE_FLOOR_PADDING", 1, true),
    "safe spawn needs floor clearance padding"
)
assert(
    string.find(bootstrap, "WorldTravelService.Teleport(player, profile.World.SpawnId", 1, true),
    "CharacterAdded must settle respawns through WorldTravelService"
)
assert(
    string.find(bootstrap, "SkipStreamingPrefetch = true", 1, true),
    "respawn settle should not redundantly block on streaming prefetch"
)
assert(
    string.find(lumenreach, "Vector3.new(0, 3.25, 0)", 1, true),
    "Lumenreach native SpawnLocations must be lifted clear of terrain"
)
assert(
    string.find(brasshaven, "Vector3.new(-38, 3.25, 0)", 1, true),
    "invisible Brasshaven interior SpawnLocations must be lifted clear of floors"
)

assert(
    string.find(bootstrap, "Players.CharacterAutoLoads = false", 1, true),
    "initial character auto-load must be disabled until profile/world spawn data is ready"
)
assert(
    string.find(bootstrap, "syncPlayerWorld(player, profileOrReason, false)", 1, true),
    "join flow must resolve RespawnLocation before creating the first character"
)
assert(
    string.find(bootstrap, "player:LoadCharacter()", 1, true),
    "join flow must explicitly create the character after selecting its spawn"
)
local deathService = fs.readFile("src/server/Services/DeathService.luau")
assert(
    string.find(deathService, "task.delay(Players.RespawnTime", 1, true)
        and string.find(deathService, "player:LoadCharacter()", 1, true),
    "manual character lifecycle must preserve respawning after death"
)

print("spawn safety rules tests passed")
