local fs = require("@lune/fs")

local function read(path)
    return fs.readFile(path)
end

local gameplay = read("src/server/Services/LumenreachGameplayService.luau")
local activity = read("src/server/Services/LumenreachActivityService.luau")
local world = read("src/server/Services/LumenreachWorldService.luau")
local quests = read("src/server/Content/QuestDefinitions.luau")
local npcs = read("src/server/Content/NpcDefinitions.luau")
local items = read("src/server/Content/ItemDefinitions.luau")
local recipes = read("src/server/Content/RecipeDefinitions.luau")
local bootstrap = read("src/server/bootstrap.server.luau")

for _, required in
    {
        'Type = "Gather"',
        'Type = "Craft"',
        'Type = "Rest"',
        'Type = "Cache"',
        'ItemId = "lumenleaf"',
        'ItemId = "glowreed"',
        'ItemId = "sunmoss_bloom"',
        'ItemId = "veilwater_crystal"',
        "makeApothecaryBench",
        "makeRestShrine",
        "makeWayfarerCache",
    }
do
    assert(
        string.find(gameplay, required, 1, true) ~= nil,
        "missing gameplay activity: " .. required
    )
end

assert(
    string.find(activity, "withinPromptRange", 1, true) ~= nil
        and string.find(activity, "prompt.MaxActivationDistance + 3", 1, true) ~= nil,
    "world activities must revalidate player distance server-side"
)
assert(
    string.find(activity, "ProfileTransaction.Run", 1, true) ~= nil
        and string.find(activity, "workingProfile.World.Secrets", 1, true) ~= nil,
    "one-time caches must be transactional and persistent"
)
assert(
    string.find(activity, 'QuestService.Record(profile, "Collect"', 1, true) ~= nil,
    "gathering must progress Collect quest objectives"
)
assert(
    string.find(bootstrap, "LumenreachGameplayService.Init()", 1, true) ~= nil,
    "Lumenreach gameplay activities must initialize after the world"
)

for _, itemId in { "lumenleaf", "glowreed", "sunmoss_bloom", "veilwater_crystal" } do
    assert(
        string.find(items, itemId .. " = table.freeze", 1, true) ~= nil,
        "missing item: " .. itemId
    )
end

for _, recipeId in { "small_tonic", "field_tonic" } do
    assert(
        string.find(recipes, recipeId .. " = table.freeze", 1, true) ~= nil,
        "missing recipe: " .. recipeId
    )
end

for _, questId in
    {
        "lumen_fieldcraft",
        "glowmere_reedwork",
        "sunmoss_observations",
        "veilfall_resonance",
    }
do
    assert(
        string.find(quests, questId .. " = table.freeze", 1, true) ~= nil,
        "missing quest: " .. questId
    )
end

for _, npcId in { "camp_healer", "glowmere_keeper", "sunmoss_researcher", "veilfall_warden" } do
    assert(
        string.find(npcs, npcId .. " = table.freeze", 1, true) ~= nil,
        "missing NPC definition: " .. npcId
    )
    assert(
        string.find(world, npcId .. " = table.freeze", 1, true) ~= nil,
        "missing NPC world style: " .. npcId
    )
end

local gatherNodeCount = 0
for _ in string.gmatch(gameplay, "makeLumenleaf%(") do
    gatherNodeCount += 1
end
for _ in string.gmatch(gameplay, "makeGlowreed%(") do
    gatherNodeCount += 1
end
for _ in string.gmatch(gameplay, "makeSunmossBloom%(") do
    gatherNodeCount += 1
end
for _ in string.gmatch(gameplay, "makeVeilCrystal%(") do
    gatherNodeCount += 1
end
assert(gatherNodeCount >= 8, "Lumenreach should contain multiple authored gather-node placements")

print("Lumenreach gameplay activity rules tests passed")
