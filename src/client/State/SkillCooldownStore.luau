local SkillCooldownStore = {}

local expirations = {}

function SkillCooldownStore.Start(skillId, duration, now)
    if type(skillId) ~= "string" or skillId == "" then
        return false
    end
    duration = math.max(0, tonumber(duration) or 0)
    now = tonumber(now) or os.clock()
    if duration <= 0 then
        expirations[skillId] = nil
        return true
    end
    expirations[skillId] = now + duration
    return true
end

function SkillCooldownStore.Remaining(skillId, now)
    local expiresAt = expirations[skillId]
    if type(expiresAt) ~= "number" then
        return 0
    end
    now = tonumber(now) or os.clock()
    local remaining = expiresAt - now
    if remaining <= 0 then
        expirations[skillId] = nil
        return 0
    end
    return remaining
end

function SkillCooldownStore.Fraction(skillId, duration, now)
    duration = math.max(0, tonumber(duration) or 0)
    if duration <= 0 then
        return 0
    end
    return math.clamp(SkillCooldownStore.Remaining(skillId, now) / duration, 0, 1)
end

function SkillCooldownStore.Clear(skillId)
    expirations[skillId] = nil
end

return SkillCooldownStore
