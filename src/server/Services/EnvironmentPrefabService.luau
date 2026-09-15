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
    Texture = true,
    Decal = true,
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

local function contentId(assetId)
    if type(assetId) ~= "number" or assetId <= 0 then
        return ""
    end
    return "rbxassetid://" .. tostring(assetId)
end

local function isFoliagePart(part)
    local lower = string.lower(part.Name)
    return string.find(lower, "twig", 1, true) ~= nil
        or string.find(lower, "leaf", 1, true) ~= nil
        or string.find(lower, "needle", 1, true) ~= nil
        or string.find(lower, "foliage", 1, true) ~= nil
end

local function applyAppearance(instance, appearance)
    if type(appearance) ~= "table" then
        return
    end

    local meshParts = {}
    if instance:IsA("MeshPart") then
        table.insert(meshParts, instance)
    end
    for _, descendant in instance:GetDescendants() do
        if descendant:IsA("MeshPart") then
            table.insert(meshParts, descendant)
        end
    end

    for _, part in meshParts do
        local foliage = isFoliagePart(part)
        local maps = if foliage then appearance.Foliage else appearance.Bark
        if maps then
            -- Controlled EverLeaf PBR must replace legacy/raw texture layers,
            -- never stack on top of whatever the imported GLB happened to keep.
            for _, child in part:GetChildren() do
                if child:IsA("Texture") or child:IsA("Decal") then
                    child:Destroy()
                end
            end
            pcall(function()
                part.TextureID = ""
            end)

            local surface = part:FindFirstChildOfClass("SurfaceAppearance")
            if not surface then
                surface = Instance.new("SurfaceAppearance")
                surface.Name = "EverLeafSurfaceAppearance"
                surface.Parent = part
            end
            for _, child in part:GetChildren() do
                if child:IsA("SurfaceAppearance") and child ~= surface then
                    child:Destroy()
                end
            end
            surface.Name = "EverLeafSurfaceAppearance"
            surface.ColorMap = contentId(maps.ColorMap)
            surface.NormalMap = contentId(maps.NormalMap)
            surface.RoughnessMap = contentId(maps.RoughnessMap)
            surface.MetalnessMap = ""
            if foliage then
                surface.AlphaMode = Enum.AlphaMode.Transparency
                part.DoubleSided = true
            else
                surface.AlphaMode = Enum.AlphaMode.Overlay
            end
            part.Color = Color3.new(1, 1, 1)
            part.Material = Enum.Material.SmoothPlastic
            part:SetAttribute("EverLeafAppearanceNormalized", true)
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

local function findTrunkLikePart(instance)
    local best = nil
    local bestScore = -math.huge
    local candidates = { instance }
    for _, descendant in instance:GetDescendants() do
        table.insert(candidates, descendant)
    end

    for _, candidate in candidates do
        if candidate:IsA("BasePart") then
            local lower = string.lower(candidate.Name)
            local nameScore = 0
            if string.find(lower, "trunk", 1, true) then
                nameScore = 1000
            elseif string.find(lower, "stem", 1, true) then
                nameScore = 800
            elseif string.find(lower, "tree", 1, true) then
                nameScore = 300
            elseif string.find(lower, "wood", 1, true) then
                nameScore = 150
            end

            local longest = math.max(candidate.Size.X, candidate.Size.Y, candidate.Size.Z)
            local score = nameScore + longest
            if score > bestScore then
                best = candidate
                bestScore = score
            end
        end
    end

    return best
end

local function autoUprightTree(instance)
    local trunk = findTrunkLikePart(instance)
    if not trunk then
        return false
    end

    local localAxis
    if trunk.Size.X >= trunk.Size.Y and trunk.Size.X >= trunk.Size.Z then
        localAxis = Vector3.xAxis
    elseif trunk.Size.Z >= trunk.Size.X and trunk.Size.Z >= trunk.Size.Y then
        localAxis = Vector3.zAxis
    else
        localAxis = Vector3.yAxis
    end

    local worldAxis = trunk.CFrame:VectorToWorldSpace(localAxis)
    if worldAxis.Y < 0 then
        worldAxis = -worldAxis
    end

    local dot = math.clamp(worldAxis:Dot(Vector3.yAxis), -1, 1)
    if dot > 0.985 then
        return true
    end

    local rotationAxis = worldAxis:Cross(Vector3.yAxis)
    if rotationAxis.Magnitude < 0.001 then
        rotationAxis = Vector3.xAxis
    else
        rotationAxis = rotationAxis.Unit
    end
    local angle = math.acos(dot)
    local pivot = instance:IsA("Model") and instance:GetPivot() or instance.CFrame
    local rotation = CFrame.fromAxisAngle(rotationAxis, angle)

    if instance:IsA("Model") then
        instance:PivotTo(CFrame.new(pivot.Position) * rotation * (pivot - pivot.Position))
    elseif instance:IsA("BasePart") then
        instance.CFrame = CFrame.new(pivot.Position) * rotation * (pivot - pivot.Position)
    end

    return true
end

function EnvironmentPrefabService.Register(prefabName, instance, sourceAssetId, options)
    if type(prefabName) ~= "string" or prefabName == "" or typeof(instance) ~= "Instance" then
        return false, "invalid_prefab"
    end

    normalizeModel(instance)
    if options and options.Appearance then
        applyAppearance(instance, options.Appearance)
    end
    if options and options.AutoUpright then
        autoUprightTree(instance)
    end
    instance.Name = prefabName
    instance:SetAttribute("SourceAssetId", sourceAssetId)
    instance:SetAttribute("GroundToPivot", options and options.GroundToPivot == true or false)
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
        if clone:GetAttribute("GroundToPivot") == true then
            local boundsCFrame, boundsSize = clone:GetBoundingBox()
            local bottomY = boundsCFrame.Position.Y - boundsSize.Y * 0.5
            local verticalOffset = pivot.Position.Y - bottomY
            clone:PivotTo(CFrame.new(0, verticalOffset, 0) * clone:GetPivot())
        end
    elseif clone:IsA("BasePart") then
        clone.Size *= scale
        clone.CFrame = pivot
        if clone:GetAttribute("GroundToPivot") == true then
            clone.CFrame += Vector3.new(0, clone.Size.Y * 0.5, 0)
        end
    else
        clone:Destroy()
        return nil, "unsupported_prefab_root"
    end

    return clone
end

return EnvironmentPrefabService
