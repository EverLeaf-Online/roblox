local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BelforgeAccessRules = require(ReplicatedStorage.Shared.Logic.BelforgeAccessRules)
local BelforgeColossusService = require(script.Parent.BelforgeColossusService)
local InteractionService = require(script.Parent.InteractionService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local PortalService = require(script.Parent.PortalService)
local StylizedNpcFactory = require(script.Parent.StylizedNpcFactory)
local WorldNoticeService = require(script.Parent.WorldNoticeService)
local WorldObjectService = require(script.Parent.WorldObjectService)
local WorldTravelService = require(script.Parent.WorldTravelService)

local BrasshavenWorldService = {}

local GENERATED_NAME = "EverLeafGeneratedBrasshaven"
local ORIGIN = Vector3.new(1450, 0, 40)
local BELFORGE_ANTECHAMBER_ORIGIN = ORIGIN + Vector3.new(430, 0, 395)
local BELFORGE_ARENA_ORIGIN = ORIGIN + Vector3.new(650, 0, 395)

local function makePart(parent, name, size, cframe, material, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.Size = size
    part.CFrame = cframe
    part.Material = material
    part.Color = color
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Parent = parent
    return part
end

local function makeCollisionProxy(parent, name, size, cframe)
    local proxy =
        makePart(parent, name, size, cframe, Enum.Material.SmoothPlastic, Color3.new(0, 0, 0))
    proxy.Transparency = 1
    proxy.CanCollide = true
    proxy.CanTouch = false
    proxy.CanQuery = true
    proxy.CastShadow = false
    proxy:SetAttribute("EverLeafCollisionProxy", true)
    return proxy
end

local function normalizeGeneratedCollisions(world)
    for _, descendant in world:GetDescendants() do
        if descendant:IsA("BasePart") then
            if descendant:GetAttribute("EverLeafCollisionProxy") == true then
                descendant.Transparency = 1
                descendant.CanCollide = true
                descendant.CanTouch = false
                descendant.CanQuery = true
                descendant.CastShadow = false
            else
                descendant.CanCollide = false
                descendant.CanTouch = false
                if descendant:IsA("SpawnLocation") or descendant.Transparency >= 0.95 then
                    descendant.CanQuery = false
                end
            end
        end
    end
end

local function makeLabel(parent, position, text)
    local anchor = makePart(
        parent,
        text:gsub("%W", "") .. "Anchor",
        Vector3.new(1, 1, 1),
        CFrame.new(position),
        Enum.Material.SmoothPlastic,
        Color3.new(0, 0, 0)
    )
    anchor.Transparency = 1
    anchor.CanCollide = false
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.fromOffset(330, 44)
    gui.AlwaysOnTop = false
    gui.MaxDistance = 120
    gui.Parent = anchor
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(28, 24, 20)
    label.BackgroundTransparency = 0.18
    label.Text = text
    label.TextColor3 = Color3.fromRGB(236, 204, 139)
    label.TextStrokeTransparency = 0.4
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = label
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(133, 94, 54)
    stroke.Transparency = 0.25
    stroke.Parent = label
end

local function makeForgeTower(parent, position, height, seed)
    local model = Instance.new("Model")
    model.Name = "ForgeTower" .. tostring(seed)
    model.Parent = parent
    local stone = Color3.fromRGB(74, 69, 62)
    local metal = Color3.fromRGB(82, 76, 68)
    makePart(
        model,
        "Base",
        Vector3.new(14, 4, 14),
        CFrame.new(position + Vector3.new(0, 2, 0)),
        Enum.Material.Basalt,
        stone
    )
    makePart(
        model,
        "Body",
        Vector3.new(10, height, 10),
        CFrame.new(position + Vector3.new(0, 4 + height / 2, 0)),
        Enum.Material.Brick,
        Color3.fromRGB(91, 78, 64)
    )
    local cap = makePart(
        model,
        "Cap",
        Vector3.new(12, 3, 12),
        CFrame.new(position + Vector3.new(0, 4 + height + 1.5, 0)),
        Enum.Material.Metal,
        metal
    )
    cap.CanCollide = false
    local vent = makePart(
        model,
        "Vent",
        Vector3.new(5, 8, 5),
        CFrame.new(position + Vector3.new(0, 4 + height + 6, 0)),
        Enum.Material.Metal,
        Color3.fromRGB(60, 56, 52)
    )
    vent.CanCollide = false
    makeCollisionProxy(
        model,
        "ForgeTowerCollision",
        Vector3.new(14.5, height + 4.2, 14.5),
        CFrame.new(position + Vector3.new(0, (height + 4.2) * 0.5, 0))
    )
    local smoke = Instance.new("Smoke")
    smoke.Color = Color3.fromRGB(95, 92, 88)
    smoke.Opacity = 0.18
    smoke.RiseVelocity = 5
    smoke.Size = 8
    smoke.Parent = vent
    return model
end

local function makeReturnGate(parent, position)
    local model = Instance.new("Model")
    model.Name = "LumenreachReturnGate"
    model.Parent = parent
    local stone = Color3.fromRGB(82, 74, 65)
    local brass = Color3.fromRGB(156, 111, 57)
    makePart(
        model,
        "LeftPillar",
        Vector3.new(5, 17, 5),
        CFrame.new(position + Vector3.new(-8, 8.5, 0)),
        Enum.Material.Brick,
        stone
    )
    makePart(
        model,
        "RightPillar",
        Vector3.new(5, 17, 5),
        CFrame.new(position + Vector3.new(8, 8.5, 0)),
        Enum.Material.Brick,
        stone
    )
    makePart(
        model,
        "Lintel",
        Vector3.new(21, 4, 5),
        CFrame.new(position + Vector3.new(0, 17, 0)),
        Enum.Material.Metal,
        brass
    )
    local gate = makePart(
        model,
        "LumenreachGate",
        Vector3.new(11, 11, 1),
        CFrame.new(position + Vector3.new(0, 6, 0)),
        Enum.Material.ForceField,
        Color3.fromRGB(104, 205, 171)
    )
    gate.Transparency = 0.48
    gate.CanCollide = false
    for _, x in { -8, 8 } do
        makeCollisionProxy(
            model,
            "ReturnGatePillarCollision",
            Vector3.new(5.2, 17, 5.2),
            CFrame.new(position + Vector3.new(x, 8.5, 0))
        )
    end
    WorldObjectService.Register(gate, "Portal", "brasshaven_to_lumenreach")

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Travel"
    prompt.ObjectText = "Lumenreach Gate"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = gate
    prompt.Triggered:Connect(function(player)
        local profile = PlayerDataService.Get(player)
        if not profile then
            return
        end
        local ok, reason = PortalService.Travel(player, profile, "brasshaven_to_lumenreach", gate)
        if ok then
            PlayerDataService.NotifyChanged(player)
        else
            WorldNoticeService.SendReason(player, reason)
        end
    end)
end

local function makeBrasshavenNpc(parent, spec)
    local model, root, head = StylizedNpcFactory.Create(parent, {
        Name = spec.NpcId,
        NpcId = spec.NpcId,
        Position = spec.Position,
        Yaw = spec.Yaw,
        Role = spec.VisualRole,
        HairStyle = spec.HairStyle,
        Build = spec.Build,
        HeightScale = spec.HeightScale,
        WidthScale = spec.WidthScale,
        DepthScale = spec.DepthScale,
        GroundMode = "World",
        Palette = spec.Palette,
    })
    if not model or not root or not head then
        return nil
    end

    local plate = Instance.new("BillboardGui")
    plate.Name = "NpcNameplate"
    plate.Size = UDim2.fromOffset(spec.NameplateWidth or 245, 34)
    plate.StudsOffsetWorldSpace = Vector3.new(0, 1.75, 0)
    plate.AlwaysOnTop = false
    plate.MaxDistance = spec.MaxDistance or 52
    plate.Parent = head

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundColor3 = spec.BackgroundColor or Color3.fromRGB(27, 24, 22)
    text.BackgroundTransparency = 0.15
    text.Text = string.upper(spec.DisplayName)
    text.TextColor3 = spec.TextColor or Color3.fromRGB(238, 203, 137)
    text.TextStrokeTransparency = 0.34
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.Parent = plate
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = text
    local edge = Instance.new("UIStroke")
    edge.Color = spec.StrokeColor
        or (spec.Palette and spec.Palette.Accent)
        or Color3.fromRGB(160, 109, 57)
    edge.Transparency = 0.26
    edge.Parent = text

    WorldObjectService.Register(model, "Npc", spec.NpcId)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = spec.ActionText or "Talk"
    prompt.ObjectText = spec.PromptText or spec.DisplayName
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
    prompt.Parent = root
    prompt.Triggered:Connect(function(player)
        InteractionService.Begin(player, spec.NpcId, model)
    end)
    return model
end

local function makeForeman(parent, position)
    return makeBrasshavenNpc(parent, {
        NpcId = "belforge_foreman",
        DisplayName = "Vale · Belforge Foreman",
        PromptText = "Vale · Belforge Foreman",
        Position = position,
        Yaw = math.rad(-90),
        VisualRole = "Quartermaster",
        HairStyle = "short",
        Build = 1.08,
        HeightScale = 1.02,
        Palette = {
            Cloth = Color3.fromRGB(82, 69, 57),
            DarkCloth = Color3.fromRGB(54, 53, 51),
            Accent = Color3.fromRGB(141, 98, 52),
            Skin = Color3.fromRGB(204, 165, 128),
            Hair = Color3.fromRGB(73, 50, 35),
            EyeColor = Color3.fromRGB(75, 62, 48),
            Leather = Color3.fromRGB(91, 61, 39),
            Metal = Color3.fromRGB(154, 109, 57),
        },
        TextColor = Color3.fromRGB(237, 209, 154),
        StrokeColor = Color3.fromRGB(141, 98, 52),
    })
end

local function makeFoundryVendor(parent, npcId, displayName, position, palette)
    local model = makeBrasshavenNpc(parent, {
        NpcId = npcId,
        DisplayName = displayName,
        PromptText = displayName,
        ActionText = "Trade",
        Position = position,
        Yaw = math.rad(180),
        VisualRole = "Quartermaster",
        HairStyle = if npcId == "belforge_mark_broker" then "bun" else "short",
        Build = if npcId == "belforge_mark_broker" then 0.96 else 1.02,
        Palette = {
            Cloth = palette.Cloth,
            DarkCloth = palette.Cloth:Lerp(Color3.new(0, 0, 0), 0.3),
            Accent = palette.Accent,
            Skin = palette.Skin,
            Hair = if npcId == "belforge_mark_broker"
                then Color3.fromRGB(69, 52, 43)
                else Color3.fromRGB(91, 63, 42),
            EyeColor = Color3.fromRGB(65, 58, 50),
            Leather = Color3.fromRGB(82, 57, 39),
            Metal = palette.Accent,
        },
        TextColor = palette.Text,
        StrokeColor = palette.Accent,
    })
    if not model then
        return nil
    end
    local counterBase = CFrame.new(position) * CFrame.Angles(0, math.rad(180), 0)
    local counter = makePart(
        model,
        "Counter",
        Vector3.new(7, 2.6, 2.6),
        counterBase * CFrame.new(0, 1.3, -3.6),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(79, 60, 44)
    )
    counter.CanCollide = false
    makeCollisionProxy(model, "VendorCounterCollision", Vector3.new(7.2, 2.8, 2.8), counter.CFrame)
    makePart(
        model,
        "CounterTrim",
        Vector3.new(7.2, 0.28, 2.8),
        counterBase * CFrame.new(0, 2.72, -3.6),
        Enum.Material.Metal,
        palette.Accent
    ).CanCollide =
        false
    return model
end

local function makeEastworksEngineer(parent, position)
    return makeBrasshavenNpc(parent, {
        NpcId = "eastworks_engineer",
        DisplayName = "Tamsin · Eastworks Engineer",
        PromptText = "Tamsin · Eastworks Engineer",
        Position = position,
        Yaw = math.rad(165),
        VisualRole = "Archivist",
        HairStyle = "bun",
        Build = 0.96,
        Palette = {
            Cloth = Color3.fromRGB(66, 73, 77),
            DarkCloth = Color3.fromRGB(48, 52, 54),
            Accent = Color3.fromRGB(92, 117, 127),
            Skin = Color3.fromRGB(202, 166, 132),
            Hair = Color3.fromRGB(67, 52, 45),
            EyeColor = Color3.fromRGB(70, 91, 97),
            Leather = Color3.fromRGB(77, 58, 43),
            Metal = Color3.fromRGB(154, 104, 54),
        },
        TextColor = Color3.fromRGB(191, 229, 238),
        StrokeColor = Color3.fromRGB(91, 142, 153),
    })
end

local function makeBelforgeMarshal(parent, position)
    return makeBrasshavenNpc(parent, {
        NpcId = "belforge_marshal",
        DisplayName = "Rook · Belforge Marshal",
        PromptText = "Rook · Belforge Marshal",
        Position = position,
        Yaw = math.rad(150),
        VisualRole = "Scout",
        HairStyle = "short",
        Build = 1.09,
        HeightScale = 1.05,
        Palette = {
            Cloth = Color3.fromRGB(54, 57, 59),
            DarkCloth = Color3.fromRGB(45, 47, 48),
            Accent = Color3.fromRGB(160, 109, 57),
            Skin = Color3.fromRGB(187, 147, 113),
            Hair = Color3.fromRGB(54, 45, 38),
            EyeColor = Color3.fromRGB(79, 66, 50),
            Leather = Color3.fromRGB(84, 58, 39),
            Metal = Color3.fromRGB(217, 164, 76),
        },
        TextColor = Color3.fromRGB(238, 203, 137),
        StrokeColor = Color3.fromRGB(160, 109, 57),
    })
end

local function makeBelforgeGate(parent, position)
    local model = Instance.new("Model")
    model.Name = "BelforgeEntrance"
    model.Parent = parent
    local stone = Color3.fromRGB(67, 61, 56)
    local brass = Color3.fromRGB(152, 103, 48)
    local iron = Color3.fromRGB(58, 58, 57)

    makePart(
        model,
        "GateLeft",
        Vector3.new(9, 30, 11),
        CFrame.new(position + Vector3.new(0, 15, -11)),
        Enum.Material.Brick,
        stone
    )
    makePart(
        model,
        "GateRight",
        Vector3.new(9, 30, 11),
        CFrame.new(position + Vector3.new(0, 15, 11)),
        Enum.Material.Brick,
        stone
    )
    makePart(
        model,
        "GateTop",
        Vector3.new(9, 8, 31),
        CFrame.new(position + Vector3.new(0, 30, 0)),
        Enum.Material.Metal,
        brass
    )
    local door = makePart(
        model,
        "SealedBelforgeDoor",
        Vector3.new(3, 23, 17),
        CFrame.new(position + Vector3.new(-1, 11.5, 0)),
        Enum.Material.DiamondPlate,
        iron
    )
    door.CanCollide = false
    for _, z in { -11, 11 } do
        makeCollisionProxy(
            model,
            "BelforgeGatePillarCollision",
            Vector3.new(9.2, 30, 11.2),
            CFrame.new(position + Vector3.new(0, 15, z))
        )
    end
    makeCollisionProxy(model, "BelforgeDoorCollision", Vector3.new(3.2, 23, 17), door.CFrame)
    for index = -2, 2 do
        local brace = makePart(
            model,
            "DoorBrace" .. tostring(index),
            Vector3.new(3.3, 1.2, 15),
            CFrame.new(position + Vector3.new(-2.7, 11.5 + index * 4.2, 0)),
            Enum.Material.Metal,
            brass
        )
        brace.CanCollide = false
    end
    local warning = makePart(
        model,
        "WarningLumen",
        Vector3.new(3.5, 1.2, 8),
        CFrame.new(position + Vector3.new(-2.9, 24.5, 0)),
        Enum.Material.Neon,
        Color3.fromRGB(218, 112, 65)
    )
    warning.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(232, 126, 71)
    light.Brightness = 1.2
    light.Range = 13
    light.Parent = warning

    local returnMarker = makePart(
        model,
        "BelforgeThresholdReturn",
        Vector3.new(4, 1, 4),
        CFrame.new(position + Vector3.new(-18, 0.5, 0)),
        Enum.Material.SmoothPlastic,
        Color3.new(0, 0, 0)
    )
    returnMarker.Transparency = 1
    returnMarker.CanCollide = false
    returnMarker.CanTouch = false
    returnMarker.CanQuery = false
    WorldTravelService.RegisterSpawn("belforge_threshold_return", returnMarker)

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "BelforgeEntryPrompt"
    prompt.ActionText = "Enter"
    prompt.ObjectText = "Belforge Gate · Level 30"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
    prompt.Parent = door
    prompt.Triggered:Connect(function(player)
        local profile = PlayerDataService.Get(player)
        if not profile then
            WorldNoticeService.SendReason(player, "profile_not_loaded")
            return
        end
        local allowed, reason = BelforgeAccessRules.CanEnter(profile)
        if not allowed then
            WorldNoticeService.SendReason(player, reason)
            return
        end
        local moved, moveReason = WorldTravelService.Teleport(player, "belforge_antechamber")
        if not moved then
            WorldNoticeService.SendReason(player, moveReason)
        end
    end)
    return model
end

local function makeBelforgeOathkeeper(parent, position)
    return makeBrasshavenNpc(parent, {
        NpcId = "belforge_oathkeeper",
        DisplayName = "Mara · Forge Oathkeeper",
        PromptText = "Mara · Forge Oathkeeper",
        ActionText = "Speak Oath",
        Position = position,
        Yaw = math.rad(-90),
        VisualRole = "Mentor",
        HairStyle = "long",
        Build = 1.0,
        HeightScale = 1.02,
        Palette = {
            Cloth = Color3.fromRGB(58, 48, 45),
            DarkCloth = Color3.fromRGB(43, 42, 42),
            Accent = Color3.fromRGB(166, 104, 56),
            Skin = Color3.fromRGB(194, 154, 121),
            Hair = Color3.fromRGB(83, 59, 47),
            EyeColor = Color3.fromRGB(94, 68, 52),
            Leather = Color3.fromRGB(82, 58, 38),
            Metal = Color3.fromRGB(190, 132, 60),
            Lumen = Color3.fromRGB(231, 152, 73),
        },
        TextColor = Color3.fromRGB(245, 207, 145),
        StrokeColor = Color3.fromRGB(166, 104, 56),
    })
end

local function makeBelforgeAntechamber(parent)
    local model = Instance.new("Model")
    model.Name = "BelforgeAntechamber"
    model.Parent = parent
    local origin = BELFORGE_ANTECHAMBER_ORIGIN
    local stone = Color3.fromRGB(55, 52, 49)
    local iron = Color3.fromRGB(62, 61, 58)
    local brass = Color3.fromRGB(155, 104, 48)

    makePart(
        model,
        "AntechamberFloor",
        Vector3.new(116, 6, 92),
        CFrame.new(origin + Vector3.new(0, -3, 0)),
        Enum.Material.Basalt,
        stone
    )
    makePart(
        model,
        "NorthWall",
        Vector3.new(116, 24, 5),
        CFrame.new(origin + Vector3.new(0, 12, -44)),
        Enum.Material.Brick,
        stone
    )
    makePart(
        model,
        "SouthWall",
        Vector3.new(116, 24, 5),
        CFrame.new(origin + Vector3.new(0, 12, 44)),
        Enum.Material.Brick,
        stone
    )
    makePart(
        model,
        "FarWall",
        Vector3.new(5, 24, 92),
        CFrame.new(origin + Vector3.new(56, 12, 0)),
        Enum.Material.Brick,
        stone
    )
    makeCollisionProxy(
        model,
        "AntechamberFloorCollision",
        Vector3.new(116, 6, 92),
        CFrame.new(origin + Vector3.new(0, -3, 0))
    )
    makeCollisionProxy(
        model,
        "AntechamberNorthWallCollision",
        Vector3.new(116, 24, 5),
        CFrame.new(origin + Vector3.new(0, 12, -44))
    )
    makeCollisionProxy(
        model,
        "AntechamberSouthWallCollision",
        Vector3.new(116, 24, 5),
        CFrame.new(origin + Vector3.new(0, 12, 44))
    )
    makeCollisionProxy(
        model,
        "AntechamberFarWallCollision",
        Vector3.new(5, 24, 92),
        CFrame.new(origin + Vector3.new(56, 12, 0))
    )

    local innerDoor = makePart(
        model,
        "ColossusSeal",
        Vector3.new(4, 25, 25),
        CFrame.new(origin + Vector3.new(53, 12.5, 0)),
        Enum.Material.DiamondPlate,
        iron
    )
    innerDoor.CanCollide = false
    makeCollisionProxy(model, "ColossusSealCollision", Vector3.new(4.2, 25, 25), innerDoor.CFrame)
    for index = -2, 2 do
        local band = makePart(
            model,
            "SealBand" .. tostring(index + 3),
            Vector3.new(4.4, 1.2, 22),
            CFrame.new(origin + Vector3.new(50.8, 12.5 + index * 4.4, 0)),
            Enum.Material.Metal,
            brass
        )
        band.CanCollide = false
    end
    local sealGlow = makePart(
        model,
        "ColossusSealGlow",
        Vector3.new(4.6, 1.0, 10),
        CFrame.new(origin + Vector3.new(50.6, 23.5, 0)),
        Enum.Material.Neon,
        Color3.fromRGB(220, 83, 43)
    )
    sealGlow.CanCollide = false
    local sealLight = Instance.new("PointLight")
    sealLight.Color = sealGlow.Color
    sealLight.Brightness = 1.4
    sealLight.Range = 15
    sealLight.Parent = sealGlow

    local arenaPrompt = Instance.new("ProximityPrompt")
    arenaPrompt.Name = "ColossusArenaPrompt"
    arenaPrompt.ActionText = "Enter Arena"
    arenaPrompt.ObjectText = "Belforge Colossus · Tier 2"
    arenaPrompt.KeyboardKeyCode = Enum.KeyCode.E
    arenaPrompt.MaxActivationDistance = 11
    arenaPrompt.RequiresLineOfSight = false
    arenaPrompt.Parent = innerDoor
    arenaPrompt.Triggered:Connect(function(player)
        local profile = PlayerDataService.Get(player)
        if not profile then
            WorldNoticeService.SendReason(player, "profile_not_loaded")
            return
        end
        local entered, reason = BelforgeColossusService.RequestEntry(player, profile)
        if not entered then
            WorldNoticeService.SendReason(player, reason)
        end
    end)

    local spawnMarker = Instance.new("SpawnLocation")
    spawnMarker.Name = "BelforgeAntechamberSpawn"
    spawnMarker.Size = Vector3.new(4, 1, 4)
    spawnMarker.CFrame = CFrame.new(origin + Vector3.new(-38, 3.25, 0))
    spawnMarker.Anchored = true
    spawnMarker.Neutral = true
    spawnMarker.Transparency = 1
    spawnMarker.CanCollide = false
    spawnMarker.CanTouch = false
    spawnMarker.CanQuery = false
    spawnMarker.Parent = model
    WorldTravelService.RegisterSpawn("belforge_antechamber", spawnMarker)

    local returnPad = makePart(
        model,
        "ReturnPad",
        Vector3.new(8, 0.7, 8),
        CFrame.new(origin + Vector3.new(-46, 0.35, 0)),
        Enum.Material.Metal,
        brass
    )
    returnPad.CanCollide = false
    local returnPrompt = Instance.new("ProximityPrompt")
    returnPrompt.ActionText = "Return"
    returnPrompt.ObjectText = "Brasshaven Eastworks"
    returnPrompt.KeyboardKeyCode = Enum.KeyCode.E
    returnPrompt.MaxActivationDistance = 10
    returnPrompt.RequiresLineOfSight = false
    returnPrompt.Parent = returnPad
    returnPrompt.Triggered:Connect(function(player)
        WorldTravelService.SetRespawn(player, "brasshaven_start")
        local moved, reason = WorldTravelService.Teleport(player, "belforge_threshold_return")
        if not moved then
            WorldNoticeService.SendReason(player, reason)
        end
    end)

    makeBelforgeOathkeeper(model, origin + Vector3.new(-8, 0, 17))
    makeLabel(model, origin + Vector3.new(4, 22, 0), "BELFORGE ANTECHAMBER · COLOSSUS SEAL")
    makeLabel(model, origin + Vector3.new(45, 15, 0), "BELFORGE COLOSSUS · TIER 2 ARENA")
    return model
end

local function makeMonsterSpawnTrigger(parent, name, position, config)
    local trigger = Instance.new("Part")
    trigger.Name = "MonsterSpawnTrigger"
    trigger.Size = Vector3.new(2, 0.4, 2)
    trigger.CFrame = CFrame.new(position + Vector3.new(0, 0.2, 0))
    trigger.Anchored = true
    trigger.CanCollide = false
    trigger.CanTouch = false
    trigger.CanQuery = false
    trigger.Transparency = 1
    trigger:SetAttribute("TriggerName", name)
    trigger:SetAttribute("MonsterType", config.MonsterType)
    trigger:SetAttribute("SpawnAmount", config.SpawnAmount)
    trigger:SetAttribute("TriggerRadius", config.TriggerRadius)
    trigger:SetAttribute("SpawnRadius", config.SpawnRadius)
    trigger:SetAttribute("MaxAliveMonster", config.MaxAliveMonster)
    trigger:SetAttribute("SpawnDelay", config.SpawnDelay)
    trigger:SetAttribute("RespawnTime", config.RespawnTime)
    trigger.Parent = parent
    CollectionService:AddTag(trigger, "MonsterSpawnTrigger")
    return trigger
end

local function makeBelforgeArena(parent)
    local model = Instance.new("Model")
    model.Name = "BelforgeColossusArena"
    model.Parent = parent
    local origin = BELFORGE_ARENA_ORIGIN
    local stone = Color3.fromRGB(48, 46, 44)
    local iron = Color3.fromRGB(61, 59, 56)
    local brass = Color3.fromRGB(147, 96, 45)

    makePart(
        model,
        "ArenaFloor",
        Vector3.new(210, 7, 170),
        CFrame.new(origin + Vector3.new(0, -3.5, 0)),
        Enum.Material.Basalt,
        stone
    )
    makePart(
        model,
        "NorthWall",
        Vector3.new(210, 30, 6),
        CFrame.new(origin + Vector3.new(0, 15, -82)),
        Enum.Material.Brick,
        stone
    )
    makePart(
        model,
        "SouthWall",
        Vector3.new(210, 30, 6),
        CFrame.new(origin + Vector3.new(0, 15, 82)),
        Enum.Material.Brick,
        stone
    )
    makePart(
        model,
        "EastWall",
        Vector3.new(6, 30, 170),
        CFrame.new(origin + Vector3.new(102, 15, 0)),
        Enum.Material.Brick,
        stone
    )
    makePart(
        model,
        "WestWall",
        Vector3.new(6, 30, 170),
        CFrame.new(origin + Vector3.new(-102, 15, 0)),
        Enum.Material.Brick,
        stone
    )
    makeCollisionProxy(
        model,
        "ArenaFloorCollision",
        Vector3.new(210, 7, 170),
        CFrame.new(origin + Vector3.new(0, -3.5, 0))
    )
    makeCollisionProxy(
        model,
        "ArenaNorthWallCollision",
        Vector3.new(210, 30, 6),
        CFrame.new(origin + Vector3.new(0, 15, -82))
    )
    makeCollisionProxy(
        model,
        "ArenaSouthWallCollision",
        Vector3.new(210, 30, 6),
        CFrame.new(origin + Vector3.new(0, 15, 82))
    )
    makeCollisionProxy(
        model,
        "ArenaEastWallCollision",
        Vector3.new(6, 30, 170),
        CFrame.new(origin + Vector3.new(102, 15, 0))
    )
    makeCollisionProxy(
        model,
        "ArenaWestWallCollision",
        Vector3.new(6, 30, 170),
        CFrame.new(origin + Vector3.new(-102, 15, 0))
    )

    for index = -3, 3 do
        if index ~= 0 then
            local column = makePart(
                model,
                "ArenaColumn" .. tostring(index + 4),
                Vector3.new(5.5, 18, 5.5),
                CFrame.new(origin + Vector3.new(index * 24, 9, if index % 2 == 0 then -58 else 58)),
                Enum.Material.Metal,
                iron
            )
            column.CanCollide = false
            makeCollisionProxy(
                model,
                "ArenaColumnCollision",
                Vector3.new(5.8, 18, 5.8),
                column.CFrame
            )
            local band = makePart(
                model,
                "ArenaColumnBand" .. tostring(index + 4),
                Vector3.new(6.0, 0.8, 6.0),
                CFrame.new(origin + Vector3.new(index * 24, 12, if index % 2 == 0 then -58 else 58)),
                Enum.Material.Metal,
                brass
            )
            band.CanCollide = false
        end
    end

    for _, spec in
        {
            { Vector3.new(-72, 0, -55), 0.92 },
            { Vector3.new(-72, 0, 55), 0.92 },
            { Vector3.new(72, 0, -55), 1.05 },
            { Vector3.new(72, 0, 55), 1.05 },
        }
    do
        local vent = makePart(
            model,
            "ArenaVent",
            Vector3.new(7, 0.7, 7) * spec[2],
            CFrame.new(origin + spec[1] + Vector3.new(0, 0.35, 0)),
            Enum.Material.Basalt,
            stone
        )
        vent.Shape = Enum.PartType.Cylinder
        vent.Orientation = Vector3.new(0, 0, 90)
        vent.CanCollide = false
        local glow = makePart(
            model,
            "ArenaVentHeat",
            Vector3.new(4.8, 0.24, 4.8) * spec[2],
            CFrame.new(origin + spec[1] + Vector3.new(0, 0.76, 0)),
            Enum.Material.Neon,
            Color3.fromRGB(238, 87, 31)
        )
        glow.Shape = Enum.PartType.Cylinder
        glow.Orientation = Vector3.new(0, 0, 90)
        glow.CanCollide = false
        glow.CanTouch = false
        local light = Instance.new("PointLight")
        light.Color = glow.Color
        light.Brightness = 1.2
        light.Range = 12
        light.Parent = glow
    end

    local arenaSpawn = makePart(
        model,
        "ColossusArenaSpawn",
        Vector3.new(4, 1, 4),
        CFrame.new(origin + Vector3.new(-78, 0.5, 0)),
        Enum.Material.SmoothPlastic,
        Color3.new(0, 0, 0)
    )
    arenaSpawn.Transparency = 1
    arenaSpawn.CanCollide = false
    arenaSpawn.CanTouch = false
    arenaSpawn.CanQuery = false
    WorldTravelService.RegisterSpawn("belforge_colossus_arena", arenaSpawn)

    local returnPad = makePart(
        model,
        "ArenaReturnPad",
        Vector3.new(9, 0.7, 9),
        CFrame.new(origin + Vector3.new(-88, 0.35, 0)),
        Enum.Material.Metal,
        brass
    )
    returnPad.CanCollide = false
    local returnPrompt = Instance.new("ProximityPrompt")
    returnPrompt.ActionText = "Leave Arena"
    returnPrompt.ObjectText = "Belforge Antechamber"
    returnPrompt.KeyboardKeyCode = Enum.KeyCode.E
    returnPrompt.MaxActivationDistance = 10
    returnPrompt.RequiresLineOfSight = false
    returnPrompt.Parent = returnPad
    returnPrompt.Triggered:Connect(function(player)
        local left, reason = BelforgeColossusService.LeaveArena(player)
        if not left then
            WorldNoticeService.SendReason(player, reason)
        end
    end)

    makeLabel(model, origin + Vector3.new(0, 28, 0), "BELFORGE COLOSSUS ARENA")
    makeMonsterSpawnTrigger(model, "BelforgeColossusEncounter", origin + Vector3.new(28, 0, 0), {
        MonsterType = "BelforgeColossus",
        SpawnAmount = 1,
        TriggerRadius = 58,
        SpawnRadius = 4,
        MaxAliveMonster = 1,
        SpawnDelay = 0,
        RespawnTime = 600,
    })
    return model
end

local function makeScrapPile(parent, position, yaw, scale)
    local model = Instance.new("Model")
    model.Name = "FoundryScrap"
    model.Parent = parent
    local base = CFrame.new(position) * CFrame.Angles(0, yaw or 0, 0)
    scale = scale or 1
    local iron = Color3.fromRGB(76, 72, 66)
    local brass = Color3.fromRGB(137, 94, 47)

    for index, spec in
        {
            { Vector3.new(-1.8, 0.65, 0.3), Vector3.new(3.6, 1.1, 1.3), iron, -18 },
            { Vector3.new(1.1, 0.85, -0.5), Vector3.new(2.7, 1.5, 1.0), brass, 27 },
            { Vector3.new(0.2, 1.45, 1.0), Vector3.new(1.1, 2.6, 1.1), iron, 74 },
            { Vector3.new(-0.4, 0.35, -1.3), Vector3.new(4.2, 0.45, 1.4), brass, -42 },
        }
    do
        local part = makePart(
            model,
            "Scrap" .. tostring(index),
            spec[2] * scale,
            base
                * CFrame.new(spec[1] * scale)
                * CFrame.Angles(0, math.rad(spec[4]), math.rad(index * 7)),
            Enum.Material.Metal,
            spec[3]
        )
        part.CanCollide = false
        part.CanTouch = false
    end
    makeCollisionProxy(
        model,
        "ScrapPileCollision",
        Vector3.new(7.0, 3.6, 5.2) * scale,
        base * CFrame.new(0, 1.8 * scale, 0)
    )
    return model
end

local function makeHotVent(parent, position, scale)
    scale = scale or 1
    local model = Instance.new("Model")
    model.Name = "HotworksVent"
    model.Parent = parent
    local rim = makePart(
        model,
        "Rim",
        Vector3.new(7, 0.7, 7) * scale,
        CFrame.new(position + Vector3.new(0, 0.35, 0)),
        Enum.Material.Basalt,
        Color3.fromRGB(54, 52, 49)
    )
    rim.Shape = Enum.PartType.Cylinder
    rim.Orientation = Vector3.new(0, 0, 90)
    rim.CanCollide = false
    local glow = makePart(
        model,
        "Heat",
        Vector3.new(4.8, 0.24, 4.8) * scale,
        CFrame.new(position + Vector3.new(0, 0.76, 0)),
        Enum.Material.Neon,
        Color3.fromRGB(246, 104, 36)
    )
    glow.Shape = Enum.PartType.Cylinder
    glow.Orientation = Vector3.new(0, 0, 90)
    glow.CanCollide = false
    glow.CanTouch = false
    local light = Instance.new("PointLight")
    light.Color = glow.Color
    light.Brightness = 1.4
    light.Range = 13 * scale
    light.Parent = glow
    local smoke = Instance.new("Smoke")
    smoke.Color = Color3.fromRGB(96, 78, 65)
    smoke.Opacity = 0.18
    smoke.RiseVelocity = 3.5
    smoke.Size = 4 * scale
    smoke.Parent = glow
    return model
end

local function dressEncounterAreas(parent)
    local scrapCenter = ORIGIN + Vector3.new(-22, 0, -56)
    makeLabel(parent, scrapCenter + Vector3.new(0, 15, 0), "SCRAP LANES")
    makeScrapPile(parent, scrapCenter + Vector3.new(-14, 0, -10), math.rad(15), 1.05)
    makeScrapPile(parent, scrapCenter + Vector3.new(12, 0, 8), math.rad(-32), 0.9)
    makeScrapPile(parent, scrapCenter + Vector3.new(21, 0, -13), math.rad(61), 0.75)
    for index = 1, 6 do
        local x = -18 + index * 6
        local post = makePart(
            parent,
            "ScrapLanePost" .. tostring(index),
            Vector3.new(0.6, 4.2, 0.6),
            CFrame.new(scrapCenter + Vector3.new(x, 2.1, 20)),
            Enum.Material.Metal,
            Color3.fromRGB(104, 76, 48)
        )
        post.CanCollide = false
        makeCollisionProxy(
            parent,
            "ScrapLanePostCollision",
            Vector3.new(0.85, 4.2, 0.85),
            post.CFrame
        )
    end

    local hotworksCenter = ORIGIN + Vector3.new(58, 0, 58)
    makeLabel(parent, hotworksCenter + Vector3.new(0, 16, 0), "LOWER HOTWORKS")
    makeHotVent(parent, hotworksCenter + Vector3.new(-14, 0, -8), 1.0)
    makeHotVent(parent, hotworksCenter + Vector3.new(10, 0, 11), 0.82)
    makeHotVent(parent, hotworksCenter + Vector3.new(19, 0, -15), 0.68)
    makeScrapPile(parent, hotworksCenter + Vector3.new(-23, 0, 16), math.rad(28), 0.78)

    makeMonsterSpawnTrigger(parent, "BrasshavenScrapLaneScuttlers", scrapCenter, {
        MonsterType = "RivetScuttler",
        SpawnAmount = 4,
        TriggerRadius = 30,
        SpawnRadius = 15,
        MaxAliveMonster = 4,
        SpawnDelay = 0.24,
        RespawnTime = 24,
    })
    makeMonsterSpawnTrigger(parent, "BrasshavenHotworksSlagmites", hotworksCenter, {
        MonsterType = "Slagmite",
        SpawnAmount = 3,
        TriggerRadius = 31,
        SpawnRadius = 14,
        MaxAliveMonster = 3,
        SpawnDelay = 0.38,
        RespawnTime = 29,
    })

    local gearworksCenter = ORIGIN + Vector3.new(-78, 0, 76)
    makeLabel(parent, gearworksCenter + Vector3.new(0, 16, 0), "GEARWORKS YARD")
    makeScrapPile(parent, gearworksCenter + Vector3.new(-18, 0, -8), math.rad(9), 1.0)
    makeScrapPile(parent, gearworksCenter + Vector3.new(15, 0, 11), math.rad(-38), 0.92)
    for index = 1, 5 do
        local wheel = makePart(
            parent,
            "GearworksWheel" .. tostring(index),
            Vector3.new(0.55, 4.2 + index * 0.4, 4.2 + index * 0.4),
            CFrame.new(gearworksCenter + Vector3.new(-14 + index * 7, 2.5, -18))
                * CFrame.Angles(0, 0, math.rad(90 + index * 14)),
            Enum.Material.Metal,
            if index % 2 == 0 then Color3.fromRGB(142, 96, 49) else Color3.fromRGB(72, 69, 64)
        )
        wheel.Shape = Enum.PartType.Cylinder
        wheel.CanCollide = false
        makeCollisionProxy(
            parent,
            "GearworksWheelCollision",
            wheel.Size + Vector3.new(0.25, 0.25, 0.25),
            wheel.CFrame
        )
    end

    local cinderCenter = ORIGIN + Vector3.new(83, 0, -72)
    makeLabel(parent, cinderCenter + Vector3.new(0, 17, 0), "CINDER DUCTS")
    makeHotVent(parent, cinderCenter + Vector3.new(-12, 0, -7), 0.9)
    makeHotVent(parent, cinderCenter + Vector3.new(15, 0, 10), 0.78)
    makeHotVent(parent, cinderCenter + Vector3.new(4, 0, 18), 0.62)
    for index = 1, 4 do
        local pipe = makePart(
            parent,
            "CinderPipe" .. tostring(index),
            Vector3.new(3.2, 3.2, 18),
            CFrame.new(cinderCenter + Vector3.new(-19 + index * 12, 4.2, -18))
                * CFrame.Angles(0, math.rad(90), 0),
            Enum.Material.Metal,
            Color3.fromRGB(83, 75, 66)
        )
        pipe.Shape = Enum.PartType.Cylinder
        pipe.CanCollide = false
        makeCollisionProxy(
            parent,
            "CinderPipeCollision",
            pipe.Size + Vector3.new(0.3, 0.3, 0.3),
            pipe.CFrame
        )
    end

    local bastionCenter = ORIGIN + Vector3.new(122, 0, -40)
    makeLabel(parent, bastionCenter + Vector3.new(0, 18, 0), "REGULATOR ROW")
    makeScrapPile(parent, bastionCenter + Vector3.new(-16, 0, 13), math.rad(52), 0.75)
    for index = -2, 2 do
        local regulator = makePart(
            parent,
            "Regulator" .. tostring(index + 3),
            Vector3.new(4.5, 8.5, 4.5),
            CFrame.new(bastionCenter + Vector3.new(index * 8, 4.25, -16)),
            Enum.Material.Metal,
            Color3.fromRGB(76, 71, 65)
        )
        regulator.Shape = Enum.PartType.Cylinder
        regulator.CanCollide = false
        makeCollisionProxy(
            parent,
            "RegulatorCollision",
            regulator.Size + Vector3.new(0.35, 0.2, 0.35),
            regulator.CFrame
        )
        local band = makePart(
            parent,
            "RegulatorBand" .. tostring(index + 3),
            Vector3.new(4.8, 0.55, 4.8),
            CFrame.new(bastionCenter + Vector3.new(index * 8, 4.5, -16)),
            Enum.Material.Metal,
            Color3.fromRGB(153, 103, 49)
        )
        band.Shape = Enum.PartType.Cylinder
        band.CanCollide = false
    end

    makeMonsterSpawnTrigger(parent, "BrasshavenGearjawHounds", gearworksCenter, {
        MonsterType = "GearjawHound",
        SpawnAmount = 4,
        TriggerRadius = 31,
        SpawnRadius = 15,
        MaxAliveMonster = 4,
        SpawnDelay = 0.22,
        RespawnTime = 27,
    })
    makeMonsterSpawnTrigger(parent, "BrasshavenCindercoils", cinderCenter, {
        MonsterType = "Cindercoil",
        SpawnAmount = 3,
        TriggerRadius = 30,
        SpawnRadius = 14,
        MaxAliveMonster = 3,
        SpawnDelay = 0.28,
        RespawnTime = 29,
    })
    makeMonsterSpawnTrigger(parent, "BrasshavenPressureBastion", bastionCenter, {
        MonsterType = "PressureBastion",
        SpawnAmount = 1,
        TriggerRadius = 24,
        SpawnRadius = 6,
        MaxAliveMonster = 1,
        SpawnDelay = 0,
        RespawnTime = 100,
    })

    local sootworksCenter = ORIGIN + Vector3.new(-58, 0, 145)
    makeLabel(parent, sootworksCenter + Vector3.new(0, 18, 0), "SOOTWORKS DEAD SHIFT")
    makeScrapPile(parent, sootworksCenter + Vector3.new(-18, 0, -12), math.rad(14), 1.05)
    makeScrapPile(parent, sootworksCenter + Vector3.new(16, 0, 13), math.rad(-21), 0.9)
    makeHotVent(parent, sootworksCenter + Vector3.new(22, 0, -10), 0.75)
    for index = -2, 2 do
        local locker = makePart(
            parent,
            "DeadShiftLocker" .. tostring(index + 3),
            Vector3.new(3.2, 7.2, 2.4),
            CFrame.new(sootworksCenter + Vector3.new(index * 4.1, 3.6, 19)),
            Enum.Material.Metal,
            Color3.fromRGB(74, 69, 63)
        )
        locker.CanCollide = false
        makeCollisionProxy(
            parent,
            "DeadShiftLockerCollision",
            locker.Size + Vector3.new(0.2, 0.1, 0.2),
            locker.CFrame
        )
    end

    local dynamoCenter = ORIGIN + Vector3.new(64, 0, -148)
    makeLabel(parent, dynamoCenter + Vector3.new(0, 19, 0), "DYNAMO GALLERY")
    for index = 1, 4 do
        local coil = makePart(
            parent,
            "DynamoCoil" .. tostring(index),
            Vector3.new(0.6, 6.2, 6.2),
            CFrame.new(dynamoCenter + Vector3.new(-18 + index * 9, 3.2, -14))
                * CFrame.Angles(0, 0, math.rad(90 + index * 10)),
            Enum.Material.Metal,
            Color3.fromRGB(143, 92, 50)
        )
        coil.Shape = Enum.PartType.Cylinder
        coil.CanCollide = false
        makeCollisionProxy(
            parent,
            "DynamoCoilCollision",
            coil.Size + Vector3.new(0.25, 0.25, 0.25),
            coil.CFrame
        )
        local core = makePart(
            parent,
            "DynamoCore" .. tostring(index),
            Vector3.new(1.2, 1.2, 1.2),
            CFrame.new(dynamoCenter + Vector3.new(-18 + index * 9, 3.2, -14)),
            Enum.Material.Neon,
            Color3.fromRGB(101, 198, 242)
        )
        core.Shape = Enum.PartType.Ball
        core.CanCollide = false
        local light = Instance.new("PointLight")
        light.Color = core.Color
        light.Brightness = 1.0
        light.Range = 9
        light.Parent = core
    end

    local railCenter = ORIGIN + Vector3.new(108, 0, 145)
    makeLabel(parent, railCenter + Vector3.new(0, 20, 0), "EASTWORKS RAIL YARD")
    for lane = -2, 2 do
        local rail = makePart(
            parent,
            "RailLine" .. tostring(lane + 3),
            Vector3.new(1.0, 0.35, 54),
            CFrame.new(railCenter + Vector3.new(lane * 5, 0.25, 0)),
            Enum.Material.Metal,
            Color3.fromRGB(91, 86, 80)
        )
        rail.CanCollide = false
    end
    makeScrapPile(parent, railCenter + Vector3.new(-18, 0, 17), math.rad(71), 0.88)
    makeScrapPile(parent, railCenter + Vector3.new(17, 0, -18), math.rad(-48), 0.82)

    makeMonsterSpawnTrigger(parent, "BrasshavenFurnaceHusks", sootworksCenter, {
        MonsterType = "FurnaceHusk",
        SpawnAmount = 4,
        TriggerRadius = 31,
        SpawnRadius = 15,
        MaxAliveMonster = 4,
        SpawnDelay = 0.3,
        RespawnTime = 30,
    })
    makeMonsterSpawnTrigger(parent, "BrasshavenArcSiphons", dynamoCenter, {
        MonsterType = "ArcSiphon",
        SpawnAmount = 4,
        TriggerRadius = 32,
        SpawnRadius = 15,
        MaxAliveMonster = 4,
        SpawnDelay = 0.26,
        RespawnTime = 29,
    })
    makeMonsterSpawnTrigger(parent, "BrasshavenRailbreaker", railCenter, {
        MonsterType = "Railbreaker",
        SpawnAmount = 1,
        TriggerRadius = 28,
        SpawnRadius = 7,
        MaxAliveMonster = 1,
        SpawnDelay = 0,
        RespawnTime = 115,
    })

    local blueglassCenter = ORIGIN + Vector3.new(-72, 0, 235)
    makeLabel(parent, blueglassCenter + Vector3.new(0, 20, 0), "BLUEGLASS ANNEX")
    for index = 1, 5 do
        local lens = makePart(
            parent,
            "BlueglassLens" .. tostring(index),
            Vector3.new(0.45, 5.0, 5.0),
            CFrame.new(blueglassCenter + Vector3.new(-18 + index * 7, 3.0, -16))
                * CFrame.Angles(0, 0, math.rad(90 + index * 8)),
            Enum.Material.Glass,
            Color3.fromRGB(86, 177, 219)
        )
        lens.Shape = Enum.PartType.Cylinder
        lens.Transparency = 0.22
        lens.CanCollide = false
        makeCollisionProxy(
            parent,
            "BlueglassLensCollision",
            lens.Size + Vector3.new(0.2, 0.2, 0.2),
            lens.CFrame
        )
    end
    makeScrapPile(parent, blueglassCenter + Vector3.new(-18, 0, 13), math.rad(18), 0.85)

    local maintenanceCenter = ORIGIN + Vector3.new(68, 0, -235)
    makeLabel(parent, maintenanceCenter + Vector3.new(0, 20, 0), "EASTWORKS MAINTENANCE DECK")
    makeScrapPile(parent, maintenanceCenter + Vector3.new(-17, 0, -12), math.rad(31), 0.9)
    makeScrapPile(parent, maintenanceCenter + Vector3.new(18, 0, 11), math.rad(-44), 0.88)
    for index = -2, 2 do
        local arm = makePart(
            parent,
            "MaintenanceArm" .. tostring(index + 3),
            Vector3.new(1.1, 9.0, 1.1),
            CFrame.new(maintenanceCenter + Vector3.new(index * 7, 4.5, 18))
                * CFrame.Angles(0, 0, math.rad(index * 5)),
            Enum.Material.Metal,
            Color3.fromRGB(93, 78, 62)
        )
        arm.CanCollide = false
        makeCollisionProxy(
            parent,
            "MaintenanceArmCollision",
            arm.Size + Vector3.new(0.25, 0.1, 0.25),
            arm.CFrame
        )
    end

    local smelterCenter = ORIGIN + Vector3.new(108, 0, 235)
    makeLabel(parent, smelterCenter + Vector3.new(0, 22, 0), "SMELTER CRUCIBLE YARD")
    makeHotVent(parent, smelterCenter + Vector3.new(-18, 0, -13), 1.05)
    makeHotVent(parent, smelterCenter + Vector3.new(17, 0, 12), 0.92)
    makeHotVent(parent, smelterCenter + Vector3.new(0, 0, 20), 0.72)
    for index = 1, 3 do
        local crucible = makePart(
            parent,
            "Crucible" .. tostring(index),
            Vector3.new(7.5, 8.0, 7.5),
            CFrame.new(smelterCenter + Vector3.new(-16 + index * 11, 4.0, -18)),
            Enum.Material.Metal,
            Color3.fromRGB(67, 64, 60)
        )
        crucible.Shape = Enum.PartType.Cylinder
        crucible.CanCollide = false
        makeCollisionProxy(
            parent,
            "CrucibleCollision",
            crucible.Size + Vector3.new(0.3, 0.2, 0.3),
            crucible.CFrame
        )
    end

    makeMonsterSpawnTrigger(parent, "EastworksBlueflameSentries", blueglassCenter, {
        MonsterType = "BlueflameSentry",
        SpawnAmount = 4,
        TriggerRadius = 32,
        SpawnRadius = 15,
        MaxAliveMonster = 4,
        SpawnDelay = 0.24,
        RespawnTime = 30,
    })
    makeMonsterSpawnTrigger(parent, "EastworksFoundryReavers", maintenanceCenter, {
        MonsterType = "FoundryReaver",
        SpawnAmount = 4,
        TriggerRadius = 32,
        SpawnRadius = 15,
        MaxAliveMonster = 4,
        SpawnDelay = 0.28,
        RespawnTime = 31,
    })
    makeMonsterSpawnTrigger(parent, "EastworksSmelterGolem", smelterCenter, {
        MonsterType = "SmelterGolem",
        SpawnAmount = 1,
        TriggerRadius = 30,
        SpawnRadius = 7,
        MaxAliveMonster = 1,
        SpawnDelay = 0,
        RespawnTime = 125,
    })

    local fluxVaultCenter = ORIGIN + Vector3.new(-105, 0, 325)
    makeLabel(parent, fluxVaultCenter + Vector3.new(0, 20, 0), "UPPER FLUX VAULTS")
    for index = 1, 5 do
        local prism = makePart(
            parent,
            "FluxPrism" .. tostring(index),
            Vector3.new(2.0, 6.0 + index * 0.45, 2.0),
            CFrame.new(fluxVaultCenter + Vector3.new(-18 + index * 7.5, 3.2, -16))
                * CFrame.Angles(0, math.rad(index * 17), math.rad(8 + index * 4)),
            Enum.Material.Glass,
            Color3.fromRGB(169, 86, 214)
        )
        prism.Transparency = 0.2
        prism.CanCollide = false
        makeCollisionProxy(
            parent,
            "FluxPrismCollision",
            prism.Size + Vector3.new(0.2, 0.2, 0.2),
            prism.CFrame
        )
    end
    makeScrapPile(parent, fluxVaultCenter + Vector3.new(-18, 0, 15), math.rad(24), 0.8)

    local enforcementCenter = ORIGIN + Vector3.new(-12, 0, 325)
    makeLabel(parent, enforcementCenter + Vector3.new(0, 20, 0), "AUTHORITY HALL")
    for index = -2, 2 do
        local column = makePart(
            parent,
            "AuthorityColumn" .. tostring(index + 3),
            Vector3.new(3.8, 13, 3.8),
            CFrame.new(enforcementCenter + Vector3.new(index * 9, 6.5, -17)),
            Enum.Material.Brick,
            Color3.fromRGB(68, 65, 61)
        )
        column.CanCollide = false
        makeCollisionProxy(
            parent,
            "AuthorityColumnCollision",
            column.Size + Vector3.new(0.25, 0.1, 0.25),
            column.CFrame
        )
        local band = makePart(
            parent,
            "AuthorityBand" .. tostring(index + 3),
            Vector3.new(4.2, 0.6, 4.2),
            CFrame.new(enforcementCenter + Vector3.new(index * 9, 8.2, -17)),
            Enum.Material.Metal,
            Color3.fromRGB(153, 101, 48)
        )
        band.CanCollide = false
    end

    local runoffCenter = ORIGIN + Vector3.new(88, 0, 325)
    makeLabel(parent, runoffCenter + Vector3.new(0, 20, 0), "MOLTEN RUNOFF CHANNELS")
    for index = -2, 2 do
        local channel = makePart(
            parent,
            "MoltenChannel" .. tostring(index + 3),
            Vector3.new(5.5, 0.5, 45),
            CFrame.new(runoffCenter + Vector3.new(index * 8, 0.22, 0)),
            Enum.Material.Neon,
            Color3.fromRGB(243, 91, 32)
        )
        channel.CanCollide = false
        channel.CanTouch = false
    end
    makeHotVent(parent, runoffCenter + Vector3.new(-20, 0, -18), 0.8)
    makeHotVent(parent, runoffCenter + Vector3.new(20, 0, 18), 0.75)

    local bellowsCenter = ORIGIN + Vector3.new(-58, 0, 395)
    makeLabel(parent, bellowsCenter + Vector3.new(0, 22, 0), "UPPER BELLOWS COURT")
    for index = 1, 4 do
        local tower = makePart(
            parent,
            "BellowsPiston" .. tostring(index),
            Vector3.new(5.5, 12 + index, 5.5),
            CFrame.new(bellowsCenter + Vector3.new(-20 + index * 10, 6.5, -16)),
            Enum.Material.Metal,
            Color3.fromRGB(73, 68, 62)
        )
        tower.Shape = Enum.PartType.Cylinder
        tower.CanCollide = false
        makeCollisionProxy(
            parent,
            "BellowsPistonCollision",
            tower.Size + Vector3.new(0.3, 0.1, 0.3),
            tower.CFrame
        )
    end
    makeHotVent(parent, bellowsCenter + Vector3.new(-18, 0, 13), 1.0)
    makeHotVent(parent, bellowsCenter + Vector3.new(17, 0, 12), 1.0)

    local sentinelCenter = ORIGIN + Vector3.new(92, 0, 395)
    makeLabel(parent, sentinelCenter + Vector3.new(0, 22, 0), "BELFORGE SENTINEL POST")
    for index = -2, 2 do
        local barricade = makePart(
            parent,
            "SentinelBarricade" .. tostring(index + 3),
            Vector3.new(7.0, 2.3, 2.0),
            CFrame.new(sentinelCenter + Vector3.new(index * 8, 1.15, -18))
                * CFrame.Angles(0, math.rad(index * 4), 0),
            Enum.Material.DiamondPlate,
            Color3.fromRGB(72, 68, 63)
        )
        barricade.CanCollide = false
        makeCollisionProxy(
            parent,
            "SentinelBarricadeCollision",
            barricade.Size + Vector3.new(0.2, 0.2, 0.2),
            barricade.CFrame
        )
    end

    makeMonsterSpawnTrigger(parent, "BelforgeForgeSpecters", fluxVaultCenter, {
        MonsterType = "ForgeSpecter",
        SpawnAmount = 4,
        TriggerRadius = 31,
        SpawnRadius = 14,
        MaxAliveMonster = 4,
        SpawnDelay = 0.23,
        RespawnTime = 29,
    })
    makeMonsterSpawnTrigger(parent, "BelforgeIroncladEnforcers", enforcementCenter, {
        MonsterType = "IroncladEnforcer",
        SpawnAmount = 4,
        TriggerRadius = 32,
        SpawnRadius = 15,
        MaxAliveMonster = 4,
        SpawnDelay = 0.27,
        RespawnTime = 31,
    })
    makeMonsterSpawnTrigger(parent, "BelforgeMoltenDrakes", runoffCenter, {
        MonsterType = "MoltenDrake",
        SpawnAmount = 4,
        TriggerRadius = 32,
        SpawnRadius = 15,
        MaxAliveMonster = 4,
        SpawnDelay = 0.3,
        RespawnTime = 32,
    })
    makeMonsterSpawnTrigger(parent, "BelforgeBellowsTitan", bellowsCenter, {
        MonsterType = "BellowsTitan",
        SpawnAmount = 1,
        TriggerRadius = 30,
        SpawnRadius = 7,
        MaxAliveMonster = 1,
        SpawnDelay = 0,
        RespawnTime = 135,
    })
    makeMonsterSpawnTrigger(parent, "BelforgeGateSentinel", sentinelCenter, {
        MonsterType = "BelforgeSentinel",
        SpawnAmount = 1,
        TriggerRadius = 30,
        SpawnRadius = 7,
        MaxAliveMonster = 1,
        SpawnDelay = 0,
        RespawnTime = 155,
    })
end

local function makeIndustrialDistrictCourt(parent, spec)
    local model = Instance.new("Model")
    model.Name = spec.Name .. "DistrictCourt"
    model:SetAttribute("MMOComposition", true)
    model.Parent = parent

    local center = ORIGIN + spec.Offset
    local yaw = spec.Yaw or 0
    local base = CFrame.new(center) * CFrame.Angles(0, yaw, 0)
    local width = spec.Width or 76
    local depth = spec.Depth or 52
    local stone = Color3.fromRGB(64, 60, 56)
    local iron = Color3.fromRGB(75, 72, 68)
    local brass = spec.Accent or Color3.fromRGB(151, 100, 48)

    local floor = makePart(
        model,
        spec.Name .. "CourtFloor",
        Vector3.new(width, 0.65, depth),
        base * CFrame.new(0, 0.35, 0),
        Enum.Material.Cobblestone,
        stone
    )
    floor.CanCollide = false

    local lane = makePart(
        model,
        spec.Name .. "ServiceLane",
        Vector3.new(14, 0.32, depth + 30),
        base * CFrame.new(0, 0.72, 0),
        Enum.Material.Metal,
        iron
    )
    lane.CanCollide = false

    for _, side in { -1, 1 } do
        local x = side * (width * 0.42)
        for _, z in { -depth * 0.34, depth * 0.34 } do
            local post = makePart(
                model,
                spec.Name .. "FramePost",
                Vector3.new(1.2, 11, 1.2),
                base * CFrame.new(x, 5.5, z),
                Enum.Material.Metal,
                iron
            )
            makeCollisionProxy(
                model,
                spec.Name .. "FramePostCollision",
                Vector3.new(1.45, 11, 1.45),
                post.CFrame
            )
        end
    end

    local overhead = makePart(
        model,
        spec.Name .. "OverheadGantry",
        Vector3.new(width * 0.84, 1.2, 3.0),
        base * CFrame.new(0, 10.5, -depth * 0.34),
        Enum.Material.DiamondPlate,
        brass
    )
    overhead.CanCollide = false
    makeCollisionProxy(
        model,
        spec.Name .. "OverheadGantryCollision",
        Vector3.new(width * 0.84, 1.35, 3.2),
        overhead.CFrame
    )

    local canopy = makePart(
        model,
        spec.Name .. "LoadingCanopy",
        Vector3.new(width * 0.42, 0.7, 12),
        base * CFrame.new(-width * 0.24, 7.2, depth * 0.31),
        Enum.Material.Metal,
        Color3.fromRGB(88, 75, 62)
    )
    canopy.CanCollide = false
    for _, xoff in { -width * 0.38, -width * 0.10 } do
        local post = makePart(
            model,
            spec.Name .. "CanopyPost",
            Vector3.new(0.8, 7, 0.8),
            base * CFrame.new(xoff, 3.5, depth * 0.31),
            Enum.Material.Metal,
            iron
        )
        makeCollisionProxy(
            model,
            spec.Name .. "CanopyPostCollision",
            Vector3.new(1.0, 7, 1.0),
            post.CFrame
        )
    end

    for _, xoff in { -width * 0.35, width * 0.35 } do
        local lamp = makePart(
            model,
            spec.Name .. "FurnaceLamp",
            Vector3.new(1.0, 6.5, 1.0),
            base * CFrame.new(xoff, 3.25, -depth * 0.08),
            Enum.Material.Metal,
            iron
        )
        makeCollisionProxy(
            model,
            spec.Name .. "LampCollision",
            Vector3.new(1.2, 6.5, 1.2),
            lamp.CFrame
        )
        local glow = makePart(
            model,
            spec.Name .. "FurnaceLampGlow",
            Vector3.new(1.8, 1.8, 1.8),
            base * CFrame.new(xoff, 6.7, -depth * 0.08),
            Enum.Material.Neon,
            brass
        )
        glow.Shape = Enum.PartType.Ball
        glow.CanCollide = false
        glow.CanTouch = false
        local light = Instance.new("PointLight")
        light.Color = brass
        light.Brightness = 1.2
        light.Range = 18
        light.Parent = glow
    end

    makeScrapPile(
        model,
        center + base.RightVector * (width * 0.31) + base.LookVector * (depth * 0.27),
        yaw + math.rad(20),
        0.72
    )
    if spec.Hot then
        makeHotVent(
            model,
            center - base.RightVector * (width * 0.28) + base.LookVector * (depth * 0.05),
            0.75
        )
    end

    makeLabel(model, center + Vector3.new(0, 17, 0), spec.Label)
    return model
end

local function makeBrasshavenMMOComposition(parent)
    local districts = {
        {
            Name = "Threshold",
            Label = "FOUNDRY THRESHOLD · TRADE COURT",
            Offset = Vector3.new(-58, 0, 12),
            Yaw = math.rad(90),
            Width = 90,
            Depth = 58,
            Accent = Color3.fromRGB(171, 118, 58),
        },
        {
            Name = "Gearworks",
            Label = "GEARWORKS · MACHINE COURT",
            Offset = Vector3.new(-78, 0, 76),
            Yaw = math.rad(10),
            Width = 84,
            Depth = 56,
            Accent = Color3.fromRGB(144, 99, 53),
        },
        {
            Name = "Cinder",
            Label = "CINDER DUCTS · MAINTENANCE COURT",
            Offset = Vector3.new(83, 0, -72),
            Yaw = math.rad(-12),
            Width = 82,
            Depth = 54,
            Accent = Color3.fromRGB(205, 103, 46),
            Hot = true,
        },
        {
            Name = "Sootworks",
            Label = "SOOTWORKS · SHIFT YARD",
            Offset = Vector3.new(-58, 0, 145),
            Yaw = math.rad(8),
            Width = 88,
            Depth = 58,
            Accent = Color3.fromRGB(139, 91, 48),
            Hot = true,
        },
        {
            Name = "Dynamo",
            Label = "DYNAMO GALLERY · POWER COURT",
            Offset = Vector3.new(64, 0, -148),
            Yaw = math.rad(-8),
            Width = 84,
            Depth = 56,
            Accent = Color3.fromRGB(90, 174, 220),
        },
        {
            Name = "Rail",
            Label = "EASTWORKS RAIL YARD · LOADING COURT",
            Offset = Vector3.new(108, 0, 145),
            Yaw = math.rad(90),
            Width = 92,
            Depth = 62,
            Accent = Color3.fromRGB(164, 109, 52),
        },
        {
            Name = "Blueglass",
            Label = "BLUEGLASS ANNEX · RESEARCH COURT",
            Offset = Vector3.new(-72, 0, 235),
            Yaw = math.rad(6),
            Width = 82,
            Depth = 56,
            Accent = Color3.fromRGB(86, 177, 219),
        },
        {
            Name = "Smelter",
            Label = "SMELTER CRUCIBLE · WORKS COURT",
            Offset = Vector3.new(108, 0, 235),
            Yaw = math.rad(-6),
            Width = 86,
            Depth = 60,
            Accent = Color3.fromRGB(225, 105, 42),
            Hot = true,
        },
        {
            Name = "Authority",
            Label = "AUTHORITY HALL · SECURITY COURT",
            Offset = Vector3.new(-12, 0, 325),
            Yaw = 0,
            Width = 88,
            Depth = 60,
            Accent = Color3.fromRGB(170, 115, 55),
        },
        {
            Name = "Runoff",
            Label = "MOLTEN RUNOFF · CONTROL COURT",
            Offset = Vector3.new(88, 0, 325),
            Yaw = 0,
            Width = 84,
            Depth = 58,
            Accent = Color3.fromRGB(232, 91, 35),
            Hot = true,
        },
        {
            Name = "Bellows",
            Label = "UPPER BELLOWS · FORGE COURT",
            Offset = Vector3.new(-58, 0, 395),
            Yaw = 0,
            Width = 90,
            Depth = 60,
            Accent = Color3.fromRGB(192, 105, 45),
            Hot = true,
        },
        {
            Name = "Sentinel",
            Label = "BELFORGE SENTINEL · MUSTER COURT",
            Offset = Vector3.new(92, 0, 395),
            Yaw = 0,
            Width = 92,
            Depth = 62,
            Accent = Color3.fromRGB(190, 119, 53),
        },
    }
    for _, spec in districts do
        makeIndustrialDistrictCourt(parent, spec)
    end
end

function BrasshavenWorldService.Init()
    local previous = Workspace:FindFirstChild(GENERATED_NAME)
    if previous then
        previous:Destroy()
    end

    local world = Instance.new("Model")
    world.Name = GENERATED_NAME
    world:SetAttribute("WorldDesignVersion", 2)
    world:SetAttribute("MMOCompositionPass", true)
    world.Parent = Workspace

    local ground = makePart(
        world,
        "BrasshavenThresholdGround",
        Vector3.new(360, 8, 900),
        CFrame.new(ORIGIN + Vector3.new(0, -4, 0)),
        Enum.Material.Slate,
        Color3.fromRGB(71, 67, 61)
    )
    ground:SetAttribute("RegionId", "brasshaven")
    makeCollisionProxy(world, "BrasshavenGroundCollision", Vector3.new(360, 8, 900), ground.CFrame)

    local road = makePart(
        world,
        "FoundryRoad",
        Vector3.new(240, 0.8, 30),
        CFrame.new(ORIGIN + Vector3.new(12, 0.45, 0)),
        Enum.Material.Cobblestone,
        Color3.fromRGB(94, 82, 69)
    )
    road.CanCollide = false

    local serviceSpine = makePart(
        world,
        "FoundryServiceSpine",
        Vector3.new(30, 0.8, 820),
        CFrame.new(ORIGIN + Vector3.new(24, 0.45, 0)),
        Enum.Material.Cobblestone,
        Color3.fromRGB(88, 77, 67)
    )
    serviceSpine.CanCollide = false

    for index = -3, 3 do
        if index ~= 0 then
            local x = index * 40
            makePart(
                world,
                "RoadBrace" .. tostring(index),
                Vector3.new(2, 0.5, 30),
                CFrame.new(ORIGIN + Vector3.new(x, 0.86, 0)),
                Enum.Material.Metal,
                Color3.fromRGB(126, 88, 45)
            ).CanCollide =
                false
        end
    end

    makeForgeTower(world, ORIGIN + Vector3.new(62, 0, -70), 28, 1)
    makeForgeTower(world, ORIGIN + Vector3.new(104, 0, 72), 34, 2)
    makeForgeTower(world, ORIGIN + Vector3.new(-88, 0, -76), 24, 3)
    makeForgeTower(world, ORIGIN + Vector3.new(-112, 0, 338), 30, 4)
    makeForgeTower(world, ORIGIN + Vector3.new(112, 0, 350), 38, 5)

    dressEncounterAreas(world)
    makeBrasshavenMMOComposition(world)

    local wallColor = Color3.fromRGB(81, 73, 65)
    makePart(
        world,
        "NorthWall",
        Vector3.new(330, 18, 8),
        CFrame.new(ORIGIN + Vector3.new(0, 9, -442)),
        Enum.Material.Brick,
        wallColor
    )
    makePart(
        world,
        "SouthWall",
        Vector3.new(330, 18, 8),
        CFrame.new(ORIGIN + Vector3.new(0, 9, 442)),
        Enum.Material.Brick,
        wallColor
    )
    makePart(
        world,
        "EastWall",
        Vector3.new(8, 18, 884),
        CFrame.new(ORIGIN + Vector3.new(166, 9, 0)),
        Enum.Material.Brick,
        wallColor
    )
    makePart(
        world,
        "WestWall",
        Vector3.new(8, 18, 884),
        CFrame.new(ORIGIN + Vector3.new(-166, 9, 0)),
        Enum.Material.Brick,
        wallColor
    )
    makeCollisionProxy(
        world,
        "BrasshavenNorthWallCollision",
        Vector3.new(330, 18, 8),
        CFrame.new(ORIGIN + Vector3.new(0, 9, -442))
    )
    makeCollisionProxy(
        world,
        "BrasshavenSouthWallCollision",
        Vector3.new(330, 18, 8),
        CFrame.new(ORIGIN + Vector3.new(0, 9, 442))
    )
    makeCollisionProxy(
        world,
        "BrasshavenEastWallCollision",
        Vector3.new(8, 18, 884),
        CFrame.new(ORIGIN + Vector3.new(166, 9, 0))
    )
    makeCollisionProxy(
        world,
        "BrasshavenWestWallCollision",
        Vector3.new(8, 18, 884),
        CFrame.new(ORIGIN + Vector3.new(-166, 9, 0))
    )

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "BrasshavenSpawn"
    spawn.Size = Vector3.new(8, 1, 8)
    spawn.CFrame = CFrame.new(ORIGIN + Vector3.new(-118, 1, 0)) * CFrame.Angles(0, math.rad(-90), 0)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Material = Enum.Material.Metal
    spawn.Color = Color3.fromRGB(154, 111, 59)
    spawn.Transparency = 0.2
    spawn.CanCollide = false
    spawn.CanTouch = false
    spawn.CanQuery = false
    spawn.Parent = world
    WorldTravelService.RegisterSpawn("brasshaven_start", spawn)

    makeReturnGate(world, ORIGIN + Vector3.new(-142, 0, 0))
    makeBelforgeGate(world, ORIGIN + Vector3.new(158, 0, 395))
    makeForeman(world, ORIGIN + Vector3.new(126, 0, 24))
    makeEastworksEngineer(world, ORIGIN + Vector3.new(92, 0, 112))
    makeBelforgeMarshal(world, ORIGIN + Vector3.new(0, 0, 276))
    makeBelforgeAntechamber(world)
    makeBelforgeArena(world)
    makeFoundryVendor(
        world,
        "foundry_quartermaster",
        "Nera · Foundry Quartermaster",
        ORIGIN + Vector3.new(-78, 0, 30),
        {
            Cloth = Color3.fromRGB(74, 67, 58),
            Accent = Color3.fromRGB(157, 109, 55),
            Skin = Color3.fromRGB(191, 151, 118),
            Text = Color3.fromRGB(239, 207, 151),
        }
    )
    makeFoundryVendor(
        world,
        "belforge_mark_broker",
        "Cale · Mark Broker",
        ORIGIN + Vector3.new(-48, 0, 30),
        {
            Cloth = Color3.fromRGB(58, 63, 69),
            Accent = Color3.fromRGB(105, 131, 139),
            Skin = Color3.fromRGB(210, 171, 134),
            Text = Color3.fromRGB(185, 224, 229),
        }
    )
    makeLabel(world, ORIGIN + Vector3.new(-58, 22, 0), "BRASSHAVEN · FOUNDRY THRESHOLD")
    makeLabel(world, ORIGIN + Vector3.new(112, 25, 395), "BELFORGE EASTWORKS · LEVEL 30 GATE")

    normalizeGeneratedCollisions(world)
    return world
end

return BrasshavenWorldService
