local QuestTurnInRules = {}

function QuestTurnInRules.Validate(profile, questId)
    if type(profile) ~= "table" or type(questId) ~= "string" or questId == "" then
        return false, "invalid_state"
    end
    local quests = profile.Quests
    local active = quests and quests.Active
    local completed = quests and quests.Completed
    if type(active) ~= "table" or type(completed) ~= "table" then
        return false, "invalid_state"
    end
    if completed[questId] == true then
        return false, "already_completed"
    end
    local state = active[questId]
    if type(state) ~= "table" then
        return false, "quest_not_active"
    end
    if state.ReadyToTurnIn ~= true then
        return false, "objectives_incomplete"
    end
    return true, state
end

function QuestTurnInRules.MarkCompleted(profile, questId)
    local ok, reason = QuestTurnInRules.Validate(profile, questId)
    if not ok then
        return false, reason
    end
    profile.Quests.Active[questId] = nil
    profile.Quests.Completed[questId] = true
    return true
end

return table.freeze(QuestTurnInRules)
