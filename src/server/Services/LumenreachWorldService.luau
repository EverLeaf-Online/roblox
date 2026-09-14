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

local function makeGrassTuft(parent, position, scale)
    local model = Instance.new("Model")
    model.Name = "GrassTuft"
    model.Parent = parent

    local color = Color3.fromRGB(74, 126, 68)
    for index = 1, 3 do
        local blade = makePart(
            model,
            "Blade" .. index,
            Vector3.new(0.22, 2.6, 1.2) * scale,
            CFrame.new(position + Vector3.new((index - 2) * 0.35 * scale, 1.2 * scale, 0))
                * CFrame.Angles(
                    math.rad(index * 6 - 12),
                    math.rad(index * 53),
                    math.rad(index * 7 - 14)
                ),
            Enum.Material.Grass,
            color
        )
        blade.CanCollide = false
        blade.CastShadow = false
    end
    return model
end

local function makeBush(parent, position, scale)
    local model = Instance.new("Model")
    model.Name = "LumenBush"
    model.Parent = parent
    local colors = {
        Color3.fromRGB(61, 111, 63),
        Color3.fromRGB(72, 126, 69),
        Color3.fromRGB(82, 137, 75),
    }
    for index = 1, 5 do
        local angle = index * math.pi * 0.4
        local offset =
            Vector3.new(math.cos(angle) * 1.25 * scale, 1.2 * scale, math.sin(angle) * 1.25 * scale)
        local leaf = makeBall(
            model,
            "Leaf" .. index,
            Vector3.new(3.2, 2.8, 3.2) * scale,
            CFrame.new(position + offset),
            Enum.Material.Grass,
            colors[((index - 1) % #colors) + 1]
        )
        leaf.CanCollide = false
    end
    return model
end

local function makeCampfire(parent, position)
    local model = Instance.new("Model")
    model.Name = "WayfarerCampfire"
    model.Parent = parent

    for index = 1, 8 do
        local angle = index * math.pi * 0.25
        makePart(
            model,
            "FireRingStone",
            Vector3.new(1.4, 0.8, 1.1),
            CFrame.new(position + Vector3.new(math.cos(angle) * 2.2, 0.45, math.sin(angle) * 2.2))
                * CFrame.Angles(0, -angle, 0),
            Enum.Material.Slate,
            Color3.fromRGB(79, 82, 77)
        )
    end

    for index = 1, 3 do
        makePart(
            model,
            "Log",
            Vector3.new(5, 0.65, 0.65),
            CFrame.new(position + Vector3.new(0, 0.75, 0))
                * CFrame.Angles(0, math.rad((index - 1) * 60), 0),
            Enum.Material.Wood,
            Color3.fromRGB(77, 48, 31)
        )
    end

    local ember = makePart(
        model,
        "Ember",
        Vector3.new(1.4, 1.2, 1.4),
        CFrame.new(position + Vector3.new(0, 1.2, 0)),
        Enum.Material.Neon,
        Color3.fromRGB(255, 139, 63)
    )
    ember.Shape = Enum.PartType.Ball
    ember.CanCollide = false

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 164, 92)
    light.Brightness = 2.4
    light.Range = 24
    light.Shadows = true
    light.Parent = ember

    local fire = Instance.new("Fire")
    fire.Color = Color3.fromRGB(255, 179, 83)
    fire.SecondaryColor = Color3.fromRGB(101, 205, 170)
    fire.Heat = 6
    fire.Size = 4.5
    fire.Parent = ember
    return model
end

local function makeWedge(parent, name, size, cframe, material, color)
    local wedge = Instance.new("WedgePart")
    wedge.Name = name
    wedge.Anchored = true
    wedge.Size = size
    wedge.CFrame = cframe
    wedge.Material = material
    wedge.Color = color
    wedge.TopSurface = Enum.SurfaceType.Smooth
    wedge.BottomSurface = Enum.SurfaceType.Smooth
    wedge.Parent = parent
    return wedge
end

local function makeTent(parent, position, yaw)
    local model = Instance.new("Model")
    model.Name = "WayfarerTent"
    model.Parent = parent

    local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
    local cloth = Color3.fromRGB(76, 104, 91)
    local trim = Color3.fromRGB(45, 65, 58)

    makeWedge(
        model,
        "TentLeft",
        Vector3.new(8, 5, 0.35),
        base * CFrame.new(-2, 2.4, 0) * CFrame.Angles(0, 0, math.rad(28)),
        Enum.Material.Fabric,
        cloth
    )
    makeWedge(
        model,
        "TentRight",
        Vector3.new(8, 5, 0.35),
        base * CFrame.new(2, 2.4, 0) * CFrame.Angles(0, math.pi, math.rad(28)),
        Enum.Material.Fabric,
        cloth
    )
    makePart(
        model,
        "RidgePole",
        Vector3.new(0.3, 0.3, 8.5),
        base * CFrame.new(0, 4.8, 0),
        Enum.Material.Wood,
        trim
    )
    makePart(
        model,
        "Bedroll",
        Vector3.new(3.2, 0.35, 5.4),
        base * CFrame.new(0, 0.35, 0.3),
        Enum.Material.Fabric,
        Color3.fromRGB(96, 78, 67)
    )
    return model
end

local function makeLantern(parent, position)
    local model = Instance.new("Model")
    model.Name = "LumenLantern"
    model.Parent = parent

    makePart(
        model,
        "Post",
        Vector3.new(0.45, 5, 0.45),
        CFrame.new(position + Vector3.new(0, 2.5, 0)),
        Enum.Material.Wood,
        Color3.fromRGB(68, 49, 36)
    )
    makePart(
        model,
        "Arm",
        Vector3.new(2.6, 0.35, 0.35),
        CFrame.new(position + Vector3.new(1, 4.7, 0)),
        Enum.Material.Wood,
        Color3.fromRGB(68, 49, 36)
    )
    local glow = makeBall(
        model,
        "Glow",
        Vector3.new(0.8, 0.8, 0.8),
        CFrame.new(position + Vector3.new(2.1, 4.15, 0)),
        Enum.Material.Neon,
        Color3.fromRGB(147, 239, 194)
    )
    glow.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color = glow.Color
    light.Brightness = 1.7
    light.Range = 16
    light.Shadows = true
    light.Parent = glow
    return model
end

local function makeBridge(parent, position)
    local model = Instance.new("Model")
    model.Name = "LumenFootbridge"
    model.Parent = parent
    local wood = Color3.fromRGB(101, 73, 49)
    for index = -5, 5 do
        makePart(
            model,
            "Plank",
            Vector3.new(4.8, 0.35, 1.15),
            CFrame.new(position + Vector3.new(0, 0.7 + math.cos(index * 0.3) * 0.22, index * 1.1)),
            Enum.Material.WoodPlanks,
            wood
        )
    end
    for _, side in { -1, 1 } do
        makePart(
            model,
            "Rail",
            Vector3.new(0.22, 0.22, 13),
            CFrame.new(position + Vector3.new(side * 2.45, 2.1, 0)),
            Enum.Material.Wood,
            wood
        )
        for index = -5, 5, 2 do
            makePart(
                model,
                "RailPost",
                Vector3.new(0.25, 2.4, 0.25),
                CFrame.new(position + Vector3.new(side * 2.45, 1.3, index * 1.1)),
                Enum.Material.Wood,
                wood
            )
        end
    end
    return model
end

local function makeWaterfall(parent, position)
    local model = Instance.new("Model")
    model.Name = "LumenFalls"
    model.Parent = parent

    local cliffColor = Color3.fromRGB(69, 78, 73)
    makePart(
        model,
        "CliffLeft",
        Vector3.new(14, 26, 18),
        CFrame.new(position + Vector3.new(-9, 13, 0)) * CFrame.Angles(0, math.rad(8), math.rad(-3)),
        Enum.Material.Rock,
        cliffColor
    )
    makePart(
        model,
        "CliffRight",
        Vector3.new(14, 22, 18),
        CFrame.new(position + Vector3.new(9, 11, 0)) * CFrame.Angles(0, math.rad(-10), math.rad(4)),
        Enum.Material.Rock,
        cliffColor
    )
    makePart(
        model,
        "CliffTop",
        Vector3.new(18, 7, 18),
        CFrame.new(position + Vector3.new(0, 20, 0)),
        Enum.Material.Rock,
        Color3.fromRGB(78, 89, 80)
    )

    local water = makePart(
        model,
        "Waterfall",
        Vector3.new(8, 20, 0.7),
        CFrame.new(position + Vector3.new(0, 10, 7.8)),
        Enum.Material.Glass,
        Color3.fromRGB(79, 188, 204)
    )
    water.Transparency = 0.28
    water.CanCollide = false
    water.Reflectance = 0.08

    local foam = makePart(
        model,
        "Foam",
        Vector3.new(11, 0.5, 6),
        CFrame.new(position + Vector3.new(0, 0.4, 6.8)),
        Enum.Material.Neon,
        Color3.fromRGB(198, 244, 236)
    )
    foam.Transparency = 0.45
    foam.CanCollide = false
    return model
end

local function makeFireflyCluster(parent, center)
    local model = Instance.new("Model")
    model.Name = "FireflyCluster"
    model.Parent = parent
    local offsets = {
        Vector3.new(-3, 2.5, 1),
        Vector3.new(2, 3.2, -2),
        Vector3.new(4, 1.8, 2),
        Vector3.new(-1, 4.1, -3),
        Vector3.new(1.5, 2.1, 3.5),
        Vector3.new(-4, 3.4, -1.5),
    }
    for index, offset in offsets do
        local glow = makeBall(
            model,
            "Firefly" .. index,
            Vector3.new(0.22, 0.22, 0.22),
            CFrame.new(center + offset),
            Enum.Material.Neon,
            Color3.fromRGB(170, 255, 177)
        )
        glow.CanCollide = false
        glow.CastShadow = false
        local light = Instance.new("PointLight")
        light.Color = glow.Color
        light.Brightness = 0.5
        light.Range = 5
        light.Parent = glow
    end
    return model
end

local function makeRockSpire(parent, position, scale)
    local model = Instance.new("Model")
    model.Name = "LumenRockSpire"
    model.Parent = parent
    local color = Color3.fromRGB(76, 87, 81)
    makeRock(
        model,
        position + Vector3.new(0, 5 * scale, 0),
        Vector3.new(10, 12, 10) * scale,
        Vector3.new(0.05, 0.4, 0.08)
    )
    makeRock(
        model,
        position + Vector3.new(1, 13 * scale, -1),
        Vector3.new(7, 10, 7) * scale,
        Vector3.new(0.1, -0.2, 0.12)
    )
    local crown = makeRock(
        model,
        position + Vector3.new(-1, 20 * scale, 0),
        Vector3.new(4, 8, 4) * scale,
        Vector3.new(-0.1, 0.2, -0.06)
    )
    crown.Color = color
    return model
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
    makePart(
        world,
        "NorthRise",
        Vector3.new(82, 7, 52),
        CFrame.new(28, 2.8, -72) * CFrame.Angles(math.rad(-4), math.rad(5), 0),
        Enum.Material.Grass,
        Color3.fromRGB(67, 96, 59)
    )
    makePart(
        world,
        "WestShelf",
        Vector3.new(56, 9, 70),
        CFrame.new(-92, 3.4, -25) * CFrame.Angles(math.rad(2), math.rad(-7), 0),
        Enum.Material.Rock,
        Color3.fromRGB(75, 84, 77)
    )
    makeWedge(
        world,
        "NorthApproachSlope",
        Vector3.new(28, 7, 26),
        CFrame.new(11, 1.2, -49) * CFrame.Angles(0, math.rad(5), 0),
        Enum.Material.Ground,
        Color3.fromRGB(91, 100, 69)
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

    local bushPositions = {
        Vector3.new(-80, 0, 58),
        Vector3.new(-72, 0, 24),
        Vector3.new(-58, 0, -18),
        Vector3.new(-23, 0, -34),
        Vector3.new(16, 0, -41),
        Vector3.new(30, 0, 52),
        Vector3.new(64, 0, 45),
        Vector3.new(76, 0, 5),
        Vector3.new(44, 0, -50),
    }
    for index, position in bushPositions do
        makeBush(world, position, 0.7 + (index % 3) * 0.12)
    end

    local grassPositions = {
        Vector3.new(-87, 0, 39),
        Vector3.new(-79, 0, 34),
        Vector3.new(-71, 0, 51),
        Vector3.new(-61, 0, 18),
        Vector3.new(-48, 0, 9),
        Vector3.new(-36, 0, 13),
        Vector3.new(-18, 0, -27),
        Vector3.new(-8, 0, -33),
        Vector3.new(5, 0, -18),
        Vector3.new(18, 0, 18),
        Vector3.new(27, 0, 29),
        Vector3.new(37, 0, 41),
        Vector3.new(48, 0, 48),
        Vector3.new(58, 0, 25),
        Vector3.new(66, 0, 18),
        Vector3.new(74, 0, 33),
        Vector3.new(81, 0, -17),
        Vector3.new(31, 0, -56),
    }
    for index, position in grassPositions do
        makeGrassTuft(world, position, 0.7 + (index % 4) * 0.1)
    end

    makeCampfire(world, Vector3.new(-59, 0, 31))
    makeTent(world, Vector3.new(-72, 0.2, 28), math.rad(18))
    makeTent(world, Vector3.new(-66, 0.2, 17), math.rad(-24))
    makeLantern(world, Vector3.new(-47, 0, 30))
    makeLantern(world, Vector3.new(-29, 0, 22))
    makeLantern(world, Vector3.new(-8, 0, 10))
    makeLantern(world, Vector3.new(17, 0, 4))
    makeBridge(world, Vector3.new(-17, 0.2, -44))
    makeWaterfall(world, Vector3.new(-92, 0, -66))
    makeRockSpire(world, Vector3.new(104, 0, -68), 1.25)
    makeRockSpire(world, Vector3.new(108, 0, 72), 0.95)
    makeFireflyCluster(world, Vector3.new(-44, 0, -26))
    makeFireflyCluster(world, Vector3.new(29, 0, -46))
    makeFireflyCluster(world, Vector3.new(67, 0, 50))
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
    makeLandmarkLabel(world, Vector3.new(-92, 30, -59), "VEILFALL CASCADE")

    EnemySpawnerService.Spawn("training_dummy", Vector3.new(-29, 4, 33), world)
    EnemySpawnerService.Spawn("lumen_mossling", Vector3.new(38, 3, 23), world)
    EnemySpawnerService.Spawn("lumen_mossling", Vector3.new(54, 3, 35), world)
    EnemySpawnerService.Spawn("lumen_mossling", Vector3.new(59, 3, 16), world)
end

return LumenreachWorldService
