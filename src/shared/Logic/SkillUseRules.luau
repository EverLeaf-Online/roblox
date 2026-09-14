local SkillUseRules = {}

function SkillUseRules.CanBegin(now, cooldownExpiresAt, currentMP, mpCost)
    if cooldownExpiresAt > now then
        return false, "cooldown"
    end
    if mpCost > 0 and currentMP < mpCost then
        return false, "insufficient_mp"
    end
    return true
end

return SkillUseRules
