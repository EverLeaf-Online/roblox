local Rules = require("../src/shared/Logic/AchievementSyncRules")

local definitions = {
    founding_adventurer = {},
    everleaf_founder = {},
    welcome_to_lumenreach = {},
    first_victory = {},
    level_10 = {},
}

local function contains(list, value)
    return table.find(list, value) ~= nil
end

local fresh = {
    Level = 1,
    Achievements = { Unlocked = {} },
}
local freshPlan = Rules.BuildJoinPlan(fresh, definitions, true)
assert(contains(freshPlan.UnlockIds, "welcome_to_lumenreach"), "fresh join unlocks welcome badge")
assert(
    contains(freshPlan.UnlockIds, "founding_adventurer"),
    "active founding phase unlocks founding badge"
)
assert(not contains(freshPlan.UnlockIds, "level_10"), "level 1 does not unlock level 10")

local veteran = {
    Level = 15,
    Achievements = {
        Unlocked = {
            first_victory = 100,
            founding_adventurer = 101,
            everleaf_founder = 102,
            welcome_to_lumenreach = 103,
            level_10 = 104,
        },
    },
}
local veteranPlan = Rules.BuildJoinPlan(veteran, definitions, false)
assert(#veteranPlan.UnlockIds == 0, "durable achievements are never re-unlocked")
assert(
    contains(veteranPlan.RepairIds, "first_victory"),
    "first victory platform badge repairs on join"
)
assert(
    contains(veteranPlan.RepairIds, "founding_adventurer"),
    "earned founding badge repairs after phase ends"
)
assert(
    contains(veteranPlan.RepairIds, "everleaf_founder"),
    "verified founder achievement repairs badge"
)
assert(contains(veteranPlan.RepairIds, "level_10"), "level badge repairs from durable state")

local levelTen = {
    Level = 10,
    Achievements = { Unlocked = { welcome_to_lumenreach = 1 } },
}
local levelPlan = Rules.BuildJoinPlan(levelTen, definitions, false)
assert(contains(levelPlan.RepairIds, "welcome_to_lumenreach"), "existing welcome badge repairs")
assert(contains(levelPlan.UnlockIds, "level_10"), "eligible missing level badge unlocks")
assert(
    not contains(levelPlan.UnlockIds, "founding_adventurer"),
    "closed founding phase creates no new founding unlock"
)

print("achievement sync rules tests passed")
