local MonsterConfig = require("../src/server/Content/MonsterConfig")
local DropTables = require("../src/server/Content/DropTableDefinitions")
local ItemDefinitions = require("../src/server/Content/ItemDefinitions")
local QuestDefinitions = require("../src/server/Content/QuestDefinitions")
local NpcDefinitions = require("../src/server/Content/NpcDefinitions")
local ProgressionMath = require("../src/shared/Math/ProgressionMath")

local sentry = MonsterConfig.Get("blueflame_sentry")
local reaver = MonsterConfig.Get("foundry_reaver")
local golem = MonsterConfig.Get("smelter_golem")
assert(sentry and sentry.TemplateName == "BlueflameSentry", "Blueflame Sentry exists")
assert(reaver and reaver.TemplateName == "FoundryReaver", "Foundry Reaver exists")
assert(
    golem and golem.TemplateName == "SmelterGolem" and golem.Elite == true,
    "Smelter Golem elite exists"
)
assert(golem.Reward.Currencies.Marks == 1, "Smelter Golem awards one Mark")

assert(
    ItemDefinitions.flux_lens and ItemDefinitions.flux_lens.Type == "Material",
    "Flux Lens exists"
)
assert(
    ItemDefinitions.reaver_actuator and ItemDefinitions.reaver_actuator.Type == "Material",
    "Reaver Actuator exists"
)
assert(
    ItemDefinitions.smelter_core and ItemDefinitions.smelter_core.Type == "Quest",
    "Smelter Core exists"
)
assert(
    DropTables.blueflame_sentry and DropTables.blueflame_sentry[1].ItemId == "flux_lens",
    "Sentry drops Flux Lens"
)
assert(
    DropTables.foundry_reaver and DropTables.foundry_reaver[1].ItemId == "reaver_actuator",
    "Reaver drops actuator"
)
assert(
    DropTables.smelter_golem
        and DropTables.smelter_golem[1].ItemId == "smelter_core"
        and DropTables.smelter_golem[1].Chance == 1,
    "Smelter Golem guarantees core"
)

local questIds = {
    "eastworks_blueflame",
    "eastworks_reaver_line",
    "eastworks_grid_purge",
    "eastworks_smelter_golem",
}
local engineer = NpcDefinitions.eastworks_engineer
assert(engineer and #engineer.QuestOffers == #questIds, "Tamsin exposes complete Level 20-24 route")
for index, questId in questIds do
    assert(
        engineer.QuestOffers[index] == questId,
        "Tamsin quest order remains sequential at index " .. tostring(index)
    )
end

local q1 = QuestDefinitions.eastworks_blueflame
local q2 = QuestDefinitions.eastworks_reaver_line
local q3 = QuestDefinitions.eastworks_grid_purge
local q4 = QuestDefinitions.eastworks_smelter_golem
assert(
    q1.MinimumLevel == 20 and q1.PrerequisiteQuests[1] == "brasshaven_railbreaker",
    "Eastworks starts after Railbreaker at Level 20"
)
assert(
    q2.MinimumLevel == 21 and q2.PrerequisiteQuests[1] == "eastworks_blueflame",
    "Reaver line follows Level 21"
)
assert(
    q3.MinimumLevel == 22 and q3.PrerequisiteQuests[1] == "eastworks_reaver_line",
    "Grid purge follows Level 22"
)
assert(
    q4.MinimumLevel == 23 and q4.PrerequisiteQuests[1] == "eastworks_grid_purge",
    "Smelter Golem follows Level 23"
)

-- The Level 10-20 Brasshaven route ends at Level 20 with a conservative 68 EXP remainder.
local level = 20
local exp = 68
local function grant(amount)
    exp += amount
    while exp >= ProgressionMath.ExpToNextLevel(level) do
        exp -= ProgressionMath.ExpToNextLevel(level)
        level += 1
    end
end

local route = {
    { q1.MinimumLevel, sentry.Reward.Exp * 5 + q1.Reward.Exp, 21 },
    { q2.MinimumLevel, reaver.Reward.Exp * 5 + q2.Reward.Exp, 22 },
    { q3.MinimumLevel, sentry.Reward.Exp * 4 + reaver.Reward.Exp * 4 + q3.Reward.Exp, 23 },
    { q4.MinimumLevel, golem.Reward.Exp + q4.Reward.Exp, 24 },
}
for index, step in route do
    assert(level >= step[1], "route reaches Eastworks gate before step " .. tostring(index))
    grant(step[2])
    assert(
        level >= step[3],
        "Eastworks route reaches expected level after step " .. tostring(index)
    )
end
assert(level >= 24, "Eastworks quest route carries Level 20 player to Level 24")

print("Eastworks Level 24 tests passed")
