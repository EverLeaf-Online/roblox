local CurrencyRules = {}

local function finiteInteger(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value % 1 == 0
end

function CurrencyRules.IsValidAmount(amount)
    return finiteInteger(amount) and amount > 0
end

function CurrencyRules.IsValidBalance(balance, maximumBalance)
    maximumBalance = tonumber(maximumBalance)
    if not finiteInteger(maximumBalance) or maximumBalance < 0 then
        return false
    end
    return finiteInteger(balance) and balance >= 0 and balance <= maximumBalance
end

function CurrencyRules.Add(balance, amount, maximumBalance)
    if not CurrencyRules.IsValidBalance(balance, maximumBalance) then
        return false, "invalid_balance"
    end
    if not CurrencyRules.IsValidAmount(amount) then
        return false, "invalid_amount"
    end
    if amount > maximumBalance - balance then
        return false, "balance_cap"
    end
    return true, balance + amount
end

function CurrencyRules.CanAfford(balance, amount, maximumBalance)
    return CurrencyRules.IsValidBalance(balance, maximumBalance)
        and CurrencyRules.IsValidAmount(amount)
        and balance >= amount
end

function CurrencyRules.Spend(balance, amount, maximumBalance)
    if not CurrencyRules.IsValidBalance(balance, maximumBalance) then
        return false, "invalid_balance"
    end
    if not CurrencyRules.IsValidAmount(amount) then
        return false, "invalid_amount"
    end
    if balance < amount then
        return false, "insufficient_funds"
    end
    return true, balance - amount
end

return table.freeze(CurrencyRules)
