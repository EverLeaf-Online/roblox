local fs = require("@lune/fs")

local lumen = fs.readFile("src/server/Services/LumenreachWorldService.luau")
local brass = fs.readFile("src/server/Services/BrasshavenWorldService.luau")

assert(
    string.find(lumen, "local function makeWorldMMOComposition", 1, true),
    "Lumenreach whole-map composition pass missing"
)
assert(
    string.find(lumen, "makeWorldMMOComposition(parent)", 1, true),
    "Lumenreach composition pass is not wired"
)
for _, district in
    {
        "Greenway",
        "Crossroads",
        "Glowmere",
        "Eastbridge",
        "Gravebone",
        "Mossglen",
        "Sunmoss",
        "Veilfall",
        "ShatteredArch",
        "Proving",
    }
do
    assert(
        string.find(lumen, 'Name = "' .. district .. '"', 1, true),
        "Lumenreach MMO court missing " .. district
    )
end
assert(
    string.find(lumen, 'model:SetAttribute("MMOComposition", true)', 1, true),
    "Lumenreach courts must identify authored MMO composition"
)

assert(
    string.find(brass, "local function makeBrasshavenMMOComposition", 1, true),
    "Brasshaven whole-map composition pass missing"
)
assert(
    string.find(brass, "makeBrasshavenMMOComposition(world)", 1, true),
    "Brasshaven composition pass is not wired"
)
for _, district in
    {
        "Threshold",
        "Gearworks",
        "Cinder",
        "Sootworks",
        "Dynamo",
        "Rail",
        "Blueglass",
        "Smelter",
        "Authority",
        "Runoff",
        "Bellows",
        "Sentinel",
    }
do
    assert(
        string.find(brass, 'Name = "' .. district .. '"', 1, true),
        "Brasshaven MMO court missing " .. district
    )
end
assert(
    string.find(brass, 'world:SetAttribute("MMOCompositionPass", true)', 1, true),
    "Brasshaven generated world must advertise the MMO composition pass"
)
print("whole-world MMO composition rules tests passed")
