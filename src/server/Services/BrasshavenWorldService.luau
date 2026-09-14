local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local InteractionService = require(script.Parent.InteractionService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local PortalService = require(script.Parent.PortalService)
local WorldObjectService = require(script.Parent.WorldObjectService)
local WorldTravelService = require(script.Parent.WorldTravelService)

local BrasshavenWorldService = {}

local GENERATED_NAME = "EverLeafGeneratedBrasshaven"
local ORIGIN = Vector3.new(1450, 0, 40)

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
    part.Parent = parent
    return part
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
        local ok = PortalService.Travel(player, profile, "brasshaven_to_lumenreach", gate)
        if ok then
            PlayerDataService.NotifyChanged(player)
        end
    end)
end

local function makeForeman(parent, position)
    local model = Instance.new("Model")
    model.Name = "belforge_foreman"
    model.Parent = parent
    local base = CFrame.new(position) * CFrame.Angles(0, math.rad(-90), 0)

    local function bodyPart(name, size, offset, material, color)
        local part = makePart(model, name, size, base * CFrame.new(offset), material, color)
        part.CanCollide = false
        part.CanTouch = false
        return part
    end

    local root = bodyPart(
        "HumanoidRootPart",
        Vector3.new(2, 6.5, 1.8),
        Vector3.new(0, 3.25, 0),
        Enum.Material.SmoothPlastic,
        Color3.new(0, 0, 0)
    )
    root.Transparency = 1
    bodyPart(
        "Torso",
        Vector3.new(2.5, 2.6, 1.5),
        Vector3.new(0, 3.85, 0),
        Enum.Material.Fabric,
        Color3.fromRGB(82, 69, 57)
    )
    bodyPart(
        "Apron",
        Vector3.new(2.15, 2.3, 0.15),
        Vector3.new(0, 3.55, -0.83),
        Enum.Material.Fabric,
        Color3.fromRGB(131, 89, 48)
    )
    for _, side in { -1, 1 } do
        bodyPart(
            side < 0 and "LeftLeg" or "RightLeg",
            Vector3.new(0.8, 2.4, 0.85),
            Vector3.new(side * 0.58, 1.42, 0),
            Enum.Material.Fabric,
            Color3.fromRGB(54, 53, 51)
        )
        bodyPart(
            side < 0 and "LeftArm" or "RightArm",
            Vector3.new(0.72, 2.2, 0.78),
            Vector3.new(side * 1.55, 3.8, 0),
            Enum.Material.Fabric,
            Color3.fromRGB(76, 63, 53)
        )
    end
    local head = bodyPart(
        "Head",
        Vector3.new(1.7, 1.7, 1.6),
        Vector3.new(0, 5.75, 0),
        Enum.Material.SmoothPlastic,
        Color3.fromRGB(204, 165, 128)
    )
    bodyPart(
        "HardCap",
        Vector3.new(1.95, 0.42, 1.8),
        Vector3.new(0, 6.52, 0),
        Enum.Material.Metal,
        Color3.fromRGB(137, 96, 48)
    )

    local plate = Instance.new("BillboardGui")
    plate.Size = UDim2.fromOffset(225, 34)
    plate.StudsOffsetWorldSpace = Vector3.new(0, 1.75, 0)
    plate.MaxDistance = 50
    plate.Parent = head
    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundColor3 = Color3.fromRGB(29, 25, 21)
    text.BackgroundTransparency = 0.16
    text.Text = "VALE · BELFORGE FOREMAN"
    text.TextColor3 = Color3.fromRGB(237, 209, 154)
    text.TextStrokeTransparency = 0.35
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.Parent = plate
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = text
    local edge = Instance.new("UIStroke")
    edge.Color = Color3.fromRGB(141, 98, 52)
    edge.Transparency = 0.3
    edge.Parent = text

    model.PrimaryPart = root
    WorldObjectService.Register(model, "Npc", "belforge_foreman")
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Talk"
    prompt.ObjectText = "Vale · Belforge Foreman"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
    prompt.Parent = root
    prompt.Triggered:Connect(function(player)
        InteractionService.Begin(player, "belforge_foreman", model)
    end)
end

