local SkillProgressionRules = {}

local function learnedRank(profile, skillId)
    local skills = type(profile) == "table" and profile.Skills or nil
    local learned = type(skills) == "table" and skills.Learned or nil
    return math.max(0, math.floor(tonumber(learned and learned[skillId]) or 0))
end

function SkillProgressionRules.CheckPrerequisites(profile, definition)
    if type(definition) ~= "table" then
        return false, "invalid_skill"
    end
    for _, requirement in definition.Prerequisites or {} do
        if type(requirement) ~= "table" or type(requirement.SkillId) ~= "string" then
            return false, "invalid_prerequisite"
        end
        local requiredRank = math.max(1, math.floor(tonumber(requirement.Rank) or 1))
        if learnedRank(profile, requirement.SkillId) < requiredRank then
            return false, "prerequisite_unmet", requirement.SkillId, requiredRank
        end
    end
    return true
end

function SkillProgressionRules.CanLearn(profile, definition)
    if type(profile) ~= "table" or type(definition) ~= "table" then
        return false, "invalid_skill"
    end

    local familyId = definition.FamilyId
    if type(familyId) == "string" and familyId ~= "" and profile.FamilyId ~= familyId then
        return false, "wrong_family"
    end

    local requiredLevel = math.max(1, math.floor(tonumber(definition.RequiredLevel) or 1))
    if (tonumber(profile.Level) or 1) < requiredLevel then
        return false, "level_too_low"
    end

    local requiredTier = math.max(0, math.floor(tonumber(definition.RequiredTier) or 0))
    if (tonumber(profile.AdvancementTier) or 0) < requiredTier then
        return false, "tier_too_low"
    end

    local prereqOk, prereqReason, missingSkillId, missingRank =
        SkillProgressionRules.CheckPrerequisites(profile, definition)
    if not prereqOk then
        return false, prereqReason, missingSkillId, missingRank
    end

    local currentRank = learnedRank(profile, definition.Id or "")
    if definition.Id == nil then
        -- Server/client callers can pass the current rank explicitly in the
        -- transient field below without mutating the canonical definition.
        currentRank = math.max(0, math.floor(tonumber(definition.CurrentRank) or 0))
    end
    local maxRank = math.max(1, math.floor(tonumber(definition.MaxRank) or 1))
    if currentRank >= maxRank then
        return false, "max_rank"
    end

    local cost = math.max(1, math.floor(tonumber(definition.SPCostPerRank) or 1))
    if (tonumber(profile.SP) or 0) < cost then
        return false, "insufficient_sp"
    end

    return true
end

return SkillProgressionRules
