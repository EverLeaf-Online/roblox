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
        "120132451351149",
        "92390768634412",
        "89565715809321",
        "130773231745162",
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

assert(
    fs.isFile("scripts/generate_lumenreach_elite_monsters.py"),
    "elite monster generator missing"
)
assert(fs.isDir("assets/original/lumenreach_elite_monsters"), "elite monster source assets missing")
local eliteUploads = fs.readFile("assets/original/lumenreach_elite_monsters/upload_results.json")
assert(
    string.find(eliteUploads, '"moderation": "Approved"', 1, true),
    "elite monster assets must be approved"
)

for _, token in
    {
        "106620969880813",
        "72467646496046",
        "120296033309062",
        "74873617387258",
        "71702053408362",
        "111953812075306",
        "109433487392238",
        "120365137194208",
        "87049781819025",
        "116143660020194",
        "116327990771458",
        "99866941784802",
        "107603565473038",
        "117267887089651",
        "83906031250479",
    }
do
    assert(string.find(npcRegistry, token, 1, true), "named authored NPC asset missing " .. token)
end
assert(fs.isFile("scripts/generate_world_npcs_wave2.py"), "NPC wave2 generator missing")
assert(fs.isDir("assets/original/world_npcs_wave2"), "NPC wave2 source assets missing")
local npcWave2Uploads = fs.readFile("assets/original/world_npcs_wave2/upload_results.json")
assert(
    string.find(npcWave2Uploads, '"moderation": "Approved"', 1, true),
    "NPC wave2 assets must be approved"
)

print("production visual asset pipeline rules tests passed")
