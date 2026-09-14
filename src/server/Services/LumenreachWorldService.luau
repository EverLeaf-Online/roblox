local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local EnemySpawnerService = require(script.Parent.EnemySpawnerService)
local EnvironmentPrefabService = require(script.Parent.EnvironmentPrefabService)
local InteractionService = require(script.Parent.InteractionService)
local PBRMaterialService = require(script.Parent.PBRMaterialService)
local WorldObjectService = require(script.Parent.WorldObjectService)

local LumenreachWorldService = {}

local GENERATED_NAME = "EverLeafGeneratedWorld"
local WORLD_WIDTH = 620
local WORLD_DEPTH = 560
local TREE_PREFAB_SCALE = 0.22
local FOREST_PROP_SCALE = 0.35

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

local function makeTree(parent, position, scale, variant)
    variant = variant or 1
    local prefabYaw = math.rad((variant * 47) % 360)
    local prefab = EnvironmentPrefabService.Place(
        "TreePrimary",
        parent,
        CFrame.new(position) * CFrame.Angles(0, prefabYaw, 0),
        scale * TREE_PREFAB_SCALE
    )
    if prefab then
        return prefab
    end

    local model = Instance.new("Model")
    model.Name = "LumenTree"
    model.Parent = parent

    variant = variant or 1
    local trunkColor = if variant == 2
        then Color3.fromRGB(72, 49, 34)
        else if variant == 3 then Color3.fromRGB(88, 61, 40) else Color3.fromRGB(78, 55, 39)
    local leafPalette = {
        Color3.fromRGB(49, 92, 54),
        Color3.fromRGB(60, 111, 61),
        Color3.fromRGB(72, 126, 66),
        Color3.fromRGB(84, 139, 72),
    }

    local trunkLower = makePart(
        model,
        "TrunkLower",
        Vector3.new(2.8, 6.5, 2.8) * scale,
        CFrame.new(position + Vector3.new(0, 3.25 * scale, 0))
            * CFrame.Angles(math.rad(variant - 2), math.rad(variant * 11), math.rad(2 - variant)),
        Enum.Material.Wood,
        trunkColor
    )
    local trunkUpper = makePart(
        model,
        "TrunkUpper",
        Vector3.new(2.1, 6.8, 2.1) * scale,
        CFrame.new(position + Vector3.new(0.35 * scale, 9.2 * scale, 0.15 * scale))
            * CFrame.Angles(math.rad(-2), math.rad(variant * 17), math.rad(3)),
        Enum.Material.Wood,
        trunkColor
    )

    local branchSpecs = {
        { Vector3.new(0.4, 10.3, 0), Vector3.new(4.8, 13.1, -1.8), 0.65 },
        { Vector3.new(0.1, 9.6, 0.2), Vector3.new(-4.2, 12.3, 1.5), 0.58 },
        { Vector3.new(0.4, 11.1, 0.1), Vector3.new(1.8, 14.7, 3.8), 0.5 },
    }
    if variant == 2 then
        branchSpecs[1][2] = Vector3.new(5.4, 12.2, 2.5)
        branchSpecs[2][2] = Vector3.new(-3.4, 13.6, -2.8)
    elseif variant == 3 then
        branchSpecs[3][2] = Vector3.new(-1.5, 15.4, 4.3)
    end

    for index, spec in branchSpecs do
        local a = position + spec[1] * scale
        local b = position + spec[2] * scale
        local delta = b - a
        local branch = makePart(
            model,
            "Branch" .. index,
            Vector3.new(0.9, 0.9, delta.Magnitude) * Vector3.new(scale, scale, 1),
            CFrame.lookAt((a + b) * 0.5, b),
            Enum.Material.Wood,
            trunkColor
        )
        branch.CanCollide = false
    end

    local lobes = {
        { Vector3.new(-3.8, 13.0, 0.9), Vector3.new(6.8, 5.4, 6.4), 1 },
        { Vector3.new(3.6, 13.6, -1.2), Vector3.new(7.1, 5.8, 6.7), 2 },
        { Vector3.new(0.2, 16.2, 1.2), Vector3.new(7.8, 6.1, 7.2), 3 },
        { Vector3.new(-1.9, 15.0, -3.1), Vector3.new(5.7, 4.8, 5.6), 2 },
        { Vector3.new(2.8, 16.4, 3.0), Vector3.new(5.4, 4.6, 5.2), 4 },
        { Vector3.new(0.7, 18.7, -0.6), Vector3.new(5.5, 4.8, 5.3), 3 },
    }
    if variant == 2 then
        lobes[1][1] = Vector3.new(-4.5, 12.7, -1.8)
        lobes[3][1] = Vector3.new(0.8, 16.8, 0)
    elseif variant == 3 then
        lobes[2][1] = Vector3.new(4.2, 14.2, 1.8)
        lobes[5][1] = Vector3.new(-2.9, 17.0, 3.4)
    end

    for index, spec in lobes do
        local leaf = makeBall(
            model,
            "Canopy" .. index,
            spec[2] * scale,
            CFrame.new(position + spec[1] * scale),
            Enum.Material.Grass,
            leafPalette[spec[3]]
        )
        leaf.CanCollide = false
        CollectionService:AddTag(leaf, "EverLeafWindSway")
    end

    model.PrimaryPart = trunkLower
    trunkUpper.CanCollide = true
    return model
