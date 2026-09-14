local ServerStorage = game:GetService("ServerStorage")

local EnvironmentPrefabService = {}

local BLOCKED_CLASSES = {
    Script = true,
    LocalScript = true,
    ModuleScript = true,
    RemoteEvent = true,
    RemoteFunction = true,
    BindableEvent = true,
    BindableFunction = true,
    ClickDetector = true,
    ProximityPrompt = true,
    Sound = true,
}

local function getFolder()
    local folder = ServerStorage:FindFirstChild("EnvironmentAssets")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "EnvironmentAssets"
        folder.Parent = ServerStorage
    end
    return folder
end

local function sanitize(instance)
    for _, descendant in instance:GetDescendants() do
        if BLOCKED_CLASSES[descendant.ClassName] then
            descendant:Destroy()
        elseif descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanTouch = false
            descendant.CanQuery = true
        end
    end
end

local function setCollision(instance)
    for _, descendant in instance:GetDescendants() do
        if descendant:IsA("BasePart") then
            local name = string.lower(descendant.Name)
            local trunkLike = string.find(name, "trunk", 1, true) ~= nil
                or string.find(name, "stem", 1, true) ~= nil
            descendant.CanCollide = trunkLike
        end
    end
end

local function normalizeModel(model)
    if model:IsA("BasePart") then
        model.Anchored = true
        model.CanTouch = false
        model.CanQuery = true
        local name = string.lower(model.Name)
        model.CanCollide = string.find(name, "trunk", 1, true) ~= nil
            or string.find(name, "stem", 1, true) ~= nil
    end
    sanitize(model)
    setCollision(model)
    if model:IsA("Model") and not model.PrimaryPart then
        local candidate = model:FindFirstChildWhichIsA("BasePart", true)
        if candidate then
            model.PrimaryPart = candidate
        end
    end
end

function EnvironmentPrefabService.Get(prefabName)
    local prefab = getFolder():FindFirstChild(prefabName)
    if not prefab then
        return nil
    end
    return prefab
end

function EnvironmentPrefabService.Register(prefabName, instance, sourceAssetId)
    if type(prefabName) ~= "string" or prefabName == "" or typeof(instance) ~= "Instance" then
        return false, "invalid_prefab"
    end

    normalizeModel(instance)
    instance.Name = prefabName
    instance:SetAttribute("SourceAssetId", sourceAssetId)
    instance.Parent = getFolder()
    return true, instance
end

function EnvironmentPrefabService.Place(prefabName, parent, pivot, scale)
    local prefab = EnvironmentPrefabService.Get(prefabName)
    if not prefab then
        return nil, "prefab_missing"
    end

    local clone = prefab:Clone()
    normalizeModel(clone)
    clone.Name = prefabName
    clone.Parent = parent

    scale = tonumber(scale) or 1
    if clone:IsA("Model") then
        pcall(function()
            clone:ScaleTo(scale)
        end)
        clone:PivotTo(pivot)
    elseif clone:IsA("BasePart") then
        clone.Size *= scale
        clone.CFrame = pivot
    else
        clone:Destroy()
        return nil, "unsupported_prefab_root"
    end

    return clone
end

return EnvironmentPrefabService
