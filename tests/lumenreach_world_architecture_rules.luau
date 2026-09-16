local fs = require("@lune/fs")

local world = fs.readFile("src/server/Services/LumenreachWorldService.luau")
local terrain = fs.readFile("src/server/Services/LumenreachTerrainBuilder.luau")

assert(
    string.find(world, "require(script.Parent.LumenreachTerrainBuilder)", 1, true),
    "Lumenreach world orchestration must delegate terrain ownership"
)
assert(
    string.find(world, "LumenreachTerrainBuilder.Build({", 1, true),
    "Lumenreach world must build terrain through the dedicated terrain module"
)
assert(
    string.find(world, "local flattenTerrain = LumenreachTerrainBuilder.FlattenTerrain", 1, true),
    "settlement floor shaping must reuse the terrain module instead of duplicating terrain helpers"
)
assert(
    string.find(
        world,
        "local fillTerrainRoute = LumenreachTerrainBuilder.FillTerrainRoute",
        1,
        true
    ),
    "district road shaping must reuse the terrain module"
)
for _, invariant in
    {
        "function LumenreachTerrainBuilder.FlattenTerrain",
        "function LumenreachTerrainBuilder.FillTerrainRoute",
        "local function fillMountainRidge",
        "local function carveGorge",
        "function LumenreachTerrainBuilder.Build",
    }
do
    assert(string.find(terrain, invariant, 1, true), "terrain builder missing " .. invariant)
end
assert(#world < 192000, "LumenreachWorldService regressed above terrain-decomposition size budget")
assert(#terrain < 14000, "terrain module became too broad; keep it focused on terrain topology")

print("Lumenreach world architecture rules tests passed")
