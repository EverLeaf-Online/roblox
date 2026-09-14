local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local CurrencyService = {}

local allowed = {}
for _, currencyName in GameConfig.Currencies do
    allowed[currencyName] = true
end

local function validAmount(amount)
    return type(amount) == "number" and amount % 1 == 0 and amount > 0
end

function CurrencyService.Add(profile, currencyName, amount)
    if not allowed[currencyName] then
        return false, "invalid_currency"
    end
    if not validAmount(amount) then
        return false, "invalid_amount"
    end

    profile.Currencies[currencyName] += amount
    return true, profile.Currencies[currencyName]
end

function CurrencyService.CanAfford(profile, currencyName, amount)
    if not allowed[currencyName] or not validAmount(amount) then
        return false
    end
    return profile.Currencies[currencyName] >= amount
end

function CurrencyService.Spend(profile, currencyName, amount)
    if not allowed[currencyName] then
        return false, "invalid_currency"
    end
    if not validAmount(amount) then
        return false, "invalid_amount"
    end
    if profile.Currencies[currencyName] < amount then
        return false, "insufficient_funds"
    end

    profile.Currencies[currencyName] -= amount
    return true, profile.Currencies[currencyName]
end

return CurrencyService
