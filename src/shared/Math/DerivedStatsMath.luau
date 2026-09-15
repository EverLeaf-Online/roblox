local DerivedStatsMath = {}

function DerivedStatsMath.Compute(level, might, finesse, insight, fortune, tuning, bonuses)
    level = math.max(1, math.floor(tonumber(level) or 1))
    might = math.max(0, tonumber(might) or 0)
    finesse = math.max(0, tonumber(finesse) or 0)
    insight = math.max(0, tonumber(insight) or 0)
    fortune = math.max(0, tonumber(fortune) or 0)
    bonuses = bonuses or {}

    local maxHP = tuning.BaseHP
        + (level - 1) * tuning.HPPerLevel
        + might * tuning.HPPerMight
        + math.max(0, tonumber(bonuses.MaxHP) or 0)
    local maxMP = tuning.BaseMP
        + (level - 1) * tuning.MPPerLevel
        + insight * tuning.MPPerInsight
        + math.max(0, tonumber(bonuses.MaxMP) or 0)
    local defense = tuning.BaseDefense
        + (level - 1) * tuning.DefensePerLevel
        + might * tuning.DefensePerMight
        + math.max(0, tonumber(bonuses.Defense) or 0)
    local critChance = tuning.BaseCritChance
        + fortune * tuning.CritChancePerFortune
        + finesse * tuning.CritChancePerFinesse
        + math.max(0, tonumber(bonuses.CritChance) or 0) / 100
    local critMultiplier = tuning.BaseCritMultiplier
        + finesse * tuning.CritMultiplierPerFinesse
        + fortune * tuning.CritMultiplierPerFortune
        + math.max(0, tonumber(bonuses.CritPower) or 0) / 100

    return {
        MaxHP = math.max(1, math.floor(maxHP)),
        MaxMP = math.max(0, math.floor(maxMP)),
        Defense = math.max(0, math.floor(defense * 10 + 0.5) / 10),
        CritChance = math.clamp(critChance, 0, tuning.MaximumCritChance),
        CritMultiplier = math.clamp(critMultiplier, 1, tuning.MaximumCritMultiplier),
    }
end

return DerivedStatsMath
