local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local EnvironmentAssetRegistry = require(script.Parent.Parent.Content.EnvironmentAssetRegistry)
local EnvironmentPrefabService = require(script.Parent.EnvironmentPrefabService)

local StudioEnvironmentAssetService = {}

local function chooseVisualRoot(container)
    local children = container:GetChildren()
    if #children == 1 and (children[1]:IsA("Model") or children[1]:IsA("BasePart")) then
        local child = children[1]
        child.Parent = nil
        container:Destroy()
        return child
    end

    local model = Instance.new("Model")
    model.Name = "ImportedEnvironmentAsset"
    for _, child in children do
        if child:IsA("Model") or child:IsA("BasePart") or child:IsA("Folder") then
            child.Parent = model
        else
            child:Destroy()
        end
    end
    container:Destroy()
    return model
end

local function countBaseParts(instance)
    local count = if instance:IsA("BasePart") then 1 else 0
    for _, descendant in instance:GetDescendants() do
        if descendant:IsA("BasePart") then
            count += 1
        end
    end
    return count
end

local function hasVisualModelChild(model)
    for _, child in model:GetChildren() do
        if child:IsA("Model") and countBaseParts(child) > 0 then
            return true
        end
    end
    return false
end

local function isTreeSizedVisual(model)
    local ok, _, size = pcall(function()
        local cframe, bounds = model:GetBoundingBox()
        return cframe, bounds
    end)
    if not ok or not size then
        return false
    end
    if size.Y < 3 or size.Y > 80 then
        return false
    end
    local horizontal = math.max(size.X, size.Z)
    return horizontal <= math.max(48, size.Y * 2.8)
end

local function collectVariantCandidates(container)
    local candidates = {}
    local contentRoot = container
    local children = container:GetChildren()
    if #children == 1 and children[1]:IsA("Model") then
        contentRoot = children[1]
    end

    -- Prefer leaf visual models. This prevents a pack-level wrapper containing
    -- many trees from being registered as one enormous repeated prefab.
    for _, descendant in contentRoot:GetDescendants() do
        if
            descendant:IsA("Model")
            and countBaseParts(descendant) > 0
            and not hasVisualModelChild(descendant)
            and isTreeSizedVisual(descendant)
        then
            table.insert(candidates, descendant)
        end
    end

    if #candidates < 2 then
        table.clear(candidates)
        for _, child in contentRoot:GetChildren() do
            if child:IsA("Model") and countBaseParts(child) > 0 and isTreeSizedVisual(child) then
                table.insert(candidates, child)
            end
        end
    end

    table.sort(candidates, function(a, b)
        return a:GetFullName() < b:GetFullName()
    end)
    return candidates
end

local function findManualStudioSource(entry)
    if not RunService:IsStudio() or entry.Status ~= "manual_studio_import" then
        return nil
    end
    local sourceName = entry.ManualSourceName or entry.Name
    if type(sourceName) ~= "string" or sourceName == "" then
        return nil
    end
    local source = Workspace:FindFirstChild(sourceName)
    if source and (source:IsA("Model") or source:IsA("Folder")) then
        return source
    end
    return nil
end

