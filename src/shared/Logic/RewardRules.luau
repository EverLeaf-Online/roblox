local RewardRules = {}

local function positiveInteger(value)
    return type(value) == "number" and value % 1 == 0 and value > 0
end

function RewardRules.Validate(reward)
    if type(reward) ~= "table" then
        return false, "invalid_reward"
    end
    if reward.Exp ~= nil and not positiveInteger(reward.Exp) then
        return false, "invalid_exp"
    end
    if reward.Currencies ~= nil then
        if type(reward.Currencies) ~= "table" then
            return false, "invalid_currencies"
        end
        for currencyName, amount in reward.Currencies do
            if type(currencyName) ~= "string" or not positiveInteger(amount) then
                return false, "invalid_currency_reward"
            end
        end
    end
    if reward.Items ~= nil then
        if type(reward.Items) ~= "table" then
            return false, "invalid_items"
        end
        for itemId, quantity in reward.Items do
            if type(itemId) ~= "string" or not positiveInteger(quantity) then
                return false, "invalid_item_reward"
            end
        end
    end
    return true
end

return RewardRules