end

local function makeFallenLog(parent, position, yaw, scale)
    local prefab = EnvironmentPrefabService.Place(
        "FallenTreeTrunk",
        parent,
        CFrame.new(position) * CFrame.Angles(0, yaw, 0),
        scale * FOREST_PROP_SCALE
    )
    if prefab then
        return prefab
    end

    local model = Instance.new("Model")
    model.Name = "FallenLog"
    model.Parent = parent
    local base = CFrame.new(position) * CFrame.Angles(0, yaw, math.rad(6))
    local bark = Color3.fromRGB(70, 49, 34)
    makePart(
        model,
        "Log",
        Vector3.new(1.9, 1.7, 9) * scale,
        base * CFrame.new(0, 0.9 * scale, 0),
        Enum.Material.Wood,
        bark
    )
    for _, z in { -3.1, 2.3 } do
        local branch = makePart(
            model,
            "BrokenBranch",
            Vector3.new(0.55, 0.55, 3.2) * scale,
            base
                * CFrame.new(0.4 * scale, 1.35 * scale, z * scale)
                * CFrame.Angles(math.rad(35), math.rad(28), 0),
            Enum.Material.Wood,
            bark
        )
        branch.CanCollide = false
    end
    return model
end

local function makeStump(parent, position, scale)
    local prefab = EnvironmentPrefabService.Place(
        "TreeStump",
        parent,
        CFrame.new(position) * CFrame.Angles(0, math.rad(17), 0),
        scale * FOREST_PROP_SCALE
    )
    if prefab then
        return prefab
    end

    local model = Instance.new("Model")
    model.Name = "TreeStump"
    model.Parent = parent
    local stump = makePart(
        model,
        "Stump",
        Vector3.new(2.6, 2.3, 2.6) * scale,
        CFrame.new(position + Vector3.new(0, 1.15 * scale, 0))
            * CFrame.Angles(0, math.rad(17), math.rad(4)),
        Enum.Material.Wood,
        Color3.fromRGB(76, 53, 36)
    )
    makeBall(
        model,
        "Moss",
        Vector3.new(2.2, 0.65, 2.1) * scale,
        stump.CFrame * CFrame.new(0, 1.0 * scale, 0),
        Enum.Material.Grass,
        Color3.fromRGB(63, 112, 63)
    ).CanCollide =
        false
    return model
end

local function makePineRoots(parent, position, yaw, scale)
    local prefab = EnvironmentPrefabService.Place(
        "PineRoots",
        parent,
        CFrame.new(position) * CFrame.Angles(0, yaw, 0),
        scale * FOREST_PROP_SCALE
    )
    if prefab then
        return prefab
    end
    return nil
end

local function makeFern(parent, position, scale)
    local model = Instance.new("Model")
    model.Name = "LumenFern"
    model.Parent = parent
    local green = Color3.fromRGB(57, 112, 67)
    for index = 1, 7 do
        local angle = (index - 1) * (math.pi * 2 / 7)
        local blade = makePart(
            model,
            "Frond" .. index,
            Vector3.new(0.22, 0.42, 3.3) * scale,
            CFrame.new(
                position + Vector3.new(math.cos(angle) * 0.85, 0.72, math.sin(angle) * 0.85) * scale
            ) * CFrame.Angles(math.rad(-20), -angle, math.rad(9)),
            Enum.Material.Grass,
            green
        )
        blade.CanCollide = false
        blade.CastShadow = false
        CollectionService:AddTag(blade, "EverLeafWindSway")
    end
    return model
