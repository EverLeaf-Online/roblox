local fs = require("@lune/fs")

local registry = fs.readFile("src/server/Content/MonsterAssetRegistry.luau")
local template = fs.readFile("src/server/Services/MonsterTemplateService.luau")
local animation = fs.readFile("src/server/Services/MonsterAnimationService.luau")

assert(
    string.find(template, "assetSpec.Parents", 1, true),
    "authored parent hierarchy must be supported"
)
assert(
    string.find(template, "parentPart.CFrame:ToObjectSpace(part.CFrame)", 1, true),
    "attachment offsets must be calculated relative to the authored parent segment"
)
for _, monsterId in
    {
        "furnace_husk",
        "foundry_reaver",
        "smelter_golem",
        "ironclad_enforcer",
        "bellows_titan",
        "belforge_sentinel",
        "belforge_colossus",
    }
do
    assert(
        string.find(registry, monsterId .. " = {", 1, true),
        "missing humanoid authored monster " .. monsterId
    )
end
assert(
    string.find(animation, 'smelter_golem = "skeleton"', 1, true),
    "Smelter Golem must animate as a segmented humanoid, not a slime"
)
assert(
    string.find(animation, 'bellows_titan = "skeleton"', 1, true),
    "Bellows Titan must animate as a segmented humanoid, not a slime"
)
assert(
    string.find(registry, 'ColossusHammerHead = "RightArm"', 1, true),
    "Colossus hammer must follow its attack arm"
)
assert(
    string.find(registry, 'LeftShield = "LeftArm"', 1, true),
    "Sentinel shield must follow its shield arm"
)
print("authored monster rig rules tests passed")
