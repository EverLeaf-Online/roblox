local DerivedStatsMath = {}

function DerivedStatsMath.Compute(level, might, insight, tuning)
    level = math.max(1, math.floor(tonumber(level) or 1))
    might = math.max(0, math.floor(tonumber(might) or 0))
    insight = math.max(0, math.floor(tonumber(insight) or 0))

    local maxHP = tuning.BaseHP + (level - 1) * tuning.HPPerLevel + might * tuning.HPPerMight
    local maxMP = tuning.BaseMP + (level - 1) * tuning.MPPerLevel + insight * tuning.MPPerInsight

    return {
        MaxHP = math.max(1, math.floor(maxHP)),
        MaxMP = math.max(0, math.floor(maxMP)),
    }
end

return DerivedStatsMath