end

local function makeFlowerPatch(parent, position, scale, warm)
    local model = Instance.new("Model")
    model.Name = "WildflowerPatch"
    model.Parent = parent
    local flowerColor = if warm
        then Color3.fromRGB(242, 191, 113)
        else Color3.fromRGB(173, 157, 230)
    local offsets = {
        Vector3.new(-1.3, 0, -0.5),
        Vector3.new(0.2, 0, 0.8),
        Vector3.new(1.5, 0, -0.2),
        Vector3.new(-0.4, 0, 1.6),
    }
    for index, offset in offsets do
        local stem = makePart(
            model,
            "Stem" .. index,
            Vector3.new(0.12, 1.25, 0.12) * scale,
            CFrame.new(position + offset * scale + Vector3.new(0, 0.62 * scale, 0)),
            Enum.Material.Grass,
            Color3.fromRGB(65, 121, 68)
        )
        stem.CanCollide = false
        stem.CastShadow = false
        local bloom = makeBall(
            model,
            "Bloom" .. index,
            Vector3.new(0.42, 0.28, 0.42) * scale,
            CFrame.new(position + offset * scale + Vector3.new(0, 1.28 * scale, 0)),
            Enum.Material.SmoothPlastic,
            flowerColor
        )
        bloom.CanCollide = false
        bloom.CastShadow = false
    end
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

local function makeRockCluster(parent, position, scale, seed)
    local model = Instance.new("Model")
    model.Name = "RockCluster"
    model.Parent = parent
    local specs = {
        { Vector3.new(0, 1.3, 0), Vector3.new(5.8, 3.1, 4.8), Vector3.new(0.12, 0.4, 0.08) },
        { Vector3.new(3.1, 0.9, -1.4), Vector3.new(3.6, 2.2, 3.2), Vector3.new(0.2, -0.2, 0.18) },
        { Vector3.new(-2.8, 0.7, 1.7), Vector3.new(2.9, 1.8, 3.5), Vector3.new(-0.1, 0.8, 0.12) },
    }
    for index, spec in specs do
        local rock = makeRock(
            model,
            position + spec[1] * scale,
            spec[2] * scale,
            spec[3] + Vector3.new(0, (seed or 1) * index * 0.08, 0)
        )
        rock.Color = if index == 1 then Color3.fromRGB(76, 84, 83) else Color3.fromRGB(91, 98, 95)
    end
    if seed and seed % 2 == 0 then
        makeBall(
            model,
            "MossCap",
            Vector3.new(3.8, 0.7, 3.2) * scale,
            CFrame.new(position + Vector3.new(-0.4, 2.85, 0.2) * scale),
            Enum.Material.Grass,
            Color3.fromRGB(63, 106, 59)
        ).CanCollide =
            false
    end
    return model
end

local function makeSupplyStack(parent, position, yaw)
    local model = Instance.new("Model")
    model.Name = "WayfarerSupplies"
    model.Parent = parent
    local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
    local wood = Color3.fromRGB(105, 77, 50)
    makePart(
        model,
        "CrateA",
        Vector3.new(3.6, 2.5, 3.2),
        base * CFrame.new(0, 1.25, 0),
        Enum.Material.WoodPlanks,
        wood
    )
    makePart(
        model,
        "CrateB",
        Vector3.new(2.7, 2.1, 2.5),
        base * CFrame.new(2.8, 1.05, 0.4),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(91, 67, 45)
    )
    local sack = makeBall(
        model,
        "SupplySack",
        Vector3.new(2.0, 2.5, 1.8),
        base * CFrame.new(-2.2, 1.25, 0.8),
        Enum.Material.Fabric,
        Color3.fromRGB(118, 103, 76)
    )
    sack.CanCollide = false
    return model
end

