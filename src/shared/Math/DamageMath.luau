local DamageMath = {}

function DamageMath.CalculateRange(primaryValue, attackPower, statScale, mastery)
    primaryValue = math.max(0, tonumber(primaryValue) or 0)
    attackPower = math.max(0, tonumber(attackPower) or 0)
    statScale = math.max(0, tonumber(statScale) or 1)
    mastery = math.clamp(tonumber(mastery) or 0.25, 0, 1)

    local maximum = math.max(1, attackPower + primaryValue * statScale)
    local minimum = math.max(1, maximum * mastery)
    return minimum, maximum
end

function DamageMath.RollFromUnit(minimum, maximum, unitRoll)
    unitRoll = math.clamp(tonumber(unitRoll) or 0, 0, 1)
    local rolled = minimum + (maximum - minimum) * unitRoll
    return math.max(1, math.floor(rolled + 0.5))
end

return DamageMath
