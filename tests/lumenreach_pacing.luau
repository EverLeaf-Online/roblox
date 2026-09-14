local ProgressionMath = require("../src/shared/Math/ProgressionMath")
local QuestDefinitions = require("../src/server/Content/QuestDefinitions")
local MonsterConfig = require("../src/server/Content/MonsterConfig")

local function expToReach(targetLevel)
    local total = 0
    for level = 1, targetLevel - 1 do
        total += ProgressionMath.ExpToNextLevel(level)
    end
    return total
end

local function questExp(id)
    return QuestDefinitions[id].Reward.Exp or 0
end

local function monsterExp(id, count)
    return (MonsterConfig.Get(id).Reward.Exp or 0) * count
end

-- Mandatory story route, intentionally excluding the optional supply quest.
local throughTrial = 0
throughTrial += questExp("lumen_first_steps") + monsterExp("lumen_mossling", 2)
throughTrial += questExp("lumen_trail_watch")
throughTrial += questExp("gravebone_problem") + monsterExp("skeleton", 4)
throughTrial += questExp("mossglen_hunt") + monsterExp("peco_peco", 4) + monsterExp(
    "brambleback",
    3
)
throughTrial += questExp("lumen_echoes")
throughTrial += questExp("old_grove_stirs") + monsterExp("mosswarden", 1)
throughTrial += questExp("first_advancement_trial") + monsterExp("gravebone_captain", 1)

assert(
    throughTrial >= expToReach(8),
    "story + trial must naturally reach first Level-8 advancement"
)
assert(
    throughTrial < expToReach(10),
    "Level-10 families should still require post-trial Lumenreach content"
)

-- Minimum kills capable of completing the two bridge quests: the fixed hunt plus
-- two Wisps and two Slimes if every collection drop rolls its maximum quantity.
local throughBridges = throughTrial
throughBridges += questExp("quiet_hunts") + monsterExp("royal_glowcap", 1) + monsterExp(
    "lumen_wisp",
    3
)
throughBridges += questExp("lumen_attunement") + monsterExp("lumen_wisp", 2) + monsterExp(
    "slime",
    2
)

assert(
    throughBridges >= expToReach(10),
    "bridge content must carry Level-10 family players without raw grinding"
)
print("Lumenreach pacing tests passed")
