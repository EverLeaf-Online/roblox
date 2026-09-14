local Workspace = game:GetService("Workspace")

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
    makeLabel(world, ORIGIN + Vector3.new(-58, 22, 0), "BRASSHAVEN · FOUNDRY THRESHOLD")
    makeLabel(world, ORIGIN + Vector3.new(92, 18, -22), "BELFORGE ROAD · UNDER CONSTRUCTION")

    return world
end

return BrasshavenWorldService
