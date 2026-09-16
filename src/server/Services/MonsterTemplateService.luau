local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")

local MonsterAssetRegistry = require(script.Parent.Parent.Content.MonsterAssetRegistry)
local MonsterConfig = require(script.Parent.Parent.Content.MonsterConfig)
local LegacyMonsterFallbackFactory = require(script.Parent.LegacyMonsterFallbackFactory)

local MonsterTemplateService = {}

local BLOCKED_ASSET_CLASSES = table.freeze({
    Script = true,
    LocalScript = true,
    ModuleScript = true,
    RemoteEvent = true,
    RemoteFunction = true,
    BindableEvent = true,
    BindableFunction = true,
})

local function sanitizeAuthoredAsset(root)
    for _, descendant in root:GetDescendants() do
        if BLOCKED_ASSET_CLASSES[descendant.ClassName] then
            descendant:Destroy()
        elseif descendant:IsA("BasePart") then
            descendant.Anchored = false
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = true
            descendant.Massless = true
        end
    end
end

local function loadAuthoredMonster(assetSpec, definition)
    if not assetSpec.AssetId or assetSpec.Status ~= "reviewed" then
        return nil
    end

    local ok, container = pcall(InsertService.LoadAsset, InsertService, assetSpec.AssetId)
    if not ok or not container then
        warn(
            string.format(
                "[MonsterTemplateService] Could not load authored asset %s for %s",
                tostring(assetSpec.AssetId),
                definition.Id
            )
        )
        return nil
    end

    sanitizeAuthoredAsset(container)
    local importedModel = container:FindFirstChildOfClass("Model") or container
    local visualParts = {}
    for _, descendant in importedModel:GetDescendants() do
        if descendant:IsA("BasePart") then
            table.insert(visualParts, descendant)
        end
    end
    if #visualParts == 0 then
        container:Destroy()
        return nil
    end

    local model = Instance.new("Model")
    model.Name = definition.TemplateName
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = assetSpec.RootSize or Vector3.new(2.5, 2.5, 2.5)
    root.Transparency = 1
    root.Anchored = true
    root.CanCollide = true
    root.CanTouch = true
    root.Massless = false
    root.CFrame = CFrame.new()
    root.Parent = model

    local humanoid = Instance.new("Humanoid")
    humanoid.DisplayName = definition.DisplayName
    humanoid.RequiresNeck = false
    humanoid.HipHeight = assetSpec.HipHeight or 1.5
    humanoid.AutoRotate = false
    humanoid.BreakJointsOnDeath = false
    humanoid.Parent = model

    local pivot = importedModel:GetPivot()
    local visualByName = {}
    for _, part in visualParts do
        local original = part.CFrame
        part.Parent = model
        part.CFrame = pivot:ToObjectSpace(original)
        visualByName[part.Name] = part
    end

    -- Authored props must follow the body segment they visually belong to. Attaching
    -- every mesh directly to HumanoidRootPart made eyes, armor, horns, caps, claws,
    -- and weapons appear to detach whenever the primary body joint animated.
    for _, part in visualParts do
        local parentName = assetSpec.Parents and assetSpec.Parents[part.Name]
        local parentPart = parentName and visualByName[parentName] or nil
        local motor = Instance.new("Motor6D")
        motor.Name = (assetSpec.Joints and assetSpec.Joints[part.Name]) or (part.Name .. "Joint")
        motor.Part0 = parentPart or root
        motor.Part1 = part
        motor.C0 = if parentPart then parentPart.CFrame:ToObjectSpace(part.CFrame) else part.CFrame
        motor.Parent = parentPart or root
    end
    container:Destroy()
    model.PrimaryPart = root
    model:SetAttribute("VisualSource", "authored_asset")
    model:SetAttribute("VisualAssetId", assetSpec.AssetId)
    return model
end

function MonsterTemplateService.Init()
    local folder = ServerStorage:FindFirstChild("Monsters")
    if folder then
        folder:Destroy()
    end
    folder = Instance.new("Folder")
    folder.Name = "Monsters"
    folder.Parent = ServerStorage

    local authoredFolder = ServerStorage:FindFirstChild("AuthoredMonsterTemplates")
    for monsterId in MonsterConfig.All() do
        local definition = MonsterConfig.Get(monsterId)
        local assetSpec = MonsterAssetRegistry[monsterId]
        local model = nil

        if definition and assetSpec and assetSpec.Status == "reviewed" then
            if authoredFolder then
                local authored =
                    authoredFolder:FindFirstChild(assetSpec.TemplateName or definition.TemplateName)
                if
                    authored
                    and authored:IsA("Model")
                    and authored:FindFirstChildOfClass("Humanoid")
                then
                    model = authored:Clone()
                    model:SetAttribute("VisualSource", "authored_serverstorage")
                end
            end
            if not model and assetSpec.AssetId then
                model = loadAuthoredMonster(assetSpec, definition)
            end
        end

        if not model then
            local fallback, fallbackReason = LegacyMonsterFallbackFactory.Build(monsterId)
            if not fallback then
                warn(
                    string.format(
                        "[MonsterTemplateService] Missing fallback for %s: %s",
                        tostring(monsterId),
                        tostring(fallbackReason)
                    )
                )
                continue
            end
            model = fallback
            model:SetAttribute("VisualSource", "legacy_procedural_fallback")
        end
        model:SetAttribute("MonsterId", monsterId)
        model.Parent = folder
    end
end

function MonsterTemplateService.Get(monsterId)
    local definition = MonsterConfig.Get(monsterId)
    local folder = ServerStorage:FindFirstChild("Monsters")
    if not definition or not folder then
        return nil
    end
    return folder:FindFirstChild(definition.TemplateName)
end

return MonsterTemplateService
