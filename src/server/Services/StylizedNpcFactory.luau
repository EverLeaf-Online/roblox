local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local StylizedNpcFactory = {}
local NpcAssetRegistry = require(script.Parent.Parent.Content.NpcAssetRegistry)
local GeneratedNpcFallbackFactory = require(script.Parent.GeneratedNpcFallbackFactory)
local NpcGroundingRules = require(script.Parent.NpcGroundingRules)

local R15_IDLE_ANIMATION = "rbxassetid://507766666"

local function bodyPart(model, name)
    local part = model:FindFirstChild(name)
    if part and part:IsA("BasePart") then
        return part
    end
    return nil
end

local function weldPart(model, anchor, part)
    part.Anchored = false
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.Parent = model
    local weld = Instance.new("WeldConstraint")
    weld.Name = "EverLeafNpcWeld"
    weld.Part0 = anchor
    weld.Part1 = part
    weld.Parent = part
    return part
end

local function configureRig(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = bodyPart(model, "HumanoidRootPart")
    if not humanoid or not root then
        return nil, nil
    end

    for _, descendant in model:GetDescendants() do
        if
            descendant:IsA("Script")
            or descendant:IsA("LocalScript")
            or descendant:IsA("ModuleScript")
        then
            descendant:Destroy()
        elseif descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = descendant.Name == "HumanoidRootPart"
            descendant.Massless = descendant.Name ~= "HumanoidRootPart"
        end
    end

    root.Anchored = true
    root.Transparency = 1
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.AutoRotate = false
    humanoid.BreakJointsOnDeath = false
    humanoid.NameDisplayDistance = 0
    humanoid.HealthDisplayDistance = 0
    pcall(function()
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end)

    local head = bodyPart(model, "Head")
    if head then
        for _, child in head:GetChildren() do
            if child:IsA("Decal") or child:IsA("SurfaceGui") then
                child:Destroy()
            end
        end
    end

    return root, head
end

local function startIdleAnimation(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    local animation = Instance.new("Animation")
    animation.Name = "EverLeafNpcIdle"
    animation.AnimationId = R15_IDLE_ANIMATION
    local ok, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)
    animation:Destroy()
    if ok and track then
        track.Priority = Enum.AnimationPriority.Idle
        track.Looped = true
        track:Play(0.2, 1, 0.82)
    end
end

local function partBottomWorldY(part)
    local half = part.Size * 0.5
    local lowest = math.huge
    for _, x in { -1, 1 } do
        for _, y in { -1, 1 } do
            for _, z in { -1, 1 } do
                local worldCorner =
                    part.CFrame:PointToWorldSpace(Vector3.new(half.X * x, half.Y * y, half.Z * z))
                lowest = math.min(lowest, worldCorner.Y)
            end
        end
    end
    return lowest
end

local function measuredFootBottomWorldY(model)
    local lowest = math.huge
    for _, name in { "LeftFoot", "RightFoot" } do
        local foot = bodyPart(model, name)
        if foot then
            lowest = math.min(lowest, partBottomWorldY(foot))
        end
    end
    if lowest == math.huge then
        return nil
    end
    return lowest
end

local function groundModel(model, requestedPosition, yaw, groundMode)
    local root = bodyPart(model, "HumanoidRootPart")
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then
        return false
    end

    -- Put the assembled rig above the target first, then let Roblox resolve
    -- the generated R15 Motor6D chain before reading foot positions. Measuring
    -- immediately after CreateHumanoidModelFromDescriptionAsync can see stale
    -- limb CFrames and was the cause of NPCs being buried to the waist.
    local stagingRoot = CFrame.new(
        requestedPosition.X,
        requestedPosition.Y + 12,
        requestedPosition.Z
    ) * CFrame.Angles(0, yaw or 0, 0)
    local stagingTransform = stagingRoot * root.CFrame:Inverse()
    model:PivotTo(stagingTransform * model:GetPivot())
    RunService.Heartbeat:Wait()

    local rayParams = RaycastParams.new()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if groundMode == "World" or not terrain then
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = { model }
    else
        rayParams.FilterType = Enum.RaycastFilterType.Include
        rayParams.FilterDescendantsInstances = { terrain }
    end
    -- All current NPCs are land actors; never ground their feet to a water surface.
    rayParams.IgnoreWater = true

    local rayOrigin =
        Vector3.new(requestedPosition.X, requestedPosition.Y + 100, requestedPosition.Z)
    local result = Workspace:Raycast(rayOrigin, Vector3.new(0, -220, 0), rayParams)
    local groundY = if result then result.Position.Y else requestedPosition.Y
    local clearance = 0.12

    local footBottomWorldY = measuredFootBottomWorldY(model)
    if not footBottomWorldY then
        footBottomWorldY = root.Position.Y - humanoid.HipHeight - root.Size.Y * 0.5
    end

    local shiftY = NpcGroundingRules.ComputeVerticalShift(groundY, footBottomWorldY, clearance)
    model:PivotTo(CFrame.new(0, shiftY, 0) * model:GetPivot())
    RunService.Heartbeat:Wait()

    local verifiedFootBottom = measuredFootBottomWorldY(model)
    model:SetAttribute("EverLeafGroundY", groundY)
    model:SetAttribute("EverLeafFootBottomWorldY", verifiedFootBottom or footBottomWorldY + shiftY)
    model:SetAttribute("EverLeafGroundShiftY", shiftY)
    model:SetAttribute("EverLeafHipHeight", humanoid.HipHeight)
    model:SetAttribute("EverLeafGroundClearance", clearance)
    model:SetAttribute(
        "EverLeafGroundError",
        (verifiedFootBottom or footBottomWorldY + shiftY) - (groundY + clearance)
    )
    return true
end

local AUTHORED_R15_PARTS = table.freeze({
    Head = true,
    UpperTorso = true,
    LowerTorso = true,
    LeftUpperArm = true,
    RightUpperArm = true,
    LeftLowerArm = true,
    RightLowerArm = true,
    LeftHand = true,
    RightHand = true,
    LeftUpperLeg = true,
    RightUpperLeg = true,
    LeftLowerLeg = true,
    RightLowerLeg = true,
    LeftFoot = true,
    RightFoot = true,
})

local BLOCKED_AUTHORED_CLASSES = table.freeze({
    Script = true,
    LocalScript = true,
    ModuleScript = true,
    RemoteEvent = true,
    RemoteFunction = true,
    BindableEvent = true,
    BindableFunction = true,
})

local function authoredAnchorName(partName)
    if AUTHORED_R15_PARTS[partName] then
        return partName
    end
    local prefix = string.match(partName, "^([^_]+)_")
    if prefix and AUTHORED_R15_PARTS[prefix] then
        return prefix
    end
    return "UpperTorso"
end

local function loadAuthoredNpcAsset(spec, assetSpec)
    if not assetSpec.AssetId then
        return nil
    end
    local ok, container = pcall(InsertService.LoadAsset, InsertService, assetSpec.AssetId)
    if not ok or not container then
        warn(
            string.format(
                "[StylizedNpcFactory] Could not load authored NPC asset %s for %s",
                tostring(assetSpec.AssetId),
                tostring(spec.NpcId)
            )
        )
        return nil
    end

    for _, descendant in container:GetDescendants() do
        if BLOCKED_AUTHORED_CLASSES[descendant.ClassName] then
            descendant:Destroy()
        elseif descendant:IsA("BasePart") then
            descendant.Anchored = false
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
            descendant.Massless = true
        end
    end

    local imported = container:FindFirstChildOfClass("Model") or container
    local sourceParts = {}
    local sourceFrames = {}
    for _, descendant in imported:GetDescendants() do
        if descendant:IsA("BasePart") then
            table.insert(sourceParts, descendant)
            if AUTHORED_R15_PARTS[descendant.Name] then
                sourceFrames[descendant.Name] = descendant.CFrame
            end
        end
    end
    if #sourceParts == 0 then
        container:Destroy()
        return nil
    end

    local description = Instance.new("HumanoidDescription")
    local rigOk, modelOrError = pcall(function()
        return Players:CreateHumanoidModelFromDescriptionAsync(
            description,
            Enum.HumanoidRigType.R15
        )
    end)
    description:Destroy()
    if not rigOk or not modelOrError then
        container:Destroy()
        return nil
    end

    local model = modelOrError
    local root, head = configureRig(model)
    if not root or not head then
        model:Destroy()
        container:Destroy()
        return nil
    end

    -- Keep Roblox's proven R15 joint/animation skeleton but make its stock body
    -- invisible. Authored MeshParts are welded to those animated segments.
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") and descendant ~= root then
            descendant.Transparency = 1
        end
    end

    for _, visual in sourceParts do
        local originalName = visual.Name
        local anchorName = authoredAnchorName(originalName)
        local anchor = bodyPart(model, anchorName) or bodyPart(model, "UpperTorso")
        if anchor then
            if AUTHORED_R15_PARTS[originalName] then
                visual.CFrame = anchor.CFrame
            else
                local sourceAnchor = sourceFrames[anchorName]
                local offset = if sourceAnchor
                    then sourceAnchor:ToObjectSpace(visual.CFrame)
                    else CFrame.new()
                visual.CFrame = anchor.CFrame * offset
            end
            visual.Name = "Visual_" .. originalName
            weldPart(model, anchor, visual)
        end
    end
    container:Destroy()
    model.Name = spec.Name or spec.NpcId or assetSpec.TemplateName or "EverLeafNpc"
    model:SetAttribute("VisualSource", "authored_asset")
    model:SetAttribute("VisualAssetId", assetSpec.AssetId)
    return model, root, head
end

local function cloneAuthoredNpc(spec)
    local npcId = spec.NpcId
    local assetSpec = npcId and NpcAssetRegistry[npcId]
    if not assetSpec or assetSpec.Status ~= "reviewed" then
        return nil
    end

    -- Studio/local authored templates remain the first choice for iteration.
    local folder = ServerStorage:FindFirstChild("AuthoredNpcTemplates")
    if folder then
        local source = folder:FindFirstChild(assetSpec.TemplateName or npcId)
        if source and source:IsA("Model") then
            local model = source:Clone()
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            local head = model:FindFirstChild("Head")
            if humanoid and root and head then
                model.Name = spec.Name or npcId or source.Name
                model:SetAttribute("VisualSource", "authored_serverstorage")
                return model, root, head
            end
            model:Destroy()
        end
    end

    return loadAuthoredNpcAsset(spec, assetSpec)
end

function StylizedNpcFactory.Create(parent, spec)
    local authored, authoredRoot, authoredHead = cloneAuthoredNpc(spec)
    if authored then
        authored.Parent = parent
        groundModel(authored, spec.Position, spec.Yaw or 0, spec.GroundMode)
        startIdleAnimation(authored)
        authored.PrimaryPart = authoredRoot
        return authored, authoredRoot, authoredHead
    end

    local model, palette, fallbackReason = GeneratedNpcFallbackFactory.CreateBase(spec)
    if not model then
        warn(
            string.format(
                "[StylizedNpcFactory] Could not build fallback R15 NPC %s: %s",
                tostring(spec.NpcId or spec.Name),
                tostring(fallbackReason)
            )
        )
        return nil, nil, nil
    end

    model:SetAttribute("VisualSource", "generated_r15_fallback")
    model.Name = spec.Name or spec.NpcId or "EverLeafNpc"
    model.Parent = parent
    local root, head = configureRig(model)
    if not root or not head then
        model:Destroy()
        warn(
            string.format(
                "[StylizedNpcFactory] R15 NPC %s missing required body parts",
                tostring(spec.NpcId or spec.Name)
            )
        )
        return nil, nil, nil
    end

    GeneratedNpcFallbackFactory.Decorate(model, spec, palette)
    groundModel(model, spec.Position, spec.Yaw or 0, spec.GroundMode)
    startIdleAnimation(model)
    model.PrimaryPart = root
    return model, root, head
end

return StylizedNpcFactory
