local QuestDefinitions = require(script.Parent.Parent.Content.QuestDefinitions)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestLifecycle = require(ReplicatedStorage.Shared.Logic.QuestLifecycle)
local QuestAccessRules = require(ReplicatedStorage.Shared.Logic.QuestAccessRules)
local ProfileTransaction = require(ReplicatedStorage.Shared.Logic.ProfileTransaction)
local QuestTurnInRules = require(ReplicatedStorage.Shared.Logic.QuestTurnInRules)
local RewardService = require(script.Parent.RewardService)

local QuestService = {}

local function makeState(definition)
    return QuestLifecycle.NewState(#definition.Objectives)
end

function QuestService.Start(profile, questId)
    local definition = QuestDefinitions[questId]
    if not definition then
        return false, "unknown_quest"
    end
    if profile.Quests.Completed[questId] then
        return false, "already_completed"
    end
    if profile.Quests.Active[questId] then
        return false, "already_active"
    end
    local accessible, accessReason = QuestAccessRules.CanStart(profile, definition)
    if not accessible then
        return false, accessReason
    end
    profile.Quests.Active[questId] = makeState(definition)
    return true
end

function QuestService.Record(profile, objectiveType, targetId, amount)
    amount = amount or 1
    local changed = false
    local completedNow = {}
    for questId, state in profile.Quests.Active do
        local definition = QuestDefinitions[questId]
        if definition then
            local questChanged, ready =
                QuestLifecycle.Record(state, definition.Objectives, objectiveType, targetId, amount)
            changed = questChanged or changed
            if questChanged and ready then
                table.insert(completedNow, questId)
            end
        end
    end
    return changed, completedNow
end

function QuestService.TurnIn(profile, questId)
    local definition = QuestDefinitions[questId]
    if not definition then
        return false, "unknown_quest"
    end

    return ProfileTransaction.Run(profile, function(workingProfile)
        local eligible, eligibilityReason = QuestTurnInRules.Validate(workingProfile, questId)
        if not eligible then
            return false, eligibilityReason
        end

        local rewardResult = nil
        if definition.Reward then
            local rewarded, resultOrReason = RewardService.Apply(workingProfile, definition.Reward)
            if not rewarded then
                return false, resultOrReason
            end
            rewardResult = resultOrReason
        end

        local completed, completionReason = QuestTurnInRules.MarkCompleted(workingProfile, questId)
        if not completed then
            return false, completionReason
        end
        return true, { Reward = definition.Reward, RewardResult = rewardResult }
    end)
end

return QuestService
