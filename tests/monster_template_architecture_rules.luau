local fs = require("@lune/fs")

local production = fs.readFile("src/server/Services/MonsterTemplateService.luau")
local fallback = fs.readFile("src/server/Services/LegacyMonsterFallbackFactory.luau")

assert(
    not string.find(production, "local function buildSkeleton", 1, true),
    "production monster loader must not own procedural monster bodies"
)
assert(
    not string.find(production, "local function makePart", 1, true),
    "production monster loader must stay asset-focused"
)
assert(
    string.find(production, "LegacyMonsterFallbackFactory.Build", 1, true),
    "production monster loader must isolate fallback construction"
)
assert(
    string.find(production, "for monsterId in MonsterConfig.All() do", 1, true),
    "template initialization must cover the full monster catalog"
)
assert(
    string.find(fallback, "function LegacyMonsterFallbackFactory.Build", 1, true),
    "fallback module must expose a single build boundary"
)
for _, builder in
    {
        "buildTrainingDummy",
        "buildSkeleton",
        "buildRoyalGlowcap",
        "buildBelforgeColossus",
        "buildMosswarden",
    }
do
    assert(string.find(fallback, builder, 1, true), "legacy fallback factory missing " .. builder)
end
print("monster template architecture rules tests passed")