local function importManualVariantAsset(entry)
    local source = findManualStudioSource(entry)
    if not source then
        return false
    end
    local prefix = entry.VariantPrefix
    if type(prefix) ~= "string" or prefix == "" then
        return false
    end
    if EnvironmentPrefabService.Get(prefix .. "01") then
        source:Destroy()
        return true
    end

    local container = source:Clone()
    local candidates = collectVariantCandidates(container)
    local maximum = math.max(1, tonumber(entry.MaxVariants) or 8)
    local registeredCount = 0
    for index = 1, math.min(#candidates, maximum) do
        local visual = candidates[index]:Clone()
        local prefabName = prefix .. string.format("%02d", index)
        local registered = EnvironmentPrefabService.Register(prefabName, visual, entry.AssetId, {
            AutoUpright = entry.AutoUpright == true,
            GroundToPivot = entry.GroundToPivot == true,
            Appearance = entry.Appearance,
        })
        if registered then
            registeredCount += 1
        else
            visual:Destroy()
        end
    end
    container:Destroy()
    source:Destroy()

    if registeredCount > 0 then
        print(
            string.format(
                "[StudioEnvironmentAssetService] Consumed local Studio source %s into %d sanitized variants",
                tostring(entry.Name),
                registeredCount
            )
        )
        return true
    end
    warn(
        string.format(
            "[StudioEnvironmentAssetService] Local Studio source %s contained no usable variants",
            tostring(entry.Name)
        )
    )
    return false
end
local function importVariantAsset(entry)
    local prefix = entry.VariantPrefix
    if type(prefix) ~= "string" or prefix == "" then
        return false
    end
    if EnvironmentPrefabService.Get(prefix .. "01") then
        return true
    end

    local ok, containerOrError = pcall(function()
        return InsertService:LoadAsset(entry.AssetId)
    end)
    if not ok then
        warn(
            string.format(
                "[StudioEnvironmentAssetService] Could not load variant pack %s (%s): %s",
                entry.Name,
                tostring(entry.AssetId),
                tostring(containerOrError)
            )
        )
        return false
    end

    local candidates = collectVariantCandidates(containerOrError)
    local maximum = math.max(1, tonumber(entry.MaxVariants) or 8)
    local registeredCount = 0
    for index = 1, math.min(#candidates, maximum) do
        local visual = candidates[index]:Clone()
        local prefabName = prefix .. string.format("%02d", index)
        local registered = EnvironmentPrefabService.Register(prefabName, visual, entry.AssetId, {
            AutoUpright = entry.AutoUpright == true,
            GroundToPivot = entry.GroundToPivot == true,
            Appearance = entry.Appearance,
        })
        if registered then
            registeredCount += 1
        else
            visual:Destroy()
        end
    end
    containerOrError:Destroy()

    if registeredCount == 0 then
        warn(
            string.format(
                "[StudioEnvironmentAssetService] No usable visual variants found in %s (%s)",
                entry.Name,
                tostring(entry.AssetId)
            )
        )
        return false
    end

    print(
        string.format(
            "[StudioEnvironmentAssetService] Loaded %d sanitized variants from %s (%s)",
            registeredCount,
            entry.Name,
            tostring(entry.AssetId)
        )
    )
    return true
end

local function importAsset(entry)
    if EnvironmentPrefabService.Get(entry.PrefabName) then
        return true
    end

    local ok, containerOrError = pcall(function()
        return InsertService:LoadAsset(entry.AssetId)
    end)
    if not ok then
        warn(
            string.format(
                "[StudioEnvironmentAssetService] Could not load %s (%s): %s",
                entry.Name,
                tostring(entry.AssetId),
                tostring(containerOrError)
            )
        )
        return false
    end

    local visualRoot = chooseVisualRoot(containerOrError)
    local registered, reason =
        EnvironmentPrefabService.Register(entry.PrefabName, visualRoot, entry.AssetId, {
            AutoUpright = entry.AutoUpright == true,
            GroundToPivot = entry.GroundToPivot == true,
            Appearance = entry.Appearance,
        })
    if not registered then
        visualRoot:Destroy()
        warn(
            string.format(
                "[StudioEnvironmentAssetService] Could not register %s: %s",
                entry.Name,
                tostring(reason)
            )
        )
        return false
    end

    print(
        string.format(
            "[StudioEnvironmentAssetService] Loaded sanitized prefab %s from asset %s",
            entry.PrefabName,
            tostring(entry.AssetId)
        )
    )
    return true
end

function StudioEnvironmentAssetService.Init()
    local inStudio = RunService:IsStudio()

    for _, entry in EnvironmentAssetRegistry do
        if inStudio and entry.Status == "manual_studio_import" and entry.VariantPrefix then
            importManualVariantAsset(entry)
        else
            local approved = entry.Status == "approved_for_sanitized_import"
                or entry.Status == "approved_for_studio_sanitized_import"
            local allowedHere = inStudio or entry.AllowRuntimeLoad == true
            if approved and allowedHere then
                if entry.VariantPrefix then
                    importVariantAsset(entry)
                elseif entry.PrefabName then
                    importAsset(entry)
                end
            end
        end
    end
end

return StudioEnvironmentAssetService
