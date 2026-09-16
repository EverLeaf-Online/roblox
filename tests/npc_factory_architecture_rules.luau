local fs = require("@lune/fs")

local production = fs.readFile("src/server/Services/StylizedNpcFactory.luau")
local fallback = fs.readFile("src/server/Services/GeneratedNpcFallbackFactory.luau")

assert(
    not string.find(production, "local function addClothingLayers", 1, true),
    "production NPC factory must not own generated fallback clothing geometry"
)
assert(
    not string.find(production, "local function makeHair", 1, true),
    "production NPC factory must stay authored-asset focused"
)
assert(
    string.find(production, "GeneratedNpcFallbackFactory.CreateBase", 1, true),
    "NPC factory must isolate generated fallback construction"
)
assert(
    string.find(production, "GeneratedNpcFallbackFactory.Decorate", 1, true),
    "NPC fallback decoration must be isolated"
)
assert(
    string.find(fallback, "function GeneratedNpcFallbackFactory.CreateBase", 1, true),
    "generated NPC fallback must expose a base-rig boundary"
)
assert(
    string.find(fallback, "function GeneratedNpcFallbackFactory.Decorate", 1, true),
    "generated NPC fallback must expose a decoration boundary"
)
print("NPC factory architecture rules tests passed")
