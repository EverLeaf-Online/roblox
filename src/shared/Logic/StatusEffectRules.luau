local StatusEffectRules = {}

function StatusEffectRules.ValidateDefinition(effectId, definition)
    if type(effectId) ~= "string" or effectId == "" or #effectId > 64 then
        return false, "invalid_effect_id"
    end
    if type(definition) ~= "table" then
        return false, "missing_definition"
    end
    if type(definition.DisplayName) ~= "string" or definition.DisplayName == "" then
        return false, "invalid_display_name"
    end
    if definition.Kind ~= "Buff" and definition.Kind ~= "Debuff" then
        return false, "invalid_kind"
    end
    if definition.ShortName ~= nil then
        if
            type(definition.ShortName) ~= "string"
            or definition.ShortName == ""
            or #definition.ShortName > 16
        then
            return false, "invalid_short_name"
        end
    end
    return true
end

function StatusEffectRules.ValidateApply(effectId, durationSeconds, definitions, maximumDuration)
    definitions = type(definitions) == "table" and definitions or {}
    local definition = definitions[effectId]
    local definitionOk, definitionReason =
        StatusEffectRules.ValidateDefinition(effectId, definition)
    if not definitionOk then
        return false, definitionReason
    end

    durationSeconds = tonumber(durationSeconds)
    if
        durationSeconds == nil
        or durationSeconds ~= durationSeconds
        or durationSeconds == math.huge
        or durationSeconds == -math.huge
        or durationSeconds <= 0
    then
        return false, "invalid_duration"
    end
    maximumDuration = math.max(0.1, tonumber(maximumDuration) or 3600)
    if durationSeconds > maximumDuration then
        return false, "duration_too_long"
    end
    return true, definition
end

function StatusEffectRules.ResolveExpiry(now, currentExpiresAt, durationSeconds)
    now = tonumber(now) or 0
    currentExpiresAt = tonumber(currentExpiresAt) or 0
    durationSeconds = math.max(0, tonumber(durationSeconds) or 0)
    return math.max(currentExpiresAt, now + durationSeconds)
end

return table.freeze(StatusEffectRules)
