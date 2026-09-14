local MonsterConfig = require("../src/server/Content/MonsterConfig")
local DropTables = require("../src/server/Content/DropTableDefinitions")
local ItemDefinitions = require("../src/server/Content/ItemDefinitions")
local QuestDefinitions = require("../src/server/Content/QuestDefinitions")
local NpcDefinitions = require("../src/server/Content/NpcDefinitions")
local ProgressionMath = require("../src/shared/Math/ProgressionMath")

local husk = MonsterConfig.Get("furnace_husk")
local arc = MonsterConfig.Get("arc_siphon")
local rail = MonsterConfig.Get("railbreaker")
assert(husk and husk.TemplateName == "FurnaceHusk", "Furnace Husk definition exists")
assert(arc and arc.TemplateName == "ArcSiphon", "Arc Siphon definition exists")
assert(
    rail and rail.TemplateName == "Railbreaker" and rail.Elite == true,
    "Railbreaker elite exists"
)
assert(rail.Reward.Currencies.Marks == 1, "Railbreaker awards one Mark")

assert(
    ItemDefinitions.furnace_plate and ItemDefinitions.furnace_plate.Type == "Material",
    "Furnace Plate exists"
)
assert(ItemDefinitions.arc_cell and ItemDefinitions.arc_cell.Type == "Material", "Arc Cell exists")
assert(
    ItemDefinitions.railbreaker_pin and ItemDefinitions.railbreaker_pin.Type == "Quest",
    "Railbreaker Pin exists"
)
assert(
    DropTables.furnace_husk and DropTables.furnace_husk[1].ItemId == "furnace_plate",
    "Furnace Husk drops plates"
)
assert(
    DropTables.arc_siphon and DropTables.arc_siphon[1].ItemId == "arc_cell",
    "Arc Siphon drops cells"
)
assert(
    DropTables.railbreaker
        and DropTables.railbreaker[1].ItemId == "railbreaker_pin"
        and DropTables.railbreaker[1].Chance == 1,
    "Railbreaker guarantees its pin"
)

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
}
local foreman = NpcDefinitions.belforge_foreman
assert(foreman and #foreman.QuestOffers == #questIds, "Vale exposes the complete Level 10-20 route")
for index, questId in questIds do
    assert(
        foreman.QuestOffers[index] == questId,
        "Vale quest order remains sequential at index " .. tostring(index)
    )
end

local dead = QuestDefinitions.brasshaven_dead_shift
local fault = QuestDefinitions.brasshaven_arc_fault
local cross = QuestDefinitions.brasshaven_crossfeed
local breaker = QuestDefinitions.brasshaven_railbreaker
assert(
    dead.MinimumLevel == 16 and dead.PrerequisiteQuests[1] == "brasshaven_pressure_bastion",
    "Dead Shift starts Level 16 band"
)
assert(
    fault.MinimumLevel == 17 and fault.PrerequisiteQuests[1] == "brasshaven_dead_shift",
    "Arc Fault follows at Level 17"
)
assert(
    cross.MinimumLevel == 18 and cross.PrerequisiteQuests[1] == "brasshaven_arc_fault",
    "Crossfeed follows at Level 18"
)
assert(
    breaker.MinimumLevel == 19 and breaker.PrerequisiteQuests[1] == "brasshaven_crossfeed",
    "Railbreaker follows at Level 19"
)

local scuttler = MonsterConfig.Get("rivet_scuttler")
local slagmite = MonsterConfig.Get("slagmite")
local gearjaw = MonsterConfig.Get("gearjaw_hound")
local cinder = MonsterConfig.Get("cindercoil")
local bastion = MonsterConfig.Get("pressure_bastion")
local q1 = QuestDefinitions.brasshaven_first_shift
local q2 = QuestDefinitions.brasshaven_hot_lines
local q3 = QuestDefinitions.brasshaven_core_sample
local q4 = QuestDefinitions.brasshaven_teeth_in_gears
local q5 = QuestDefinitions.brasshaven_cinder_signal
local q6 = QuestDefinitions.brasshaven_pressure_bastion

-- Conservative mandatory-kill route. Collection RNG may require extra kills,
-- which only adds more EXP; this verifies the route never requires grinding
-- beyond its own quest objectives to unlock the next quest level.
local level = 10
local exp = 220 -- Brasshaven Passage reward immediately before arrival.
local function grant(amount)
    exp += amount
    while exp >= ProgressionMath.ExpToNextLevel(level) do
        exp -= ProgressionMath.ExpToNextLevel(level)
        level += 1
    end
end

local route = {
    { q1.MinimumLevel, scuttler.Reward.Exp * 5 + q1.Reward.Exp, 11 },
    { q2.MinimumLevel, scuttler.Reward.Exp * 5 + slagmite.Reward.Exp * 3 + q2.Reward.Exp, 12 },
    { q3.MinimumLevel, slagmite.Reward.Exp * 4 + q3.Reward.Exp, 13 },
    { q4.MinimumLevel, gearjaw.Reward.Exp * 5 + q4.Reward.Exp, 14 },
    { q5.MinimumLevel, cinder.Reward.Exp * 4 + q5.Reward.Exp, 15 },
    { q6.MinimumLevel, bastion.Reward.Exp + q6.Reward.Exp, 16 },
    { dead.MinimumLevel, husk.Reward.Exp * 5 + dead.Reward.Exp, 17 },
    { fault.MinimumLevel, arc.Reward.Exp * 4 + fault.Reward.Exp, 18 },
    { cross.MinimumLevel, husk.Reward.Exp * 4 + cinder.Reward.Exp * 4 + cross.Reward.Exp, 19 },
    { breaker.MinimumLevel, rail.Reward.Exp + breaker.Reward.Exp, 20 },
}

for index, step in route do
    assert(level >= step[1], "route reaches quest gate before step " .. tostring(index))
    grant(step[2])
    assert(level >= step[3], "route reaches expected level after step " .. tostring(index))
end
assert(level >= 20, "Brasshaven quest route carries a fresh arrival to Level 20")

print("Brasshaven Level 20 tests passed")
