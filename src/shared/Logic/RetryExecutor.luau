local RetryExecutor = {}

function RetryExecutor.DelayForAttempt(attempt, baseSeconds)
    attempt = math.max(1, math.floor(tonumber(attempt) or 1))
    baseSeconds = math.max(0, tonumber(baseSeconds) or 0)
    return baseSeconds * (2 ^ (attempt - 1))
end

function RetryExecutor.Run(operation, maxAttempts, baseSeconds, waitFunction)
    if type(operation) ~= "function" then
        return false, "invalid_operation", 0
    end
    maxAttempts = math.max(1, math.floor(tonumber(maxAttempts) or 1))
    baseSeconds = math.max(0, tonumber(baseSeconds) or 0)
    waitFunction = if type(waitFunction) == "function" then waitFunction else function() end

    local lastError = nil
    for attempt = 1, maxAttempts do
        local ok, result = pcall(operation, attempt)
        if ok then
            return true, result, attempt
        end
        lastError = result
        if attempt < maxAttempts then
            waitFunction(RetryExecutor.DelayForAttempt(attempt, baseSeconds), attempt)
        end
    end
    return false, lastError, maxAttempts
end

return table.freeze(RetryExecutor)
