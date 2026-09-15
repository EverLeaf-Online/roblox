local BelforgeColossusRules = {}

function BelforgeColossusRules.PhaseForHealth(currentHealth, maxHealth)
    currentHealth = math.max(0, tonumber(currentHealth) or 0)
    maxHealth = math.max(1, tonumber(maxHealth) or 1)
    local fraction = math.clamp(currentHealth / maxHealth, 0, 1)
    if fraction > 0.7 then
        return 1, "Pressure Rising"
    end
    if fraction > 0.35 then
        return 2, "Furnace Breach"
    end
    return 3, "Critical Overheat"
end

function BelforgeColossusRules.SpecialInterval(phase)
    if phase == 1 then
        return 7
    elseif phase == 2 then
        return 5.25
    end
    return 3.8
end

function BelforgeColossusRules.SpecialDamage(phase)
    if phase == 1 then
        return 18
    elseif phase == 2 then
        return 27
    end
    return 35
end

return BelforgeColossusRules
