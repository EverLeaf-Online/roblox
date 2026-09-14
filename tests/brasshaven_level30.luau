local BelforgeAccessRules = require("../src/shared/Logic/BelforgeAccessRules")
local MonsterConfig = require("../src/server/Content/MonsterConfig")
local DropTables = require("../src/server/Content/DropTableDefinitions")
local ItemDefinitions = require("../src/server/Content/ItemDefinitions")
local QuestDefinitions = require("../src/server/Content/QuestDefinitions")
local NpcDefinitions = require("../src/server/Content/NpcDefinitions")
local ProgressionMath = require("../src/shared/Math/ProgressionMath")

local specter = MonsterConfig.Get("forge_specter")
local enforcer = MonsterConfig.Get("ironclad_enforcer")
local drake = MonsterConfig.Get("molten_drake")
local titan = MonsterConfig.Get("bellows_titan")
local sentinel = MonsterConfig.Get("belforge_sentinel")
assert(specter and specter.TemplateName == "ForgeSpecter", "Forge Specter exists")
assert(enforcer and enforcer.TemplateName == "IroncladEnforcer", "Ironclad Enforcer exists")
assert(drake and drake.TemplateName == "MoltenDrake", "Molten Drake exists")
assert(
    titan and titan.TemplateName == "BellowsTitan" and titan.Elite == true,
    "Bellows Titan elite exists"
)
assert(
    sentinel and sentinel.TemplateName == "BelforgeSentinel" and sentinel.Elite == true,
    "Belforge Sentinel elite exists"
)
assert(titan.Reward.Currencies.Marks == 1, "Bellows Titan awards a Mark")
assert(sentinel.Reward.Currencies.Marks == 1, "Belforge Sentinel awards a Mark")

assert(
    ItemDefinitions.specter_residue and ItemDefinitions.specter_residue.Type == "Material",
    "Specter Residue exists"
)
assert(
    ItemDefinitions.enforcer_badge and ItemDefinitions.enforcer_badge.Type == "Material",
    "Enforcer Badge exists"
)
assert(
    ItemDefinitions.drake_scale and ItemDefinitions.drake_scale.Type == "Material",
    "Molten Drake Scale exists"
)
assert(
    ItemDefinitions.bellows_core and ItemDefinitions.bellows_core.Type == "Quest",
    "Bellows Titan Core exists"
)
assert(
    ItemDefinitions.belforge_gate_key and ItemDefinitions.belforge_gate_key.Type == "Quest",
    "Belforge Gate Key exists"
)
assert(
    DropTables.bellows_titan
        and DropTables.bellows_titan[1].ItemId == "bellows_core"
        and DropTables.bellows_titan[1].Chance == 1,
    "Bellows Titan guarantees core"
)
assert(
    DropTables.belforge_sentinel
        and DropTables.belforge_sentinel[1].ItemId == "belforge_gate_key"
        and DropTables.belforge_sentinel[1].Chance == 1,
    "Belforge Sentinel guarantees gate key"
)

