local PlayerDamageFeedbackRules = {}

function PlayerDamageFeedbackRules.Build(rawDamage, appliedDamage, maxHealth, stagger, sourceId)
    rawDamage = math.max(0, math.floor((tonumber(rawDamage) or 0) + 0.5))
    appliedDamage = math.max(0, math.floor((tonumber(appliedDamage) or 0) + 0.5))
    maxHealth = math.max(1, tonumber(maxHealth) or 1)
    stagger = math.max(0, tonumber(stagger) or 0)
    local mitigated = math.max(0, rawDamage - appliedDamage)
    local heavyThreshold = math.max(20, maxHealth * 0.2)
    return {
        Amount = appliedDamage,
        RawAmount = rawDamage,
        Mitigated = mitigated,
        SourceId = tostring(sourceId or "unknown"),
        Stagger = stagger,
        Heavy = appliedDamage >= heavyThreshold or stagger >= 0.4,
    }
end

return table.freeze(PlayerDamageFeedbackRules)
