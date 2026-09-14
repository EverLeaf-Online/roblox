local AchievementDefinitions = require(script.Parent.Parent.Content.AchievementDefinitions)
local AchievementService = {}

function AchievementService.Unlock(profile, achievementId)
    if not AchievementDefinitions[achievementId] then
        return false, "unknown_achievement"
    end
    if profile.Achievements.Unlocked[achievementId] then
        return false, "already_unlocked"
    end
    profile.Achievements.Unlocked[achievementId] = os.time()
    return true
end

return AchievementService
