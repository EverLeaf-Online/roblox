local PayloadBounds = {}

local function bounded(value, depth)
    if depth > 4 then
        return false
    end
    local kind = type(value)
    if kind == "nil" or kind == "boolean" then
        return true
    end
    if kind == "number" then
        return value == value and value ~= math.huge and value ~= -math.huge
    end
    if kind == "string" then
        return #value <= 128
    end
    if kind ~= "table" then
        return false
    end

    local count = 0
    for key, child in value do
        count += 1
        if count > 32 then
            return false
        end
        if not bounded(key, depth + 1) or not bounded(child, depth + 1) then
            return false
        end
    end
    return true
end

function PayloadBounds.IsBounded(payload)
    return bounded(payload, 0)
end

return PayloadBounds
