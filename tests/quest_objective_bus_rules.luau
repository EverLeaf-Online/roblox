local fs = require("@lune/fs")

local bus = fs.readFile("src/server/Services/QuestObjectiveService.luau")
local enemy = fs.readFile("src/server/Services/EnemyService.luau")
local exploration = fs.readFile("src/server/Services/ExplorationService.luau")
local activity = fs.readFile("src/server/Services/LumenreachActivityService.luau")
local interaction = fs.readFile("src/server/Services/InteractionService.luau")
local consumable = fs.readFile("src/server/Services/ConsumableService.luau")
local ui = fs.readFile("src/client/Controllers/ReactUIController.luau")
local quests = fs.readFile("src/server/Content/QuestDefinitions.luau")
local loot = fs.readFile("src/server/Services/LootDropService.luau")
local publicEvent = fs.readFile("src/server/Services/PublicEventService.luau")

for _, objectiveType in
    {
        "Defeat",
        "Collect",
        "Explore",
        "Interact",
        "Craft",
        "Use",
        "Reach",
        "Escort",
        "Survive",
        "PublicEvent",
    }
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

assert(
    string.find(interaction, 'QuestObjectiveService.Record(profile, "Interact"', 1, true),
    "NPC interactions must progress Interact objectives"
)
assert(
    string.find(activity, 'QuestObjectiveService.Record(profile, "Craft"', 1, true),
    "crafting must progress Craft objectives"
)
assert(
    string.find(consumable, 'QuestObjectiveService.Record(profile, "Use"', 1, true),
    "consumables must progress Use objectives"
)
assert(
    string.find(exploration, 'QuestObjectiveService.Record(profile, "Reach"', 1, true),
    "landmarks must progress Reach objectives"
)
assert(
    string.find(publicEvent, 'QuestObjectiveService.Record(profile, "PublicEvent"', 1, true),
    "public events must progress PublicEvent objectives"
)
for _, token in
    {
        'Type = "Interact"',
        'Type = "Craft"',
        'Type = "Use"',
        'Type = "Reach"',
        'Type = "PublicEvent"',
    }
do
    assert(
        string.find(quests, token, 1, true),
        "quest content must actually use objective type " .. token
    )
end
for _, phrase in { "Talk to %s", "Craft %s", "Use %s", "Reach %s", "Complete %s" } do
    assert(
        string.find(ui, phrase, 1, true),
        "quest HUD missing readable objective wording " .. phrase
    )
end

print("quest objective bus rules tests passed")
