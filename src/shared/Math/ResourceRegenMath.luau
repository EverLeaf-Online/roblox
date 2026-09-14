local ResourceRegenMath = {}

function ResourceRegenMath.MPPerTick(insight, config)
    insight = math.max(0, tonumber(insight) or 0)
    return math.max(
        0,
        (config.BaseMPPerSecond or 0) + insight * (config.MPPerInsightPerSecond or 0)
    ) * (config.RegenTickSeconds or 1)
end

function ResourceRegenMath.HPPerTick(maxHP, config)
    maxHP = math.max(1, tonumber(maxHP) or 1)
    local perSecond =
        math.max(config.MinimumHPPerSecond or 0, maxHP * (config.HPPercentPerSecond or 0))
    return perSecond * (config.RegenTickSeconds or 1)
end

return ResourceRegenMath
