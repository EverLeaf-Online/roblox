local WorldObjectService = {}
local registry = {}

function WorldObjectService.Register(instance, kind, objectId)
    if typeof(instance) ~= "Instance" or type(kind) ~= "string" or type(objectId) ~= "string" then
        return false, "invalid_world_object"
    end
    registry[instance] = { Kind = kind, Id = objectId }
    -- Mirror the authoritative registry entry into attributes so Studio/runtime
    -- inspection can verify portal/NPC/object wiring without depending on this
    -- module's private table. Interaction still validates against the registry.
    instance:SetAttribute("WorldObjectKind", kind)
    instance:SetAttribute("WorldObjectId", objectId)
    instance.Destroying:Once(function()
        registry[instance] = nil
    end)
    return true
end

function WorldObjectService.Get(instance)
    return registry[instance]
end

function WorldObjectService.CanInteract(player, instance, maxDistance)
    local character = player.Character
    local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not playerRoot or typeof(instance) ~= "Instance" then
        return false
    end
    local objectRoot = if instance:IsA("Model") then instance.PrimaryPart else instance
    if not objectRoot or not objectRoot:IsA("BasePart") then
        return false
    end
    return (objectRoot.Position - playerRoot.Position).Magnitude <= (maxDistance or 10)
end

return WorldObjectService