local rookQuestIds = {
    "belforge_flux_ghosts",
    "belforge_enforcer_protocol",
    "belforge_molten_runoff",
    "belforge_triple_lock",
    "belforge_bellows_titan",
    "belforge_gate_sentinel",
}
local marshal = NpcDefinitions.belforge_marshal
assert(marshal and #marshal.QuestOffers == #rookQuestIds, "Rook exposes complete Level 24-30 route")
for index, questId in rookQuestIds do
    assert(
        marshal.QuestOffers[index] == questId,
        "Rook quest order remains sequential at index " .. tostring(index)
    )
end

local q15 = QuestDefinitions.belforge_flux_ghosts
local q16 = QuestDefinitions.belforge_enforcer_protocol
local q17 = QuestDefinitions.belforge_molten_runoff
local q18 = QuestDefinitions.belforge_triple_lock
local q19 = QuestDefinitions.belforge_bellows_titan
local q20 = QuestDefinitions.belforge_gate_sentinel
assert(
    q15.MinimumLevel == 24 and q15.PrerequisiteQuests[1] == "eastworks_smelter_golem",
    "Rook arc begins after Tamsin at Level 24"
)
assert(
    q16.MinimumLevel == 25 and q16.PrerequisiteQuests[1] == "belforge_flux_ghosts",
    "Enforcer protocol follows Level 25"
)
assert(
    q17.MinimumLevel == 26 and q17.PrerequisiteQuests[1] == "belforge_enforcer_protocol",
    "Molten runoff follows Level 26"
)
assert(
    q18.MinimumLevel == 27 and q18.PrerequisiteQuests[1] == "belforge_molten_runoff",
    "Triple lock follows Level 27"
)
assert(
    q19.MinimumLevel == 28 and q19.PrerequisiteQuests[1] == "belforge_triple_lock",
    "Bellows Titan follows Level 28"
)
assert(
    q20.MinimumLevel == 29 and q20.PrerequisiteQuests[1] == "belforge_bellows_titan",
    "Gate Sentinel follows Level 29"
)

local lockedLevel, lockedReason = BelforgeAccessRules.CanEnter({
    Level = 29,
    Quests = { Completed = { belforge_gate_sentinel = true } },
})
assert(
    not lockedLevel and lockedReason == "level_too_low",
    "Belforge gate rejects players below Level 30"
)
local lockedQuest, questReason = BelforgeAccessRules.CanEnter({
    Level = 30,
    Quests = { Completed = {} },
})
assert(
    not lockedQuest and questReason == "sentinel_incomplete",
    "Belforge gate requires Sentinel quest completion"
)
local allowed = BelforgeAccessRules.CanEnter({
    Level = 30,
    Quests = { Completed = { belforge_gate_sentinel = true } },
})
assert(allowed, "Level 30 player with Sentinel completion can enter Belforge antechamber")

-- Regression-lock the full Brasshaven route from first arrival to Level 30.
local questIds = {
    "brasshaven_first_shift",
    "brasshaven_hot_lines",
    "brasshaven_core_sample",
    "brasshaven_teeth_in_gears",
    "brasshaven_cinder_signal",
    "brasshaven_pressure_bastion",
    "brasshaven_dead_shift",
    "brasshaven_arc_fault",
    "brasshaven_crossfeed",
    "brasshaven_railbreaker",
    "eastworks_blueflame",
    "eastworks_reaver_line",
    "eastworks_grid_purge",
    "eastworks_smelter_golem",
    "belforge_flux_ghosts",
    "belforge_enforcer_protocol",
    "belforge_molten_runoff",
    "belforge_triple_lock",
    "belforge_bellows_titan",
    "belforge_gate_sentinel",
}
for _, questId in questIds do
    assert(QuestDefinitions[questId], "Brasshaven route quest exists: " .. questId)
end

local scuttler = MonsterConfig.Get("rivet_scuttler")
local slagmite = MonsterConfig.Get("slagmite")
local gearjaw = MonsterConfig.Get("gearjaw_hound")
local cinder = MonsterConfig.Get("cindercoil")
local bastion = MonsterConfig.Get("pressure_bastion")
local husk = MonsterConfig.Get("furnace_husk")
local arc = MonsterConfig.Get("arc_siphon")
local rail = MonsterConfig.Get("railbreaker")
local sentry = MonsterConfig.Get("blueflame_sentry")
local reaver = MonsterConfig.Get("foundry_reaver")
local golem = MonsterConfig.Get("smelter_golem")

local q = QuestDefinitions
local level = 10
local exp = 220 -- Brasshaven Passage reward immediately before first arrival.
local function grant(amount)
    exp += amount
    while exp >= ProgressionMath.ExpToNextLevel(level) do
        exp -= ProgressionMath.ExpToNextLevel(level)
        level += 1
    end
end

local route = {
    { 10, scuttler.Reward.Exp * 5 + q.brasshaven_first_shift.Reward.Exp, 11 },
    {
        11,
        scuttler.Reward.Exp * 5 + slagmite.Reward.Exp * 3 + q.brasshaven_hot_lines.Reward.Exp,
        12,
    },
    { 12, slagmite.Reward.Exp * 4 + q.brasshaven_core_sample.Reward.Exp, 13 },
    { 13, gearjaw.Reward.Exp * 5 + q.brasshaven_teeth_in_gears.Reward.Exp, 14 },
    { 14, cinder.Reward.Exp * 4 + q.brasshaven_cinder_signal.Reward.Exp, 15 },
    { 15, bastion.Reward.Exp + q.brasshaven_pressure_bastion.Reward.Exp, 16 },
    { 16, husk.Reward.Exp * 5 + q.brasshaven_dead_shift.Reward.Exp, 17 },
    { 17, arc.Reward.Exp * 4 + q.brasshaven_arc_fault.Reward.Exp, 18 },
    { 18, husk.Reward.Exp * 4 + cinder.Reward.Exp * 4 + q.brasshaven_crossfeed.Reward.Exp, 19 },
    { 19, rail.Reward.Exp + q.brasshaven_railbreaker.Reward.Exp, 20 },
    { 20, sentry.Reward.Exp * 5 + q.eastworks_blueflame.Reward.Exp, 21 },
    { 21, reaver.Reward.Exp * 5 + q.eastworks_reaver_line.Reward.Exp, 22 },
    { 22, sentry.Reward.Exp * 4 + reaver.Reward.Exp * 4 + q.eastworks_grid_purge.Reward.Exp, 23 },
    { 23, golem.Reward.Exp + q.eastworks_smelter_golem.Reward.Exp, 24 },
    { 24, specter.Reward.Exp * 5 + q15.Reward.Exp, 25 },
    { 25, enforcer.Reward.Exp * 5 + q16.Reward.Exp, 26 },
    { 26, drake.Reward.Exp * 5 + q17.Reward.Exp, 27 },
    {
        27,
        specter.Reward.Exp * 3 + enforcer.Reward.Exp * 3 + drake.Reward.Exp * 3 + q18.Reward.Exp,
        28,
    },
    { 28, titan.Reward.Exp + q19.Reward.Exp, 29 },
    { 29, sentinel.Reward.Exp + q20.Reward.Exp, 30 },
}

for index, step in route do
    assert(
        level >= step[1],
        "full Brasshaven route reaches quest gate before step " .. tostring(index)
    )
    grant(step[2])
    assert(
        level >= step[3],
        "full Brasshaven route reaches expected level after step " .. tostring(index)
    )
end
assert(level >= 30, "Brasshaven route carries a fresh Level 10 arrival to Level 30")

print("Brasshaven Level 30 tests passed")
