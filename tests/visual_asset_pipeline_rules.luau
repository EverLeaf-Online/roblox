local fs = require("@lune/fs")

local monsters = fs.readFile("src/server/Services/MonsterTemplateService.luau")
local npcs = fs.readFile("src/server/Services/StylizedNpcFactory.luau")
local monsterRegistry = fs.readFile("src/server/Content/MonsterAssetRegistry.luau")
local npcRegistry = fs.readFile("src/server/Content/NpcAssetRegistry.luau")

assert(
    string.find(monsters, "AuthoredMonsterTemplates", 1, true),
    "monster visuals must prefer authored templates"
)
assert(
    string.find(monsters, 'assetSpec.Status == "reviewed"', 1, true),
    "monster authored visuals require review state"
)
assert(
    string.find(monsters, 'VisualSource", "authored_serverstorage"', 1, true),
    "monster authored visuals must be tagged"
)
assert(
    string.find(monsters, 'VisualSource", "legacy_procedural_fallback"', 1, true),
    "legacy monster visuals must be explicit fallback"
)
assert(
    string.find(monsterRegistry, "Canonical production monster visual registry", 1, true),
    "monster visual registry policy missing"
)

assert(
    string.find(npcs, "AuthoredNpcTemplates", 1, true),
    "NPC visuals must prefer authored templates"
)
assert(
    string.find(npcs, 'assetSpec.Status ~= "reviewed"', 1, true),
    "NPC authored visuals require review state"
)
assert(
    string.find(npcs, 'VisualSource", "authored"', 1, true),
    "NPC authored visuals must be tagged"
)
assert(
    string.find(npcs, 'VisualSource", "generated_r15_fallback"', 1, true),
    "generated R15 NPCs must be explicit fallback"
)
assert(
    string.find(
        npcRegistry,
        "Production NPC visuals should be reviewed authored R15 models",
        1,
        true
    ),
    "NPC visual registry policy missing"
)

for _, token in
    {
        "111556426711525",
        "139841213411079",
        "123954746000436",
        "89263541500191",
        "80182968126504",
    }
do
    assert(
        string.find(monsterRegistry, token, 1, true),
        "starter authored monster asset missing " .. token
    )
end
assert(
    string.find(monsters, "InsertService:LoadAsset", 1, true)
        or string.find(monsters, "pcall(InsertService.LoadAsset", 1, true),
    "reviewed monster assets must load through InsertService"
)
assert(
    string.find(monsters, "sanitizeAuthoredAsset", 1, true),
    "authored monster assets must be sanitized"
)
assert(
    string.find(monsters, 'VisualSource", "authored_asset"', 1, true),
    "runtime authored monster source tag missing"
)

print("production visual asset pipeline rules tests passed")
