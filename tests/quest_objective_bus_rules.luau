local fs = require("@lune/fs")

local bus = fs.readFile("src/server/Services/QuestObjectiveService.luau")
local enemy = fs.readFile("src/server/Services/EnemyService.luau")
local exploration = fs.readFile("src/server/Services/ExplorationService.luau")
local activity = fs.readFile("src/server/Services/LumenreachActivityService.luau")
local loot = fs.readFile("src/server/Services/LootDropService.luau")

for _, objectiveType in
    { "Defeat", "Collect", "Explore", "Interact", "Craft", "Use", "Reach", "Escort", "Survive" }
do
    assert(
        string.find(bus, objectiveType .. " = true", 1, true),
        "objective bus missing type " .. objectiveType
    )
end
assert(
    string.find(enemy, 'QuestObjectiveService.Record(profile, "Defeat"', 1, true),
    "enemy quest progress must use objective bus"
)
assert(
    string.find(exploration, 'QuestObjectiveService.Record(profile, "Explore"', 1, true),
    "exploration quest progress must use objective bus"
)
assert(
    string.find(activity, 'QuestObjectiveService.Record(profile, "Collect"', 1, true),
    "gather quest progress must use objective bus"
)

assert(
    string.find(loot, 'QuestObjectiveService.Record(profile, "Collect"', 1, true),
    "loot collection quest progress must use objective bus"
)

print("quest objective bus rules tests passed")
