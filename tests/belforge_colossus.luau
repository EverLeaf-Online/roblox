local BelforgeAccessRules = require("../src/shared/Logic/BelforgeAccessRules")
local BelforgeColossusRules = require("../src/shared/Logic/BelforgeColossusRules")
local BossDefinitions = require("../src/server/Content/BossDefinitions")
local DropTables = require("../src/server/Content/DropTableDefinitions")
local ItemDefinitions = require("../src/server/Content/ItemDefinitions")
local MonsterConfig = require("../src/server/Content/MonsterConfig")
local NpcDefinitions = require("../src/server/Content/NpcDefinitions")
local QuestDefinitions = require("../src/server/Content/QuestDefinitions")

local tierOne = {
    Level = 30,
    AdvancementTier = 1,
    Quests = { Completed = { belforge_gate_sentinel = true } },
}
local ok, reason = BelforgeAccessRules.CanEnterColossus(tierOne)
assert(
    not ok and reason == "second_advancement_required",
    "Colossus arena requires second advancement"
)

local tierTwo = {
    Level = 30,
    AdvancementTier = 2,
    Quests = { Completed = { belforge_gate_sentinel = true } },
}
ok, reason = BelforgeAccessRules.CanEnterColossus(tierTwo)
assert(ok and reason == nil, "qualified Tier-2 player can enter Colossus arena")

local phase, name = BelforgeColossusRules.PhaseForHealth(7200, 7200)
assert(phase == 1 and name == "Pressure Rising", "full-health Colossus starts Phase 1")
phase, name = BelforgeColossusRules.PhaseForHealth(5040, 7200)
assert(phase == 2 and name == "Furnace Breach", "70 percent health enters Phase 2")
phase, name = BelforgeColossusRules.PhaseForHealth(2520, 7200)
assert(phase == 3 and name == "Critical Overheat", "35 percent health enters Phase 3")
assert(
    BelforgeColossusRules.SpecialInterval(1) > BelforgeColossusRules.SpecialInterval(2),
    "Phase 2 specials accelerate"
)
assert(
    BelforgeColossusRules.SpecialInterval(2) > BelforgeColossusRules.SpecialInterval(3),
    "Phase 3 specials accelerate again"
)
assert(
    BelforgeColossusRules.SpecialDamage(1) < BelforgeColossusRules.SpecialDamage(2),
    "Phase 2 specials hit harder"
)
assert(
    BelforgeColossusRules.SpecialDamage(2) < BelforgeColossusRules.SpecialDamage(3),
    "Phase 3 specials hit hardest"
)

local boss = MonsterConfig.Get("belforge_colossus")
assert(
    boss and boss.Boss == true and boss.MaxHealth == 7200,
    "Belforge Colossus monster definition is canonical"
)
assert(boss.Reward.Currencies.Marks == 3, "Colossus kill awards Marks")
local bossCatalog = BossDefinitions.belforge_colossus
assert(
    bossCatalog and bossCatalog.MonsterId == "belforge_colossus",
    "boss catalog links to Colossus monster"
)
assert(
    bossCatalog.RecommendedLevel == 30 and bossCatalog.MaxPlayers == 6,
    "boss catalog level/party cap locked"
)

local core = ItemDefinitions.belforge_colossus_core
local emblem = ItemDefinitions.colossus_emblem
assert(core and core.Type == "Quest", "Colossus core item exists")
assert(
    emblem and emblem.Type == "Equipment" and emblem.EquipmentSlot == "Ring2",
    "Colossus Emblem reward exists"
)
assert(
    emblem.RequiredLevel == 30 and emblem.RequiredAdvancementTier == 2,
    "Colossus Emblem is Tier-2 Level-30 gear"
)
local drops = DropTables.belforge_colossus
assert(
    drops and drops[1].ItemId == "belforge_colossus_core" and drops[1].Chance == 1,
    "Colossus guarantees quest core"
)

local quest = QuestDefinitions.belforge_colossus_trial
assert(
    quest and quest.MinimumLevel == 30 and quest.MinimumAdvancementTier == 2,
    "Colossus quest is Tier-2 Level 30"
)
assert(
    quest.PrerequisiteQuests[1] == "belforge_gate_sentinel",
    "Colossus quest follows Sentinel progression"
)
assert(quest.Objectives[1].Target == "belforge_colossus", "Colossus quest records boss defeat")
assert(
    quest.Objectives[2].Target == "belforge_colossus_core",
    "Colossus quest records core collection"
)
assert(quest.Reward.Items.colossus_emblem == 1, "Colossus quest guarantees emblem reward")
assert(quest.Reward.Currencies.Marks == 3, "Colossus quest grants additional Marks")

local mara = NpcDefinitions.belforge_oathkeeper
assert(mara and mara.QuestOffers[1] == "belforge_colossus_trial", "Mara offers the Colossus trial")

print("Belforge Colossus tests passed")
