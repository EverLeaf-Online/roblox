local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local StylizedNpcFactory = {}
local NpcAssetRegistry = require(script.Parent.Parent.Content.NpcAssetRegistry)
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

local function attachPart(model, anchor, name, size, localCFrame, material, color, shape)
    if not anchor then
        return nil
    end
    local part
    if shape == "Wedge" then
        part = Instance.new("WedgePart")
    else
        part = Instance.new("Part")
        if shape == "Ball" then
            part.Shape = Enum.PartType.Ball
        elseif shape == "Cylinder" then
            part.Shape = Enum.PartType.Cylinder
        end
    end
    part.Name = name
    part.Size = size
    part.CFrame = anchor.CFrame * localCFrame
    part.Material = material or Enum.Material.SmoothPlastic
    part.Color = color
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    return weldPart(model, anchor, part)
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

local function makeDescription(spec, palette)
    local description = Instance.new("HumanoidDescription")
    local skin = palette.Skin or Color3.fromRGB(214, 181, 146)
    local cloth = palette.Cloth or Color3.fromRGB(63, 91, 77)
    local dark = palette.DarkCloth or cloth:Lerp(Color3.new(0, 0, 0), 0.28)

    description.HeadColor = skin
    description.LeftArmColor = skin
    description.RightArmColor = skin
    description.TorsoColor = cloth
    description.LeftLegColor = dark
    description.RightLegColor = dark

    description.HeightScale = tonumber(spec.HeightScale) or 0.98
    description.WidthScale = tonumber(spec.WidthScale) or (tonumber(spec.Build) or 1)
    description.DepthScale = tonumber(spec.DepthScale)
        or math.clamp((tonumber(spec.Build) or 1) * 0.96, 0.82, 1.15)
    description.HeadScale = tonumber(spec.HeadScale) or 0.96
    description.BodyTypeScale = tonumber(spec.BodyTypeScale) or 0.18
    description.ProportionScale = tonumber(spec.ProportionScale) or 0.22

    return description
end

local function makeFace(head, palette, role)
    if not head then
        return
    end
    local gui = Instance.new("SurfaceGui")
    gui.Name = "EverLeafNpcFace"
    gui.Face = Enum.NormalId.Front
    gui.AlwaysOnTop = false
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 72
    gui.LightInfluence = 0
    gui.Parent = head

    local canvas = Instance.new("Frame")
    canvas.Size = UDim2.fromScale(1, 1)
    canvas.BackgroundTransparency = 1
    canvas.Parent = gui

    local eyeColor = palette.EyeColor or Color3.fromRGB(43, 61, 52)
    local browColor = palette.Hair or Color3.fromRGB(67, 50, 42)
    for index, x in { 0.31, 0.69 } do
        local eye = Instance.new("Frame")
        eye.Name = if index == 1 then "LeftEye" else "RightEye"
        eye.AnchorPoint = Vector2.new(0.5, 0.5)
        eye.Position = UDim2.fromScale(x, 0.43)
        eye.Size = UDim2.fromScale(0.09, if role == "Archivist" then 0.07 else 0.085)
        eye.BackgroundColor3 = eyeColor
        eye.BorderSizePixel = 0
        eye.Parent = canvas
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = eye

        local brow = Instance.new("Frame")
        brow.AnchorPoint = Vector2.new(0.5, 0.5)
        brow.Position = UDim2.fromScale(x, 0.31)
        brow.Size = UDim2.fromScale(0.18, 0.035)
        brow.Rotation = if index == 1 then -4 else 4
        brow.BackgroundColor3 = browColor
        brow.BorderSizePixel = 0
        brow.Parent = canvas
    end

    local mouth = Instance.new("Frame")
    mouth.AnchorPoint = Vector2.new(0.5, 0.5)
    mouth.Position = UDim2.fromScale(0.5, 0.69)
    mouth.Size = UDim2.fromScale(0.19, 0.028)
    mouth.BackgroundColor3 = Color3.fromRGB(124, 75, 67)
    mouth.BorderSizePixel = 0
    mouth.Parent = canvas
    local mouthCorner = Instance.new("UICorner")
    mouthCorner.CornerRadius = UDim.new(1, 0)
    mouthCorner.Parent = mouth
