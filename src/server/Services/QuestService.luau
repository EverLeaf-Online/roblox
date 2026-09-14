local QuestDefinitions = require(script.Parent.Parent.Content.QuestDefinitions)
local RewardService = require(script.Parent.RewardService)

local QuestService = {}

local function makeState(definition)
    local progress = {}
    for index, _ in definition.Objectives do
        progress[index] = 0
    end
    return { Progress = progress }
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
            local complete = true
            for index, objective in definition.Objectives do
                local current = state.Progress[index] or 0
                if objective.Type == objectiveType and objective.Target == targetId then
                    current = math.min(objective.Required, current + amount)
                    state.Progress[index] = current
                    changed = true
                end
                if current < objective.Required then
                    complete = false
                end
            end
            if complete and not state.ReadyToTurnIn then
                state.ReadyToTurnIn = true
                table.insert(completedNow, questId)
                changed = true
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
