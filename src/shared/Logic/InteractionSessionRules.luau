local InteractionSessionRules = {}

function InteractionSessionRules.CanValidate(expired, idMatches, worldObjectMatches, inRange)
    if expired then
        return false, "expired"
    end
    if not idMatches then
        return false, "id_mismatch"
    end
    if not worldObjectMatches then
        return false, "world_object_mismatch"
    end
    if not inRange then
        return false, "too_far"
    end
    return true
end

return table.freeze(InteractionSessionRules)
