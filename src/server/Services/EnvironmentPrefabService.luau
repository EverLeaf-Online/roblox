local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
    Animation = true,
    Dialog = true,
    Tool = true,
    Humanoid = true,
    AnimationController = true,
    Animator = true,
    Seat = true,
    VehicleSeat = true,
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
        local blocked = BLOCKED_CLASSES[descendant.ClassName]
            or descendant:IsA("LuaSourceContainer")
            or descendant:IsA("Constraint")
            or descendant:IsA("JointInstance")
            or descendant:IsA("WeldConstraint")
            or descendant:IsA("PackageLink")
        if blocked then
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

local FOLIAGE_TOKENS = table.freeze({ "twig", "leaf", "needle", "foliage" })

local function containsFoliageToken(value)
    local lower = string.lower(tostring(value or ""))
    for _, token in FOLIAGE_TOKENS do
        if string.find(lower, token, 1, true) ~= nil then
            return true
        end
    end
    return false
end

local function isFoliagePart(part)
    if containsFoliageToken(part.Name) then
        return true
    end
    -- Roblox commonly splits multi-material GLBs into MeshParts whose part
    -- names stay generic while their imported SurfaceAppearance keeps the
    -- material name (for this pine, pine_sapling_small_twig). Inspect that
    -- name before the raw appearance is removed.
    for _, child in part:GetChildren() do
        if child:IsA("SurfaceAppearance") and containsFoliageToken(child.Name) then
            return true
        end
    end
    return false
end

local function appearanceTemplate(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    local folder = ReplicatedStorage:FindFirstChild("EverLeafSurfaceAppearances")
    local template = folder and folder:FindFirstChild(name)
    if template and template:IsA("SurfaceAppearance") then
        return template
    end
    return nil
end

local function fallbackColor(config, defaultColor)
    local rgb = type(config) == "table" and config.FallbackColor or nil
    if type(rgb) == "table" then
        local r = math.clamp(tonumber(rgb[1]) or 0, 0, 255)
        local g = math.clamp(tonumber(rgb[2]) or 0, 0, 255)
        local b = math.clamp(tonumber(rgb[3]) or 0, 0, 255)
        return Color3.fromRGB(r, g, b)
    end
    return defaultColor
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
        local config = if foliage then appearance.Foliage else appearance.Bark
        if config then
            -- Never author SurfaceAppearance map properties from a runtime
            -- server thread. Roblox protects ColorMap/NormalMap/etc. with
            -- Plugin capability. The maps are authored into the Rojo place and
            -- runtime only clones that preconfigured instance.
            for _, child in part:GetChildren() do
                if child:IsA("Texture") or child:IsA("Decal") or child:IsA("SurfaceAppearance") then
                    child:Destroy()
                end
            end
            local template = appearanceTemplate(config.TemplateName)
            if template then
                local surface = template:Clone()
                surface.Name = "EverLeafSurfaceAppearance"
                surface.Parent = part
                part.Color = Color3.new(1, 1, 1)
            else
                part.Color = fallbackColor(
                    config,
                    foliage and Color3.fromRGB(53, 92, 58) or Color3.fromRGB(103, 82, 59)
                )
            end

            part.Material = Enum.Material.SmoothPlastic
            if config.DoubleSided == true or foliage then
                part.DoubleSided = true
            end
            if type(config.MaterialVariant) == "string" and config.MaterialVariant ~= "" then
                part:SetAttribute("EverLeafMaterialVariant", config.MaterialVariant)
            else
                part:SetAttribute("EverLeafMaterialVariant", nil)
            end
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
    instance:SetAttribute("SourcePrefabName", prefabName)
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
    clone:SetAttribute("SourcePrefabName", prefabName)
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