end

local function makeHair(model, head, palette, style)
    if not head then
        return
    end
    local hair = palette.Hair or Color3.fromRGB(71, 52, 43)
    attachPart(
        model,
        head,
        "HairCrown",
        Vector3.new(1.72, 0.7, 1.65),
        CFrame.new(0, 0.55, 0.02),
        Enum.Material.SmoothPlastic,
        hair,
        "Ball"
    )
    for _, side in { -1, 1 } do
        attachPart(
            model,
            head,
            if side < 0 then "HairLockLeft" else "HairLockRight",
            Vector3.new(0.42, 0.9, 0.22),
            CFrame.new(side * 0.38, 0.18, -0.78)
                * CFrame.Angles(math.rad(-8), 0, math.rad(side * 9)),
            Enum.Material.SmoothPlastic,
            hair,
            "Wedge"
        )
    end
    if style == "ponytail" then
        attachPart(
            model,
            head,
            "Ponytail",
            Vector3.new(0.66, 2.25, 0.55),
            CFrame.new(0, -0.18, 0.92) * CFrame.Angles(math.rad(-12), 0, math.rad(4)),
            Enum.Material.SmoothPlastic,
            hair,
            "Wedge"
        )
    elseif style == "bun" then
        attachPart(
            model,
            head,
            "HairBun",
            Vector3.new(0.86, 0.86, 0.86),
            CFrame.new(0, 0.68, 0.72),
            Enum.Material.SmoothPlastic,
            hair,
            "Ball"
        )
    elseif style == "long" then
        for _, side in { -1, 1 } do
            attachPart(
                model,
                head,
                if side < 0 then "LongHairLeft" else "LongHairRight",
                Vector3.new(0.58, 1.95, 0.36),
                CFrame.new(side * 0.52, -0.42, 0.72)
                    * CFrame.Angles(math.rad(-7), 0, math.rad(side * 5)),
                Enum.Material.SmoothPlastic,
                hair,
                "Wedge"
            )
        end
    end
end

