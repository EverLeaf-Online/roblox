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
    string.find(monsters, 'VisualSource", "authored"', 1, true),
    "monster authored visuals must be tagged"
)
assert(
    string.find(monsters, 'VisualSource", "legacy_procedural_fallback"', 1, true),
    "legacy monster visuals must be explicit fallback"
)
assert(
    string.find(monsterRegistry, "Production monster visuals should be authored models", 1, true),
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

print("production visual asset pipeline rules tests passed")
