local QuestAccessRules = {}

function QuestAccessRules.CanStart(profile, definition)
    if type(profile) ~= "table" or type(definition) ~= "table" then
        return false, "invalid_state"
    end
    if (tonumber(profile.Level) or 1) < (tonumber(definition.MinimumLevel) or 1) then
        return false, "level_too_low"
    end
    if
        (tonumber(profile.AdvancementTier) or 0)
        < (tonumber(definition.MinimumAdvancementTier) or 0)
    then
        return false, "advancement_too_low"
    end
    for _, prerequisiteId in definition.PrerequisiteQuests or {} do
        if
            not (
                profile.Quests
                and profile.Quests.Completed
                and profile.Quests.Completed[prerequisiteId] == true
            )
        then
            return false, "prerequisite_incomplete"
        end
    end
    return true
end

return QuestAccessRules