local function addClothingLayers(model, spec, palette)
    local upper = bodyPart(model, "UpperTorso")
    local lower = bodyPart(model, "LowerTorso")
    local head = bodyPart(model, "Head")
    local rightHand = bodyPart(model, "RightHand")
    local leftHand = bodyPart(model, "LeftHand")
    local accent = palette.Accent or Color3.fromRGB(103, 152, 119)
    local cloth = palette.Cloth or Color3.fromRGB(63, 91, 77)
    local dark = palette.DarkCloth or cloth:Lerp(Color3.new(0, 0, 0), 0.28)
    local leather = palette.Leather or Color3.fromRGB(84, 58, 39)
    local metal = palette.Metal or Color3.fromRGB(162, 132, 72)
    local lumen = palette.Lumen or Color3.fromRGB(113, 238, 170)
    local role = spec.Role or "Villager"

    attachPart(
        model,
        upper,
        "Collar",
        Vector3.new(2.0, 0.36, 1.15),
        CFrame.new(0, 0.72, 0),
        Enum.Material.Fabric,
        accent
    )
    attachPart(
        model,
        lower,
        "Belt",
        Vector3.new(1.95, 0.26, 1.05),
        CFrame.new(0, 0.35, 0),
        Enum.Material.Fabric,
        leather
    )
    attachPart(
        model,
        lower,
        "Buckle",
        Vector3.new(0.34, 0.32, 0.1),
        CFrame.new(0, 0.35, -0.56),
        Enum.Material.Metal,
        metal
    )

    if role == "Guide" then
        attachPart(
            model,
            upper,
            "GuideCape",
            Vector3.new(2.15, 2.75, 0.28),
            CFrame.new(0, -0.35, 0.68) * CFrame.Angles(math.rad(-7), 0, 0),
            Enum.Material.Fabric,
            dark,
            "Wedge"
        )
        attachPart(
            model,
            lower,
            "Satchel",
            Vector3.new(0.95, 1.15, 0.48),
            CFrame.new(-1.0, -0.1, 0.55),
            Enum.Material.Fabric,
            leather
        )
        attachPart(
            model,
            head,
            "GuideHood",
            Vector3.new(2.0, 1.75, 1.95),
            CFrame.new(0, 0.02, 0.14),
            Enum.Material.Fabric,
            dark,
            "Ball"
        )
        attachPart(
            model,
            head,
            "GuideHoodOpening",
            Vector3.new(1.55, 1.3, 0.38),
            CFrame.new(0, -0.03, -0.82),
            Enum.Material.Fabric,
            cloth,
            "Ball"
        )
        if rightHand then
            attachPart(
                model,
                rightHand,
                "WayfinderStaff",
                Vector3.new(6.0, 0.18, 0.18),
                CFrame.new(0, -2.0, 0.18) * CFrame.Angles(0, 0, math.rad(90)),
                Enum.Material.Wood,
                Color3.fromRGB(75, 52, 34),
                "Cylinder"
            )
            local crystal = attachPart(
                model,
                rightHand,
                "StaffLumen",
                Vector3.new(0.68, 0.68, 0.68),
                CFrame.new(0, 1.1, 0.18),
                Enum.Material.Neon,
                lumen,
                "Ball"
            )
            if crystal then
                local light = Instance.new("PointLight")
                light.Color = lumen
                light.Brightness = 0.8
                light.Range = 8
                light.Parent = crystal
            end
        end
    elseif role == "Quartermaster" then
        attachPart(
            model,
            upper,
            "QuartermasterVest",
            Vector3.new(2.05, 2.05, 0.22),
            CFrame.new(0, -0.05, -0.58),
            Enum.Material.Fabric,
            accent
        )
        attachPart(
            model,
            lower,
            "Apron",
            Vector3.new(1.65, 1.9, 0.18),
            CFrame.new(0, -0.7, -0.55),
            Enum.Material.Fabric,
            accent
        )
        attachPart(
            model,
            lower,
            "PouchLeft",
            Vector3.new(0.55, 0.65, 0.38),
            CFrame.new(-0.82, 0.0, -0.5),
            Enum.Material.Fabric,
            leather
        )
        attachPart(
            model,
            lower,
            "PouchRight",
            Vector3.new(0.55, 0.65, 0.38),
            CFrame.new(0.82, 0.0, -0.5),
            Enum.Material.Fabric,
            leather
        )
        if leftHand then
            attachPart(
                model,
                leftHand,
                "Ledger",
                Vector3.new(1.05, 0.18, 1.35),
                CFrame.new(0, -0.25, -0.35) * CFrame.Angles(math.rad(18), math.rad(15), 0),
                Enum.Material.Wood,
                Color3.fromRGB(104, 75, 48)
            )
        end
    elseif role == "Scout" then
        attachPart(
            model,
            upper,
            "ScoutCloak",
            Vector3.new(2.1, 2.55, 0.28),
            CFrame.new(0, -0.3, 0.66) * CFrame.Angles(math.rad(-6), 0, 0),
            Enum.Material.Fabric,
            accent,
            "Wedge"
        )
        attachPart(
            model,
            upper,
            "FieldPack",
            Vector3.new(1.45, 1.6, 0.62),
            CFrame.new(0, -0.2, 0.88),
            Enum.Material.Fabric,
            leather
        )
        if rightHand then
            attachPart(
                model,
                rightHand,
                "ScoutSpear",
                Vector3.new(5.8, 0.16, 0.16),
                CFrame.new(0, -1.8, 0.12) * CFrame.Angles(0, 0, math.rad(90)),
                Enum.Material.Wood,
                Color3.fromRGB(77, 54, 35),
                "Cylinder"
            )
            attachPart(
                model,
                rightHand,
                "SpearHead",
                Vector3.new(0.4, 0.82, 0.18),
                CFrame.new(0, 1.18, 0.12),
                Enum.Material.Metal,
                Color3.fromRGB(151, 162, 156),
                "Wedge"
            )
        end
    elseif role == "Archivist" then
        attachPart(
            model,
            upper,
            "ArchivistMantle",
            Vector3.new(2.25, 0.72, 1.35),
            CFrame.new(0, 0.57, 0),
            Enum.Material.Fabric,
            accent,
            "Wedge"
        )
        attachPart(
            model,
            lower,
            "ArchiveRobe",
            Vector3.new(2.05, 2.25, 1.05),
            CFrame.new(0, -0.75, 0.02),
            Enum.Material.Fabric,
            dark,
            "Wedge"
        )
        if rightHand then
            attachPart(
                model,
                rightHand,
                "ArchiveBook",
                Vector3.new(1.15, 0.3, 1.45),
                CFrame.new(0, -0.15, -0.42)
                    * CFrame.Angles(math.rad(18), math.rad(-10), math.rad(6)),
                Enum.Material.Fabric,
                accent
            )
        end
        if head then
            for _, side in { -1, 1 } do
                attachPart(
                    model,
                    head,
                    if side < 0 then "GlassesLeft" else "GlassesRight",
                    Vector3.new(0.46, 0.3, 0.05),
                    CFrame.new(side * 0.31, 0.08, -0.83),
                    Enum.Material.Metal,
                    Color3.fromRGB(89, 79, 67)
                )
            end
        end
    elseif role == "Mentor" then
        attachPart(
            model,
            upper,
            "PathkeeperMantle",
            Vector3.new(2.35, 0.82, 1.45),
            CFrame.new(0, 0.56, 0),
            Enum.Material.Fabric,
            accent,
            "Wedge"
        )
        attachPart(
            model,
            upper,
            "PathkeeperCoat",
            Vector3.new(2.15, 2.75, 0.3),
            CFrame.new(0, -0.35, 0.68) * CFrame.Angles(math.rad(-5), 0, 0),
            Enum.Material.Fabric,
            dark,
            "Wedge"
        )
        if rightHand then
            attachPart(
                model,
                rightHand,
                "PathkeeperStaff",
                Vector3.new(6.1, 0.18, 0.18),
                CFrame.new(0, -2.0, 0.2) * CFrame.Angles(0, 0, math.rad(90)),
                Enum.Material.Wood,
                Color3.fromRGB(82, 58, 38),
                "Cylinder"
            )
            local crystal = attachPart(
                model,
                rightHand,
                "PathkeeperLumen",
                Vector3.new(0.7, 0.7, 0.7),
                CFrame.new(0, 1.15, 0.2),
                Enum.Material.Neon,
                lumen,
                "Ball"
            )
            if crystal then
                local light = Instance.new("PointLight")
                light.Color = lumen
                light.Brightness = 0.8
                light.Range = 8
                light.Parent = crystal
            end
        end
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

    local palette = spec.Palette or {}
    palette.Cloth = palette.Cloth or Color3.fromRGB(63, 91, 77)
    palette.Accent = palette.Accent or Color3.fromRGB(103, 152, 119)
    palette.Skin = palette.Skin or Color3.fromRGB(214, 181, 146)
    palette.Leather = palette.Leather or Color3.fromRGB(84, 58, 39)
    palette.DarkCloth = palette.DarkCloth or palette.Cloth:Lerp(Color3.new(0, 0, 0), 0.28)

    local description = makeDescription(spec, palette)
    local ok, modelOrError = pcall(function()
        return Players:CreateHumanoidModelFromDescriptionAsync(
            description,
            Enum.HumanoidRigType.R15
        )
    end)
    description:Destroy()
    if not ok or not modelOrError then
        warn(
            string.format(
                "[StylizedNpcFactory] Could not build R15 NPC %s: %s",
                tostring(spec.NpcId or spec.Name),
                tostring(modelOrError)
            )
        )
        return nil, nil, nil
    end

    local model = modelOrError
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

    makeFace(head, palette, spec.Role)
    makeHair(model, head, palette, spec.HairStyle or "short")
    addClothingLayers(model, spec, palette)
    groundModel(model, spec.Position, spec.Yaw or 0, spec.GroundMode)
    startIdleAnimation(model)
    model.PrimaryPart = root
    return model, root, head
end

return StylizedNpcFactory
