local HttpService = game:GetService("HttpService")
local InstanceService = {}
local instances = {}

function InstanceService.Create(kind, ownerUserId, memberUserIds)
    local id = HttpService:GenerateGUID(false)
    local state = {
        Id = id,
        Kind = kind,
        OwnerUserId = ownerUserId,
        MemberUserIds = memberUserIds or { ownerUserId },
        CreatedAt = os.time(),
        State = "Active",
    }
    instances[id] = state
    return state
end

function InstanceService.Get(instanceId)
    return instances[instanceId]
end
function InstanceService.Close(instanceId)
    if not instances[instanceId] then
        return false
    end
    instances[instanceId] = nil
    return true
end

return InstanceService