local function makeSignpost(parent, position, yaw)
    local model = Instance.new("Model")
    model.Name = "WayfarerSignpost"
    model.Parent = parent
    local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
    local wood = Color3.fromRGB(78, 56, 38)
    makePart(
        model,
        "Post",
        Vector3.new(0.5, 5.5, 0.5),
        base * CFrame.new(0, 2.75, 0),
        Enum.Material.Wood,
        wood
    )
    local armA = makePart(
        model,
        "ArrowCamp",
        Vector3.new(4.3, 0.8, 0.35),
        base * CFrame.new(1.55, 4.35, 0),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(111, 80, 48)
    )
    local armB = makePart(
        model,
        "ArrowRuins",
        Vector3.new(3.8, 0.8, 0.35),
        base * CFrame.new(-1.35, 3.3, 0) * CFrame.Angles(0, math.pi, 0),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(99, 71, 45)
    )
    armA.CanCollide = false
    armB.CanCollide = false
    return model
end

local function makeCrystal(parent, position)
    local crystal = makePart(
        parent,
        "LumenCrystal",
        Vector3.new(1.6, 4.6, 1.6),
        CFrame.new(position) * CFrame.Angles(0, 0, math.rad(45)),
        Enum.Material.Glass,
        Color3.fromRGB(103, 193, 184)
    )
    crystal.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color = crystal.Color
    crystal.Transparency = 0.08
    light.Brightness = 0.55
    light.Range = 9
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
        CollectionService:AddTag(blade, "EverLeafWindSway")
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
        CollectionService:AddTag(leaf, "EverLeafWindSway")
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
    light.Brightness = 1.1
    light.Range = 14
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
        CollectionService:AddTag(glow, "EverLeafFirefly")
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
        CFrame.new(50, 3.5, -22) * CFrame.Angles(0, math.rad(-7), math.rad(2)),
        Enum.Material.Rock,
        Color3.fromRGB(89, 96, 91)
    )
    makePart(
        parent,
        "BrokenLintel",
        Vector3.new(9, 2.2, 3.4),
        CFrame.new(22, 1.5, -26) * CFrame.Angles(math.rad(8), math.rad(27), math.rad(17)),
        Enum.Material.Cobblestone,
        Color3.fromRGB(105, 112, 106)
    )
    makePart(
        parent,
        "FallenPillar",
        Vector3.new(3.2, 10, 3.2),
        CFrame.new(45, 1.9, -37) * CFrame.Angles(math.rad(82), math.rad(14), math.rad(4)),
        Enum.Material.Cobblestone,
        Color3.fromRGB(102, 110, 105)
    )
    makeRockCluster(parent, Vector3.new(20, 0.2, -36), 0.7, 6)
    makeRockCluster(parent, Vector3.new(52, 0.2, -37), 0.65, 7)
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

    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain:Clear()
        terrain:FillBlock(
            CFrame.new(0, -5, 0),
            Vector3.new(WORLD_WIDTH, 10, WORLD_DEPTH),
            Enum.Material.Grass
        )

        -- Keep the playable core readable and mostly level. Terrain masses live on the perimeter.
        terrain:FillBlock(CFrame.new(-55, -0.75, 34), Vector3.new(72, 3, 58), Enum.Material.Ground)
        terrain:FillBlock(CFrame.new(48, -0.85, 28), Vector3.new(76, 2.8, 66), Enum.Material.Grass)

        local perimeterHills = {
            { Vector3.new(-292, -10, 170), 48, Enum.Material.Grass },
            { Vector3.new(-300, -8, 55), 52, Enum.Material.Rock },
            { Vector3.new(-292, -12, -95), 50, Enum.Material.Rock },
            { Vector3.new(-235, -14, -238), 48, Enum.Material.Grass },
            { Vector3.new(-95, -16, -255), 46, Enum.Material.Grass },
            { Vector3.new(70, -16, -260), 48, Enum.Material.Rock },
            { Vector3.new(225, -13, -235), 52, Enum.Material.Rock },
            { Vector3.new(292, -9, -120), 48, Enum.Material.Rock },
            { Vector3.new(300, -9, 35), 50, Enum.Material.Grass },
            { Vector3.new(285, -11, 185), 48, Enum.Material.Grass },
            { Vector3.new(175, -14, 255), 46, Enum.Material.Grass },
            { Vector3.new(10, -15, 265), 48, Enum.Material.Grass },
            { Vector3.new(-150, -14, 255), 46, Enum.Material.Grass },
            { Vector3.new(-270, -11, 225), 48, Enum.Material.Rock },
        }
        for _, hill in perimeterHills do
            terrain:FillBall(hill[1], hill[2], hill[3])
        end

        local pathSegments = {
            {
                CFrame.new(-42, 0.2, 28) * CFrame.Angles(0, math.rad(-58), 0),
                Vector3.new(12, 1.1, 48),
            },
            {
                CFrame.new(1, 0.25, 5) * CFrame.Angles(0, math.rad(-90), 0),
                Vector3.new(12, 1.1, 62),
            },
            {
                CFrame.new(30, 0.3, -19) * CFrame.Angles(0, math.rad(-30), 0),
                Vector3.new(10, 1.1, 44),
            },
            {
                CFrame.new(92, 0.25, 24) * CFrame.Angles(0, math.rad(-88), 0),
                Vector3.new(14, 1.1, 118),
            },
            {
                CFrame.new(154, 0.25, 47) * CFrame.Angles(0, math.rad(-68), 0),
                Vector3.new(14, 1.1, 76),
            },
        }
        for _, segment in pathSegments do
            terrain:FillBlock(segment[1], segment[2], Enum.Material.Ground)
        end

        terrain:FillBlock(CFrame.new(-18, -1.5, -43), Vector3.new(46, 4, 33), Enum.Material.Water)
        terrain:FillBlock(CFrame.new(-18, -3.5, -43), Vector3.new(50, 3, 37), Enum.Material.Rock)
    end

    local foundation = makePart(
        world,
        "InvisibleFoundation",
        Vector3.new(WORLD_WIDTH, 2, WORLD_DEPTH),
        CFrame.new(0, -9, 0),
        Enum.Material.SmoothPlastic,
        Color3.new(0, 0, 0)
    )
    foundation.Transparency = 1

    local boundaryThickness = 8
    local boundaryHeight = 90
    local halfWidth = WORLD_WIDTH * 0.5
    local halfDepth = WORLD_DEPTH * 0.5
    local boundarySpecs = {
        {
            "NorthBoundary",
            Vector3.new(WORLD_WIDTH, boundaryHeight, boundaryThickness),
            CFrame.new(0, boundaryHeight * 0.5 - 2, -halfDepth),
        },
        {
            "SouthBoundary",
            Vector3.new(WORLD_WIDTH, boundaryHeight, boundaryThickness),
            CFrame.new(0, boundaryHeight * 0.5 - 2, halfDepth),
        },
        {
            "WestBoundary",
            Vector3.new(boundaryThickness, boundaryHeight, WORLD_DEPTH),
            CFrame.new(-halfWidth, boundaryHeight * 0.5 - 2, 0),
        },
        {
            "EastBoundary",
            Vector3.new(boundaryThickness, boundaryHeight, WORLD_DEPTH),
            CFrame.new(halfWidth, boundaryHeight * 0.5 - 2, 0),
        },
    }
    for _, spec in boundarySpecs do
        local wall = makePart(
            world,
            spec[1],
            spec[2],
            spec[3],
            Enum.Material.SmoothPlastic,
            Color3.new(0, 0, 0)
        )
        wall.Transparency = 1
        wall.CanCollide = true
        wall.CanTouch = false
        wall.CanQuery = false
    end
