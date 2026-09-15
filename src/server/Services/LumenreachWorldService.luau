local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local EnemySpawnerService = require(script.Parent.EnemySpawnerService)
local EnvironmentPrefabService = require(script.Parent.EnvironmentPrefabService)
local InteractionService = require(script.Parent.InteractionService)
local InventoryService = require(script.Parent.InventoryService)
local PBRMaterialService = require(script.Parent.PBRMaterialService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local QuestService = require(script.Parent.QuestService)
local PortalService = require(script.Parent.PortalService)
local WorldNoticeService = require(script.Parent.WorldNoticeService)
local WorldObjectService = require(script.Parent.WorldObjectService)
local WorldTravelService = require(script.Parent.WorldTravelService)

local LumenreachWorldService = {}

local GENERATED_NAME = "EverLeafGeneratedWorld"
local WORLD_WIDTH = 900
local WORLD_DEPTH = 760
local FOLIAGE_MATERIAL = Enum.Material.SmoothPlastic

local WORLD_ZONES = table.freeze({
    Camp = Vector3.new(-250, 0, 120),
    Crossroads = Vector3.new(-80, 0, 28),
    Ruins = Vector3.new(78, 0, -92),
    CombatGrove = Vector3.new(220, 0, 82),
    Waterfall = Vector3.new(-255, 0, -178),
    Glowmere = Vector3.new(22, 0, 176),
    Overlook = Vector3.new(155, 0, -225),
})

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

local function useMaterialVariant(part, variantName)
    part:SetAttribute("EverLeafMaterialVariant", variantName)
    return part
end

local function makeBall(parent, name, size, cframe, material, color)
    local part = makePart(parent, name, size, cframe, material, color)
    part.Shape = Enum.PartType.Ball
    return part
end

local function prefabExtents(prefabName)
    local prefab = EnvironmentPrefabService.Get(prefabName)
    if not prefab then
        return nil
    end
    if prefab:IsA("Model") then
        return prefab:GetExtentsSize()
    elseif prefab:IsA("BasePart") then
        return prefab.Size
    end
    return nil
end

local function prefabScaleForHeight(prefabName, targetHeight, multiplier)
    local extents = prefabExtents(prefabName)
    if not extents or extents.Y <= 0.001 then
        return multiplier
    end
    return (targetHeight / extents.Y) * multiplier
end

local function prefabScaleForLongest(prefabName, targetLongest, multiplier)
    local extents = prefabExtents(prefabName)
    if not extents then
        return multiplier
    end
    local longest = math.max(extents.X, extents.Y, extents.Z)
    if longest <= 0.001 then
        return multiplier
    end
    return (targetLongest / longest) * multiplier
end

local function makeTree(parent, position, scale, variant)
    variant = variant or 1
    local prefabYaw = math.rad((variant * 47) % 360)
    local prefab = EnvironmentPrefabService.Place(
        "TreePrimary",
        parent,
        CFrame.new(position) * CFrame.Angles(0, prefabYaw, 0),
        prefabScaleForHeight("TreePrimary", 22, scale)
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
            FOLIAGE_MATERIAL,
            leafPalette[spec[3]]
        )
        leaf.CanCollide = false
        CollectionService:AddTag(leaf, "EverLeafWindSway")
    end

    model.PrimaryPart = trunkLower
    trunkUpper.CanCollide = true
    return model
end

local function makeFallenLog(parent, position, yaw, scale, variant)
    local prefabName = if variant == 2 then "FallenTreeTrunk2" else "FallenTreeTrunk"
    local prefab = EnvironmentPrefabService.Place(
        prefabName,
        parent,
        CFrame.new(position) * CFrame.Angles(0, yaw, 0),
        prefabScaleForLongest(prefabName, 10, scale)
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

local function makeStump(parent, position, scale, variant)
    local prefabName = if variant == 2 then "TreeStump2" else "TreeStump"
    local prefab = EnvironmentPrefabService.Place(
        prefabName,
        parent,
        CFrame.new(position) * CFrame.Angles(0, math.rad(17 + (variant or 1) * 23), 0),
        prefabScaleForHeight(prefabName, 3, scale)
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
        FOLIAGE_MATERIAL,
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
        prefabScaleForLongest("PineRoots", 7, scale)
    )
    if prefab then
        return prefab
    end
    return nil
end

local function makeFern(parent, position, scale, yaw)
    local prefab = EnvironmentPrefabService.Place(
        "FernPrimary",
        parent,
        CFrame.new(position)
            * CFrame.Angles(0, yaw or math.rad((math.floor(position.X + position.Z) * 37) % 360), 0),
        prefabScaleForLongest("FernPrimary", 4.2, scale)
    )
    if prefab then
        return prefab
    end

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
            FOLIAGE_MATERIAL,
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
            FOLIAGE_MATERIAL,
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
        Enum.Material.Rock,
        Color3.fromRGB(112, 119, 115)
    )
    rock.Shape = Enum.PartType.Ball
    useMaterialVariant(rock, "MossyRock")
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
        rock.Color = if index == 1
            then Color3.fromRGB(104, 111, 108)
            else Color3.fromRGB(119, 125, 120)
    end
    if seed and seed % 2 == 0 then
        makeBall(
            model,
            "MossCap",
            Vector3.new(3.8, 0.7, 3.2) * scale,
            CFrame.new(position + Vector3.new(-0.4, 2.85, 0.2) * scale),
            FOLIAGE_MATERIAL,
            Color3.fromRGB(63, 106, 59)
        ).CanCollide =
            false
    end
    return model
end

local function setInstanceCollision(instance, enabled)
    if instance:IsA("BasePart") then
        instance.CanCollide = enabled
    end
    for _, descendant in instance:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = enabled
            descendant.CanTouch = false
        end
    end
end

local function makeDryBranches(parent, position, yaw, scale)
    local prefab = EnvironmentPrefabService.Place(
        "DryBranches",
        parent,
        CFrame.new(position) * CFrame.Angles(0, yaw, 0),
        prefabScaleForLongest("DryBranches", 4.6, scale)
    )
    if prefab then
        setInstanceCollision(prefab, false)
        return prefab
    end

    local model = Instance.new("Model")
    model.Name = "DryBranchesFallback"
    model.Parent = parent
    local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
    local branchColor = Color3.fromRGB(79, 58, 42)
    for index, spec in
        {
            { Vector3.new(0, 0.28, 0), Vector3.new(0.28, 0.28, 5.8), math.rad(7) },
            { Vector3.new(1.2, 0.35, -0.4), Vector3.new(0.22, 0.22, 4.2), math.rad(-24) },
            { Vector3.new(-1.1, 0.32, 0.6), Vector3.new(0.2, 0.2, 3.6), math.rad(31) },
        }
    do
        local branch = makePart(
            model,
            "Branch" .. index,
            spec[2] * scale,
            base * CFrame.new(spec[1] * scale) * CFrame.Angles(0, spec[3], math.rad(index * 3 - 5)),
            Enum.Material.Wood,
            branchColor
        )
        branch.CanCollide = false
    end
    return model
end

local function makeMossyRockSet(parent, position, yaw, scale)
    local prefab = EnvironmentPrefabService.Place(
        "MossyRockSet",
        parent,
        CFrame.new(position) * CFrame.Angles(0, yaw, 0),
        prefabScaleForLongest("MossyRockSet", 9, scale)
    )
    if prefab then
        setInstanceCollision(prefab, true)
        return prefab
    end
    return makeRockCluster(parent, position, 0.9 * scale, math.max(1, math.floor(scale * 9)))
end

local function makeRockFace(parent, position, yaw, scale)
    local model = Instance.new("Model")
    model.Name = "IntegratedRockFace"
    model.Parent = parent

    local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
    local prefab = EnvironmentPrefabService.Place(
        "RockFace",
        model,
        CFrame.new(position - Vector3.new(0, 2.15 * scale, 0)) * CFrame.Angles(0, yaw, 0),
        prefabScaleForLongest("RockFace", 16, scale)
    )
    if prefab then
        setInstanceCollision(prefab, true)
    end

    local supportSpecs = {
        { Vector3.new(-5.2, 2.6, 2.7), Vector3.new(9.4, 5.8, 8.0), Vector3.new(0.05, -0.18, 0.08) },
        { Vector3.new(4.8, 2.2, 3.2), Vector3.new(8.0, 4.8, 7.0), Vector3.new(-0.08, 0.24, -0.04) },
        {
            Vector3.new(-1.0, 1.5, -2.8),
            Vector3.new(10.5, 3.8, 6.8),
            Vector3.new(0.12, 0.08, 0.06),
        },
        { Vector3.new(0.8, 4.6, 3.8), Vector3.new(7.0, 5.6, 6.2), Vector3.new(-0.12, -0.12, 0.08) },
    }
    for index, spec in supportSpecs do
        local worldPosition = (base * CFrame.new(spec[1] * scale)).Position
        local rock = makeRock(
            model,
            worldPosition,
            spec[2] * scale,
            Vector3.new(spec[3].X, spec[3].Y + yaw, spec[3].Z)
        )
        rock.Color = if index % 2 == 0
            then Color3.fromRGB(98, 105, 101)
            else Color3.fromRGB(88, 97, 94)
    end

    local mossShelf = makeBall(
        model,
        "MossShelf",
        Vector3.new(9.2, 0.85, 6.4) * scale,
        base * CFrame.new(-1.4 * scale, 5.55 * scale, 3.0 * scale),
        FOLIAGE_MATERIAL,
        Color3.fromRGB(69, 105, 61)
    )
    mossShelf.CanCollide = false
    mossShelf.CanTouch = false

    return model
end

local function makeMushroomCluster(parent, position, scale, seed)
    local model = Instance.new("Model")
    model.Name = "LumenMushroomCluster"
    model.Parent = parent

    local stemColor = Color3.fromRGB(211, 199, 166)
    local caps = {
        Color3.fromRGB(100, 151, 121),
        Color3.fromRGB(124, 105, 166),
        Color3.fromRGB(191, 126, 87),
    }
    local offsets = {
        Vector3.new(-0.7, 0, -0.3),
        Vector3.new(0.45, 0, 0.25),
        Vector3.new(1.05, 0, -0.5),
        Vector3.new(-0.15, 0, 0.9),
        Vector3.new(-1.05, 0, 0.75),
    }
    for index, offset in offsets do
        local height = (0.75 + ((index + seed) % 3) * 0.22) * scale
        local stem = makePart(
            model,
            "Stem" .. index,
            Vector3.new(0.22, height, 0.22),
            CFrame.new(position + offset * scale + Vector3.new(0, height * 0.5, 0)),
            Enum.Material.SmoothPlastic,
            stemColor
        )
        stem.CanCollide = false
        stem.CastShadow = false
        local cap = makeBall(
            model,
            "Cap" .. index,
            Vector3.new(0.82, 0.32, 0.82) * (scale * (0.86 + (index % 2) * 0.16)),
            CFrame.new(position + offset * scale + Vector3.new(0, height + 0.08 * scale, 0)),
            Enum.Material.SmoothPlastic,
            caps[((index + seed - 2) % #caps) + 1]
        )
        cap.CanCollide = false
        cap.CastShadow = false
    end
    return model
end

local function makeCattailCluster(parent, position, scale, seed)
    local model = Instance.new("Model")
    model.Name = "LumenCattails"
    model.Parent = parent
    local offsets = {
        Vector3.new(-0.8, 0, -0.3),
        Vector3.new(0.1, 0, 0.4),
        Vector3.new(0.85, 0, -0.2),
        Vector3.new(-0.2, 0, -0.9),
        Vector3.new(0.7, 0, 0.9),
    }
    for index, offset in offsets do
        local height = (2.4 + ((index + seed) % 3) * 0.35) * scale
        local stem = makePart(
            model,
            "ReedStem" .. index,
            Vector3.new(0.12, height, 0.12),
            CFrame.new(position + offset * scale + Vector3.new(0, height * 0.5, 0)),
            FOLIAGE_MATERIAL,
            Color3.fromRGB(75, 118, 64)
        )
        stem.CanCollide = false
        stem.CastShadow = false
        local head = makePart(
            model,
            "Cattail" .. index,
            Vector3.new(0.28, 0.72 * scale, 0.28),
            CFrame.new(position + offset * scale + Vector3.new(0, height + 0.24 * scale, 0)),
            Enum.Material.SmoothPlastic,
            Color3.fromRGB(95, 67, 43)
        )
        head.CanCollide = false
        head.CastShadow = false
    end
    return model
end

local function makeWaystone(parent, position, yaw, scale)
    local model = Instance.new("Model")
    model.Name = "LumenWaystone"
    model.Parent = parent
    local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
    local foot = makeBall(
        model,
        "MossyFoot",
        Vector3.new(3.2, 1.1, 2.7) * scale,
        base * CFrame.new(0, 0.5 * scale, 0),
        Enum.Material.Rock,
        Color3.fromRGB(78, 88, 82)
    )
    useMaterialVariant(foot, "MossyRock")
    local pillar = makePart(
        model,
        "Waystone",
        Vector3.new(1.8, 4.6, 1.2) * scale,
        base * CFrame.new(0, 2.65 * scale, 0) * CFrame.Angles(math.rad(-2), 0, math.rad(3)),
        Enum.Material.Slate,
        Color3.fromRGB(76, 86, 82)
    )
    local rune = makePart(
        model,
        "LumenRune",
        Vector3.new(0.55, 1.45, 0.08) * scale,
        base * CFrame.new(0, 2.95 * scale, -0.64 * scale),
        Enum.Material.Neon,
        Color3.fromRGB(97, 218, 181)
    )
    rune.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color = rune.Color
    light.Brightness = 0.45
    light.Range = 7 * scale
    light.Parent = rune
    pillar.CanTouch = false
    return model
end

local function makeTrailStones(parent)
    local model = Instance.new("Model")
    model.Name = "LumenTrailPebbles"
    model.Parent = parent

    -- Small, embedded shoulder stones. These should read as natural trail-edge
    -- pebbles, never as rectangular paving bricks dropped in the travel lane.
    local markers = {
        { Vector3.new(-214, 0, 103), math.rad(-57), 1 },
        { Vector3.new(-189, 0, 87), math.rad(-58), -1 },
        { Vector3.new(-164, 0, 72), math.rad(-60), 1 },
        { Vector3.new(-137, 0, 57), math.rad(-61), -1 },
        { Vector3.new(-108, 0, 42), math.rad(-66), 1 },
        { Vector3.new(-63, 0, 35), math.rad(-82), -1 },
        { Vector3.new(-31, 0, 47), math.rad(-72), 1 },
        { Vector3.new(6, 0, 59), math.rad(-78), -1 },
        { Vector3.new(48, 0, 67), math.rad(-84), 1 },
        { Vector3.new(89, 0, 74), math.rad(-85), -1 },
        { Vector3.new(132, 0, 79), math.rad(-87), 1 },
        { Vector3.new(173, 0, 81), math.rad(-88), -1 },
        { Vector3.new(-70, 0, 6), math.rad(-25), 1 },
        { Vector3.new(-39, 0, -14), math.rad(-35), -1 },
        { Vector3.new(-6, 0, -32), math.rad(-56), 1 },
        { Vector3.new(27, 0, -50), math.rad(-63), -1 },
        { Vector3.new(54, 0, -70), math.rad(-44), 1 },
    }

    for index, entry in markers do
        local forward = Vector3.new(math.sin(entry[2]), 0, math.cos(entry[2]))
        local right = Vector3.new(forward.Z, 0, -forward.X)
        local shoulder = entry[1] + right * (6.2 * entry[3])
        local count = 3 + (index % 3)
        for pebbleIndex = 1, count do
            local along = (pebbleIndex - (count + 1) * 0.5) * 1.25
            local outward = ((pebbleIndex % 2) * 0.75) + (index % 2) * 0.25
            local pebblePosition = shoulder + forward * along + right * outward * entry[3]
            local pebble = makeRock(
                model,
                pebblePosition + Vector3.new(0, 0.12 + (pebbleIndex % 2) * 0.05, 0),
                Vector3.new(
                    0.9 + (pebbleIndex % 3) * 0.28,
                    0.35 + (pebbleIndex % 2) * 0.12,
                    0.75 + ((pebbleIndex + index) % 3) * 0.24
                ),
                Vector3.new(
                    math.rad((pebbleIndex % 3) * 4 - 4),
                    entry[2] + pebbleIndex * 0.61,
                    math.rad((index % 3) * 3 - 3)
                )
            )
            pebble.Name = "TrailPebble" .. tostring(index) .. "_" .. tostring(pebbleIndex)
            pebble.CanCollide = false
            pebble.CanTouch = false
            pebble.Color = if (index + pebbleIndex) % 3 == 0
                then Color3.fromRGB(104, 111, 104)
                else Color3.fromRGB(92, 101, 96)
        end
    end

    return model
end

local function makeSupplyStack(parent, position, yaw)
    local model = Instance.new("Model")
    model.Name = "WayfarerSupplies"
    model.Parent = parent

    local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
    local wood = Color3.fromRGB(112, 82, 51)
    local woodDark = Color3.fromRGB(76, 55, 38)
    local canvas = Color3.fromRGB(126, 111, 78)

    local function makeCrate(name, localOffset, localYaw, scale)
        local crate = Instance.new("Model")
        crate.Name = name
        crate.Parent = model
        local crateBase = base * CFrame.new(localOffset) * CFrame.Angles(0, localYaw, 0)
        local width = 3.6 * scale
        local height = 2.7 * scale
        local depth = 3.1 * scale

        makePart(
            crate,
            "Bottom",
            Vector3.new(width, 0.2 * scale, depth),
            crateBase * CFrame.new(0, 0.12 * scale, 0),
            Enum.Material.Wood,
            woodDark
        )

        for _, x in { -1, 1 } do
            for _, z in { -1, 1 } do
                makePart(
                    crate,
                    "CornerPost",
                    Vector3.new(0.22, height, 0.22) * scale,
                    crateBase * CFrame.new(x * width * 0.46, height * 0.5, z * depth * 0.46),
                    Enum.Material.Wood,
                    woodDark
                )
            end
        end

        for row = 1, 3 do
            local y = (0.48 + (row - 1) * 0.73) * scale
            for _, z in { -1, 1 } do
                makePart(
                    crate,
                    "FrontBackSlat",
                    Vector3.new(width * 0.88, 0.46 * scale, 0.18 * scale),
                    crateBase * CFrame.new(0, y, z * depth * 0.48),
                    Enum.Material.Wood,
                    if row == 2 then woodDark else wood
                )
            end
            for _, x in { -1, 1 } do
                makePart(
                    crate,
                    "SideSlat",
                    Vector3.new(0.18 * scale, 0.46 * scale, depth * 0.82),
                    crateBase * CFrame.new(x * width * 0.48, y, 0),
                    Enum.Material.Wood,
                    wood
                )
            end
        end
        return crate
    end

    makeCrate("ProvisionCrate", Vector3.new(0, 0, 0), 0, 1)
    makeCrate("ToolCrate", Vector3.new(3.8, 0, 1.15), math.rad(12), 0.72)

    for index, offset in
        {
            Vector3.new(-2.25, 0, 0.75),
            Vector3.new(-2.8, 0, -0.8),
        }
    do
        local sack = makeBall(
            model,
            "SupplySack" .. index,
            Vector3.new(1.65, 2.15, 1.5),
            base * CFrame.new(offset + Vector3.new(0, 1.0, 0)),
            Enum.Material.Fabric,
            if index == 1 then canvas else Color3.fromRGB(103, 94, 69)
        )
        sack.CanCollide = false
    end

    local bedroll = makePart(
        model,
        "RolledBedroll",
        Vector3.new(2.7, 0.85, 1.05),
        base * CFrame.new(3.6, 2.35, 1.1) * CFrame.Angles(0, math.rad(12), math.rad(5)),
        Enum.Material.Fabric,
        Color3.fromRGB(73, 111, 96)
    )
    bedroll.CanCollide = false

    for _, x in { -0.9, 0.9 } do
        local strap = makePart(
            model,
            "BedrollStrap",
            Vector3.new(0.16, 0.92, 1.1),
            bedroll.CFrame * CFrame.new(x, 0, 0),
            Enum.Material.Fabric,
            Color3.fromRGB(70, 48, 32)
        )
        strap.CanCollide = false
    end

    return model
end

local function makeSignpost(parent, position, yaw)
    local model = Instance.new("Model")
    model.Name = "WayfarerSignpost"
    model.Parent = parent

    local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
    local wood = Color3.fromRGB(69, 49, 34)
    local boardWood = Color3.fromRGB(118, 84, 48)
    local trimWood = Color3.fromRGB(82, 57, 38)

    local foot = makeBall(
        model,
        "MossyBase",
        Vector3.new(2.35, 0.72, 2.05),
        base * CFrame.new(0, 0.28, 0),
        Enum.Material.Rock,
        Color3.fromRGB(82, 91, 79)
    )
    foot.CanCollide = false
    useMaterialVariant(foot, "MossyRock")

    makePart(
        model,
        "Post",
        Vector3.new(0.54, 8.6, 0.54),
        base * CFrame.new(0, 4.3, 0),
        Enum.Material.Wood,
        wood
    )

    local function addBoard(name, text, y, direction, width, tilt)
        local centerX = direction * (width * 0.5 + 0.42)
        local board = makePart(
            model,
            name,
            Vector3.new(width, 1.18, 0.38),
            base
                * CFrame.new(centerX, y, 0)
                * CFrame.Angles(0, direction < 0 and math.pi or 0, math.rad(tilt or 0)),
            Enum.Material.Wood,
            boardWood
        )
        board.CanCollide = false

        -- A small darker heel makes each arm read as attached without allowing
        -- the center post to cover the destination text.
        local heel = makePart(
            model,
            name .. "Heel",
            Vector3.new(0.72, 1.03, 0.42),
            base * CFrame.new(direction * 0.48, y, 0),
            Enum.Material.Wood,
            trimWood
        )
        heel.CanCollide = false

        for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
            local surface = Instance.new("SurfaceGui")
            surface.Name = "DirectionLabel"
            surface.Face = face
            surface.CanvasSize = Vector2.new(640, 128)
            surface.LightInfluence = 0.25
            surface.Parent = board

            local label = Instance.new("TextLabel")
            label.Position = UDim2.fromScale(0.045, 0.08)
            label.Size = UDim2.fromScale(0.91, 0.84)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = Color3.fromRGB(236, 222, 180)
            label.TextStrokeColor3 = Color3.fromRGB(45, 31, 22)
            label.TextStrokeTransparency = 0.12
            label.Font = Enum.Font.GothamBold
            label.TextScaled = true
            label.Parent = surface
        end
        return board
    end

    addBoard("CampBoard", "WAYFARER CAMP", 6.85, 1, 6.2, 1.5)
    addBoard("RuinsBoard", "LUMEN ARCH", 5.35, -1, 5.35, -1.5)

    local cap = makeBall(
        model,
        "LumenMarker",
        Vector3.new(0.72, 0.72, 0.72),
        base * CFrame.new(0, 8.78, 0),
        Enum.Material.Neon,
        Color3.fromRGB(114, 232, 194)
    )
    cap.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color = cap.Color
    light.Brightness = 0.5
    light.Range = 7
    light.Parent = cap

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
            FOLIAGE_MATERIAL,
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
            FOLIAGE_MATERIAL,
            colors[((index - 1) % #colors) + 1]
        )
        leaf.CanCollide = false
        CollectionService:AddTag(leaf, "EverLeafWindSway")
    end
    return model
end

local function makeRodBetween(parent, name, a, b, thickness, material, color)
    local delta = b - a
    local rod = makePart(
        parent,
        name,
        Vector3.new(thickness, thickness, delta.Magnitude),
        CFrame.lookAt((a + b) * 0.5, b),
        material,
        color
    )
    rod.CanCollide = false
    rod.CanTouch = false
    return rod
end

local function makeCampfire(parent, position)
    local model = Instance.new("Model")
    model.Name = "WayfarerCampfire"
    model.Parent = parent

    local coals = makePart(
        model,
        "CoalBed",
        Vector3.new(0.18, 3.5, 3.5),
        CFrame.new(position + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Enum.Material.Slate,
        Color3.fromRGB(37, 31, 27)
    )
    coals.Shape = Enum.PartType.Cylinder
    coals.CanCollide = false

    for index = 1, 9 do
        local angle = index * math.pi * 2 / 9
        local stone = makeBall(
            model,
            "FireRingStone" .. index,
            Vector3.new(1.45, 0.85, 1.15),
            CFrame.new(position + Vector3.new(math.cos(angle) * 2.2, 0.45, math.sin(angle) * 2.2))
                * CFrame.Angles(0, -angle, math.rad((index % 3 - 1) * 6)),
            Enum.Material.Rock,
            Color3.fromRGB(88, 89, 82)
        )
        stone.CanCollide = false
        useMaterialVariant(stone, "MossyRock")
    end

    for index = 1, 3 do
        local log = makePart(
            model,
            "FireLog" .. index,
            Vector3.new(4.7, 0.62, 0.62),
            CFrame.new(position + Vector3.new(0, 0.72 + index * 0.05, 0))
                * CFrame.Angles(0, math.rad((index - 1) * 60 + 12), math.rad((index - 2) * 4)),
            Enum.Material.Wood,
            Color3.fromRGB(72, 46, 31)
        )
        log.Shape = Enum.PartType.Cylinder
        log.CanCollide = false
    end

    local ember = makeBall(
        model,
        "EmberCore",
        Vector3.new(1.55, 1.1, 1.55),
        CFrame.new(position + Vector3.new(0, 1.05, 0)),
        Enum.Material.Neon,
        Color3.fromRGB(255, 126, 48)
    )
    ember.CanCollide = false

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 169, 98)
    light.Brightness = 1.45
    light.Range = 18
    light.Shadows = true
    light.Parent = ember

    local fire = Instance.new("Fire")
    fire.Color = Color3.fromRGB(255, 181, 83)
    fire.SecondaryColor = Color3.fromRGB(83, 196, 156)
    fire.Heat = 7
    fire.Size = 5.5
    fire.Parent = ember
    return model
end

local function makeTent(parent, position, yaw)
    local model = Instance.new("Model")
    model.Name = "WayfarerTent"
    model.Parent = parent

    local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
    local cloth = Color3.fromRGB(54, 91, 79)
    local clothDark = Color3.fromRGB(34, 61, 54)
    local clothTrim = Color3.fromRGB(117, 91, 59)
    local poleColor = Color3.fromRGB(88, 62, 40)
    local ropeColor = Color3.fromRGB(151, 135, 97)
    local halfWidth = 6.0
    local ridgeHeight = 7.2
    local eaveHeight = 0.7
    local canvasLength = 14.5
    local panelWidth =
        math.sqrt(halfWidth * halfWidth + (ridgeHeight - eaveHeight) * (ridgeHeight - eaveHeight))
    local slope = math.atan2(ridgeHeight - eaveHeight, halfWidth)

    local groundSheet = makePart(
        model,
        "GroundSheet",
        Vector3.new(10.6, 0.14, 12.8),
        base * CFrame.new(0, 0.16, 0.35),
        Enum.Material.Fabric,
        Color3.fromRGB(71, 67, 54)
    )
    groundSheet.CanCollide = false

    local leftCanvas = makePart(
        model,
        "CanvasLeft",
        Vector3.new(panelWidth, 0.22, canvasLength),
        base
            * CFrame.new(-halfWidth * 0.5, (ridgeHeight + eaveHeight) * 0.5, 0)
            * CFrame.Angles(0, 0, slope),
        Enum.Material.Fabric,
        cloth
    )
    local rightCanvas = makePart(
        model,
        "CanvasRight",
        Vector3.new(panelWidth, 0.22, canvasLength),
        base
            * CFrame.new(halfWidth * 0.5, (ridgeHeight + eaveHeight) * 0.5, 0)
            * CFrame.Angles(0, 0, -slope),
        Enum.Material.Fabric,
        clothDark
    )
    leftCanvas.CanCollide = false
    rightCanvas.CanCollide = false

    local ridge = makePart(
        model,
        "RidgePole",
        Vector3.new(0.34, 0.34, canvasLength + 1.0),
        base * CFrame.new(0, ridgeHeight + 0.06, 0),
        Enum.Material.Wood,
        poleColor
    )
    ridge.CanCollide = false

    for _, z in { -canvasLength * 0.5, canvasLength * 0.5 } do
        local support = makePart(
            model,
            "SupportPole",
            Vector3.new(0.36, ridgeHeight + 0.45, 0.36),
            base * CFrame.new(0, (ridgeHeight + 0.45) * 0.5, z),
            Enum.Material.Wood,
            poleColor
        )
        support.CanCollide = false
    end

    for _, side in { -1, 1 } do
        local trim = makePart(
            model,
            "CanvasEdgeTrim",
            Vector3.new(0.18, 0.18, canvasLength),
            base
                * CFrame.new(side * halfWidth, eaveHeight + 0.05, 0)
                * CFrame.Angles(0, 0, math.rad(side * 2)),
            Enum.Material.Fabric,
            clothTrim
        )
        trim.CanCollide = false
    end

    local entranceZ = -canvasLength * 0.5 - 0.04
    for _, side in { -1, 1 } do
        local flap = makePart(
            model,
            if side < 0 then "EntranceFlapLeft" else "EntranceFlapRight",
            Vector3.new(3.25, 5.15, 0.16),
            base
                * CFrame.new(side * 2.2, 2.9, entranceZ)
                * CFrame.Angles(0, math.rad(side * 23), math.rad(side * -8)),
            Enum.Material.Fabric,
            if side < 0 then cloth else clothDark
        )
        flap.CanCollide = false
    end

    local awning = makePart(
        model,
        "EntranceAwning",
        Vector3.new(6.8, 0.16, 3.8),
        base * CFrame.new(0, 5.2, entranceZ - 1.65) * CFrame.Angles(math.rad(-7), 0, 0),
        Enum.Material.Fabric,
        cloth
    )
    awning.CanCollide = false

    for _, side in { -1, 1 } do
        local awningPole = makePart(
            model,
            "AwningPole",
            Vector3.new(0.26, 4.6, 0.26),
            base * CFrame.new(side * 3.15, 2.3, entranceZ - 3.1),
            Enum.Material.Wood,
            poleColor
        )
        awningPole.CanCollide = false
    end

    for _, bed in
        {
            { Vector3.new(-2.45, 0.38, 1.8), Color3.fromRGB(116, 86, 65) },
            { Vector3.new(2.45, 0.38, 1.8), Color3.fromRGB(83, 111, 94) },
        }
    do
        local bedroll = makePart(
            model,
            "Bedroll",
            Vector3.new(3.25, 0.34, 5.4),
            base * CFrame.new(bed[1]),
            Enum.Material.Fabric,
            bed[2]
        )
        bedroll.CanCollide = false
        local pillow = makePart(
            model,
            "Pillow",
            Vector3.new(2.5, 0.42, 1.0),
            base * CFrame.new(bed[1] + Vector3.new(0, 0.35, 1.95)),
            Enum.Material.Fabric,
            Color3.fromRGB(139, 126, 93)
        )
        pillow.CanCollide = false
    end

    local emblem = makePart(
        model,
        "LumenEmblem",
        Vector3.new(1.0, 0.08, 1.8),
        base * CFrame.new(-3.05, 4.6, -1.2) * CFrame.Angles(0, 0, slope),
        Enum.Material.Neon,
        Color3.fromRGB(91, 213, 176)
    )
    emblem.CanCollide = false
    emblem.Transparency = 0.15

    local stakeOffsets = {
        Vector3.new(-halfWidth - 1.0, 0.2, -canvasLength * 0.5 - 0.8),
        Vector3.new(halfWidth + 1.0, 0.2, -canvasLength * 0.5 - 0.8),
        Vector3.new(-halfWidth - 1.0, 0.2, canvasLength * 0.5 + 0.8),
        Vector3.new(halfWidth + 1.0, 0.2, canvasLength * 0.5 + 0.8),
    }
    for index, offset in stakeOffsets do
        local worldStake = (base * CFrame.new(offset)).Position
        local stake = makePart(
            model,
            "Stake" .. index,
            Vector3.new(0.24, 0.8, 0.24),
            CFrame.new(worldStake + Vector3.new(0, 0.25, 0))
                * CFrame.Angles(math.rad(10), 0, math.rad(8)),
            Enum.Material.Wood,
            poleColor
        )
        stake.CanCollide = false

        local side = if index % 2 == 1 then -1 else 1
        local endZ = if index <= 2 then -canvasLength * 0.5 else canvasLength * 0.5
        local ropeStart = (base * CFrame.new(side * 0.18, ridgeHeight - 0.2, endZ)).Position
        makeRodBetween(
            model,
            "GuyRope" .. index,
            ropeStart,
            worldStake + Vector3.new(0, 0.5, 0),
            0.075,
            Enum.Material.Fabric,
            ropeColor
        )
    end

    return model
end

local function makeCampBench(parent, position, yaw)
    local model = Instance.new("Model")
    model.Name = "WayfarerBench"
    model.Parent = parent
    local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
    local wood = Color3.fromRGB(91, 65, 42)

    makePart(
        model,
        "Seat",
        Vector3.new(5.6, 0.42, 1.5),
        base * CFrame.new(0, 1.25, 0),
        Enum.Material.Wood,
        wood
    )
    for _, x in { -2.05, 2.05 } do
        makePart(
            model,
            "Leg",
            Vector3.new(0.44, 1.35, 1.15),
            base * CFrame.new(x, 0.65, 0),
            Enum.Material.Wood,
            Color3.fromRGB(69, 50, 35)
        )
    end
    return model
end

local function makeMapTable(parent, position, yaw)
    local model = Instance.new("Model")
    model.Name = "WayfarerMapTable"
    model.Parent = parent
    local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)

    makePart(
        model,
        "TableTop",
        Vector3.new(6.2, 0.42, 3.8),
        base * CFrame.new(0, 3.0, 0),
        Enum.Material.Wood,
        Color3.fromRGB(100, 72, 46)
    )
    for _, x in { -2.45, 2.45 } do
        for _, z in { -1.25, 1.25 } do
            makePart(
                model,
                "TableLeg",
                Vector3.new(0.42, 3.0, 0.42),
                base * CFrame.new(x, 1.5, z),
                Enum.Material.Wood,
                Color3.fromRGB(70, 50, 35)
            )
        end
    end

    local map = makePart(
        model,
        "TrailMap",
        Vector3.new(4.8, 0.05, 2.65),
        base * CFrame.new(0, 3.24, 0) * CFrame.Angles(0, math.rad(-4), 0),
        Enum.Material.Fabric,
        Color3.fromRGB(194, 174, 126)
    )
    map.CanCollide = false

    for index, offset in
        {
            Vector3.new(-1.45, 3.32, -0.55),
            Vector3.new(0.2, 3.32, 0.6),
            Vector3.new(1.5, 3.32, -0.15),
        }
    do
        local marker = makeBall(
            model,
            "MapMarker" .. index,
            Vector3.new(0.2, 0.2, 0.2),
            base * CFrame.new(offset),
            Enum.Material.Neon,
            Color3.fromRGB(89, 218, 181)
        )
        marker.CanCollide = false
    end
    return model
end

local function makeCampBanner(parent, position, yaw)
    local model = Instance.new("Model")
    model.Name = "WayfarerBanner"
    model.Parent = parent
    local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
    local wood = Color3.fromRGB(73, 52, 35)

    for _, x in { -2.7, 2.7 } do
        makePart(
            model,
            "BannerPost",
            Vector3.new(0.34, 7.6, 0.34),
            base * CFrame.new(x, 3.8, 0),
            Enum.Material.Wood,
            wood
        )
    end
    makePart(
        model,
        "BannerTop",
        Vector3.new(5.8, 0.34, 0.34),
        base * CFrame.new(0, 7.25, 0),
        Enum.Material.Wood,
        wood
    )

    local banner = makePart(
        model,
        "BannerCloth",
        Vector3.new(4.9, 3.6, 0.12),
        base * CFrame.new(0, 5.25, 0),
        Enum.Material.Fabric,
        Color3.fromRGB(45, 91, 78)
    )
    banner.CanCollide = false
    local rune = makePart(
        model,
        "BannerRune",
        Vector3.new(0.65, 2.25, 0.08),
        base * CFrame.new(0, 5.3, -0.08) * CFrame.Angles(0, 0, math.rad(25)),
        Enum.Material.Neon,
        Color3.fromRGB(97, 218, 181)
    )
    rune.CanCollide = false
    return model
end

local function makeLantern(parent, position, yaw)
    local model = Instance.new("Model")
    model.Name = "LumenLantern"
    model.Parent = parent

    yaw = yaw or 0
    local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
    local wood = Color3.fromRGB(62, 45, 33)
    local metal = Color3.fromRGB(61, 70, 65)

    local foot = makeBall(
        model,
        "StoneFoot",
        Vector3.new(1.55, 0.5, 1.45),
        base * CFrame.new(0, 0.18, 0),
        Enum.Material.Rock,
        Color3.fromRGB(75, 84, 79)
    )
    foot.CanCollide = false
    useMaterialVariant(foot, "MossyRock")

    makePart(
        model,
        "Post",
        Vector3.new(0.38, 7.1, 0.38),
        base * CFrame.new(0, 3.55, 0),
        Enum.Material.Wood,
        wood
    )
    makePart(
        model,
        "Arm",
        Vector3.new(2.75, 0.3, 0.3),
        base * CFrame.new(1.18, 6.72, 0),
        Enum.Material.Wood,
        wood
    )
    makePart(
        model,
        "Brace",
        Vector3.new(1.25, 0.2, 0.2),
        base * CFrame.new(0.66, 6.2, 0) * CFrame.Angles(0, 0, math.rad(-43)),
        Enum.Material.Wood,
        wood
    )
    makePart(
        model,
        "Hanger",
        Vector3.new(0.12, 0.78, 0.12),
        base * CFrame.new(2.42, 6.28, 0),
        Enum.Material.Metal,
        metal
    )

    makePart(
        model,
        "CageTop",
        Vector3.new(0.92, 0.12, 0.92),
        base * CFrame.new(2.42, 6.12, 0),
        Enum.Material.Metal,
        metal
    ).CanCollide =
        false
    makePart(
        model,
        "CageBottom",
        Vector3.new(0.78, 0.12, 0.78),
        base * CFrame.new(2.42, 5.16, 0),
        Enum.Material.Metal,
        metal
    ).CanCollide =
        false
    for _, corner in
        {
            Vector2.new(-0.34, -0.34),
            Vector2.new(0.34, -0.34),
            Vector2.new(-0.34, 0.34),
            Vector2.new(0.34, 0.34),
        }
    do
        local rail = makePart(
            model,
            "CageRail",
            Vector3.new(0.09, 1.02, 0.09),
            base * CFrame.new(2.42 + corner.X, 5.64, corner.Y),
            Enum.Material.Metal,
            metal
        )
        rail.CanCollide = false
    end

    local glow = makeBall(
        model,
        "Glow",
        Vector3.new(0.62, 0.62, 0.62),
        base * CFrame.new(2.42, 5.64, 0),
        Enum.Material.Neon,
        Color3.fromRGB(147, 239, 194)
    )
    glow.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color = glow.Color
    light.Brightness = 1.45
    light.Range = 18
    light.Shadows = true
    light.Parent = glow
    return model
end

local function makeBridge(parent, position, yaw, length, width)
    local model = Instance.new("Model")
    model.Name = "LumenFootbridge"
    model.Parent = parent

    yaw = yaw or 0
    length = length or 14
    width = width or 5
    local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
    local wood = Color3.fromRGB(101, 73, 49)
    local darkWood = Color3.fromRGB(69, 50, 35)
    local plankCount = math.max(7, math.floor(length / 1.15))
    local spacing = length / plankCount

    for index = 0, plankCount do
        local z = -length * 0.5 + index * spacing
        local rise = math.sin((index / plankCount) * math.pi) * 0.55
        local plank = makePart(
            model,
            "Plank",
            Vector3.new(width, 0.34, math.max(0.82, spacing * 0.9)),
            base
                * CFrame.new(0, 0.75 + rise, z)
                * CFrame.Angles(0, math.rad((index % 3 - 1) * 0.7), 0),
            Enum.Material.Wood,
            if index % 4 == 0 then darkWood else wood
        )
        plank.CanTouch = false
    end

    for _, side in { -1, 1 } do
        makePart(
            model,
            "Rail",
            Vector3.new(0.24, 0.24, length + 0.5),
            base * CFrame.new(side * (width * 0.5 - 0.1), 2.25, 0),
            Enum.Material.Wood,
            darkWood
        )
        local postCount = math.max(4, math.floor(length / 4))
        for index = 0, postCount do
            local z = -length * 0.5 + (length / postCount) * index
            makePart(
                model,
                "RailPost",
                Vector3.new(0.28, 2.7, 0.28),
                base * CFrame.new(side * (width * 0.5 - 0.1), 1.45, z),
                Enum.Material.Wood,
                darkWood
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

    local specs = {
        { Vector3.new(0, 2.9, 0), Vector3.new(13.5, 6.8, 11.5), Vector3.new(0.03, 0.28, 0.06) },
        { Vector3.new(-3.4, 6.2, -0.8), Vector3.new(8.4, 7.2, 7.6), Vector3.new(0.1, -0.18, 0.14) },
        { Vector3.new(3.5, 5.3, 1.6), Vector3.new(7.4, 5.8, 8.6), Vector3.new(-0.12, 0.4, -0.08) },
        { Vector3.new(-0.6, 9.4, 0.2), Vector3.new(7.0, 6.2, 6.5), Vector3.new(0.08, 0.12, 0.12) },
        {
            Vector3.new(1.7, 11.8, -0.6),
            Vector3.new(4.8, 4.6, 5.2),
            Vector3.new(-0.1, -0.28, 0.06),
        },
    }
    for index, spec in specs do
        local rock = makeRock(model, position + spec[1] * scale, spec[2] * scale, spec[3])
        rock.Color = if index == 1
            then Color3.fromRGB(91, 100, 96)
            else if index % 2 == 0
                then Color3.fromRGB(101, 109, 103)
                else Color3.fromRGB(84, 94, 90)
    end

    local moss = makeBall(
        model,
        "MossCrown",
        Vector3.new(7.8, 0.8, 6.8) * scale,
        CFrame.new(position + Vector3.new(-0.5, 12.2, 0.3) * scale)
            * CFrame.Angles(math.rad(4), math.rad(14), math.rad(-3)),
        FOLIAGE_MATERIAL,
        Color3.fromRGB(67, 108, 59)
    )
    moss.CanCollide = false
    moss.CanTouch = false
    return model
end

local function makeRuins(parent, origin)
    local model = Instance.new("Model")
    model.Name = "ShatteredLumenArch"
    model.Parent = parent
    origin = origin or Vector3.zero

    local stone = Color3.fromRGB(108, 117, 111)
    local darkStone = Color3.fromRGB(78, 87, 83)

    local function ruinPart(name, size, offset, rotation, color)
        return makePart(
            model,
            name,
            size,
            CFrame.new(origin + offset) * (rotation or CFrame.new()),
            Enum.Material.Rock,
            color or stone
        )
    end

    ruinPart(
        "WestPillar",
        Vector3.new(5, 18, 5),
        Vector3.new(-11, 9, 0),
        CFrame.Angles(0, 0, math.rad(-2))
    )
    ruinPart(
        "EastPillar",
        Vector3.new(5, 15, 5),
        Vector3.new(11, 7.5, 0),
        CFrame.Angles(0, 0, math.rad(3))
    )
    ruinPart(
        "ArchLintel",
        Vector3.new(27, 3.5, 5),
        Vector3.new(0, 16.2, 0),
        CFrame.Angles(0, 0, math.rad(1))
    )
    ruinPart(
        "WestWall",
        Vector3.new(4, 8, 20),
        Vector3.new(-18, 4, 7),
        CFrame.Angles(0, math.rad(10), math.rad(-2)),
        darkStone
    )
    ruinPart(
        "EastWall",
        Vector3.new(4, 7, 17),
        Vector3.new(18, 3.5, 9),
        CFrame.Angles(0, math.rad(-13), math.rad(2)),
        darkStone
    )
    ruinPart(
        "BrokenLintel",
        Vector3.new(11, 2.7, 4),
        Vector3.new(-17, 1.7, -11),
        CFrame.Angles(math.rad(8), math.rad(32), math.rad(15))
    )
    ruinPart(
        "FallenPillar",
        Vector3.new(3.8, 13, 3.8),
        Vector3.new(14, 2.2, -14),
        CFrame.Angles(math.rad(82), math.rad(17), math.rad(5))
    )

    makeRockCluster(model, origin + Vector3.new(-23, 0.2, -12), 0.9, 6)
    makeRockCluster(model, origin + Vector3.new(24, 0.2, -14), 0.82, 7)
    makeCrystal(model, origin + Vector3.new(-7, 3.4, -8))
    makeCrystal(model, origin + Vector3.new(9, 2.7, 7))

    local gate = makePart(
        model,
        "BrasshavenGate",
        Vector3.new(13, 11, 0.9),
        CFrame.new(origin + Vector3.new(0, 6.1, 0.7)),
        Enum.Material.ForceField,
        Color3.fromRGB(91, 195, 181)
    )
    gate.Transparency = 0.38
    gate.CanCollide = false
    WorldObjectService.Register(gate, "Portal", "lumenreach_to_brasshaven")

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "BrasshavenGatePrompt"
    prompt.ActionText = "Travel"
    prompt.ObjectText = "Brasshaven Gate · Level 10"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Enabled = true
    prompt.Parent = gate
    prompt.Triggered:Connect(function(player)
        local profile = PlayerDataService.Get(player)
        if not profile then
            return
        end
        local ok, reason = PortalService.Travel(player, profile, "lumenreach_to_brasshaven", gate)
        if ok then
            PlayerDataService.NotifyChanged(player)
        else
            WorldNoticeService.SendReason(player, reason)
        end
    end)

    return model
end

local function makeCombatGrove(parent, center)
    local model = Instance.new("Model")
    model.Name = "MossglenCombatGrove"
    model.Parent = parent
    center = center or Vector3.zero

    for index = 1, 14 do
        local angle = (index - 1) * math.pi * 2 / 14
        local radius = if index % 2 == 0 then 34 else 31
        local position = center
            + Vector3.new(math.cos(angle) * radius, 0.6, math.sin(angle) * radius)
        local stone = makeRock(
            model,
            position,
            Vector3.new(3.4 + (index % 3) * 0.5, 1.5 + (index % 2) * 0.4, 3.0),
            Vector3.new(math.rad(index % 3 * 3), angle * 0.35, math.rad((index % 4 - 2) * 4))
        )
        stone.CanCollide = false
    end

    for _, entry in
        {
            { Vector3.new(-30, 0, 17), math.rad(68), 0.76 },
            { Vector3.new(30, 0, 17), math.rad(-68), 0.76 },
            { Vector3.new(0, 0, 35), math.rad(180), 0.86 },
        }
    do
        makeWaystone(model, center + entry[1], entry[2], entry[3])
    end

    local totemBase = CFrame.new(center + Vector3.new(0, 0, 37))
    makePart(
        model,
        "GroveTotem",
        Vector3.new(2.0, 8.4, 2.0),
        totemBase * CFrame.new(0, 4.2, 0),
        Enum.Material.Wood,
        Color3.fromRGB(65, 50, 35)
    )
    local rune = makePart(
        model,
        "GroveRune",
        Vector3.new(0.9, 2.7, 0.1),
        totemBase * CFrame.new(0, 4.8, -1.06) * CFrame.Angles(0, 0, math.rad(45)),
        Enum.Material.Neon,
        Color3.fromRGB(101, 226, 182)
    )
    rune.CanCollide = false
    local glow = Instance.new("PointLight")
    glow.Color = rune.Color
    glow.Brightness = 0.7
    glow.Range = 12
    glow.Parent = rune

    for _, offset in
        {
            Vector3.new(-18, 0, -31),
            Vector3.new(18, 0, -31),
        }
    do
        local marker = makePart(
            model,
            "GroveMarker",
            Vector3.new(4.2, 0.3, 1.4),
            CFrame.new(center + offset + Vector3.new(0, 0.18, 0)),
            Enum.Material.Wood,
            Color3.fromRGB(83, 61, 42)
        )
        marker.CanCollide = false
    end

    return model
end

local function makeGuide(parent, position, yaw)
    local model = Instance.new("Model")
    model.Name = "LumenGuide"
    model.Parent = parent

    local base = CFrame.new(position) * CFrame.Angles(0, yaw or 0, 0)
    local skin = Color3.fromRGB(218, 187, 153)
    local coat = Color3.fromRGB(48, 91, 80)
    local coatDark = Color3.fromRGB(29, 58, 53)
    local clothLight = Color3.fromRGB(125, 139, 111)
    local leather = Color3.fromRGB(91, 61, 39)
    local leatherDark = Color3.fromRGB(58, 42, 31)
    local brass = Color3.fromRGB(166, 132, 67)
    local lumen = Color3.fromRGB(105, 231, 194)

    local function guidePart(name, size, offset, material, color, rotation)
        local part = makePart(
            model,
            name,
            size,
            base * CFrame.new(offset) * (rotation or CFrame.new()),
            material,
            color
        )
        part.CanCollide = false
        part.CanTouch = false
        return part
    end

    local root = guidePart(
        "HumanoidRootPart",
        Vector3.new(2.2, 7.4, 2.0),
        Vector3.new(0, 3.7, 0),
        Enum.Material.SmoothPlastic,
        Color3.new(0, 0, 0)
    )
    root.Transparency = 1

    for _, leg in
        {
            { "LeftLeg", Vector3.new(-0.58, 1.45, 0), math.rad(-2) },
            { "RightLeg", Vector3.new(0.58, 1.45, 0), math.rad(2) },
        }
    do
        guidePart(
            leg[1],
            Vector3.new(0.82, 1.85, 0.92),
            leg[2],
            Enum.Material.Fabric,
            Color3.fromRGB(57, 66, 61),
            CFrame.Angles(0, 0, leg[3])
        )
    end

    for _, boot in
        {
            { "LeftBoot", Vector3.new(-0.58, 0.48, -0.12) },
            { "RightBoot", Vector3.new(0.58, 0.48, -0.12) },
        }
    do
        guidePart(
            boot[1],
            Vector3.new(0.95, 0.82, 1.35),
            boot[2],
            Enum.Material.SmoothPlastic,
            leatherDark
        )
    end

    guidePart(
        "CoatSkirt",
        Vector3.new(2.65, 1.8, 1.45),
        Vector3.new(0, 2.55, 0.08),
        Enum.Material.Fabric,
        coatDark
    )
    guidePart(
        "Torso",
        Vector3.new(2.55, 2.3, 1.5),
        Vector3.new(0, 4.05, 0),
        Enum.Material.Fabric,
        coat
    )
    guidePart(
        "ChestPanel",
        Vector3.new(1.75, 1.55, 0.14),
        Vector3.new(0, 4.15, -0.82),
        Enum.Material.Fabric,
        clothLight,
        CFrame.Angles(0, 0, math.rad(-5))
    )
    guidePart(
        "Belt",
        Vector3.new(2.72, 0.32, 1.62),
        Vector3.new(0, 3.05, 0),
        Enum.Material.Fabric,
        leather
    )
    guidePart(
        "BeltBuckle",
        Vector3.new(0.42, 0.44, 0.12),
        Vector3.new(0, 3.03, -0.86),
        Enum.Material.Metal,
        brass
    )

    guidePart(
        "Cape",
        Vector3.new(2.5, 3.25, 0.18),
        Vector3.new(0, 3.55, 0.9),
        Enum.Material.Fabric,
        Color3.fromRGB(35, 69, 61),
        CFrame.Angles(math.rad(-5), 0, 0)
    )

    for _, shoulder in
        {
            { "LeftShoulder", Vector3.new(-1.48, 4.65, 0) },
            { "RightShoulder", Vector3.new(1.48, 4.65, 0) },
        }
    do
        local pad = makeBall(
            model,
            shoulder[1],
            Vector3.new(1.05, 0.72, 1.08),
            base * CFrame.new(shoulder[2]),
            Enum.Material.Fabric,
            coatDark
        )
        pad.CanCollide = false
    end

    for _, arm in
        {
            { "LeftArm", Vector3.new(-1.48, 3.65, -0.03), math.rad(-9) },
            { "RightArm", Vector3.new(1.52, 3.68, -0.05), math.rad(8) },
        }
    do
        guidePart(
            arm[1],
            Vector3.new(0.78, 2.15, 0.82),
            arm[2],
            Enum.Material.Fabric,
            coat,
            CFrame.Angles(0, 0, arm[3])
        )
    end

    for _, hand in
        {
            { "LeftHand", Vector3.new(-1.67, 2.45, -0.05) },
            { "RightHand", Vector3.new(1.7, 2.48, -0.02) },
        }
    do
        local handPart = makeBall(
            model,
            hand[1],
            Vector3.new(0.72, 0.72, 0.72),
            base * CFrame.new(hand[2]),
            Enum.Material.SmoothPlastic,
            skin
        )
        handPart.CanCollide = false
    end

    guidePart(
        "NeckWrap",
        Vector3.new(1.85, 0.5, 1.55),
        Vector3.new(0, 5.15, 0),
        Enum.Material.Fabric,
        Color3.fromRGB(153, 108, 62)
    )

    local head = guidePart(
        "Head",
        Vector3.new(1.72, 1.78, 1.62),
        Vector3.new(0, 6.05, -0.02),
        Enum.Material.SmoothPlastic,
        skin
    )

    guidePart(
        "HoodTop",
        Vector3.new(1.92, 0.48, 1.76),
        Vector3.new(0, 6.82, 0.03),
        Enum.Material.Fabric,
        coatDark
    )
    for _, side in { -1, 1 } do
        guidePart(
            if side < 0 then "HoodLeft" else "HoodRight",
            Vector3.new(0.34, 1.18, 1.72),
            Vector3.new(side * 0.86, 6.12, 0.04),
            Enum.Material.Fabric,
            coatDark,
            CFrame.Angles(0, 0, math.rad(side * 4))
        )
    end

    for _, eye in
        {
            { "LeftEye", Vector3.new(-0.34, 6.18, -0.85) },
            { "RightEye", Vector3.new(0.34, 6.18, -0.85) },
        }
    do
        guidePart(
            eye[1],
            Vector3.new(0.16, 0.16, 0.08),
            eye[2],
            Enum.Material.SmoothPlastic,
            Color3.fromRGB(38, 46, 42)
        )
    end
    guidePart(
        "Mouth",
        Vector3.new(0.48, 0.08, 0.07),
        Vector3.new(0, 5.78, -0.86),
        Enum.Material.SmoothPlastic,
        Color3.fromRGB(120, 74, 62)
    )

    guidePart(
        "Satchel",
        Vector3.new(1.3, 1.55, 0.62),
        Vector3.new(-1.3, 3.15, 0.78),
        Enum.Material.Fabric,
        leather,
        CFrame.Angles(0, 0, math.rad(7))
    )
    guidePart(
        "SatchelFlap",
        Vector3.new(1.12, 0.55, 0.12),
        Vector3.new(-1.3, 3.55, 0.43),
        Enum.Material.Fabric,
        leatherDark,
        CFrame.Angles(math.rad(10), 0, math.rad(7))
    )

    local staffBottom = (base * CFrame.new(2.05, 0.35, 0.2)).Position
    local staffTop = (base * CFrame.new(2.05, 6.95, 0.2)).Position
    makeRodBetween(
        model,
        "WayfinderStaff",
        staffBottom,
        staffTop,
        0.24,
        Enum.Material.Wood,
        Color3.fromRGB(74, 52, 34)
    )
    local staffCrystal = makeBall(
        model,
        "StaffLumen",
        Vector3.new(0.72, 0.92, 0.72),
        CFrame.new(staffTop + Vector3.new(0, 0.28, 0)),
        Enum.Material.Neon,
        lumen
    )
    staffCrystal.CanCollide = false
    local staffLight = Instance.new("PointLight")
    staffLight.Color = lumen
    staffLight.Brightness = 0.8
    staffLight.Range = 9
    staffLight.Parent = staffCrystal

    local badge = guidePart(
        "WayfarerBadge",
        Vector3.new(0.42, 0.42, 0.08),
        Vector3.new(0.72, 4.45, -0.87),
        Enum.Material.Neon,
        lumen,
        CFrame.Angles(0, 0, math.rad(45))
    )
    badge.Transparency = 0.08

    local nameplate = Instance.new("BillboardGui")
    nameplate.Name = "GuideNameplate"
    nameplate.Size = UDim2.fromOffset(190, 34)
    nameplate.StudsOffsetWorldSpace = Vector3.new(0, 1.75, 0)
    nameplate.AlwaysOnTop = false
    nameplate.MaxDistance = 48
    nameplate.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.fromScale(1, 1)
    nameLabel.BackgroundTransparency = 0.18
    nameLabel.BackgroundColor3 = Color3.fromRGB(17, 27, 24)
    nameLabel.Text = "ILYRA · WAYFARER GUIDE"
    nameLabel.TextColor3 = Color3.fromRGB(215, 243, 226)
    nameLabel.TextStrokeColor3 = Color3.fromRGB(24, 39, 34)
    nameLabel.TextStrokeTransparency = 0.25
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Parent = nameplate
    local nameCorner = Instance.new("UICorner")
    nameCorner.CornerRadius = UDim.new(0, 8)
    nameCorner.Parent = nameLabel
    local nameStroke = Instance.new("UIStroke")
    nameStroke.Color = Color3.fromRGB(87, 142, 112)
    nameStroke.Transparency = 0.35
    nameStroke.Thickness = 1
    nameStroke.Parent = nameLabel

    model.PrimaryPart = root
    WorldObjectService.Register(model, "Npc", "lumen_guide")

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "TalkPrompt"
    prompt.ActionText = "Talk"
    prompt.ObjectText = "Ilyra · Lumen Guide"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
    prompt.Parent = root
    prompt.Triggered:Connect(function(player)
        InteractionService.Begin(player, "lumen_guide", model)
    end)

    return model
end

local function makeCampNpc(parent, npcId, displayName, position, yaw, palette, role)
    local model = Instance.new("Model")
    model.Name = npcId
    model.Parent = parent
    local base = CFrame.new(position) * CFrame.Angles(0, yaw or 0, 0)
    local cloth = palette.Cloth
    local accent = palette.Accent
    local skin = palette.Skin or Color3.fromRGB(214, 181, 146)
    local leather = palette.Leather or Color3.fromRGB(84, 58, 39)

    local function npcPart(name, size, offset, material, color, rotation)
        local part = makePart(
            model,
            name,
            size,
            base * CFrame.new(offset) * (rotation or CFrame.new()),
            material,
            color
        )
        part.CanCollide = false
        part.CanTouch = false
        return part
    end

    local root = npcPart(
        "HumanoidRootPart",
        Vector3.new(2, 6.8, 1.8),
        Vector3.new(0, 3.4, 0),
        Enum.Material.SmoothPlastic,
        Color3.new(0, 0, 0)
    )
    root.Transparency = 1
    npcPart(
        "Torso",
        Vector3.new(2.5, 2.5, 1.45),
        Vector3.new(0, 3.9, 0),
        Enum.Material.Fabric,
        cloth
    )
    npcPart(
        "Belt",
        Vector3.new(2.65, 0.3, 1.55),
        Vector3.new(0, 2.8, 0),
        Enum.Material.Fabric,
        leather
    )
    for _, side in { -1, 1 } do
        npcPart(
            side < 0 and "LeftLeg" or "RightLeg",
            Vector3.new(0.78, 2.5, 0.82),
            Vector3.new(side * 0.58, 1.45, 0),
            Enum.Material.Fabric,
            Color3.fromRGB(58, 64, 60)
        )
        npcPart(
            side < 0 and "LeftArm" or "RightArm",
            Vector3.new(0.72, 2.2, 0.76),
            Vector3.new(side * 1.55, 3.75, 0),
            Enum.Material.Fabric,
            cloth,
            CFrame.Angles(0, 0, math.rad(side * 5))
        )
    end
    local head = npcPart(
        "Head",
        Vector3.new(1.7, 1.7, 1.6),
        Vector3.new(0, 5.75, 0),
        Enum.Material.SmoothPlastic,
        skin
    )
    for _, x in { -0.34, 0.34 } do
        npcPart(
            x < 0 and "LeftEye" or "RightEye",
            Vector3.new(0.14, 0.14, 0.07),
            Vector3.new(x, 5.95, -0.82),
            Enum.Material.SmoothPlastic,
            Color3.fromRGB(35, 42, 39)
        )
    end

    if role == "Quartermaster" then
        npcPart(
            "Apron",
            Vector3.new(2.0, 2.4, 0.14),
            Vector3.new(0, 3.65, -0.78),
            Enum.Material.Fabric,
            accent
        )
        npcPart(
            "Ledger",
            Vector3.new(1.2, 0.18, 1.55),
            Vector3.new(-1.35, 3.0, -0.7),
            Enum.Material.Wood,
            Color3.fromRGB(104, 75, 48),
            CFrame.Angles(math.rad(15), math.rad(14), math.rad(-8))
        )
    elseif role == "Scout" then
        npcPart(
            "ScoutCape",
            Vector3.new(2.4, 3.0, 0.16),
            Vector3.new(0, 3.5, 0.88),
            Enum.Material.Fabric,
            accent,
            CFrame.Angles(math.rad(-6), 0, 0)
        )
        npcPart(
            "Pack",
            Vector3.new(1.8, 2.0, 0.8),
            Vector3.new(0, 3.5, 1.1),
            Enum.Material.Fabric,
            leather
        )
        npcPart(
            "ShortSpear",
            Vector3.new(0.18, 5.8, 0.18),
            Vector3.new(1.75, 3.0, 0.25),
            Enum.Material.Wood,
            Color3.fromRGB(77, 54, 35),
            CFrame.Angles(0, 0, math.rad(-7))
        )
    elseif role == "Archivist" then
        npcPart(
            "ArchiveMantle",
            Vector3.new(2.8, 0.65, 1.8),
            Vector3.new(0, 4.7, 0),
            Enum.Material.Fabric,
            accent
        )
        npcPart(
            "Book",
            Vector3.new(1.2, 0.35, 1.55),
            Vector3.new(1.3, 2.9, -0.55),
            Enum.Material.Fabric,
            Color3.fromRGB(82, 59, 106),
            CFrame.Angles(math.rad(20), math.rad(-12), math.rad(9))
        )
        npcPart(
            "Headband",
            Vector3.new(1.82, 0.22, 1.7),
            Vector3.new(0, 6.22, 0),
            Enum.Material.Fabric,
            accent
        )
    elseif role == "Mentor" then
        npcPart(
            "PathkeeperMantle",
            Vector3.new(3.0, 0.72, 1.92),
            Vector3.new(0, 4.75, 0),
            Enum.Material.Fabric,
            accent
        )
        npcPart(
            "PathkeeperStaff",
            Vector3.new(0.2, 6.2, 0.2),
            Vector3.new(1.65, 3.2, 0.3),
            Enum.Material.Wood,
            Color3.fromRGB(82, 58, 38),
            CFrame.Angles(0, 0, math.rad(-6))
        )
        local pathLumen = npcPart(
            "PathkeeperLumen",
            Vector3.new(0.64, 0.64, 0.64),
            Vector3.new(1.49, 6.28, 0.12),
            Enum.Material.Neon,
            Color3.fromRGB(113, 238, 170)
        )
        pathLumen.Shape = Enum.PartType.Ball
        local light = Instance.new("PointLight")
        light.Color = Color3.fromRGB(121, 244, 183)
        light.Brightness = 0.75
        light.Range = 8
        light.Parent = pathLumen
    end

    local nameplate = Instance.new("BillboardGui")
    nameplate.Size = UDim2.fromOffset(210, 32)
    nameplate.StudsOffsetWorldSpace = Vector3.new(0, 1.65, 0)
    nameplate.MaxDistance = 45
    nameplate.Parent = head
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 0.18
    label.BackgroundColor3 = Color3.fromRGB(17, 27, 24)
    label.Text = displayName
    label.TextColor3 = Color3.fromRGB(226, 243, 230)
    label.TextStrokeTransparency = 0.25
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = nameplate
    local labelCorner = Instance.new("UICorner")
    labelCorner.CornerRadius = UDim.new(0, 8)
    labelCorner.Parent = label
    local labelStroke = Instance.new("UIStroke")
    labelStroke.Color = Color3.fromRGB(78, 126, 104)
    labelStroke.Transparency = 0.42
    labelStroke.Thickness = 1
    labelStroke.Parent = label

    model.PrimaryPart = root
    WorldObjectService.Register(model, "Npc", npcId)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Talk"
    prompt.ObjectText = displayName
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
    prompt.Parent = root
    prompt.Triggered:Connect(function(player)
        InteractionService.Begin(player, npcId, model)
    end)
    return model
end

local function makeProvingCircle(parent)
    local origin = WORLD_ZONES.Camp + Vector3.new(74, 0, -42)
    local model = Instance.new("Model")
    model.Name = "WayfarerProvingCircle"
    model.Parent = parent

    local platform = makePart(
        model,
        "ProvingStone",
        Vector3.new(1.2, 25, 25),
        CFrame.new(origin + Vector3.new(0, 0.55, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Enum.Material.Slate,
        Color3.fromRGB(62, 78, 69)
    )
    platform.Shape = Enum.PartType.Cylinder
    platform.CanCollide = true

    local inset = makePart(
        model,
        "LumenInlay",
        Vector3.new(1.26, 15.5, 15.5),
        CFrame.new(origin + Vector3.new(0, 0.61, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Enum.Material.Neon,
        Color3.fromRGB(52, 126, 91)
    )
    inset.Shape = Enum.PartType.Cylinder
    inset.Transparency = 0.38
    inset.CanCollide = false

    local familyColors = {
        Color3.fromRGB(98, 157, 103),
        Color3.fromRGB(211, 156, 76),
        Color3.fromRGB(86, 188, 171),
        Color3.fromRGB(145, 105, 184),
        Color3.fromRGB(197, 151, 74),
    }
    for index, color in familyColors do
        local angle = math.rad(-90 + (index - 1) * 72)
        local position = origin + Vector3.new(math.cos(angle) * 15.5, 0, math.sin(angle) * 15.5)
        local stone = makePart(
            model,
            "PathStone" .. tostring(index),
            Vector3.new(3.2, 6.4, 2.1),
            CFrame.new(position + Vector3.new(0, 3.2, 0))
                * CFrame.Angles(0, -angle + math.rad(90), 0),
            Enum.Material.Slate,
            Color3.fromRGB(55, 69, 63)
        )
        stone.CanCollide = false
        local rune = makePart(
            model,
            "PathRune" .. tostring(index),
            Vector3.new(1.15, 2.5, 0.12),
            stone.CFrame * CFrame.new(0, 0.15, -1.08),
            Enum.Material.Neon,
            color
        )
        rune.CanCollide = false
    end

    local beacon = makeBall(
        model,
        "PathkeeperBeacon",
        Vector3.new(1.1, 1.1, 1.1),
        CFrame.new(origin + Vector3.new(0, 2.0, 0)),
        Enum.Material.Neon,
        Color3.fromRGB(121, 244, 183)
    )
    beacon.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(121, 244, 183)
    light.Brightness = 1.1
    light.Range = 13
    light.Parent = beacon

    return origin
end

local function makeExplorationTrigger(parent, landmarkId, position, radius)
    local trigger = Instance.new("Part")
    trigger.Name = "Explore_" .. landmarkId
    trigger.Size = Vector3.new(2, 0.4, 2)
    trigger.CFrame = CFrame.new(position + Vector3.new(0, 0.2, 0))
    trigger.Anchored = true
    trigger.CanCollide = false
    trigger.CanTouch = false
    trigger.CanQuery = false
    trigger.Transparency = 1
    trigger:SetAttribute("LandmarkId", landmarkId)
    trigger:SetAttribute("TriggerRadius", radius or 14)
    trigger.Parent = parent
    CollectionService:AddTag(trigger, "ExplorationTrigger")
    return trigger
end

local function makeWhisperrootHollow(parent)
    local origin = WORLD_ZONES.Waterfall + Vector3.new(-69, 0, -44)
    local model = Instance.new("Model")
    model.Name = "WhisperrootHollow"
    model.Parent = parent
    makeRockCluster(model, origin + Vector3.new(-8, 0, 0), 1.7, 31)
    makeRockCluster(model, origin + Vector3.new(8, 0, 0), 1.7, 32)
    makeRockCluster(model, origin + Vector3.new(0, 5.8, 2), 1.45, 33)
    makeDryBranches(model, origin + Vector3.new(-5, 0.2, 7), math.rad(24), 0.75)
    makeCrystal(model, origin + Vector3.new(0, 2.4, 9))
    makeCrystal(model, origin + Vector3.new(5, 1.9, 6))
    local cache = makePart(
        model,
        "OldWayfarerCache",
        Vector3.new(4.4, 1.3, 2.8),
        CFrame.new(origin + Vector3.new(-2, 0.75, 11)) * CFrame.Angles(0, math.rad(-18), 0),
        Enum.Material.Wood,
        Color3.fromRGB(89, 63, 42)
    )
    cache.CanCollide = true

    local cachePrompt = Instance.new("ProximityPrompt")
    cachePrompt.Name = "WayfarerCachePrompt"
    cachePrompt.ActionText = "Search"
    cachePrompt.ObjectText = "Old Wayfarer Cache"
    cachePrompt.KeyboardKeyCode = Enum.KeyCode.E
    cachePrompt.HoldDuration = 0.35
    cachePrompt.MaxActivationDistance = 9
    cachePrompt.RequiresLineOfSight = false
    cachePrompt.Parent = cache
    cachePrompt.Triggered:Connect(function(player)
        local profile = PlayerDataService.Get(player)
        if not profile then
            return
        end
        profile.World.Secrets = profile.World.Secrets or {}
        if profile.World.Secrets.whisperroot_cache == true then
            return
        end
        local added = InventoryService.Add(profile, "old_wayfinder_page", 1)
        if not added then
            return
        end
        profile.World.Secrets.whisperroot_cache = true
        QuestService.Record(profile, "Collect", "old_wayfinder_page", 1)
        PlayerDataService.NotifyChanged(player)
    end)

    for index = 1, 3 do
        local page = makePart(
            model,
            "WeatheredPage" .. index,
            Vector3.new(1.2, 0.05, 1.55),
            CFrame.new(origin + Vector3.new(-5 + index * 2.1, 1.5, 9.5 + index * 0.4))
                * CFrame.Angles(math.rad(2), math.rad(index * 23), math.rad(index * 4)),
            Enum.Material.Fabric,
            Color3.fromRGB(201, 189, 151)
        )
        page.CanCollide = false
    end
    makeExplorationTrigger(parent, "whisperroot_hollow", origin + Vector3.new(0, 0, 8), 13)
    return model
end

local function makeStoryRemnant(parent, position, yaw)
    local model = Instance.new("Model")
    model.Name = "WayfarerRemnant"
    model.Parent = parent
    local base = CFrame.new(position) * CFrame.Angles(0, yaw or 0, 0)
    local crate = makePart(
        model,
        "BrokenCrate",
        Vector3.new(3.2, 1.4, 2.5),
        base * CFrame.new(0, 0.75, 0),
        Enum.Material.Wood,
        Color3.fromRGB(92, 65, 43)
    )
    crate.CanCollide = false
    local bedroll = makePart(
        model,
        "FadedBedroll",
        Vector3.new(1.2, 0.7, 2.8),
        base * CFrame.new(2.2, 0.45, 0.6) * CFrame.Angles(0, 0, math.rad(12)),
        Enum.Material.Fabric,
        Color3.fromRGB(86, 100, 82)
    )
    bedroll.Shape = Enum.PartType.Cylinder
    bedroll.CanCollide = false
    local marker = makePart(
        model,
        "OldWaymark",
        Vector3.new(0.5, 3.2, 0.5),
        base * CFrame.new(-2.1, 1.6, -0.4),
        Enum.Material.Rock,
        Color3.fromRGB(112, 120, 114)
    )
    marker.CanCollide = false
    local rune = makePart(
        model,
        "FadedRune",
        Vector3.new(0.58, 0.58, 0.08),
        base * CFrame.new(-2.1, 2.1, -0.68) * CFrame.Angles(0, 0, math.rad(45)),
        Enum.Material.Neon,
        Color3.fromRGB(89, 180, 157)
    )
    rune.Transparency = 0.35
    rune.CanCollide = false
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
    billboard.Size = UDim2.fromOffset(340, 38)
    billboard.AlwaysOnTop = false
    billboard.MaxDistance = 90
    billboard.Parent = anchor

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 0.28
    label.BackgroundColor3 = Color3.fromRGB(14, 23, 21)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(226, 244, 230)
    label.TextStrokeTransparency = 0.45
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextWrapped = false
    label.Parent = billboard
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(84, 134, 111)
    stroke.Transparency = 0.5
    stroke.Thickness = 1
    stroke.Parent = label
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

        local function fillClearing(center, size, material)
            terrain:FillBlock(
                CFrame.new(center + Vector3.new(0, -0.62, 0)),
                Vector3.new(size.X, 2.6, size.Z),
                material
            )
        end

        local function fillTrail(a, b, width)
            local startPoint = Vector3.new(a.X, 0.28, a.Z)
            local endPoint = Vector3.new(b.X, 0.28, b.Z)
            local delta = endPoint - startPoint
            local length = delta.Magnitude
            if length < 0.1 then
                return
            end
            local midpoint = (startPoint + endPoint) * 0.5
            terrain:FillBlock(
                CFrame.lookAt(midpoint, endPoint),
                Vector3.new(width, 1.25, length + 3),
                Enum.Material.Ground
            )
        end

        fillClearing(WORLD_ZONES.Camp, Vector3.new(118, 0, 82), Enum.Material.Ground)
        fillClearing(WORLD_ZONES.Crossroads, Vector3.new(66, 0, 48), Enum.Material.Ground)
        fillClearing(WORLD_ZONES.Ruins, Vector3.new(132, 0, 106), Enum.Material.Grass)
        fillClearing(WORLD_ZONES.CombatGrove, Vector3.new(170, 0, 138), Enum.Material.Grass)
        fillClearing(WORLD_ZONES.Glowmere, Vector3.new(148, 0, 120), Enum.Material.Grass)
        fillClearing(WORLD_ZONES.Waterfall, Vector3.new(126, 0, 104), Enum.Material.Grass)
        fillClearing(WORLD_ZONES.Overlook, Vector3.new(132, 0, 94), Enum.Material.Grass)

        local trails = {
            { WORLD_ZONES.Camp + Vector3.new(46, 0, -8), Vector3.new(-182, 0, 86), 16 },
            { Vector3.new(-182, 0, 86), WORLD_ZONES.Crossroads, 15 },
            { WORLD_ZONES.Crossroads, Vector3.new(-12, 0, -18), 14 },
            { Vector3.new(-12, 0, -18), WORLD_ZONES.Ruins + Vector3.new(-34, 0, 18), 13 },
            { WORLD_ZONES.Crossroads + Vector3.new(16, 0, 8), Vector3.new(28, 0, 63), 15 },
            { Vector3.new(28, 0, 63), Vector3.new(125, 0, 79), 15 },
            { Vector3.new(125, 0, 79), WORLD_ZONES.CombatGrove + Vector3.new(-47, 0, -3), 16 },
            { WORLD_ZONES.Crossroads + Vector3.new(-20, 0, -13), Vector3.new(-144, 0, -60), 12 },
            { Vector3.new(-144, 0, -60), Vector3.new(-210, 0, -126), 12 },
            { Vector3.new(-210, 0, -126), WORLD_ZONES.Waterfall + Vector3.new(24, 0, 28), 11 },
            { WORLD_ZONES.Camp + Vector3.new(30, 0, 36), Vector3.new(-155, 0, 157), 13 },
            { Vector3.new(-155, 0, 157), Vector3.new(-62, 0, 177), 13 },
            { Vector3.new(-62, 0, 177), WORLD_ZONES.Glowmere + Vector3.new(-50, 0, 0), 13 },
            { WORLD_ZONES.Glowmere + Vector3.new(45, 0, -14), Vector3.new(122, 0, 143), 13 },
            { Vector3.new(122, 0, 143), WORLD_ZONES.CombatGrove + Vector3.new(-28, 0, 36), 14 },
            { WORLD_ZONES.Ruins + Vector3.new(25, 0, -28), Vector3.new(112, 0, -160), 12 },
            { Vector3.new(112, 0, -160), WORLD_ZONES.Overlook + Vector3.new(-20, 0, 23), 12 },
            { WORLD_ZONES.Overlook + Vector3.new(36, 0, 18), Vector3.new(245, 0, -132), 11 },
            { Vector3.new(245, 0, -132), WORLD_ZONES.CombatGrove + Vector3.new(35, 0, -43), 12 },
        }
        for _, trail in trails do
            fillTrail(trail[1], trail[2], trail[3])
        end

        -- Break the giant flat clearings into irregular, framed spaces. These
        -- low banks sit outside the main travel lanes and make paths feel cut
        -- through a forest rather than painted across a flat baseplate.
        local lowBanks = {
            { WORLD_ZONES.Camp + Vector3.new(-68, -8.5, -42), 13, Enum.Material.Grass },
            { WORLD_ZONES.Camp + Vector3.new(-60, -9.5, 43), 14, Enum.Material.Grass },
            { WORLD_ZONES.Camp + Vector3.new(4, -10, -52), 13, Enum.Material.Grass },
            { WORLD_ZONES.Camp + Vector3.new(47, -9, 44), 14, Enum.Material.Grass },
            { WORLD_ZONES.Camp + Vector3.new(63, -10, 8), 13, Enum.Material.Grass },
            { WORLD_ZONES.Crossroads + Vector3.new(-43, -9, -31), 12, Enum.Material.Grass },
            { WORLD_ZONES.Crossroads + Vector3.new(-37, -9, 32), 12, Enum.Material.Grass },
            { WORLD_ZONES.Crossroads + Vector3.new(39, -9, -29), 12, Enum.Material.Grass },
            { WORLD_ZONES.Crossroads + Vector3.new(42, -9, 29), 12, Enum.Material.Grass },
            { Vector3.new(-185, -10, 116), 12, Enum.Material.Grass },
            { Vector3.new(-152, -10, 101), 11, Enum.Material.Grass },
            { Vector3.new(-120, -10, 83), 12, Enum.Material.Grass },
            { Vector3.new(-86, -10, 66), 11, Enum.Material.Grass },
            { Vector3.new(-45, -10, 55), 11, Enum.Material.Grass },
            { Vector3.new(-5, -10, 69), 11, Enum.Material.Grass },
        }
        for _, bank in lowBanks do
            terrain:FillBall(bank[1], bank[2], bank[3])
        end

        local edgeRock = {
            { WORLD_ZONES.Camp + Vector3.new(-73, -5.8, 7), 10 },
            { WORLD_ZONES.Camp + Vector3.new(56, -6.0, -41), 9 },
            { WORLD_ZONES.Crossroads + Vector3.new(-48, -6.0, 6), 9 },
            { WORLD_ZONES.Crossroads + Vector3.new(45, -6.2, 5), 9 },
        }
        for _, rock in edgeRock do
            terrain:FillBall(rock[1], rock[2], Enum.Material.Rock)
        end

        local grassIntrusions = {
            WORLD_ZONES.Camp + Vector3.new(-56, -6.0, -31),
            WORLD_ZONES.Camp + Vector3.new(-47, -6.0, 35),
            WORLD_ZONES.Camp + Vector3.new(15, -6.0, -39),
            WORLD_ZONES.Camp + Vector3.new(45, -6.0, 30),
            WORLD_ZONES.Crossroads + Vector3.new(-28, -6.0, -22),
            WORLD_ZONES.Crossroads + Vector3.new(-25, -6.0, 21),
            WORLD_ZONES.Crossroads + Vector3.new(27, -6.0, -20),
            WORLD_ZONES.Crossroads + Vector3.new(28, -6.0, 21),
        }
        for index, intrusion in grassIntrusions do
            terrain:FillBall(intrusion, 6.5 + (index % 3) * 1.2, Enum.Material.Grass)
        end

        local perimeterRidges = {
            { Vector3.new(-425, -24, -275), 58, Enum.Material.Basalt },
            { Vector3.new(-430, -24, -125), 54, Enum.Material.Grass },
            { Vector3.new(-426, -23, 35), 57, Enum.Material.Grass },
            { Vector3.new(-420, -24, 205), 60, Enum.Material.Basalt },
            { Vector3.new(-340, -25, 335), 58, Enum.Material.Grass },
            { Vector3.new(-170, -24, 350), 60, Enum.Material.Grass },
            { Vector3.new(10, -25, 354), 62, Enum.Material.Basalt },
            { Vector3.new(195, -24, 348), 60, Enum.Material.Grass },
            { Vector3.new(355, -25, 320), 57, Enum.Material.Basalt },
            { Vector3.new(425, -24, 210), 60, Enum.Material.Grass },
            { Vector3.new(432, -24, 45), 56, Enum.Material.Basalt },
            { Vector3.new(428, -24, -125), 60, Enum.Material.Basalt },
            { Vector3.new(415, -24, -285), 58, Enum.Material.Grass },
            { Vector3.new(295, -25, -350), 62, Enum.Material.Basalt },
            { Vector3.new(105, -24, -355), 60, Enum.Material.Grass },
            { Vector3.new(-85, -24, -356), 62, Enum.Material.Basalt },
            { Vector3.new(-270, -25, -342), 60, Enum.Material.Grass },
        }
        for _, ridge in perimeterRidges do
            terrain:FillBall(ridge[1], ridge[2], ridge[3])
        end

        local interiorMasses = {
            { Vector3.new(-337, -22, 42), 32, Enum.Material.Grass },
            { Vector3.new(-338, -22, -72), 29, Enum.Material.Basalt },
            { Vector3.new(-330, -23, 244), 33, Enum.Material.Grass },
            { Vector3.new(-175, -22, 256), 31, Enum.Material.Grass },
            { Vector3.new(-55, -22, 270), 30, Enum.Material.Basalt },
            { Vector3.new(115, -22, 260), 32, Enum.Material.Grass },
            { Vector3.new(287, -22, 235), 34, Enum.Material.Grass },
            { Vector3.new(330, -22, 118), 30, Enum.Material.Basalt },
            { Vector3.new(330, -22, -42), 34, Enum.Material.Basalt },
            { Vector3.new(292, -22, -204), 31, Enum.Material.Grass },
            { Vector3.new(30, -22, -275), 32, Enum.Material.Basalt },
            { Vector3.new(-135, -22, -265), 31, Enum.Material.Grass },
            { Vector3.new(-320, -22, -212), 34, Enum.Material.Basalt },
        }
        for _, mound in interiorMasses do
            terrain:FillBall(mound[1], mound[2], mound[3])
        end

        -- Glowmere is a real water landmark instead of another grass clearing.
        terrain:FillBlock(
            CFrame.new(WORLD_ZONES.Glowmere + Vector3.new(0, -4.0, 0)),
            Vector3.new(84, 6, 61),
            Enum.Material.Rock
        )
        terrain:FillBlock(
            CFrame.new(WORLD_ZONES.Glowmere + Vector3.new(0, -1.25, 0)),
            Vector3.new(78, 3.2, 55),
            Enum.Material.Water
        )
        terrain:FillBall(WORLD_ZONES.Glowmere + Vector3.new(-27, -4, 19), 9, Enum.Material.Rock)
        terrain:FillBall(WORLD_ZONES.Glowmere + Vector3.new(24, -4, -17), 7, Enum.Material.Rock)

        -- Veilfall basin and stream carve a second, visually separate water space.
        local fallPool = WORLD_ZONES.Waterfall + Vector3.new(0, 0, 25)
        terrain:FillBlock(
            CFrame.new(fallPool + Vector3.new(0, -4.2, 0)),
            Vector3.new(74, 6, 54),
            Enum.Material.Rock
        )
        terrain:FillBlock(
            CFrame.new(fallPool + Vector3.new(0, -1.35, 0)),
            Vector3.new(66, 3.2, 46),
            Enum.Material.Water
        )
        local streamPoints = {
            fallPool + Vector3.new(28, 0, 16),
            Vector3.new(-192, 0, -116),
            Vector3.new(-157, 0, -91),
        }
        for index = 1, #streamPoints - 1 do
            local a = streamPoints[index]
            local b = streamPoints[index + 1]
            local startPoint = Vector3.new(a.X, -1.2, a.Z)
            local endPoint = Vector3.new(b.X, -1.2, b.Z)
            local length = (endPoint - startPoint).Magnitude
            terrain:FillBlock(
                CFrame.lookAt((startPoint + endPoint) * 0.5, endPoint),
                Vector3.new(9, 2.2, length + 2),
                Enum.Material.Water
            )
        end

        -- The overlook rises gently in walkable terraces rather than a single inaccessible hill.
        for step = 1, 5 do
            local offset = Vector3.new((step - 3) * 7, (step - 1) * 0.45 - 0.5, (step - 3) * -5)
            terrain:FillBlock(
                CFrame.new(WORLD_ZONES.Overlook + offset),
                Vector3.new(78 - step * 5, 1.2, 54 - step * 3),
                if step >= 4 then Enum.Material.Rock else Enum.Material.Grass
            )
        end
    end

    local foundation = makePart(
        world,
        "InvisibleFoundation",
        Vector3.new(WORLD_WIDTH, 2, WORLD_DEPTH),
        CFrame.new(0, -12, 0),
        Enum.Material.SmoothPlastic,
        Color3.new(0, 0, 0)
    )
    foundation.Transparency = 1

    local boundaryThickness = 8
    local boundaryHeight = 120
    local boundaryInset = 9
    local halfWidth = WORLD_WIDTH * 0.5 - boundaryInset
    local halfDepth = WORLD_DEPTH * 0.5 - boundaryInset
    local boundarySpecs = {
        {
            "NorthBoundary",
            Vector3.new(WORLD_WIDTH, boundaryHeight, boundaryThickness),
            CFrame.new(0, boundaryHeight * 0.5 - 4, -halfDepth),
        },
        {
            "SouthBoundary",
            Vector3.new(WORLD_WIDTH, boundaryHeight, boundaryThickness),
            CFrame.new(0, boundaryHeight * 0.5 - 4, halfDepth),
        },
        {
            "WestBoundary",
            Vector3.new(boundaryThickness, boundaryHeight, WORLD_DEPTH),
            CFrame.new(-halfWidth, boundaryHeight * 0.5 - 4, 0),
        },
        {
            "EastBoundary",
            Vector3.new(boundaryThickness, boundaryHeight, WORLD_DEPTH),
            CFrame.new(halfWidth, boundaryHeight * 0.5 - 4, 0),
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

local function placeTreeArc(
    parent,
    center,
    radiusX,
    radiusZ,
    count,
    startDegrees,
    spanDegrees,
    seed
)
    for index = 1, count do
        local alpha = if count <= 1 then 0 else (index - 1) / (count - 1)
        local angle = math.rad(startDegrees + spanDegrees * alpha)
        local wobble = math.sin((index + seed) * 2.37) * 5
        local position = center
            + Vector3.new(
                math.cos(angle) * (radiusX + wobble),
                0,
                math.sin(angle) * (radiusZ + wobble * 0.7)
            )
        local scale = 0.78 + ((index + seed) % 5) * 0.075
        makeTree(parent, position, scale, ((index + seed) % 3) + 1)
    end
end

local function dressZoneEdge(parent, center, radiusX, radiusZ, count, seed)
    for index = 1, count do
        local angle = (index - 1) * math.pi * 2 / count + seed * 0.17
        local position = center
            + Vector3.new(math.cos(angle) * radiusX, 0, math.sin(angle) * radiusZ)
        local scale = 0.62 + ((index + seed) % 4) * 0.09
        local selector = (index + seed) % 6
        if selector == 0 then
            makeBush(parent, position, scale)
        elseif selector == 1 then
            makeFern(parent, position, scale)
        elseif selector == 2 then
            makeGrassTuft(parent, position, scale)
        elseif selector == 3 then
            makeMushroomCluster(parent, position, scale * 0.8, index + seed)
        elseif selector == 4 then
            makeFlowerPatch(parent, position, scale * 0.75, index % 2 == 0)
        else
            makeFern(parent, position, scale * 0.86)
        end
    end
end

local function scatterForestPatch(parent, center, radiusX, radiusZ, count, seed)
    local goldenAngle = math.rad(137.507764)
    for index = 1, count do
        local alpha = math.sqrt(index / count)
        local angle = index * goldenAngle + seed * 0.41
        local jitterX = math.sin(index * 1.73 + seed) * 4
        local jitterZ = math.cos(index * 2.11 + seed) * 4
        local position = center
            + Vector3.new(
                math.cos(angle) * radiusX * alpha + jitterX,
                0,
                math.sin(angle) * radiusZ * alpha + jitterZ
            )
        local scale = 0.78 + ((index + seed) % 6) * 0.07
        makeTree(parent, position, scale, ((index + seed) % 3) + 1)

        if index % 2 == 0 then
            local undergrowthOffset = Vector3.new(
                math.cos(angle + 0.8) * (5 + (index % 4) * 2),
                0,
                math.sin(angle + 0.8) * (5 + (index % 4) * 2)
            )
            local selector = (index + seed) % 4
            if selector == 0 then
                makeFern(parent, position + undergrowthOffset, 0.72 + (index % 3) * 0.08)
            elseif selector == 1 then
                makeBush(parent, position + undergrowthOffset, 0.58 + (index % 3) * 0.08)
            elseif selector == 2 then
                makeGrassTuft(parent, position + undergrowthOffset, 0.68 + (index % 2) * 0.1)
            else
                makeMushroomCluster(parent, position + undergrowthOffset, 0.62, index + seed)
            end
        end
    end
end

local function makeTrailsideCluster(parent, position, yaw, seed)
    makeRockCluster(parent, position, 0.52 + (seed % 3) * 0.08, seed)
    local side = if seed % 2 == 0 then 1 else -1
    makeFern(parent, position + Vector3.new(side * 4.2, 0, 2.6), 0.72 + (seed % 3) * 0.06)
    makeGrassTuft(parent, position + Vector3.new(-side * 3.6, 0, -2.4), 0.7)
    if seed % 3 == 0 then
        makeDryBranches(parent, position + Vector3.new(side * 6.0, 0.1, -4.0), yaw, 0.55)
    elseif seed % 3 == 1 then
        makeStump(parent, position + Vector3.new(side * 5.2, 0, -3.2), 0.58, (seed % 2) + 1)
    else
        makePineRoots(parent, position + Vector3.new(side * 5.8, 0, 3.1), yaw, 0.52)
    end
end

local function makeWoodlandCluster(parent, center, seed, scale)
    scale = scale or 1
    local rotation = seed * 0.71
    local treeOffsets = {
        Vector3.new(math.cos(rotation) * 7.5, 0, math.sin(rotation) * 7.5),
        Vector3.new(math.cos(rotation + 2.05) * 9.2, 0, math.sin(rotation + 2.05) * 9.2),
        Vector3.new(math.cos(rotation + 4.2) * 6.4, 0, math.sin(rotation + 4.2) * 6.4),
    }
    for index, offset in treeOffsets do
        makeTree(
            parent,
            center + offset * scale,
            (0.82 + ((seed + index) % 4) * 0.08) * scale,
            ((seed + index) % 3) + 1
        )
    end

    makeBush(parent, center + Vector3.new(-3.2, 0, 1.8) * scale, 0.82 * scale)
    makeFern(parent, center + Vector3.new(3.8, 0, -2.7) * scale, 0.78 * scale, rotation)
    makeGrassTuft(parent, center + Vector3.new(1.4, 0, 4.2) * scale, 0.78 * scale)
    if seed % 2 == 0 then
        makeFlowerPatch(
            parent,
            center + Vector3.new(-4.7, 0, -3.8) * scale,
            0.68 * scale,
            seed % 4 == 0
        )
    else
        makeMushroomCluster(parent, center + Vector3.new(-4.2, 0, -3.4) * scale, 0.7 * scale, seed)
    end
    if seed % 3 == 0 then
        makeFallenLog(
            parent,
            center + Vector3.new(5.8, 0.15, 4.8) * scale,
            rotation + 0.45,
            0.62 * scale,
            (seed % 2) + 1
        )
    elseif seed % 3 == 1 then
        makePineRoots(parent, center + Vector3.new(5.5, 0, 4.0) * scale, rotation, 0.58 * scale)
    else
        makeRockCluster(parent, center + Vector3.new(5.6, 0, 4.1) * scale, 0.5 * scale, seed)
    end
end

local function decorate(world)
    -- A forest belt frames the whole map. Major clearings stay readable instead of being carpeted with props.
    placeTreeArc(world, Vector3.zero, 365, 305, 44, 0, 360, 2)
    placeTreeArc(world, WORLD_ZONES.Camp, 78, 59, 22, 104, 262, 7)
    placeTreeArc(world, WORLD_ZONES.Crossroads, 57, 44, 16, 18, 320, 9)
    placeTreeArc(world, WORLD_ZONES.Ruins, 78, 65, 12, -45, 285, 11)
    placeTreeArc(world, WORLD_ZONES.CombatGrove, 96, 78, 15, 35, 285, 17)
    placeTreeArc(world, WORLD_ZONES.Glowmere, 91, 72, 12, 5, 320, 23)
    placeTreeArc(world, WORLD_ZONES.Waterfall, 82, 68, 11, 100, 250, 31)
    placeTreeArc(world, WORLD_ZONES.Overlook, 82, 62, 10, 10, 315, 37)

    dressZoneEdge(world, WORLD_ZONES.Camp, 61, 44, 20, 3)
    dressZoneEdge(world, WORLD_ZONES.Crossroads, 42, 31, 16, 7)
    dressZoneEdge(world, WORLD_ZONES.Ruins, 61, 48, 12, 11)
    dressZoneEdge(world, WORLD_ZONES.CombatGrove, 72, 58, 14, 15)
    dressZoneEdge(world, WORLD_ZONES.Glowmere, 67, 52, 15, 19)
    dressZoneEdge(world, WORLD_ZONES.Waterfall, 61, 48, 13, 23)
    dressZoneEdge(world, WORLD_ZONES.Overlook, 60, 44, 10, 29)

    -- Fill the spaces between destinations with continuous forest instead of open grass fields.
    local forestPatches = {
        { Vector3.new(-365, 0, 140), 45, 38, 12, 41 },
        { Vector3.new(-350, 0, 15), 48, 42, 12, 43 },
        { Vector3.new(-335, 0, -110), 48, 40, 11, 47 },
        { Vector3.new(-310, 0, 245), 50, 42, 12, 53 },
        { Vector3.new(-215, 0, 250), 52, 42, 13, 59 },
        { Vector3.new(-115, 0, 255), 50, 40, 12, 61 },
        { Vector3.new(75, 0, 275), 55, 42, 13, 67 },
        { Vector3.new(205, 0, 250), 50, 40, 12, 71 },
        { Vector3.new(325, 0, 210), 48, 42, 12, 73 },
        { Vector3.new(345, 0, 85), 46, 38, 11, 79 },
        { Vector3.new(335, 0, -65), 48, 40, 12, 83 },
        { Vector3.new(300, 0, -210), 54, 42, 13, 89 },
        { Vector3.new(205, 0, -300), 50, 40, 12, 97 },
        { Vector3.new(70, 0, -305), 52, 42, 13, 101 },
        { Vector3.new(-70, 0, -300), 52, 44, 13, 103 },
        { Vector3.new(-205, 0, -285), 52, 42, 13, 107 },
        { Vector3.new(-330, 0, -225), 50, 42, 12, 109 },
        { Vector3.new(-178, 0, -22), 34, 28, 9, 113 },
        { Vector3.new(-18, 0, -108), 36, 30, 10, 127 },
        { Vector3.new(112, 0, 20), 34, 28, 9, 131 },
        { Vector3.new(112, 0, 174), 36, 30, 10, 137 },
    }
    for _, patch in forestPatches do
        scatterForestPatch(world, patch[1], patch[2], patch[3], patch[4], patch[5])
    end

    -- Dense, authored clumps frame the opening route and create alternating
    -- compression/release instead of a uniformly sparse grass field.
    local openingClusters = {
        { WORLD_ZONES.Camp + Vector3.new(-66, 0, -25), 201, 1.05 },
        { WORLD_ZONES.Camp + Vector3.new(-57, 0, 42), 203, 0.96 },
        { WORLD_ZONES.Camp + Vector3.new(-16, 0, -55), 205, 0.92 },
        { WORLD_ZONES.Camp + Vector3.new(24, 0, 53), 207, 0.9 },
        { WORLD_ZONES.Camp + Vector3.new(67, 0, 21), 209, 0.88 },
        { Vector3.new(-208, 0, 133), 211, 0.88 },
        { Vector3.new(-184, 0, 67), 213, 0.92 },
        { Vector3.new(-154, 0, 119), 215, 0.86 },
        { Vector3.new(-131, 0, 50), 217, 0.94 },
        { Vector3.new(-111, 0, 88), 219, 0.9 },
        { WORLD_ZONES.Crossroads + Vector3.new(-44, 0, 31), 221, 0.9 },
        { WORLD_ZONES.Crossroads + Vector3.new(-35, 0, -34), 223, 0.95 },
        { WORLD_ZONES.Crossroads + Vector3.new(38, 0, -32), 225, 0.9 },
        { WORLD_ZONES.Crossroads + Vector3.new(44, 0, 29), 227, 0.94 },
    }
    for _, cluster in openingClusters do
        makeWoodlandCluster(world, cluster[1], cluster[2], cluster[3])
    end

    local trailClusters = {
        { Vector3.new(-207, 0, 69), math.rad(25), 11 },
        { Vector3.new(-169, 0, 113), math.rad(-31), 12 },
        { Vector3.new(-126, 0, 48), math.rad(54), 13 },
        { Vector3.new(-51, 0, 11), math.rad(-12), 14 },
        { Vector3.new(-17, 0, 8), math.rad(61), 15 },
        { Vector3.new(22, 0, -23), math.rad(-46), 16 },
        { Vector3.new(55, 0, -59), math.rad(24), 17 },
        { Vector3.new(116, 0, -70), math.rad(-68), 18 },
        { Vector3.new(151, 0, 55), math.rad(37), 19 },
        { Vector3.new(182, 0, 117), math.rad(-28), 20 },
        { Vector3.new(120, 0, 133), math.rad(48), 21 },
        { Vector3.new(72, 0, 158), math.rad(-53), 22 },
        { Vector3.new(-47, 0, 148), math.rad(17), 23 },
        { Vector3.new(-113, 0, 132), math.rad(-36), 24 },
        { Vector3.new(-151, 0, -49), math.rad(62), 25 },
        { Vector3.new(-191, 0, -96), math.rad(-41), 26 },
        { Vector3.new(-231, 0, -132), math.rad(26), 27 },
        { Vector3.new(116, 0, -144), math.rad(-52), 28 },
        { Vector3.new(148, 0, -181), math.rad(31), 29 },
        { Vector3.new(207, 0, -160), math.rad(-22), 30 },
        { Vector3.new(252, 0, -94), math.rad(57), 31 },
        { Vector3.new(268, 0, 18), math.rad(-33), 32 },
    }
    for _, cluster in trailClusters do
        makeTrailsideCluster(world, cluster[1], cluster[2], cluster[3])
    end

    local routeBeacons = {
        { Vector3.new(-187, 0, 93), math.rad(-54), 0.58 },
        { Vector3.new(-131, 0, 61), math.rad(-61), 0.62 },
        { Vector3.new(-24, 0, -7), math.rad(-42), 0.58 },
        { Vector3.new(53, 0, 66), math.rad(-78), 0.6 },
        { Vector3.new(139, 0, 79), math.rad(-84), 0.64 },
        { Vector3.new(-171, 0, -88), math.rad(44), 0.58 },
        { Vector3.new(-85, 0, 169), math.rad(-88), 0.56 },
        { Vector3.new(126, 0, -166), math.rad(26), 0.62 },
    }
    for index, beacon in routeBeacons do
        makeWaystone(world, beacon[1], beacon[2], beacon[3])
        if index % 2 == 0 then
            local side = if index % 4 == 0 then 1 else -1
            local localFrame = CFrame.new(beacon[1]) * CFrame.Angles(0, beacon[2], 0)
            local lampPosition = (localFrame * CFrame.new(8.5 * side, 0, 0)).Position
            local lampYaw = beacon[2] + if side > 0 then math.pi else 0
            makeLantern(world, lampPosition, lampYaw)
        end
    end

    -- Wayfarer Camp is now one district in the world, not the world itself.
    makeCampfire(world, WORLD_ZONES.Camp + Vector3.new(10, 0, -3))
    makeTent(world, WORLD_ZONES.Camp + Vector3.new(-28, 0.2, -23), math.rad(25))
    makeTent(world, WORLD_ZONES.Camp + Vector3.new(-31, 0.2, 28), math.rad(-20))
    makeCampBench(world, WORLD_ZONES.Camp + Vector3.new(12, 0, -14), math.rad(7))
    makeCampBench(world, WORLD_ZONES.Camp + Vector3.new(24, 0, 8), math.rad(78))
    makeMapTable(world, WORLD_ZONES.Camp + Vector3.new(-10, 0, 9), math.rad(10))
    makeSupplyStack(world, WORLD_ZONES.Camp + Vector3.new(-43, 0, 3), math.rad(-8))
    makeSupplyStack(world, WORLD_ZONES.Camp + Vector3.new(-21, 0, 43), math.rad(18))
    makeCampBanner(world, WORLD_ZONES.Camp + Vector3.new(-9, 0, 51), math.rad(3))
    makeSignpost(world, WORLD_ZONES.Camp + Vector3.new(55, 0, -31), math.rad(-56))
    for _, offset in
        {
            { Vector3.new(38, 0, -29), math.rad(132) },
            { Vector3.new(47, 0, 4), math.rad(-52) },
            { Vector3.new(-9, 0, 43), math.rad(-88) },
            { Vector3.new(-48, 0, -30), math.rad(38) },
        }
    do
        makeLantern(world, WORLD_ZONES.Camp + offset[1], offset[2])
    end
    makeTent(world, WORLD_ZONES.Camp + Vector3.new(-55, 0.2, 3), math.rad(69))
    makeCampBench(world, WORLD_ZONES.Camp + Vector3.new(47, 0, -18), math.rad(-18))
    makeWaystone(world, WORLD_ZONES.Camp + Vector3.new(51, 0, 32), math.rad(33), 0.68)
    makeFallenLog(world, WORLD_ZONES.Camp + Vector3.new(51, 0.2, 45), math.rad(-29), 0.66, 1)
    makeMossyRockSet(world, WORLD_ZONES.Camp + Vector3.new(-62, 0, 34), math.rad(18), 0.72)
    makePineRoots(world, WORLD_ZONES.Camp + Vector3.new(61, 0, 36), math.rad(-31), 0.7)

    -- Lumenwood Crossroads establishes the main navigation fork.
    makeSignpost(world, WORLD_ZONES.Crossroads + Vector3.new(-18, 0, -2), math.rad(-82))
    makeWaystone(world, WORLD_ZONES.Crossroads + Vector3.new(16, 0, -14), math.rad(18), 0.82)
    makeWaystone(world, WORLD_ZONES.Crossroads + Vector3.new(-18, 0, 12), math.rad(-38), 0.74)
    makeLantern(world, WORLD_ZONES.Crossroads + Vector3.new(-31, 0, -22), math.rad(26))
    makeLantern(world, WORLD_ZONES.Crossroads + Vector3.new(31, 0, 23), math.rad(-154))
    makeRockCluster(world, WORLD_ZONES.Crossroads + Vector3.new(31, 0, -26), 0.65, 12)
    makeCampBench(world, WORLD_ZONES.Crossroads + Vector3.new(7, 0, 28), math.rad(9))
    makeSupplyStack(world, WORLD_ZONES.Crossroads + Vector3.new(-34, 0, 25), math.rad(-17))
    makeCampfire(world, WORLD_ZONES.Crossroads + Vector3.new(24, 0, 31))
    makeStump(world, WORLD_ZONES.Crossroads + Vector3.new(-37, 0, -23), 0.64, 2)
    makeFallenLog(world, WORLD_ZONES.Crossroads + Vector3.new(38, 0.2, -34), math.rad(22), 0.68, 2)
    makeMossyRockSet(world, WORLD_ZONES.Crossroads + Vector3.new(-42, 0, 34), math.rad(-18), 0.72)
    makeFlowerPatch(world, WORLD_ZONES.Crossroads + Vector3.new(35, 0, 31), 0.9, true)

    -- Veilfall is a rocky wet forest with a basin, stream, deadwood, and cliff dressing.
    makeWaterfall(world, WORLD_ZONES.Waterfall)
    makeRockFace(world, WORLD_ZONES.Waterfall + Vector3.new(-31, 0, -10), math.rad(18), 1.0)
    makeRockFace(world, WORLD_ZONES.Waterfall + Vector3.new(34, 0, -5), math.rad(-22), 0.92)
    makeMossyRockSet(world, WORLD_ZONES.Waterfall + Vector3.new(-29, 0, 39), math.rad(27), 1.0)
    makeMossyRockSet(world, WORLD_ZONES.Waterfall + Vector3.new(30, 0, 41), math.rad(-35), 0.88)
    makeFallenLog(world, WORLD_ZONES.Waterfall + Vector3.new(41, 0.2, -36), math.rad(61), 0.9, 2)
    makePineRoots(world, WORLD_ZONES.Waterfall + Vector3.new(-45, 0, 27), math.rad(-24), 0.82)
    for index, offset in
        {
            Vector3.new(-23, 0, 43),
            Vector3.new(-9, 0, 48),
            Vector3.new(15, 0, 46),
            Vector3.new(31, 0, 35),
        }
    do
        makeCattailCluster(world, WORLD_ZONES.Waterfall + offset, 0.82 + index * 0.03, index)
    end
    makeFireflyCluster(world, WORLD_ZONES.Waterfall + Vector3.new(-24, 0, 27))
    makeFireflyCluster(world, WORLD_ZONES.Waterfall + Vector3.new(29, 0, 18))
    makeCampBench(world, WORLD_ZONES.Waterfall + Vector3.new(49, 0, 17), math.rad(-71))
    makeLantern(world, WORLD_ZONES.Waterfall + Vector3.new(43, 0, 28))
    makeSupplyStack(world, WORLD_ZONES.Waterfall + Vector3.new(-48, 0, -28), math.rad(22))

    -- Glowmere is a calmer exploration landmark with bridge, reeds, crystals, and fireflies.
    makeBridge(world, WORLD_ZONES.Glowmere + Vector3.new(-8, 0.2, 0), math.rad(2), 60, 6.5)
    makeWaystone(world, WORLD_ZONES.Glowmere + Vector3.new(-48, 0, -24), math.rad(-56), 0.75)
    makeMossyRockSet(world, WORLD_ZONES.Glowmere + Vector3.new(45, 0, -26), math.rad(33), 0.9)
    makeFallenLog(world, WORLD_ZONES.Glowmere + Vector3.new(39, 0.2, 33), math.rad(-38), 0.82, 1)
    for index, offset in
        {
            Vector3.new(-34, 0, -21),
            Vector3.new(-39, 0, 10),
            Vector3.new(-25, 0, 27),
            Vector3.new(24, 0, 27),
            Vector3.new(38, 0, 11),
            Vector3.new(35, 0, -20),
        }
    do
        makeCattailCluster(
            world,
            WORLD_ZONES.Glowmere + offset,
            0.75 + (index % 3) * 0.08,
            index + 10
        )
    end
    makeCrystal(world, WORLD_ZONES.Glowmere + Vector3.new(-28, 2.1, 9))
    makeCrystal(world, WORLD_ZONES.Glowmere + Vector3.new(31, 2.1, -6))
    makeFireflyCluster(world, WORLD_ZONES.Glowmere + Vector3.new(-18, 0, -30))
    makeFireflyCluster(world, WORLD_ZONES.Glowmere + Vector3.new(25, 0, 24))
    makeCampBench(world, WORLD_ZONES.Glowmere + Vector3.new(-52, 0, 31), math.rad(31))
    makeCampBench(world, WORLD_ZONES.Glowmere + Vector3.new(48, 0, 27), math.rad(-27))
    makeLantern(world, WORLD_ZONES.Glowmere + Vector3.new(-49, 0, 20))
    makeLantern(world, WORLD_ZONES.Glowmere + Vector3.new(49, 0, 18))
    makeSignpost(world, WORLD_ZONES.Glowmere + Vector3.new(-57, 0, -38), math.rad(36))

    -- The Shattered Arch is now a destination in its own clearing.
    makeRuins(world, WORLD_ZONES.Ruins)
    makeRockFace(world, WORLD_ZONES.Ruins + Vector3.new(57, 0, -37), math.rad(-67), 0.78)
    makeMossyRockSet(world, WORLD_ZONES.Ruins + Vector3.new(-51, 0, 31), math.rad(28), 0.9)
    makeDryBranches(world, WORLD_ZONES.Ruins + Vector3.new(37, 0.1, 34), math.rad(-31), 0.8)
    makeStump(world, WORLD_ZONES.Ruins + Vector3.new(-39, 0, -33), 0.82, 2)
    makeWaystone(world, WORLD_ZONES.Ruins + Vector3.new(-46, 0, -3), math.rad(76), 0.72)
    makeWaystone(world, WORLD_ZONES.Ruins + Vector3.new(46, 0, 21), math.rad(-66), 0.64)
    makeFireflyCluster(world, WORLD_ZONES.Ruins + Vector3.new(-27, 0, 18))
    makeCampBench(world, WORLD_ZONES.Ruins + Vector3.new(-48, 0, 42), math.rad(28))
    makeLantern(world, WORLD_ZONES.Ruins + Vector3.new(-43, 0, 35))

    -- Mossglen is a large combat arena with space around enemy spawns.
    makeCombatGrove(world, WORLD_ZONES.CombatGrove)
    makeMossyRockSet(world, WORLD_ZONES.CombatGrove + Vector3.new(-60, 0, -39), math.rad(21), 0.92)
    makeMossyRockSet(world, WORLD_ZONES.CombatGrove + Vector3.new(61, 0, 31), math.rad(-44), 0.86)
    makeFallenLog(world, WORLD_ZONES.CombatGrove + Vector3.new(-55, 0.2, 41), math.rad(48), 0.84, 2)
    makeStump(world, WORLD_ZONES.CombatGrove + Vector3.new(57, 0, -34), 0.78, 1)
    makeFireflyCluster(world, WORLD_ZONES.CombatGrove + Vector3.new(0, 0, 47))
    makeCampBench(world, WORLD_ZONES.CombatGrove + Vector3.new(-67, 0, 11), math.rad(82))
    makeCampBench(world, WORLD_ZONES.CombatGrove + Vector3.new(66, 0, 6), math.rad(-81))
    makeLantern(world, WORLD_ZONES.CombatGrove + Vector3.new(-58, 0, -24))
    makeLantern(world, WORLD_ZONES.CombatGrove + Vector3.new(58, 0, -24))
    makeSignpost(world, WORLD_ZONES.CombatGrove + Vector3.new(-47, 0, -51), math.rad(67))

    -- Sunmoss Overlook finishes the northern loop with large silhouettes instead of another flat clearing.
    makeRockSpire(world, WORLD_ZONES.Overlook + Vector3.new(-31, 0, 8), 1.15)
    makeRockSpire(world, WORLD_ZONES.Overlook + Vector3.new(35, 0, -8), 0.94)
    makeRockFace(world, WORLD_ZONES.Overlook + Vector3.new(0, 0, -39), math.rad(178), 0.9)
    makeWaystone(world, WORLD_ZONES.Overlook + Vector3.new(-5, 2.2, 19), math.rad(8), 0.86)
    makeCrystal(world, WORLD_ZONES.Overlook + Vector3.new(20, 5.0, 12))
    makeDryBranches(world, WORLD_ZONES.Overlook + Vector3.new(-46, 0.1, -22), math.rad(56), 0.9)
    makeCampBench(world, WORLD_ZONES.Overlook + Vector3.new(-7, 2.1, 31), math.rad(176))
    makeLantern(world, WORLD_ZONES.Overlook + Vector3.new(-21, 1.5, 24))
    makeSupplyStack(world, WORLD_ZONES.Overlook + Vector3.new(37, 0, 31), math.rad(-23))
    makeSignpost(world, WORLD_ZONES.Overlook + Vector3.new(-48, 0, 28), math.rad(54))

    -- The imported forest kit is used between destinations rather than stacked in one location.
    for _, entry in
        {
            { Vector3.new(-175, 0, 121), math.rad(25), 0.8 },
            { Vector3.new(-128, 0, 75), math.rad(-42), 0.76 },
            { Vector3.new(-35, 0, 72), math.rad(63), 0.82 },
            { Vector3.new(58, 0, 72), math.rad(-14), 0.78 },
            { Vector3.new(138, 0, 123), math.rad(37), 0.84 },
            { Vector3.new(166, 0, -37), math.rad(-58), 0.82 },
            { Vector3.new(19, 0, -166), math.rad(24), 0.86 },
            { Vector3.new(-112, 0, -149), math.rad(-36), 0.8 },
            { Vector3.new(-206, 0, -63), math.rad(72), 0.82 },
        }
    do
        makeDryBranches(world, entry[1], entry[2], entry[3])
    end

    for _, entry in
        {
            { Vector3.new(-157, 0, 109), math.rad(-31), 0.9 },
            { Vector3.new(-101, 0, 111), math.rad(43), 0.82 },
            { Vector3.new(-6, 0, 89), math.rad(17), 0.86 },
            { Vector3.new(91, 0, 125), math.rad(-44), 0.92 },
            { Vector3.new(160, 0, -84), math.rad(28), 0.88 },
            { Vector3.new(31, 0, -139), math.rad(-62), 0.9 },
            { Vector3.new(-124, 0, -118), math.rad(47), 0.85 },
        }
    do
        makeMossyRockSet(world, entry[1], entry[2], entry[3])
    end

    makeTrailStones(world)
end

local function makeMonsterSpawnTrigger(world, name, position, config)
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
    trigger.Parent = world
    CollectionService:AddTag(trigger, "MonsterSpawnTrigger")
    return trigger
end

local function makeSpawn(world)
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "LumenreachSpawn"
    spawn.Size = Vector3.new(8, 1, 8)
    spawn.CFrame = CFrame.new(WORLD_ZONES.Camp + Vector3.new(-48, 4, 31))
        * CFrame.Angles(0, math.rad(128), 0)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Material = Enum.Material.Slate
    spawn.Color = Color3.fromRGB(77, 96, 87)
    spawn.Transparency = 0.15
    spawn.Parent = world
    WorldTravelService.RegisterSpawn("lumenreach_start", spawn)
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
    makeGuide(world, WORLD_ZONES.Camp + Vector3.new(31, 0, 8), math.rad(102))
    makeCampNpc(
        world,
        "camp_quartermaster",
        "Orin · Quartermaster",
        WORLD_ZONES.Camp + Vector3.new(-5, 0, 24),
        math.rad(156),
        { Cloth = Color3.fromRGB(105, 83, 58), Accent = Color3.fromRGB(154, 115, 68) },
        "Quartermaster"
    )
    makeCampNpc(
        world,
        "moss_scout",
        "Tovin · Mossglen Scout",
        WORLD_ZONES.Camp + Vector3.new(48, 0, 31),
        math.rad(-128),
        { Cloth = Color3.fromRGB(56, 84, 65), Accent = Color3.fromRGB(86, 126, 79) },
        "Scout"
    )
    makeCampNpc(
        world,
        "archive_keeper",
        "Maela · Archive Keeper",
        WORLD_ZONES.Camp + Vector3.new(-32, 0, -18),
        math.rad(34),
        { Cloth = Color3.fromRGB(67, 65, 92), Accent = Color3.fromRGB(132, 104, 157) },
        "Archivist"
    )
    makeCampNpc(
        world,
        "path_mentor",
        "Seren · Pathkeeper",
        WORLD_ZONES.Camp + Vector3.new(24, 0, -28),
        math.rad(18),
        { Cloth = Color3.fromRGB(51, 74, 65), Accent = Color3.fromRGB(87, 151, 116) },
        "Mentor"
    )
    local provingCircleOrigin = makeProvingCircle(world)

    makeStoryRemnant(world, WORLD_ZONES.Crossroads + Vector3.new(28, 0, -26), math.rad(26))
    makeStoryRemnant(world, WORLD_ZONES.Ruins + Vector3.new(-34, 0, -42), math.rad(-41))
    makeStoryRemnant(world, WORLD_ZONES.Overlook + Vector3.new(46, 2.0, 12), math.rad(79))
    makeWhisperrootHollow(world)

    makeLandmarkLabel(world, WORLD_ZONES.Camp + Vector3.new(8, 15, 4), "LUMENREACH WAYFARER CAMP")
    makeLandmarkLabel(world, provingCircleOrigin + Vector3.new(0, 11, 0), "WAYFARER PROVING CIRCLE")
    makeLandmarkLabel(world, WORLD_ZONES.Crossroads + Vector3.new(0, 11, 0), "LUMENWOOD CROSSROADS")
    makeLandmarkLabel(
        world,
        WORLD_ZONES.CombatGrove + Vector3.new(0, 13, 3),
        "MOSSGLEN COMBAT GROVE"
    )
    makeLandmarkLabel(world, WORLD_ZONES.Ruins + Vector3.new(0, 21, -2), "SHATTERED LUMEN ARCH")
    makeLandmarkLabel(world, WORLD_ZONES.Waterfall + Vector3.new(0, 31, 4), "VEILFALL CASCADE")
    makeLandmarkLabel(world, WORLD_ZONES.Glowmere + Vector3.new(0, 11, 0), "GLOWMERE POOL")
    makeLandmarkLabel(world, WORLD_ZONES.Overlook + Vector3.new(0, 19, 0), "SUNMOSS OVERLOOK")

    makeExplorationTrigger(world, "lumenwood_crossroads", WORLD_ZONES.Crossroads, 17)
    makeExplorationTrigger(world, "wayfarer_proving_circle", provingCircleOrigin, 15)
    makeExplorationTrigger(world, "glowmere_pool", WORLD_ZONES.Glowmere, 22)
    makeExplorationTrigger(world, "shattered_lumen_arch", WORLD_ZONES.Ruins, 22)
    makeExplorationTrigger(
        world,
        "veilfall_cascade",
        WORLD_ZONES.Waterfall + Vector3.new(0, 0, 20),
        22
    )
    makeExplorationTrigger(world, "sunmoss_overlook", WORLD_ZONES.Overlook, 20)

    EnemySpawnerService.Spawn("training_dummy", WORLD_ZONES.Camp + Vector3.new(51, 4, -7), world)

    makeMonsterSpawnTrigger(
        world,
        "LumenwoodMosslings",
        WORLD_ZONES.Crossroads + Vector3.new(-27, 0, -21),
        {
            MonsterType = "LumenMossling",
            SpawnAmount = 4,
            TriggerRadius = 25,
            SpawnRadius = 12,
            MaxAliveMonster = 4,
            SpawnDelay = 0.34,
            RespawnTime = 18,
        }
    )
    makeMonsterSpawnTrigger(
        world,
        "ShatteredArchSkeletons",
        WORLD_ZONES.Ruins + Vector3.new(-7, 0, 24),
        {
            MonsterType = "Skeleton",
            SpawnAmount = 3,
            TriggerRadius = 30,
            SpawnRadius = 13,
            MaxAliveMonster = 3,
            SpawnDelay = 0.28,
            RespawnTime = 30,
        }
    )
    makeMonsterSpawnTrigger(
        world,
        "GlowmereSlimes",
        WORLD_ZONES.Glowmere + Vector3.new(39, 0, -20),
        {
            MonsterType = "Slime",
            SpawnAmount = 3,
            TriggerRadius = 27,
            SpawnRadius = 12,
            MaxAliveMonster = 3,
            SpawnDelay = 0.42,
            RespawnTime = 32,
        }
    )
    makeMonsterSpawnTrigger(
        world,
        "MossglenRidgebeaks",
        WORLD_ZONES.CombatGrove + Vector3.new(-8, 0, -18),
        {
            MonsterType = "PecoPeco",
            SpawnAmount = 3,
            TriggerRadius = 34,
            SpawnRadius = 16,
            MaxAliveMonster = 3,
            SpawnDelay = 0.2,
            RespawnTime = 30,
        }
    )
    makeMonsterSpawnTrigger(world, "BramblebackTrail", Vector3.new(118, 0, 121), {
        MonsterType = "Brambleback",
        SpawnAmount = 3,
        TriggerRadius = 31,
        SpawnRadius = 15,
        MaxAliveMonster = 3,
        SpawnDelay = 0.32,
        RespawnTime = 35,
    })
    makeMonsterSpawnTrigger(
        world,
        "VeilfallWisps",
        WORLD_ZONES.Waterfall + Vector3.new(31, 0, 12),
        {
            MonsterType = "LumenWisp",
            SpawnAmount = 3,
            TriggerRadius = 29,
            SpawnRadius = 14,
            MaxAliveMonster = 3,
            SpawnDelay = 0.24,
            RespawnTime = 33,
        }
    )
    makeMonsterSpawnTrigger(
        world,
        "GraveboneCaptainRare",
        WORLD_ZONES.Ruins + Vector3.new(33, 0, -29),
        {
            MonsterType = "GraveboneCaptain",
            SpawnAmount = 1,
            TriggerRadius = 24,
            SpawnRadius = 6,
            MaxAliveMonster = 1,
            SpawnDelay = 0,
            RespawnTime = 80,
        }
    )
    makeMonsterSpawnTrigger(
        world,
        "RoyalGlowcapRare",
        WORLD_ZONES.Glowmere + Vector3.new(-32, 0, 29),
        {
            MonsterType = "RoyalGlowcap",
            SpawnAmount = 1,
            TriggerRadius = 22,
            SpawnRadius = 6,
            MaxAliveMonster = 1,
            SpawnDelay = 0,
            RespawnTime = 85,
        }
    )
    makeMonsterSpawnTrigger(
        world,
        "MosswardenFieldBoss",
        WORLD_ZONES.CombatGrove + Vector3.new(32, 0, 34),
        {
            MonsterType = "Mosswarden",
            SpawnAmount = 1,
            TriggerRadius = 38,
            SpawnRadius = 7,
            MaxAliveMonster = 1,
            SpawnDelay = 0,
            RespawnTime = 180,
        }
    )
end

return LumenreachWorldService
