local BossRewardRules = {}

local DEFAULT_MINIMUM_FRACTION = 0.02

function BossRewardRules.MinimumDamage(maxHealth, minimumFraction)
    maxHealth = math.max(1, tonumber(maxHealth) or 1)
    minimumFraction = tonumber(minimumFraction) or DEFAULT_MINIMUM_FRACTION
    minimumFraction = math.clamp(minimumFraction, 0, 1)
    return math.max(1, math.ceil(maxHealth * minimumFraction))
end

function BossRewardRules.IsEligible(damage, maxHealth, minimumFraction)
    damage = tonumber(damage) or 0
    return damage >= BossRewardRules.MinimumDamage(maxHealth, minimumFraction)
end

return table.freeze(BossRewardRules)
