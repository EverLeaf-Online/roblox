local MonsterConfig = require("../src/server/Content/MonsterConfig")
local DropTables = require("../src/server/Content/DropTableDefinitions")
local ItemDefinitions = require("../src/server/Content/ItemDefinitions")
local QuestDefinitions = require("../src/server/Content/QuestDefinitions")
local NpcDefinitions = require("../src/server/Content/NpcDefinitions")
local ProgressionMath = require("../src/shared/Math/ProgressionMath")

local gearjaw = MonsterConfig.Get("gearjaw_hound")
local cinder = MonsterConfig.Get("cindercoil")
local bastion = MonsterConfig.Get("pressure_bastion")
assert(gearjaw and gearjaw.TemplateName == "GearjawHound", "Gearjaw Hound definition exists")
assert(cinder and cinder.TemplateName == "Cindercoil", "Cindercoil definition exists")
assert(
    bastion and bastion.TemplateName == "PressureBastion" and bastion.Elite == true,
    "Pressure Bastion elite exists"
)
assert(bastion.Reward.Currencies.Marks == 1, "Pressure Bastion awards a Mark")

assert(
    ItemDefinitions.gearjaw_tooth and ItemDefinitions.gearjaw_tooth.Type == "Material",
    "Gearjaw Tooth exists"
)
assert(
    ItemDefinitions.cinder_coil and ItemDefinitions.cinder_coil.Type == "Material",
    "Cinder Coil exists"
)
assert(
    ItemDefinitions.pressure_seal and ItemDefinitions.pressure_seal.Type == "Quest",
    "Pressure Seal exists"
)
assert(DropTables.gearjaw_hound and #DropTables.gearjaw_hound >= 1, "Gearjaw drop table exists")
assert(DropTables.cindercoil and #DropTables.cindercoil >= 1, "Cindercoil drop table exists")
assert(
    DropTables.pressure_bastion and DropTables.pressure_bastion[1].ItemId == "pressure_seal",
    "Pressure Bastion guarantees seal"
)

local q1 = QuestDefinitions.brasshaven_first_shift
local q2 = QuestDefinitions.brasshaven_hot_lines
local q3 = QuestDefinitions.brasshaven_core_sample
local q4 = QuestDefinitions.brasshaven_teeth_in_gears
local q5 = QuestDefinitions.brasshaven_cinder_signal
local q6 = QuestDefinitions.brasshaven_pressure_bastion
assert(q1 and q2 and q3 and q4 and q5 and q6, "six-quest Brasshaven route exists")
assert(
    q4.MinimumLevel == 13 and q4.PrerequisiteQuests[1] == "brasshaven_core_sample",
    "Gearjaw quest follows core sample at Level 13"
)
assert(
    q5.MinimumLevel == 14 and q5.PrerequisiteQuests[1] == "brasshaven_teeth_in_gears",
    "Cinder quest follows Gearjaw quest at Level 14"
)
assert(
    q6.MinimumLevel == 15 and q6.PrerequisiteQuests[1] == "brasshaven_cinder_signal",
    "Pressure Bastion quest follows at Level 15"
)
assert(
    q4.Objectives[1].Target == "gearjaw_hound" and q4.Objectives[2].Target == "gearjaw_tooth",
    "Gearjaw quest objectives are wired"
)
assert(
    q5.Objectives[1].Target == "cindercoil" and q5.Objectives[2].Target == "cinder_coil",
    "Cinder quest objectives are wired"
)
assert(
    q6.Objectives[1].Target == "pressure_bastion" and q6.Objectives[2].Target == "pressure_seal",
    "Bastion quest objectives are wired"
)

local foreman = NpcDefinitions.belforge_foreman
assert(
    foreman and #foreman.QuestOffers >= 6,
    "Vale preserves the first six sequential Brasshaven quests"
)

-- Conservative no-grind pacing: count only mandatory defeat objectives plus quest EXP.
-- Brasshaven Passage deposits 220 EXP immediately before arrival at Level 10.
local level = 10
local exp = 220
local function apply(amount)
    exp += amount
    while exp >= ProgressionMath.ExpToNextLevel(level) do
        exp -= ProgressionMath.ExpToNextLevel(level)
        level += 1
    end
end

local scuttler = MonsterConfig.Get("rivet_scuttler")
local slagmite = MonsterConfig.Get("slagmite")
apply(scuttler.Reward.Exp * 5 + q1.Reward.Exp)
assert(level >= 11, "First Shift reaches Level 11")
apply(scuttler.Reward.Exp * 5 + slagmite.Reward.Exp * 3 + q2.Reward.Exp)
assert(level >= 12, "Hot Lines reaches Level 12")
apply(slagmite.Reward.Exp * 4 + q3.Reward.Exp)
assert(level >= 13, "Core Sample reaches Level 13")
apply(gearjaw.Reward.Exp * 5 + q4.Reward.Exp)
assert(level >= 14, "Teeth in the Gears reaches Level 14")
apply(cinder.Reward.Exp * 4 + q5.Reward.Exp)
assert(level >= 15, "Cinders in the Ducts reaches Level 15")
apply(bastion.Reward.Exp + q6.Reward.Exp)
assert(level >= 16, "Pressure Bastion route reaches Level 16")

print("Brasshaven midgame tests passed")
