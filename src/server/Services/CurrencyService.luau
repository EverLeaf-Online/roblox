local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyRules = require(ReplicatedStorage.Shared.Logic.CurrencyRules)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local CurrencyService = {}

local allowed = {}
for _, currencyName in GameConfig.Currencies do
    allowed[currencyName] = true
end

local function getBalance(profile, currencyName)
    if type(profile) ~= "table" or type(profile.Currencies) ~= "table" then
        return nil
    end
    return profile.Currencies[currencyName]
end

function CurrencyService.Add(profile, currencyName, amount)
    if not allowed[currencyName] then
        return false, "invalid_currency"
    end
    local balance = getBalance(profile, currencyName)
    local ok, balanceOrReason =
        CurrencyRules.Add(balance, amount, GameConfig.CurrencyMaximumBalance)
    if not ok then
        return false, balanceOrReason
    end
    profile.Currencies[currencyName] = balanceOrReason
    return true, balanceOrReason
end

function CurrencyService.CanAfford(profile, currencyName, amount)
    if not allowed[currencyName] then
        return false
    end
    return CurrencyRules.CanAfford(
        getBalance(profile, currencyName),
        amount,
        GameConfig.CurrencyMaximumBalance
    )
end

function CurrencyService.Spend(profile, currencyName, amount)
    if not allowed[currencyName] then
        return false, "invalid_currency"
    end
    local balance = getBalance(profile, currencyName)
    local ok, balanceOrReason =
        CurrencyRules.Spend(balance, amount, GameConfig.CurrencyMaximumBalance)
    if not ok then
        return false, balanceOrReason
    end
    profile.Currencies[currencyName] = balanceOrReason
    return true, balanceOrReason
end

return CurrencyService
