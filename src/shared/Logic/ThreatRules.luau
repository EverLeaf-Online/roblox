local ThreatRules = {}

function ThreatRules.ShouldSwitch(currentThreat, challengerThreat, switchRatio)
    currentThreat = math.max(0, tonumber(currentThreat) or 0)
    challengerThreat = math.max(0, tonumber(challengerThreat) or 0)
    switchRatio = math.max(1, tonumber(switchRatio) or 1)

    if challengerThreat <= 0 then
        return false
    end
    if currentThreat <= 0 then
        return true
    end
    return challengerThreat >= currentThreat * switchRatio
end

function ThreatRules.Add(currentThreat, amount)
    currentThreat = math.max(0, tonumber(currentThreat) or 0)
    amount = tonumber(amount) or 0
    if amount <= 0 or amount ~= amount or amount == math.huge then
        return currentThreat
    end
    return currentThreat + amount
end

return table.freeze(ThreatRules)
