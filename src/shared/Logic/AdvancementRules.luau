local AdvancementRules = {}

function AdvancementRules.CanFirstAdvance(profile, familyDefinition, trialQuestId)
    if type(profile) ~= "table" or type(familyDefinition) ~= "table" then
        return false, "invalid_state"
    end
    if tonumber(profile.AdvancementTier) ~= 0 then
        return false, "already_advanced"
    end
    if type(profile.FamilyId) == "string" and profile.FamilyId ~= "" then
        return false, "family_already_selected"
    end

    local requiredLevel = tonumber(familyDefinition.FirstAdvancementLevel)
    if not requiredLevel or requiredLevel < 1 or requiredLevel % 1 ~= 0 then
        return false, "invalid_requirement"
    end
    if (tonumber(profile.Level) or 1) < requiredLevel then
        return false, "level_too_low"
    end

    if type(trialQuestId) == "string" and trialQuestId ~= "" then
        local completed = profile.Quests
            and profile.Quests.Completed
            and profile.Quests.Completed[trialQuestId] == true
        if not completed then
            return false, "trial_incomplete"
        end
    end
    return true
end

function AdvancementRules.CanUseFamilySkill(profile, skillDefinition)
    if type(skillDefinition) ~= "table" then
        return false, "invalid_skill"
    end
    local familyId = skillDefinition.FamilyId
    if familyId == nil or familyId == "" then
        return true
    end
    if type(profile) ~= "table" or profile.FamilyId ~= familyId then
        return false, "wrong_family"
    end
    return true
end

return AdvancementRules
