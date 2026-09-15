local CombatHitboxMath = {}

function CombatHitboxMath.BoxSize(range, width, verticalRange)
    range = math.max(1, tonumber(range) or 1)
    width = math.max(1, tonumber(width) or 1)
    verticalRange = math.max(1, tonumber(verticalRange) or 1)
    return width, verticalRange * 2, range
end

return CombatHitboxMath
