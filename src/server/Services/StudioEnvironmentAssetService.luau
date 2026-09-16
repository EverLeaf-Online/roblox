local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local EnvironmentAssetRegistry = require(script.Parent.Parent.Content.EnvironmentAssetRegistry)
local EnvironmentPrefabService = require(script.Parent.EnvironmentPrefabService)

local StudioEnvironmentAssetService = {}
local assetContainerCache = {}

local BUILDING_TOKENS = table.freeze({
    "house",
    "home",
    "building",
    "cottage",
    "hut",
    "barn",
    "stable",
    "shop",
    "hall",
    "inn",
    "tower",
    "gate",
    "castle",
    "keep",
    "ruin",
    "tomb",
    "crypt",
    "shrine",
    "chapel",
    "temple",
    "arch",
})

local PROP_TOKENS = table.freeze({
    "tree",
    "bush",
    "grass",
    "flower",
    "rock",
    "crate",
    "barrel",
    "fence",
    "lamp",
    "lantern",
    "cart",
    "wagon",
    "well",
    "bench",
    "chair",
    "table",
    "sign",
    "road",
    "path",
    "ground",
    "terrain",
})

local function countBaseParts(instance)
    local count = if instance:IsA("BasePart") then 1 else 0
    for _, descendant in instance:GetDescendants() do
        if descendant:IsA("BasePart") then
            count += 1
        end
    end
    return count
end

local function boundsSize(instance)
    if instance:IsA("Model") then
        local ok, _, size = pcall(function()
            local cframe, extents = instance:GetBoundingBox()
            return cframe, extents
        end)
        return if ok then size else nil
    elseif instance:IsA("BasePart") then
        return instance.Size
    end
    return nil
end

local function containsToken(text, tokens)
    local lower = string.lower(text)
    for _, token in tokens do
        if string.find(lower, string.lower(token), 1, true) then
            return true
        end
    end
    return false
end

local function architectureCandidateScore(instance, entry)
    local size = boundsSize(instance)
    if not size then
        return nil
    end
    local horizontalLongest = math.max(size.X, size.Z)
    local horizontalShortest = math.min(size.X, size.Z)
    if size.Y < 3.5 or size.Y > 140 or horizontalLongest < 5 or horizontalLongest > 180 then
        return nil
    end
    if horizontalShortest < 1.8 then
        return nil
    end

    local name = instance:GetFullName()
    local selectedTokens = entry.SelectTokens or {}
    local selectedMatch = containsToken(name, selectedTokens)
    local buildingMatch = containsToken(name, BUILDING_TOKENS)
    local propMatch = containsToken(name, PROP_TOKENS)
    if propMatch and not selectedMatch then
        return nil
    end

    local parts = countBaseParts(instance)
    if parts < 2 and not instance:IsA("MeshPart") then
        return nil
    end

    -- Prefer named building variants, but still allow well-sized unnamed models
    -- from packs that use generic labels like Model01/Model02.
    local score = 0
    for _, token in selectedTokens do
        if string.find(string.lower(name), string.lower(token), 1, true) then
            score += 120
        end
    end
    if buildingMatch then
        score += 45
    end
    score += math.min(parts, 50) * 0.6
    score += math.min(horizontalLongest, 70) * 0.25
    score += math.min(size.Y, 45) * 0.2
    if not buildingMatch and parts < 6 then
        score -= 40
    end
    return score
end

local function collectArchitectureCandidates(container, entry)
    local contentRoot = container
    local children = container:GetChildren()
    if #children == 1 and (children[1]:IsA("Model") or children[1]:IsA("Folder")) then
        contentRoot = children[1]
    end

    local candidates = {}
    local function consider(instance)
        if not (instance:IsA("Model") or instance:IsA("BasePart")) then
            return
        end
        local score = architectureCandidateScore(instance, entry)
        if score then
            table.insert(candidates, { Instance = instance, Score = score })
        end
    end

    -- Pack authors normally place complete buildings as direct children or one
    -- folder below the pack root. Do not descend into roof/wall submodels first.
    for _, child in contentRoot:GetChildren() do
        if child:IsA("Folder") then
            for _, grandchild in child:GetChildren() do
                consider(grandchild)
            end
        else
            consider(child)
        end
    end

    if #candidates == 0 then
        for _, descendant in contentRoot:GetDescendants() do
            if descendant:IsA("Model") and countBaseParts(descendant) >= 4 then
                consider(descendant)
            end
        end
    end

    table.sort(candidates, function(a, b)
        if math.abs(a.Score - b.Score) > 0.001 then
            return a.Score > b.Score
        end
        return a.Instance:GetFullName() < b.Instance:GetFullName()
    end)
    return candidates
end

local function chooseVisualRoot(container, entry)
    if entry.SelectModelFromPack == true then
        local candidates = collectArchitectureCandidates(container, entry)
        if #candidates > 0 then
            local ordinal = math.max(1, math.floor(tonumber(entry.VariantOrdinal) or 1))
            local selected = candidates[((ordinal - 1) % #candidates) + 1].Instance:Clone()
            selected.Name = entry.PrefabName or selected.Name
            selected:SetAttribute("CreatorStorePackSelection", true)
            selected:SetAttribute("CreatorStoreCandidateCount", #candidates)
            selected:SetAttribute("CreatorStoreVariantOrdinal", ordinal)
            container:Destroy()
            return selected
        end
        warn(
            string.format(
                "[StudioEnvironmentAssetService] No architectural candidate found in pack %s (%s); refusing whole-pack fallback",
                tostring(entry.Name),
                tostring(entry.AssetId)
            )
        )
        container:Destroy()
        return nil
    end

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

local function loadAssetContainer(assetId)
    local cached = assetContainerCache[assetId]
    if cached and cached.Parent == nil then
        return cached:Clone()
    end

    local ok, containerOrError = pcall(function()
        return AssetService:LoadAssetAsync(assetId)
    end)
    if not ok then
        return nil, containerOrError
    end
    assetContainerCache[assetId] = containerOrError
    return containerOrError:Clone()
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

    local containerOrError, loadError = loadAssetContainer(entry.AssetId)
    if not containerOrError then
        warn(
            string.format(
                "[StudioEnvironmentAssetService] Could not load variant pack %s (%s): %s",
                entry.Name,
                tostring(entry.AssetId),
                tostring(loadError)
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

    local containerOrError, loadError = loadAssetContainer(entry.AssetId)
    if not containerOrError then
        warn(
            string.format(
                "[StudioEnvironmentAssetService] Could not load %s (%s): %s",
                entry.Name,
                tostring(entry.AssetId),
                tostring(loadError)
            )
        )
        return false
    end

    local visualRoot = chooseVisualRoot(containerOrError, entry)
    if not visualRoot then
        return false
    end
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
                or entry.Status == "approved_free_creator_store"
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

    for assetId, container in assetContainerCache do
        if container then
            container:Destroy()
        end
        assetContainerCache[assetId] = nil
    end
end

return StudioEnvironmentAssetService
