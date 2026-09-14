local QuestLifecycle = {}

function QuestLifecycle.NewState(objectiveCount)
    local progress = {}
    for index = 1, objectiveCount do
        progress[index] = 0
    end
    return { Progress = progress, ReadyToTurnIn = false }
end

function QuestLifecycle.Record(state, objectives, objectiveType, targetId, amount)
    amount = amount or 1
    local changed = false
    local complete = true

    for index, objective in objectives do
        local current = state.Progress[index] or 0
        if objective.Type == objectiveType and objective.Target == targetId then
            local nextValue = math.min(objective.Required, current + amount)
            if nextValue ~= current then
                state.Progress[index] = nextValue
                current = nextValue
                changed = true
            end
        end
        if current < objective.Required then
            complete = false
        end
    end

    if complete and not state.ReadyToTurnIn then
        state.ReadyToTurnIn = true
        changed = true
    end

    return changed, state.ReadyToTurnIn == true
end

return QuestLifecycle
