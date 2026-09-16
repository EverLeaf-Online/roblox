local fs = require("@lune/fs")

local files = {
    "src/client/Controllers/CameraController.luau",
    "src/server/Services/LumenreachWorldService.luau",
    "src/server/Services/LumenreachTerrainBuilder.luau",
    "src/server/Services/LumenreachGameplayService.luau",
    "src/server/Services/MonsterAttackHitboxService.luau",
    "src/server/Services/MonsterSpawnService.luau",
    "src/server/Services/EnemySpawnerService.luau",
    "src/server/Services/ProjectileService.luau",
    "src/server/Services/TargetingService.luau",
    "src/server/Services/WorldGroundingService.luau",
    "src/server/Services/WorldTravelService.luau",
    "src/server/Services/StylizedNpcFactory.luau",
}

for _, path in files do
    local source = fs.readFile(path)
    assert(
        string.find(source, "IgnoreWater = false", 1, true) == nil,
        path .. " must not treat traversable water as solid raycast geometry"
    )
end

local world = fs.readFile("src/server/Services/LumenreachWorldService.luau")
local terrainBuilder = fs.readFile("src/server/Services/LumenreachTerrainBuilder.luau")
assert(
    string.find(terrainBuilder, "Enum.Material.Water", 1, true) ~= nil
        and string.find(terrainBuilder, "carveGorge", 1, true) ~= nil
        and string.find(terrainBuilder, "Glowmere's wetland", 1, true) ~= nil,
    "Lumenreach must retain real Terrain water in the gorge and Glowmere wetland"
)
assert(
    string.find(world, "water.CanCollide = false", 1, true) ~= nil
        and string.find(world, "water.CanQuery = false", 1, true) ~= nil,
    "decorative well water must never become a hidden solid"
)
assert(
    string.find(world, '"WaterAnchorBottom"', 1, true) ~= nil
        and string.find(world, '"WaterAnchorTop"', 1, true) ~= nil,
    "Veilfall waterfall must remain visual beam-based water rather than physical slabs"
)

local allSource = ""
for _, path in files do
    allSource ..= fs.readFile(path)
end
assert(
    string.find(allSource, "HumanoidStateType.Swimming", 1, true) == nil,
    "current movement code must not disable or override Roblox swimming state"
)

local gorgeStart = assert(string.find(terrainBuilder, "local function carveGorge", 1, true))
local gorgeEnd = assert(
    string.find(terrainBuilder, "\nfunction LumenreachTerrainBuilder.Build", gorgeStart + 1, true)
)
local gorge = string.sub(terrainBuilder, gorgeStart, gorgeEnd - 1)
local rockAt = assert(string.find(gorge, "Enum.Material.Rock", 1, true))
local waterAt = assert(string.find(gorge, "Enum.Material.Water", 1, true))
assert(rockAt < waterAt, "gorge rock lining must be completed before the final water pass")
assert(
    string.find(gorge, "samplesBySegment", 1, true) ~= nil,
    "gorge must retain samples for a separate final water pass"
)
assert(
    string.find(gorge, "Vector3.new(0, -4, 0), 19, Enum.Material.Air", 1, true) ~= nil,
    "gorge must recut a continuous inner channel before refilling water"
)

print("water collision rules tests passed")
