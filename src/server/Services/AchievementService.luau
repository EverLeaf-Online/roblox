local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MonetizationConfig = require(ReplicatedStorage.Shared.MonetizationConfig)
local AchievementSyncRules = require(ReplicatedStorage.Shared.Logic.AchievementSyncRules)
local AchievementDefinitions = require(script.Parent.Parent.Content.AchievementDefinitions)

local AchievementService = {}

function AchievementService.Unlock(profile, achievementId)
    local definition = AchievementDefinitions[achievementId]
    if not definition then
        return false, "unknown_achievement"
    end
    if profile.Achievements.Unlocked[achievementId] then
        return false, "already_unlocked"
    end
    profile.Achievements.Unlocked[achievementId] = os.time()
    return true
end

function AchievementService.AwardRobloxBadge(player, achievementId)
    local definition = AchievementDefinitions[achievementId]
    local badgeId = definition and definition.RobloxBadgeId
    if not definition or type(badgeId) ~= "number" or badgeId <= 0 then
        return false, "badge_not_configured"
    end
    if not player or not player:IsA("Player") then
        return false, "invalid_player"
    end
    if RunService:IsStudio() then
        return false, "studio"
    end

    local success, result = pcall(function()
        if BadgeService:UserHasBadgeAsync(player.UserId, badgeId) then
            return true
        end
        return BadgeService:AwardBadge(player.UserId, badgeId)
    end)
    if not success then
        warn(
            string.format(
                "[AchievementService] Badge award failed for %s/%s: %s",
                player.Name,
                achievementId,
                tostring(result)
            )
        )
        return false, "badge_api_failed"
    end
    return result == true, result == true and nil or "badge_not_awarded"
end

function AchievementService.UnlockAndAward(player, profile, achievementId)
    local changed, reason = AchievementService.Unlock(profile, achievementId)
    -- Platform badges are independently idempotent. Attempt the Roblox award
    -- even for an already-unlocked local achievement so join-time sync can
    -- repair a prior transient BadgeService failure.
    task.spawn(AchievementService.AwardRobloxBadge, player, achievementId)
    return changed, reason
end

function AchievementService.SyncJoin(player, profile)
    local plan = AchievementSyncRules.BuildJoinPlan(
        profile,
        AchievementDefinitions,
        MonetizationConfig.FoundingPhaseActive
    )

    -- Repair platform badges from durable local achievement state first. This
    -- covers prior transient BadgeService failures, including First Victory and
    -- Founding Adventurer after the founding phase has ended.
    for _, achievementId in plan.RepairIds do
        task.spawn(AchievementService.AwardRobloxBadge, player, achievementId)
    end

    local changed = false
    for _, achievementId in plan.UnlockIds do
        local unlocked = AchievementService.UnlockAndAward(player, profile, achievementId)
        changed = unlocked or changed
    end
    return changed
end

function AchievementService.SyncProgression(player, profile)
    if profile.Level < 10 or profile.Achievements.Unlocked.level_10 then
        return false
    end
    return AchievementService.UnlockAndAward(player, profile, "level_10")
end

return AchievementService
