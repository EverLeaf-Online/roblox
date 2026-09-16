local fs = require("@lune/fs")

local definitions = fs.readFile("src/server/Content/PublicEventDefinitions.luau")
local service = fs.readFile("src/server/Services/PublicEventService.luau")
local enemy = fs.readFile("src/server/Services/EnemyService.luau")
local spawner = fs.readFile("src/server/Services/EnemySpawnerService.luau")
local bootstrap = fs.readFile("src/server/bootstrap.server.luau")
local clientBootstrap = fs.readFile("src/client/bootstrap.client.luau")
local net = fs.readFile("src/shared/Net.luau")
local config = fs.readFile("src/shared/GameConfig.luau")
local store = fs.readFile("src/client/State/PublicEventStore.luau")
local hud = fs.readFile("src/client/UI/Components/PublicEventHud.luau")
local ui = fs.readFile("src/client/Controllers/ReactUIController.luau")
local quests = fs.readFile("src/server/Content/QuestDefinitions.luau")
local npcs = fs.readFile("src/server/Content/NpcDefinitions.luau")

for _, token in
    {
        "greenway_breach = table.freeze",
        "glowmere_surge = table.freeze",
        "eastbridge_assault = table.freeze",
        'DisplayName = "Greenway Breach"',
        'MonsterId = "lumen_mossling"',
        'MonsterId = "slime"',
        'MonsterId = "peco_peco"',
        'MonsterId = "brambleback"',
        'MonsterId = "royal_glowcap"',
        "Exp = 120",
        "Shards = 10",
    }
do
    assert(string.find(definitions, token, 1, true), "public event definition missing " .. token)
end

for _, token in
    {
        "PublicEventService.Start",
        "AutoRespawn = false",
        "GroundToTerrain = true",
        "Participants = {}",
        'QuestObjectiveService.Record(profile, "PublicEvent", state.Id, 1)',
        'enemy:SetAttribute("PublicEventId", state.Id)',
        "eligibleUserIds",
        "RewardService.Grant",
        "recipientCount(definition.RegionId)",
        "PublicEventService.SendSnapshot",
        "nextConfiguredEventId",
        "definition.StartText",
        "state.Definition.SuccessText",
        "state.Definition.FailureText",
    }
do
    assert(string.find(service, token, 1, true), "public event service missing invariant " .. token)
end

assert(
    string.find(enemy, "eligibleUserIds", 1, true)
        and string.find(spawner, "eligibleUserIds", 1, true),
    "enemy contribution identities must reach public event death callbacks"
)
assert(string.find(config, "GameConfig.PublicEvents", 1, true), "public event tuning missing")
assert(
    string.find(config, "CooldownSeconds = 300", 1, true),
    "public event cooldown tuning missing"
)
assert(
    string.find(
        config,
        'Order = { "greenway_breach", "glowmere_surge", "eastbridge_assault" }',
        1,
        true
    ),
    "public event rotation order missing"
)
assert(
    string.find(net, 'PublicEvent = "PublicEvent"', 1, true),
    "public event network contract missing"
)
assert(
    string.find(bootstrap, "PublicEventService.Init()", 1, true),
    "public event service must initialize"
)
assert(
    string.find(bootstrap, "publicEvent:FireClient", 1, true),
    "server must replicate event state"
)
assert(
    string.find(bootstrap, "PublicEventService.SendSnapshot(player)", 1, true),
    "joining players must receive an active event snapshot"
)
assert(
    string.find(
        clientBootstrap,
        "publicEvent.OnClientEvent:Connect(PublicEventStore.Push)",
        1,
        true
    ),
    "client must consume public event network messages"
)
assert(string.find(store, 'payload.Type == "Started"', 1, true), "event store missing start state")
assert(
    string.find(store, 'payload.Type == "Completed"', 1, true),
    "event store missing completion state"
)
assert(string.find(hud, "HOSTILES REMAIN", 1, true), "public event HUD missing combat progress")
assert(
    string.find(hud, "LocalReceivedAt", 1, true),
    "event HUD countdown must be local-time stable"
)
assert(string.find(ui, "PublicEventHud", 1, true), "main React UI must render public event HUD")
assert(
    string.find(quests, 'Type = "PublicEvent", Target = "greenway_breach"', 1, true),
    "quest content must use the public event objective"
)
assert(
    string.find(npcs, '"greenway_breach_watch"', 1, true),
    "the Greenway defense quest must be offered by an NPC"
)

print("public event rules tests passed")
