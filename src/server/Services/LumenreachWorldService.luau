local Workspace = game:GetService("Workspace")

local EnemySpawnerService = require(script.Parent.EnemySpawnerService)
local InteractionService = require(script.Parent.InteractionService)
local WorldObjectService = require(script.Parent.WorldObjectService)

local LumenreachWorldService = {}

local GENERATED_NAME = "EverLeafGeneratedWorld"

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

local function makeBall(parent, name, size, cframe, material, color)
    local part = makePart(parent, name, size, cframe, material, color)
    part.Shape = Enum.PartType.Ball
    return part
end

local function makeTree(parent, position, scale)
    local model = Instance.new("Model")
    model.Name = "LumenTree"
    model.Parent = parent

    local trunk = makePart(
        model,
        "Trunk",
        Vector3.new(2.2, 10, 2.2) * scale,
        CFrame.new(position + Vector3.new(0, 5 * scale, 0)),
        Enum.Material.Wood,
        Color3.fromRGB(78, 55, 39)
    )
    makeBall(
        model,
        "CrownLower",
        Vector3.new(9, 7, 9) * scale,
        CFrame.new(position + Vector3.new(0, 10 * scale, 0)),
        Enum.Material.Grass,
        Color3.fromRGB(65, 112, 62)
    )
    makeBall(
        model,
        "CrownUpper",
        Vector3.new(7, 6, 7) * scale,
        CFrame.new(position + Vector3.new(1.3 * scale, 14 * scale, 0)),
        Enum.Material.Grass,
        Color3.fromRGB(83, 137, 72)
    )
    model.PrimaryPart = trunk
    return model
end

local function makeRock(parent, position, size, rotation)
    local rock = makePart(
        parent,
        "Rock",
        size,
        CFrame.new(position) * CFrame.Angles(rotation.X, rotation.Y, rotation.Z),
        Enum.Material.Slate,
        Color3.fromRGB(83, 91, 92)
    )
    rock.Shape = Enum.PartType.Block
    return rock
end

local function makeCrystal(parent, position)
    local crystal = makePart(
        parent,
        "LumenCrystal",
        Vector3.new(2.6, 7, 2.6),
        CFrame.new(position) * CFrame.Angles(0, 0, math.rad(45)),
        Enum.Material.Neon,
        Color3.fromRGB(113, 219, 207)
    )
    crystal.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color = crystal.Color
    light.Brightness = 2
    light.Range = 18
    light.Parent = crystal
    return crystal
end

local function makeRuins(parent)
    local stone = Color3.fromRGB(116, 123, 117)
    makePart(
        parent,
        "RuinPillar",
        Vector3.new(4, 14, 4),
        CFrame.new(29, 7, -31),
        Enum.Material.Cobblestone,
        stone
    )
    makePart(
        parent,
        "RuinPillar",
        Vector3.new(4, 11, 4),
        CFrame.new(43, 5.5, -31),
        Enum.Material.Cobblestone,
        stone
    )
    makePart(
        parent,
        "RuinLintel",
        Vector3.new(18, 3, 4),
        CFrame.new(36, 13, -31),
        Enum.Material.Cobblestone,
        stone
    )
    makePart(
        parent,
        "RuinWall",
        Vector3.new(3, 7, 18),
        CFrame.new(50, 3.5, -22),
        Enum.Material.Rock,
        Color3.fromRGB(89, 96, 91)
    )
    makeCrystal(parent, Vector3.new(36, 3.2, -25))

    local gate = makePart(
        parent,
        "BrasshavenGate",
        Vector3.new(10, 9, 0.8),
        CFrame.new(36, 5.2, -30.4),
        Enum.Material.ForceField,
        Color3.fromRGB(91, 195, 181)
    )
    gate.Transparency = 0.38
    gate.CanCollide = false
    WorldObjectService.Register(gate, "Portal", "lumenreach_to_brasshaven")

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "SealedGatePrompt"
    prompt.ActionText = "Sealed"
    prompt.ObjectText = "Brasshaven Gate · Level 20"
    prompt.MaxActivationDistance = 9
    prompt.RequiresLineOfSight = false
    prompt.Enabled = false
    prompt.Parent = gate
