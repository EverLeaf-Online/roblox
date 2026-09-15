local PartyInstanceRules = {}

local function positiveInteger(value, maximum)
    return type(value) == "number" and value % 1 == 0 and value >= 1 and value <= maximum
end

local function positiveFinite(value, maximum)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value > 0
        and value <= maximum
end

function PartyInstanceRules.ValidateDefinition(instanceId, definition)
    if type(instanceId) ~= "string" or instanceId == "" or #instanceId > 64 then
        return false, "invalid_instance_id"
    end
    if type(definition) ~= "table" or definition.Id ~= instanceId then
        return false, "invalid_definition"
    end
    for _, fieldName in { "Purpose", "EntrySpawnId", "DestinationSpawnId", "ReturnSpawnId" } do
        local value = definition[fieldName]
        if type(value) ~= "string" or value == "" or #value > 96 then
            return false, "invalid_" .. string.lower(fieldName)
        end
    end
    if not positiveInteger(definition.MinimumPartySize, 100) then
        return false, "invalid_minimum_party_size"
    end
    if not positiveInteger(definition.MaximumPartySize, 100) then
        return false, "invalid_maximum_party_size"
    end
    if definition.MinimumPartySize > definition.MaximumPartySize then
        return false, "invalid_party_size_range"
    end
    if not positiveFinite(definition.AssemblyRadius, 1000) then
        return false, "invalid_assembly_radius"
    end
    if not positiveFinite(definition.ReadyCheckSeconds, 300) then
        return false, "invalid_ready_check_seconds"
    end
    return true
end

function PartyInstanceRules.CanStart(isLeader, memberCount, definition)
    if type(definition) ~= "table" then
        return false, "invalid_definition"
    end
    memberCount = math.max(0, math.floor(tonumber(memberCount) or 0))
    if not isLeader then
        return false, "not_party_leader"
    end
    if memberCount < (tonumber(definition.MinimumPartySize) or 1) then
        return false, "party_too_small"
    end
    if memberCount > (tonumber(definition.MaximumPartySize) or 1) then
        return false, "party_too_large"
    end
    return true
end

function PartyInstanceRules.IsAssembled(distance, definition)
    distance = tonumber(distance)
    if
        distance == nil
        or distance ~= distance
        or distance == math.huge
        or distance == -math.huge
    then
        return false
    end
    local radius = type(definition) == "table" and tonumber(definition.AssemblyRadius) or nil
    return radius ~= nil and radius > 0 and distance <= radius
end

return table.freeze(PartyInstanceRules)