local function makeFoundryVendor(parent, npcId, displayName, position, palette)
    local model = Instance.new("Model")
    model.Name = npcId
    model.Parent = parent
    local base = CFrame.new(position) * CFrame.Angles(0, math.rad(180), 0)

    local function bodyPart(name, size, offset, material, color)
        local part = makePart(model, name, size, base * CFrame.new(offset), material, color)
        part.CanCollide = false
        part.CanTouch = false
        return part
    end

    local root = bodyPart(
        "HumanoidRootPart",
        Vector3.new(2, 6.4, 1.8),
        Vector3.new(0, 3.2, 0),
        Enum.Material.SmoothPlastic,
        Color3.new(0, 0, 0)
    )
    root.Transparency = 1
    bodyPart(
        "Torso",
        Vector3.new(2.5, 2.55, 1.5),
        Vector3.new(0, 3.8, 0),
        Enum.Material.Fabric,
        palette.Cloth
    )
    bodyPart(
        "Apron",
        Vector3.new(2.1, 2.2, 0.14),
        Vector3.new(0, 3.5, -0.82),
        Enum.Material.Fabric,
        palette.Accent
    )
    for _, side in { -1, 1 } do
        bodyPart(
            side < 0 and "LeftLeg" or "RightLeg",
            Vector3.new(0.8, 2.4, 0.85),
            Vector3.new(side * 0.58, 1.4, 0),
            Enum.Material.Fabric,
            Color3.fromRGB(54, 53, 51)
        )
        bodyPart(
            side < 0 and "LeftArm" or "RightArm",
            Vector3.new(0.72, 2.15, 0.78),
            Vector3.new(side * 1.55, 3.75, 0),
            Enum.Material.Fabric,
            palette.Cloth
        )
    end
    local head = bodyPart(
        "Head",
        Vector3.new(1.7, 1.7, 1.6),
        Vector3.new(0, 5.7, 0),
        Enum.Material.SmoothPlastic,
        palette.Skin
    )
    bodyPart(
        "WorkCap",
        Vector3.new(1.95, 0.38, 1.82),
        Vector3.new(0, 6.46, 0),
        Enum.Material.Metal,
        palette.Accent
    )

    local plate = Instance.new("BillboardGui")
    plate.Size = UDim2.fromOffset(240, 34)
    plate.StudsOffsetWorldSpace = Vector3.new(0, 1.72, 0)
    plate.MaxDistance = 50
    plate.Parent = head
    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundColor3 = Color3.fromRGB(29, 25, 21)
    text.BackgroundTransparency = 0.16
    text.Text = string.upper(displayName)
    text.TextColor3 = palette.Text
    text.TextStrokeTransparency = 0.35
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.Parent = plate
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = text
    local edge = Instance.new("UIStroke")
    edge.Color = palette.Accent
    edge.Transparency = 0.3
    edge.Parent = text

    local counter = makePart(
        model,
        "Counter",
        Vector3.new(7, 2.6, 2.6),
        base * CFrame.new(0, 1.3, -3.6),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(79, 60, 44)
    )
    counter.CanCollide = true
    makePart(
        model,
        "CounterTrim",
        Vector3.new(7.2, 0.28, 2.8),
        base * CFrame.new(0, 2.72, -3.6),
        Enum.Material.Metal,
        palette.Accent
    ).CanCollide =
        false

    model.PrimaryPart = root
    WorldObjectService.Register(model, "Npc", npcId)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Trade"
    prompt.ObjectText = displayName
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
    prompt.Parent = root
    prompt.Triggered:Connect(function(player)
        InteractionService.Begin(player, npcId, model)
    end)
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
    door.CanCollide = true
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
end

function BrasshavenWorldService.Init()
    local previous = Workspace:FindFirstChild(GENERATED_NAME)
    if previous then
        previous:Destroy()
    end

    local world = Instance.new("Model")
    world.Name = GENERATED_NAME
    world.Parent = Workspace

    local ground = makePart(
        world,
        "BrasshavenThresholdGround",
        Vector3.new(360, 8, 260),
        CFrame.new(ORIGIN + Vector3.new(0, -4, 0)),
        Enum.Material.Slate,
        Color3.fromRGB(71, 67, 61)
    )
    ground:SetAttribute("RegionId", "brasshaven")

    local road = makePart(
        world,
        "FoundryRoad",
        Vector3.new(240, 0.8, 30),
        CFrame.new(ORIGIN + Vector3.new(12, 0.45, 0)),
        Enum.Material.Cobblestone,
        Color3.fromRGB(94, 82, 69)
    )
    road.CanCollide = false

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

    dressEncounterAreas(world)

    local wallColor = Color3.fromRGB(81, 73, 65)
    makePart(
        world,
        "NorthWall",
        Vector3.new(330, 18, 8),
        CFrame.new(ORIGIN + Vector3.new(0, 9, -122)),
        Enum.Material.Brick,
        wallColor
    )
    makePart(
        world,
        "SouthWall",
        Vector3.new(330, 18, 8),
        CFrame.new(ORIGIN + Vector3.new(0, 9, 122)),
        Enum.Material.Brick,
        wallColor
    )
    makePart(
        world,
        "EastWall",
        Vector3.new(8, 18, 244),
        CFrame.new(ORIGIN + Vector3.new(166, 9, 0)),
        Enum.Material.Brick,
        wallColor
    )
    makePart(
        world,
        "WestWall",
        Vector3.new(8, 18, 244),
        CFrame.new(ORIGIN + Vector3.new(-166, 9, 0)),
        Enum.Material.Brick,
        wallColor
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
    spawn.Parent = world
    WorldTravelService.RegisterSpawn("brasshaven_start", spawn)

    makeReturnGate(world, ORIGIN + Vector3.new(-142, 0, 0))
    makeBelforgeGate(world, ORIGIN + Vector3.new(158, 0, 0))
    makeForeman(world, ORIGIN + Vector3.new(126, 0, 24))
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
    makeLabel(world, ORIGIN + Vector3.new(104, 25, 0), "BELFORGE EASTWORKS · SEALED")

    return world
end

return BrasshavenWorldService
