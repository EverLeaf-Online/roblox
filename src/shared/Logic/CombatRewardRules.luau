local CombatRewardRules = {}

local function finiteNonNegative(value)
    value = tonumber(value)
    if value == nil or value ~= value or value == math.huge or value == -math.huge then
        return 0
    end
    return math.max(0, value)
end

local function normalizedFraction(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value or value == math.huge or value == -math.huge then
        value = fallback
    end
    return math.clamp(value or 0, 0, 1)
end

local function orderedContributors(contributors)
    local result = {}
    for _, entry in contributors or {} do
        local userId = tonumber(entry.UserId)
        local damage = finiteNonNegative(entry.Damage)
        if userId and userId % 1 == 0 and userId > 0 and damage > 0 then
            table.insert(result, { UserId = userId, Damage = damage })
        end
    end
    table.sort(result, function(a, b)
        if a.Damage ~= b.Damage then
            return a.Damage > b.Damage
        end
        return a.UserId < b.UserId
    end)
    return result
end

local function copyReward(reward)
    local result = {}
    if type(reward) ~= "table" then
        return result
    end
    if reward.Exp ~= nil then
        result.Exp = reward.Exp
    end
    if type(reward.Currencies) == "table" then
        result.Currencies = table.clone(reward.Currencies)
    end
    if type(reward.Items) == "table" then
        result.Items = table.clone(reward.Items)
    end
    if type(reward.UnlockRegions) == "table" then
        result.UnlockRegions = table.clone(reward.UnlockRegions)
    end
    return result
end

function CombatRewardRules.CreditDamage(totalCredited, maxHealth, requestedDamage)
    totalCredited = finiteNonNegative(totalCredited)
    maxHealth = math.max(1, finiteNonNegative(maxHealth))
    requestedDamage = finiteNonNegative(requestedDamage)
    local remaining = math.max(0, maxHealth - totalCredited)
    return math.min(requestedDamage, remaining)
end

function CombatRewardRules.MinimumDamage(maxHealth, fraction)
    maxHealth = math.max(1, finiteNonNegative(maxHealth))
    fraction = normalizedFraction(fraction, 0.05)
    return math.max(1, math.ceil(maxHealth * fraction))
end

function CombatRewardRules.ContributionFraction(config, tuning)
    config = type(config) == "table" and config or {}
    tuning = type(tuning) == "table" and tuning or {}
    if config.Boss == true then
        return normalizedFraction(config.MinimumRewardContribution, 0.02)
    end
    if config.Elite == true then
        return normalizedFraction(tuning.EliteRewardContributionFraction, 0.03)
    end
    return normalizedFraction(tuning.NormalRewardContributionFraction, 0.05)
end

function CombatRewardRules.EligibleContributors(contributors, maxHealth, fraction)
    local ordered = orderedContributors(contributors)
    if #ordered == 0 then
        return {}, nil
    end
    local winner = ordered[1]
    local minimumDamage = CombatRewardRules.MinimumDamage(maxHealth, fraction)
    local eligible = {}
    for _, entry in ordered do
        if entry.Damage >= minimumDamage then
            table.insert(eligible, entry)
        end
    end
    if #eligible == 0 then
        table.insert(eligible, winner)
    end
    return eligible, winner
end

local function splitInteger(total, eligible)
    total = math.max(0, math.floor(tonumber(total) or 0))
    local result = {}
    if total == 0 or #eligible == 0 then
        return result
    end

    local totalDamage = 0
    for _, entry in eligible do
        totalDamage += entry.Damage
    end
    if totalDamage <= 0 then
        result[eligible[1].UserId] = total
        return result
    end

    local assigned = 0
    local remainders = {}
    for _, entry in eligible do
        local exact = total * entry.Damage / totalDamage
        local base = math.floor(exact)
        result[entry.UserId] = base
        assigned += base
        table.insert(remainders, {
            UserId = entry.UserId,
            Fraction = exact - base,
            Damage = entry.Damage,
        })
    end
    table.sort(remainders, function(a, b)
        if a.Fraction ~= b.Fraction then
            return a.Fraction > b.Fraction
        end
        if a.Damage ~= b.Damage then
            return a.Damage > b.Damage
        end
        return a.UserId < b.UserId
    end)

    local remaining = total - assigned
    for index = 1, remaining do
        local entry = remainders[((index - 1) % #remainders) + 1]
        result[entry.UserId] = (result[entry.UserId] or 0) + 1
    end
    return result
end

local function splitSharedReward(reward, eligible)
    local byUserId = {}
    for _, entry in eligible do
        byUserId[entry.UserId] = {}
    end

    if type(reward) ~= "table" then
        return byUserId
    end
    if reward.Exp ~= nil then
        for userId, amount in splitInteger(reward.Exp, eligible) do
            if amount > 0 then
                byUserId[userId].Exp = amount
            end
        end
    end
    for currencyName, total in reward.Currencies or {} do
        for userId, amount in splitInteger(total, eligible) do
            if amount > 0 then
                local currencies = byUserId[userId].Currencies
                if not currencies then
                    currencies = {}
                    byUserId[userId].Currencies = currencies
                end
                currencies[currencyName] = amount
            end
        end
    end
    return byUserId
end

function CombatRewardRules.BuildPlan(contributors, maxHealth, config, reward, tuning)
    config = type(config) == "table" and config or {}
    local fraction = CombatRewardRules.ContributionFraction(config, tuning)
    local eligible, winner =
        CombatRewardRules.EligibleContributors(contributors, maxHealth, fraction)
    local plan = {
        Eligible = eligible,
        WinnerUserId = winner and winner.UserId or nil,
        RewardByUserId = {},
        LootUserIds = {},
        SharedPool = config.Boss ~= true,
        MinimumDamage = CombatRewardRules.MinimumDamage(maxHealth, fraction),
    }
    if #eligible == 0 then
        return plan
    end

    if config.Boss == true then
        for _, entry in eligible do
            plan.RewardByUserId[entry.UserId] = copyReward(reward)
            table.insert(plan.LootUserIds, entry.UserId)
        end
    else
        plan.RewardByUserId = splitSharedReward(reward, eligible)
        if winner then
            table.insert(plan.LootUserIds, winner.UserId)
        end
    end
    return plan
end

function CombatRewardRules.HasReward(reward)
    if type(reward) ~= "table" then
        return false
    end
    if (tonumber(reward.Exp) or 0) > 0 then
        return true
    end
    for _, amount in reward.Currencies or {} do
        if (tonumber(amount) or 0) > 0 then
            return true
        end
    end
    for _, quantity in reward.Items or {} do
        if (tonumber(quantity) or 0) > 0 then
            return true
        end
    end
    return type(reward.UnlockRegions) == "table" and #reward.UnlockRegions > 0
end

return table.freeze(CombatRewardRules)
