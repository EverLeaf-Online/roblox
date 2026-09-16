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
    string.find(npcs, 'VisualSource", "authored_serverstorage"', 1, true),
    "NPC authored ServerStorage visuals must be tagged"
)
assert(
    string.find(npcs, 'VisualSource", "authored_asset"', 1, true),
    "runtime authored NPC asset source tag missing"
)
assert(
    string.find(npcs, 'VisualSource", "generated_r15_fallback"', 1, true),
    "generated R15 NPCs must be explicit fallback"
)
assert(
    string.find(npcRegistry, "Canonical production NPC visual registry", 1, true),
    "NPC visual registry policy missing"
)
for _, token in
    {
        "106620969880813",
        "72467646496046",
        "120296033309062",
        "74873617387258",
        "71702053408362",
    }
do
    assert(string.find(npcRegistry, token, 1, true), "hero authored NPC asset missing " .. token)
end
assert(
    string.find(npcs, "InsertService.LoadAsset", 1, true),
    "reviewed NPC model assets must load through InsertService"
)
assert(
    string.find(npcs, "AUTHORED_R15_PARTS", 1, true),
    "authored NPC visuals must attach to the R15 animation skeleton"
)
assert(fs.isFile("scripts/generate_lumenreach_hero_npcs.py"), "hero NPC generator missing")
assert(fs.isFile("assets/original/lumenreach_hero_npcs/manifest.json"), "hero NPC manifest missing")
assert(
    fs.isFile("assets/original/lumenreach_hero_npcs/upload_results.json"),
    "hero NPC uploads missing"
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
