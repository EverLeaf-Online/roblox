local fs = require("@lune/fs")

local lumenreach = fs.readFile("src/server/Services/LumenreachWorldService.luau")
local brasshaven = fs.readFile("src/server/Services/BrasshavenWorldService.luau")
local spawner = fs.readFile("src/server/Services/MonsterSpawnService.luau")
local worldObjects = fs.readFile("src/server/Services/WorldObjectService.luau")
local portals = fs.readFile("src/server/Content/PortalDefinitions.luau")

for _, source in { lumenreach, brasshaven } do
    for _, attribute in
        {
            "MonsterType",
            "SpawnAmount",
            "TriggerRadius",
            "SpawnRadius",
            "MaxAliveMonster",
            "SpawnDelay",
            "RespawnTime",
        }
    do
        assert(
            string.find(source, 'trigger:SetAttribute("' .. attribute .. '"', 1, true) ~= nil,
            "monster spawn helper missing required attribute: " .. attribute
        )
    end
    assert(
        string.find(source, 'CollectionService:AddTag(trigger, "MonsterSpawnTrigger")', 1, true)
            ~= nil,
        "monster spawn helper must tag generated triggers"
    )
end

assert(
    string.find(spawner, 'trigger:GetAttribute("MonsterType") or "Skeleton"', 1, true) ~= nil,
    "MonsterSpawnService must retain a safe monster-type fallback"
)

for _, portalId in { "lumenreach_to_brasshaven", "brasshaven_to_lumenreach" } do
    assert(
        string.find(portals, portalId .. " = table.freeze", 1, true) ~= nil,
        "portal definition missing: " .. portalId
    )
end
assert(
    string.find(
        lumenreach,
        'WorldObjectService.Register(gate, "Portal", "lumenreach_to_brasshaven")',
        1,
        true
    ) ~= nil,
    "Lumenreach portal must be registered in WorldObjectService"
)
assert(
    string.find(
        brasshaven,
        'WorldObjectService.Register(gate, "Portal", "brasshaven_to_lumenreach")',
        1,
        true
    ) ~= nil,
    "Brasshaven portal must be registered in WorldObjectService"
)
assert(
    string.find(worldObjects, 'instance:SetAttribute("WorldObjectKind", kind)', 1, true) ~= nil
        and string.find(
                worldObjects,
                'instance:SetAttribute("WorldObjectId", objectId)',
                1,
                true
            )
            ~= nil,
    "registered world objects must expose debug attributes for Studio verification"
)

print("runtime world wiring rules tests passed")
