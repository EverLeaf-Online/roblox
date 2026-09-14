local QuestDefinitions = require(script.Parent.Parent.Content.QuestDefinitions)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestLifecycle = require(ReplicatedStorage.Shared.Logic.QuestLifecycle)
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
    if profile.Level < (definition.MinimumLevel or 1) then
        return false, "level_too_low"
    end
    for _, prerequisiteId in definition.PrerequisiteQuests or {} do
        if profile.Quests.Completed[prerequisiteId] ~= true then
            return false, "prerequisite_incomplete"
        end
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
    if profile.Quests.Completed[questId] then
        return false, "already_completed"
    end

    local state = profile.Quests.Active[questId]
    if not state then
        return false, "quest_not_active"
    end
    if not state.ReadyToTurnIn then
        return false, "objectives_incomplete"
    end

    profile.Quests.Active[questId] = nil
    profile.Quests.Completed[questId] = true
    if definition.Reward then
        RewardService.Grant(profile, definition.Reward)
    end
    return true, { Reward = definition.Reward }
end

return QuestService
