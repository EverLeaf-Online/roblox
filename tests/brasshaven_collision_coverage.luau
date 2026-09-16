local fs = require("@lune/fs")

local source = fs.readFile("src/server/Services/BrasshavenWorldService.luau")

assert(
    string.find(source, "part.CanCollide = false", 1, true) ~= nil
        and string.find(source, "part.CanTouch = false", 1, true) ~= nil
        and string.find(source, "part.CanQuery = false", 1, true) ~= nil,
    "Brasshaven render parts must default non-physical"
)
assert(
    string.find(source, "local function makeCollisionProxy", 1, true) ~= nil
        and string.find(source, 'proxy:SetAttribute("EverLeafCollisionProxy", true)', 1, true) ~= nil
        and string.find(source, "proxy.CanCollide = true", 1, true) ~= nil
        and string.find(source, "proxy.CanQuery = true", 1, true) ~= nil,
    "Brasshaven must use explicit queryable collision proxies"
)

for _, required in
    {
        '"BrasshavenGroundCollision"',
        '"BrasshavenNorthWallCollision"',
        '"BrasshavenSouthWallCollision"',
        '"BrasshavenEastWallCollision"',
        '"BrasshavenWestWallCollision"',
        '"ForgeTowerCollision"',
        '"ReturnGatePillarCollision"',
        '"VendorCounterCollision"',
        '"BelforgeGatePillarCollision"',
        '"BelforgeDoorCollision"',
        '"AntechamberFloorCollision"',
        '"AntechamberNorthWallCollision"',
        '"AntechamberSouthWallCollision"',
        '"AntechamberFarWallCollision"',
        '"ColossusSealCollision"',
        '"ArenaFloorCollision"',
        '"ArenaNorthWallCollision"',
        '"ArenaSouthWallCollision"',
        '"ArenaEastWallCollision"',
        '"ArenaWestWallCollision"',
        '"ArenaColumnCollision"',
        '"ScrapPileCollision"',
        '"ScrapLanePostCollision"',
        '"GearworksWheelCollision"',
        '"CinderPipeCollision"',
        '"RegulatorCollision"',
        '"DeadShiftLockerCollision"',
        '"DynamoCoilCollision"',
        '"BlueglassLensCollision"',
        '"MaintenanceArmCollision"',
        '"CrucibleCollision"',
        '"FluxPrismCollision"',
        '"AuthorityColumnCollision"',
        '"BellowsPistonCollision"',
        '"SentinelBarricadeCollision"',
    }
do
    assert(
        string.find(source, required, 1, true) ~= nil,
        "missing Brasshaven collision coverage: " .. required
    )
end

local explicitTrueCount = 0
for _ in string.gmatch(source, "CanCollide%s*=%s*true") do
    explicitTrueCount += 1
end
assert(
    explicitTrueCount == 2,
    "Brasshaven should only enable collision inside the proxy helper/normalizer"
)
assert(
    string.find(source, "normalizeGeneratedCollisions(world)", 1, true) ~= nil,
    "Brasshaven must run collision normalization after generated content is assembled"
)
assert(
    string.find(source, "spawn.CanCollide = false", 1, true) ~= nil
        and string.find(source, "spawn.CanQuery = false", 1, true) ~= nil,
    "Brasshaven spawn marker must not behave like a physical platform"
)

print("Brasshaven collision coverage tests passed")
