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

function DamageMath.ApplyCritical(damage, critChance, critMultiplier, unitRoll)
    damage = math.max(1, tonumber(damage) or 1)
    critChance = math.clamp(tonumber(critChance) or 0, 0, 1)
    critMultiplier = math.max(1, tonumber(critMultiplier) or 1.5)
    unitRoll = math.clamp(tonumber(unitRoll) or 1, 0, 1)
    if unitRoll < critChance then
        return math.max(1, math.floor(damage * critMultiplier + 0.5)), true
    end
    return math.max(1, math.floor(damage + 0.5)), false
end

function DamageMath.MitigateIncoming(damage, defense, defenseConstant)
    damage = math.max(0, tonumber(damage) or 0)
    defense = math.max(0, tonumber(defense) or 0)
    defenseConstant = math.max(1, tonumber(defenseConstant) or 100)
    if damage <= 0 then
        return 0
    end
    local multiplier = defenseConstant / (defenseConstant + defense)
    return math.max(1, math.floor(damage * multiplier + 0.5))
end

return DamageMath
