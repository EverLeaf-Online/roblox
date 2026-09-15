local AchievementSyncRules = {}

local function sortedKeys(set)
    local result = {}
    for key in set do
        table.insert(result, key)
    end
    table.sort(result)
    return result
end

function AchievementSyncRules.BuildJoinPlan(profile, definitions, foundingPhaseActive)
    local plan = { RepairIds = {}, UnlockIds = {} }
    if type(profile) ~= "table" or type(definitions) ~= "table" then
        return plan
    end

    local unlocked = profile.Achievements and profile.Achievements.Unlocked
    unlocked = type(unlocked) == "table" and unlocked or {}

    local repairSet = {}
    for achievementId, value in unlocked do
        if value and definitions[achievementId] ~= nil then
            repairSet[achievementId] = true
        end
    end

    local unlockSet = {}
    local function requireUnlock(achievementId, condition)
        if condition and definitions[achievementId] ~= nil and not unlocked[achievementId] then
            unlockSet[achievementId] = true
        end
    end

    requireUnlock("welcome_to_lumenreach", true)
    requireUnlock("founding_adventurer", foundingPhaseActive == true)
    requireUnlock("level_10", (tonumber(profile.Level) or 0) >= 10)

    plan.RepairIds = sortedKeys(repairSet)
    plan.UnlockIds = sortedKeys(unlockSet)
    return plan
end

return table.freeze(AchievementSyncRules)