end

local function makeGuide(parent, position)
    local model = Instance.new("Model")
    model.Name = "LumenGuide"
    model.Parent = parent

    local root = makePart(
        model,
        "HumanoidRootPart",
        Vector3.new(2, 5, 2),
        CFrame.new(position + Vector3.new(0, 2.5, 0)),
        Enum.Material.SmoothPlastic,
        Color3.fromRGB(48, 72, 68)
    )
    root.Transparency = 1
    root.CanCollide = false

    local body = makePart(
        model,
        "Body",
        Vector3.new(3, 4.5, 2),
        CFrame.new(position + Vector3.new(0, 2.4, 0)),
        Enum.Material.Fabric,
        Color3.fromRGB(72, 111, 104)
    )
    local head = makeBall(
        model,
        "Head",
        Vector3.new(2.2, 2.2, 2.2),
        CFrame.new(position + Vector3.new(0, 5.4, 0)),
        Enum.Material.SmoothPlastic,
        Color3.fromRGB(218, 190, 163)
    )
    body.CanCollide = false
    head.CanCollide = false

    model.PrimaryPart = root
    WorldObjectService.Register(model, "Npc", "lumen_guide")

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "TalkPrompt"
    prompt.ActionText = "Talk"
    prompt.ObjectText = "Lumen Guide"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = root
    prompt.Triggered:Connect(function(player)
        InteractionService.Begin(player, "lumen_guide", model)
    end)

    return model
end

local function makeLandmarkLabel(parent, position, text)
    local anchor = makePart(
        parent,
        text .. "Anchor",
        Vector3.new(1, 1, 1),
        CFrame.new(position),
        Enum.Material.SmoothPlastic,
        Color3.new(1, 1, 1)
    )
    anchor.Transparency = 1
    anchor.CanCollide = false

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "LandmarkLabel"
    billboard.Size = UDim2.fromOffset(240, 42)
    billboard.AlwaysOnTop = false
    billboard.MaxDistance = 90
    billboard.Parent = anchor

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(226, 244, 230)
    label.TextStrokeTransparency = 0.45
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = billboard
end

local function prepareGround(world)
    for _, child in Workspace:GetChildren() do
        if child:IsA("SpawnLocation") then
            child:Destroy()
        end
    end

    local oldBaseplate = Workspace:FindFirstChild("Baseplate")
    if oldBaseplate and oldBaseplate:IsA("BasePart") then
        oldBaseplate.Transparency = 1
        oldBaseplate.CanCollide = false
    end

    makePart(
        world,
        "LumenreachGround",
        Vector3.new(240, 4, 220),
        CFrame.new(0, -2, 0),
        Enum.Material.Grass,
        Color3.fromRGB(72, 106, 62)
    )
    makePart(
        world,
        "SpawnRise",
        Vector3.new(62, 3, 52),
        CFrame.new(-61, 1.5, 38) * CFrame.Angles(0, math.rad(-8), 0),
        Enum.Material.Ground,
        Color3.fromRGB(96, 104, 69)
    )
    makePart(
        world,
        "CombatGrove",
        Vector3.new(70, 2, 62),
        CFrame.new(49, 1, 27),
        Enum.Material.Ground,
        Color3.fromRGB(82, 96, 64)
    )

    local pathColor = Color3.fromRGB(131, 116, 86)
    makePart(
        world,
        "Path",
        Vector3.new(12, 0.6, 58),
        CFrame.new(-32, 0.3, 24) * CFrame.Angles(0, math.rad(-58), 0),
        Enum.Material.Ground,
        pathColor
    )
    makePart(
        world,
        "Path",
        Vector3.new(12, 0.6, 70),
        CFrame.new(8, 0.3, 3) * CFrame.Angles(0, math.rad(-92), 0),
        Enum.Material.Ground,
        pathColor
    )
    makePart(
        world,
        "Path",
        Vector3.new(10, 0.6, 46),
        CFrame.new(29, 0.3, -17) * CFrame.Angles(0, math.rad(-32), 0),
        Enum.Material.Ground,
        pathColor
    )

    local pond = makePart(
        world,
        "LumenPond",
        Vector3.new(44, 0.8, 31),
        CFrame.new(-18, 0.15, -43),
        Enum.Material.Glass,
        Color3.fromRGB(59, 153, 159)
    )
    pond.Transparency = 0.25
    pond.CanCollide = false
    pond.Reflectance = 0.08
