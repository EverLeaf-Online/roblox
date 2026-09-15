local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, child in value do
        copy[deepCopy(key)] = deepCopy(child)
    end
    return copy
end

local ProfileTransaction = {}

local function commit(target, source)
    for key in target do
        target[key] = nil
    end
    for key, value in source do
        target[key] = value
    end
end

function ProfileTransaction.Run(profile, mutate)
    if type(profile) ~= "table" or type(mutate) ~= "function" then
        return false, "invalid_transaction"
    end
    local working = deepCopy(profile)
    local callOk, ok, result, extra = pcall(mutate, working)
    if not callOk then
        return false, "transaction_error", tostring(ok)
    end
    if not ok then
        return false, result, extra
    end
    commit(profile, working)
    return true, result, extra
end

return table.freeze(ProfileTransaction)
