local MonsterAttackHitboxMath = {}

function MonsterAttackHitboxMath.ResolveWidth(range, overrideWidth, tuning)
    range = math.max(0, tonumber(range) or 0)
    overrideWidth = tonumber(overrideWidth)
    if overrideWidth and overrideWidth > 0 then
        return overrideWidth
    end

    tuning = tuning or {}
    local multiplier = math.max(0, tonumber(tuning.WidthMultiplier) or 1)
    local minimum = math.max(1, tonumber(tuning.MinWidth) or 1)
    local maximum = math.max(minimum, tonumber(tuning.MaxWidth) or minimum)
    return math.clamp(range * multiplier, minimum, maximum)
end

function MonsterAttackHitboxMath.ResolveDepth(range, slack)
    range = math.max(0, tonumber(range) or 0)
    slack = math.max(0, tonumber(slack) or 0)
    return math.max(1, range + slack)
end

return table.freeze(MonsterAttackHitboxMath)