end

local function decorate(world)
    local trees = {
        { Vector3.new(-94, 0, 53), 1.15 },
        { Vector3.new(-84, 0, 8), 0.9 },
        { Vector3.new(-53, 0, -43), 1.1 },
        { Vector3.new(-2, 0, -70), 1.25 },
        { Vector3.new(24, 0, -67), 0.95 },
        { Vector3.new(70, 0, -50), 1.15 },
        { Vector3.new(91, 0, -8), 1.0 },
        { Vector3.new(91, 0, 52), 1.2 },
        { Vector3.new(58, 0, 70), 0.95 },
        { Vector3.new(11, 0, 80), 1.15 },
        { Vector3.new(-40, 0, 83), 0.9 },
    }
    for _, entry in trees do
        makeTree(world, entry[1], entry[2])
    end

    local rocks = {
        { Vector3.new(-55, 2, -20), Vector3.new(7, 4, 5), Vector3.new(0.1, 0.7, 0.15) },
        { Vector3.new(-28, 1.5, -60), Vector3.new(5, 3, 6), Vector3.new(0.2, 0.2, 0.1) },
        { Vector3.new(14, 2, -52), Vector3.new(8, 4, 4), Vector3.new(0.05, 1.0, 0.2) },
        { Vector3.new(70, 2.5, 12), Vector3.new(7, 5, 6), Vector3.new(0.2, 0.4, 0.25) },
        { Vector3.new(54, 1.4, 57), Vector3.new(6, 3, 7), Vector3.new(0.2, 0.8, 0.05) },
    }
    for _, entry in rocks do
        makeRock(world, entry[1], entry[2], entry[3])
    end

    for _, position in
        {
            Vector3.new(-46, 3, -33),
            Vector3.new(-6, 3, -58),
            Vector3.new(55, 3, -14),
            Vector3.new(82, 3, 37),
        }
    do
        makeCrystal(world, position)
    end

    makeRuins(world)
end

local function makeSpawn(world)
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "LumenreachSpawn"
    spawn.Size = Vector3.new(8, 1, 8)
    spawn.CFrame = CFrame.new(-68, 4, 42)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Material = Enum.Material.Slate
    spawn.Color = Color3.fromRGB(77, 96, 87)
    spawn.Transparency = 0.15
    spawn.Parent = world
    return spawn
end

function LumenreachWorldService.Init()
    local previous = Workspace:FindFirstChild(GENERATED_NAME)
    if previous then
        previous:Destroy()
    end

    local world = Instance.new("Model")
    world.Name = GENERATED_NAME
    world.Parent = Workspace

    prepareGround(world)
    decorate(world)
    makeSpawn(world)
    makeGuide(world, Vector3.new(-48, 2, 35))

    makeLandmarkLabel(world, Vector3.new(-49, 11, 35), "LUMENREACH WAYFARER CAMP")
    makeLandmarkLabel(world, Vector3.new(48, 9, 28), "MOSSGLEN COMBAT GROVE")
    makeLandmarkLabel(world, Vector3.new(37, 18, -31), "SHATTERED LUMEN ARCH")

    EnemySpawnerService.Spawn("training_dummy", Vector3.new(-29, 4, 33), world)
    EnemySpawnerService.Spawn("lumen_mossling", Vector3.new(38, 3, 23), world)
    EnemySpawnerService.Spawn("lumen_mossling", Vector3.new(54, 3, 35), world)
    EnemySpawnerService.Spawn("lumen_mossling", Vector3.new(59, 3, 16), world)
end

return LumenreachWorldService
