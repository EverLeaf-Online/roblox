local MonsterConfig = require("../src/server/Content/MonsterConfig")
local DropTables = require("../src/server/Content/DropTableDefinitions")
local ItemDefinitions = require("../src/server/Content/ItemDefinitions")
local QuestDefinitions = require("../src/server/Content/QuestDefinitions")
local NpcDefinitions = require("../src/server/Content/NpcDefinitions")
local ProgressionMath = require("../src/shared/Math/ProgressionMath")

local scuttler = MonsterConfig.Get("rivet_scuttler")
local slagmite = MonsterConfig.Get("slagmite")
assert(scuttler and scuttler.TemplateName == "RivetScuttler", "Rivet Scuttler definition exists")
assert(slagmite and slagmite.TemplateName == "Slagmite", "Slagmite definition exists")
assert(
    scuttler.Reward.Exp > 0 and slagmite.Reward.Exp > scuttler.Reward.Exp,
    "Brasshaven enemy rewards scale"
)

assert(
    ItemDefinitions.rivet_spring and ItemDefinitions.rivet_spring.Type == "Material",
    "Rivet Spring exists"
)
assert(
    ItemDefinitions.slag_core and ItemDefinitions.slag_core.Type == "Material",
    "Slag Core exists"
)
assert(DropTables.rivet_scuttler and #DropTables.rivet_scuttler >= 1, "Scuttler drop table exists")
assert(DropTables.slagmite and #DropTables.slagmite >= 1, "Slagmite drop table exists")

local first = QuestDefinitions.brasshaven_first_shift
local hot = QuestDefinitions.brasshaven_hot_lines
local core = QuestDefinitions.brasshaven_core_sample
assert(first and hot and core, "Brasshaven opening quest chain exists")
assert(
    first.MinimumLevel == 10 and first.MinimumAdvancementTier == 1,
    "First Shift starts at advanced Level 10"
)
assert(hot.PrerequisiteQuests[1] == "brasshaven_first_shift", "Hot Lines follows First Shift")
assert(core.PrerequisiteQuests[1] == "brasshaven_hot_lines", "Core Sample follows Hot Lines")
assert(
    first.Objectives[1].Type == "Defeat" and first.Objectives[1].Target == "rivet_scuttler",
    "First Shift targets Scuttlers"
)
assert(
    hot.Objectives[1].Type == "Collect" and hot.Objectives[1].Target == "rivet_spring",
    "Hot Lines collects springs"
)
assert(
    hot.Objectives[2].Type == "Defeat" and hot.Objectives[2].Target == "slagmite",
    "Hot Lines targets Slagmites"
)
assert(
    core.Objectives[1].Type == "Collect" and core.Objectives[1].Target == "slag_core",
    "Core Sample collects Slag Cores"
)

local foreman = NpcDefinitions.belforge_foreman
assert(foreman and #foreman.QuestOffers == 3, "Vale offers three opening Brasshaven quests")
assert(
    foreman.QuestOffers[1] == "brasshaven_first_shift",
    "Vale quest order begins with First Shift"
)

-- Conservative progression check using only mandatory defeat counts plus quest rewards.
-- Brasshaven Passage grants 220 EXP immediately before arrival.
local expAt10 = 220
expAt10 += scuttler.Reward.Exp * 5 + first.Reward.Exp
assert(
    expAt10 >= ProgressionMath.ExpToNextLevel(10),
    "First Shift carries a fresh Level 10 to Level 11"
)
local remainder11 = expAt10 - ProgressionMath.ExpToNextLevel(10)
local expAt11 = remainder11 + scuttler.Reward.Exp * 5 + slagmite.Reward.Exp * 3 + hot.Reward.Exp
assert(expAt11 >= ProgressionMath.ExpToNextLevel(11), "Hot Lines carries the route to Level 12")
local remainder12 = expAt11 - ProgressionMath.ExpToNextLevel(11)
local expAt12 = remainder12 + slagmite.Reward.Exp * 4 + core.Reward.Exp
assert(
    expAt12 >= ProgressionMath.ExpToNextLevel(12) * 0.9,
    "Core Sample keeps Level 12 progression moving without a grind cliff"
)

print("Brasshaven content tests passed")