end

local function decorate(world)
    local trees = {
        { Vector3.new(-104, 0, 61), 1.15, 1 },
        { Vector3.new(-94, 0, 53), 0.95, 2 },
        { Vector3.new(-91, 0, 21), 1.05, 3 },
        { Vector3.new(-84, 0, 8), 0.82, 1 },
        { Vector3.new(-72, 0, -18), 0.92, 2 },
        { Vector3.new(-53, 0, -43), 1.05, 3 },
        { Vector3.new(-29, 0, -74), 0.88, 1 },
        { Vector3.new(-2, 0, -76), 1.12, 2 },
        { Vector3.new(24, 0, -72), 0.9, 3 },
        { Vector3.new(50, 0, -66), 1.0, 1 },
        { Vector3.new(75, 0, -55), 1.08, 2 },
        { Vector3.new(94, 0, -31), 0.9, 3 },
        { Vector3.new(101, 0, -2), 1.0, 1 },
        { Vector3.new(96, 0, 31), 0.86, 2 },
        { Vector3.new(91, 0, 61), 1.08, 3 },
        { Vector3.new(67, 0, 78), 0.92, 1 },
        { Vector3.new(36, 0, 86), 1.02, 2 },
        { Vector3.new(7, 0, 84), 1.08, 3 },
        { Vector3.new(-22, 0, 88), 0.9, 1 },
        { Vector3.new(-50, 0, 82), 1.02, 2 },
        { Vector3.new(-77, 0, 76), 0.88, 3 },
    }
    for _, entry in trees do
        makeTree(world, entry[1], entry[2], entry[3])
    end

    local outerTrees = {
        { Vector3.new(-225, 0, 168), 1.05, 1 },
        { Vector3.new(-205, 0, 126), 0.9, 2 },
        { Vector3.new(-218, 0, 62), 1.08, 3 },
        { Vector3.new(-222, 0, -12), 0.94, 1 },
        { Vector3.new(-214, 0, -86), 1.02, 2 },
        { Vector3.new(-188, 0, -156), 0.92, 3 },
        { Vector3.new(-134, 0, -196), 1.05, 1 },
        { Vector3.new(-70, 0, -212), 0.9, 2 },
        { Vector3.new(8, 0, -218), 1.08, 3 },
        { Vector3.new(84, 0, -208), 0.94, 1 },
        { Vector3.new(148, 0, -184), 1.04, 2 },
        { Vector3.new(202, 0, -142), 0.92, 3 },
        { Vector3.new(224, 0, -72), 1.05, 1 },
        { Vector3.new(226, 0, 6), 0.9, 2 },
        { Vector3.new(218, 0, 82), 1.08, 3 },
        { Vector3.new(198, 0, 148), 0.94, 1 },
        { Vector3.new(150, 0, 198), 1.04, 2 },
        { Vector3.new(82, 0, 214), 0.92, 3 },
        { Vector3.new(8, 0, 220), 1.05, 1 },
        { Vector3.new(-72, 0, 214), 0.9, 2 },
        { Vector3.new(-142, 0, 202), 1.08, 3 },
        { Vector3.new(-198, 0, 182), 0.94, 1 },
        { Vector3.new(122, 0, 95), 0.86, 2 },
        { Vector3.new(154, 0, 68), 0.92, 3 },
        { Vector3.new(174, 0, 42), 0.82, 1 },
        { Vector3.new(144, 0, 12), 0.9, 2 },
        { Vector3.new(118, 0, -28), 0.86, 3 },
    }
    for _, entry in outerTrees do
        makeTree(world, entry[1], entry[2], entry[3])
    end

    local rockClusters = {
        { Vector3.new(-58, 0, -21), 0.95, 1 },
        { Vector3.new(-30, 0, -62), 0.78, 2 },
        { Vector3.new(12, 0, -56), 1.0, 3 },
        { Vector3.new(74, 0, 9), 0.92, 4 },
        { Vector3.new(58, 0, 61), 0.86, 5 },
        { Vector3.new(-90, 0, 11), 0.72, 8 },
    }
    for _, entry in rockClusters do
        makeRockCluster(world, entry[1], entry[2], entry[3])
    end

    for _, position in
        {
            Vector3.new(-46, 2.1, -33),
            Vector3.new(-6, 2.1, -58),
            Vector3.new(55, 2.1, -14),
            Vector3.new(82, 2.1, 37),
        }
    do
        makeCrystal(world, position)
    end

    local bushPositions = {
        Vector3.new(-86, 0, 58),
        Vector3.new(-79, 0, 42),
        Vector3.new(-72, 0, 24),
        Vector3.new(-61, 0, -18),
        Vector3.new(-51, 0, -31),
        Vector3.new(-34, 0, -36),
        Vector3.new(-23, 0, -34),
        Vector3.new(-8, 0, -48),
        Vector3.new(16, 0, -41),
        Vector3.new(30, 0, 52),
        Vector3.new(44, 0, 60),
        Vector3.new(64, 0, 45),
        Vector3.new(76, 0, 5),
        Vector3.new(82, 0, 24),
        Vector3.new(44, 0, -50),
    }
    for index, position in bushPositions do
        makeBush(world, position, 0.6 + (index % 4) * 0.1)
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
        Vector3.new(-96, 0, -4),
        Vector3.new(-66, 0, -51),
        Vector3.new(10, 0, 63),
        Vector3.new(54, 0, -37),
        Vector3.new(88, 0, 55),
        Vector3.new(-36, 0, 69),
    }
    for index, position in grassPositions do
        makeGrassTuft(world, position, 0.65 + (index % 4) * 0.1)
    end

    local fernPositions = {
        Vector3.new(-82, 0, 50),
        Vector3.new(-75, 0, 46),
        Vector3.new(-66, 0, -22),
        Vector3.new(-42, 0, -40),
        Vector3.new(-15, 0, -55),
        Vector3.new(9, 0, -61),
        Vector3.new(30, 0, -61),
        Vector3.new(69, 0, -44),
        Vector3.new(84, 0, -2),
        Vector3.new(78, 0, 48),
        Vector3.new(55, 0, 67),
        Vector3.new(21, 0, 73),
        Vector3.new(-8, 0, 72),
        Vector3.new(-43, 0, 74),
        Vector3.new(-73, 0, 66),
    }
    for index, position in fernPositions do
        makeFern(world, position, 0.72 + (index % 3) * 0.12)
    end

    local flowerPatches = {
        { Vector3.new(-71, 0, 55), 0.9, true },
        { Vector3.new(-55, 0, 7), 0.8, false },
        { Vector3.new(-26, 0, -44), 0.85, true },
        { Vector3.new(18, 0, -48), 0.78, false },
        { Vector3.new(45, 0, 54), 0.9, true },
        { Vector3.new(72, 0, 42), 0.82, false },
        { Vector3.new(25, 0, 62), 0.75, false },
        { Vector3.new(-35, 0, 68), 0.88, true },
    }
    for _, entry in flowerPatches do
        makeFlowerPatch(world, entry[1], entry[2], entry[3])
    end

    makeFallenLog(world, Vector3.new(-79, 0.2, -3), math.rad(33), 0.9)
    makeFallenLog(world, Vector3.new(71, 0.2, -28), math.rad(-52), 0.82)
    makeFallenLog(world, Vector3.new(42, 0.2, 69), math.rad(74), 0.76)
    makeStump(world, Vector3.new(-62, 0, 67), 0.9)
    makeStump(world, Vector3.new(83, 0, 17), 0.72)
    makeStump(world, Vector3.new(12, 0, -66), 0.8)
    makePineRoots(world, Vector3.new(-84, 0, -18), math.rad(24), 0.78)
    makePineRoots(world, Vector3.new(76, 0, 57), math.rad(-38), 0.72)
    makePineRoots(world, Vector3.new(31, 0, -63), math.rad(71), 0.66)

    makeCampfire(world, Vector3.new(-59, 0, 31))
    makeTent(world, Vector3.new(-72, 0.2, 28), math.rad(18))
    makeTent(world, Vector3.new(-66, 0.2, 17), math.rad(-24))
    makeSupplyStack(world, Vector3.new(-77, 0, 36), math.rad(-15))
    makeSupplyStack(world, Vector3.new(-61, 0, 45), math.rad(24))
    makeSignpost(world, Vector3.new(-38, 0, 25), math.rad(-58))
    makeLantern(world, Vector3.new(-47, 0, 30))
    makeLantern(world, Vector3.new(-29, 0, 22))
    makeLantern(world, Vector3.new(-8, 0, 10))
    makeLantern(world, Vector3.new(17, 0, 4))
    makeBridge(world, Vector3.new(-17, 0.2, -44))
    makeWaterfall(world, Vector3.new(-92, 0, -66))
    makeRockSpire(world, Vector3.new(104, 0, -68), 1.05)
    makeRockSpire(world, Vector3.new(108, 0, 72), 0.82)
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
    PBRMaterialService.ApplyGeneratedWorld(world)
    makeSpawn(world)
    makeGuide(world, Vector3.new(-48, 2, 35))

    makeLandmarkLabel(world, Vector3.new(-49, 11, 35), "LUMENREACH WAYFARER CAMP")
    makeLandmarkLabel(world, Vector3.new(148, 9, 42), "MOSSGLEN COMBAT GROVE")
    makeLandmarkLabel(world, Vector3.new(37, 18, -31), "SHATTERED LUMEN ARCH")
    makeLandmarkLabel(world, Vector3.new(-92, 30, -59), "VEILFALL CASCADE")

    EnemySpawnerService.Spawn("training_dummy", Vector3.new(-29, 4, 33), world)
    EnemySpawnerService.Spawn("lumen_mossling", Vector3.new(132, 3, 34), world)
    EnemySpawnerService.Spawn("lumen_mossling", Vector3.new(151, 3, 48), world)
    EnemySpawnerService.Spawn("lumen_mossling", Vector3.new(166, 3, 29), world)
end

return LumenreachWorldService
