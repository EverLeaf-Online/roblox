local CurrencyService = require(script.Parent.CurrencyService)
local ProgressionService = require(script.Parent.ProgressionService)

local RewardService = {}

function RewardService.Grant(profile, reward)
    if type(reward) ~= "table" then
        return false, "invalid_reward"
    end

    local result = {
        LevelsGained = 0,
        Currencies = {},
    }

    if reward.Exp then
        result.LevelsGained = ProgressionService.GrantExp(profile, reward.Exp)
    end

    if reward.Currencies then
        for currencyName, amount in reward.Currencies do
            local ok, balanceOrReason = CurrencyService.Add(profile, currencyName, amount)
            if not ok then
                return false, balanceOrReason
            end
            result.Currencies[currencyName] = balanceOrReason
        end
    end

    return true, result
end

return RewardService
