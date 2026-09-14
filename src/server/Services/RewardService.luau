local CurrencyService = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)

local RewardService = {}

function RewardService.Grant(profile, reward)
    if type(reward) ~= "table" then
        return false, "invalid_reward"
    end

    if reward.Items then
        for itemId, quantity in reward.Items do
            if not InventoryService.CanAdd(profile, itemId, quantity) then
                return false, "inventory_full"
            end
        end
    end

    local result = { LevelsGained = 0, Currencies = {}, Items = {} }
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
    if reward.Items then
        for itemId, quantity in reward.Items do
            local ok, reason = InventoryService.Add(profile, itemId, quantity)
            if not ok then
                return false, reason
            end
            result.Items[itemId] = quantity
        end
    end
    return true, result
end

return RewardService
