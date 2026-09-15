local AttackCadenceMath = {}

local function finiteNumber(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value or value == math.huge or value == -math.huge then
        return tonumber(fallback) or 0
    end
    return value
end

function AttackCadenceMath.ResolveBonus(bonusPercent, tuning)
    tuning = type(tuning) == "table" and tuning or {}
    local minimum = finiteNumber(tuning.MinimumAttackSpeedBonus, -40)
    local maximum = math.max(minimum, finiteNumber(tuning.MaximumAttackSpeedBonus, 30))
    return math.clamp(finiteNumber(bonusPercent, 0), minimum, maximum)
end

function AttackCadenceMath.ResolveCooldown(baseCooldown, bonusPercent, tuning)
    tuning = type(tuning) == "table" and tuning or {}
    local minimumCooldown = math.max(0.05, finiteNumber(tuning.MinimumBasicAttackCooldown, 0.28))
    local base = math.max(minimumCooldown, finiteNumber(baseCooldown, minimumCooldown))
    local bonus = AttackCadenceMath.ResolveBonus(bonusPercent, tuning)
    local speedMultiplier = math.max(0.1, 1 + bonus / 100)
    return math.max(minimumCooldown, base / speedMultiplier), bonus
end

return table.freeze(AttackCadenceMath)
