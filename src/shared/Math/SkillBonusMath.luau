local SkillBonusMath = {}

function SkillBonusMath.Compute(learned, definitions, statName)
    if type(learned) ~= "table" or type(definitions) ~= "table" or type(statName) ~= "string" then
        return 0
    end
    local total = 0
    for skillId, rankValue in learned do
        local rank = math.max(0, math.floor(tonumber(rankValue) or 0))
        if rank > 0 then
            local definition = definitions[skillId]
            local bonuses = definition
                and definition.Kind == "Passive"
                and definition.PassiveBonuses
            local perRank = bonuses and tonumber(bonuses[statName])
            if perRank then
                total += perRank * rank
            end
        end
    end
    return total
end

return SkillBonusMath
