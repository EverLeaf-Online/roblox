local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local EnemySpawnerService = require(script.Parent.EnemySpawnerService)
local EnvironmentPrefabService = require(script.Parent.EnvironmentPrefabService)
local InteractionService = require(script.Parent.InteractionService)
local InventoryService = require(script.Parent.InventoryService)
local PBRMaterialService = require(script.Parent.PBRMaterialService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local ProfileTransaction = require(ReplicatedStorage.Shared.Logic.ProfileTransaction)
local QuestService = require(script.Parent.QuestService)
local StylizedNpcFactory = require(script.Parent.StylizedNpcFactory)
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
    -- West basin / opening chapter.
    Camp = Vector3.new(-325, 0, 190),
    Crossroads = Vector3.new(-175, 4, 78),
    Waterfall = Vector3.new(-305, -4, -165),
    Glowmere = Vector3.new(-62, 0, 270),

    -- East side, reached across the Lumen Gorge bridge.
    Ruins = Vector3.new(125, 3, -72),
    CombatGrove = Vector3.new(270, 1, 128),
    Overlook = Vector3.new(285, 12, -238),
})

-- Opening progression is now a west-basin climb into a raised saddle. It is
-- deliberately not aligned with the old flat west->east road.
local OPENING_ROUTE_POINTS = table.freeze({
    WORLD_ZONES.Camp + Vector3.new(38, 0, -5),
    Vector3.new(-281, 0.5, 169),
    Vector3.new(-260, 1.0, 146),
    Vector3.new(-241, 1.4, 118),
    Vector3.new(-219, 2.0, 97),
    Vector3.new(-198, 3.0, 85),
    WORLD_ZONES.Crossroads + Vector3.new(-8, 0, 4),
    WORLD_ZONES.Crossroads,
})

-- Advancement training sits south of Camp in its own wooded pocket instead of
-- sharing the primary navigation sightline.
local PROVING_CIRCLE_ORIGIN = WORLD_ZONES.Camp + Vector3.new(10, 0, -92)

-- Decorative generation runs before authored encounters are registered. Keep the
-- actual combat footprints free of trees, deadfall, roots, and large rocks so
-- player-height fights remain readable even as the surrounding forest gets denser.
local PROTECTED_GAMEPLAY_CLEARINGS = table.freeze({
    table.freeze({
        Id = "arrival_spawn",
        Center = WORLD_ZONES.Camp + Vector3.new(-31, 0, 19),
        Radius = 9.5,
    }),
    table.freeze({
        Id = "training_dummy",
        Center = WORLD_ZONES.Camp + Vector3.new(31, 0, -5),
        Radius = 8.5,
    }),
    table.freeze({ Id = "proving_circle", Center = PROVING_CIRCLE_ORIGIN, Radius = 18.5 }),
    table.freeze({
        Id = "proving_entrance",
        Center = PROVING_CIRCLE_ORIGIN + Vector3.new(0, 0, 17),
        Radius = 10.5,
    }),
    table.freeze({ Id = "mossling_hollow", Center = Vector3.new(-226, 1.5, 123), Radius = 15.5 }),
    table.freeze({
        Id = "shattered_arch",
        Center = WORLD_ZONES.Ruins + Vector3.new(-7, 0, 24),
        Radius = 16.5,
    }),
    table.freeze({
        Id = "glowmere_slimes",
        Center = WORLD_ZONES.Glowmere + Vector3.new(39, 0, -20),
        Radius = 15.5,
    }),
    table.freeze({
        Id = "mossglen_ridgebeaks",
        Center = WORLD_ZONES.CombatGrove + Vector3.new(-8, 0, -18),
        Radius = 18.0,
    }),
    table.freeze({ Id = "brambleback_trail", Center = Vector3.new(118, 0, 121), Radius = 17.0 }),
    table.freeze({
        Id = "veilfall_wisps",
        Center = WORLD_ZONES.Waterfall + Vector3.new(31, 0, 12),
        Radius = 16.0,
    }),
    table.freeze({
        Id = "gravebone_captain",
        Center = WORLD_ZONES.Ruins + Vector3.new(33, 0, -29),
        Radius = 10.5,
    }),
    table.freeze({
        Id = "royal_glowcap",
        Center = WORLD_ZONES.Glowmere + Vector3.new(-32, 0, 29),
        Radius = 10.5,
    }),
    table.freeze({
        Id = "mosswarden",
        Center = WORLD_ZONES.CombatGrove + Vector3.new(32, 0, 34),
        Radius = 23.0,
    }),
})
local PROVING_SPUR_POINTS = table.freeze({
    WORLD_ZONES.Camp + Vector3.new(2, 0, -31),
    WORLD_ZONES.Camp + Vector3.new(-3, 0, -54),
    PROVING_CIRCLE_ORIGIN + Vector3.new(0, 0, 20),
    PROVING_CIRCLE_ORIGIN,
})

local GORGE_POINTS = table.freeze({
    WORLD_ZONES.Glowmere + Vector3.new(20, 0, -20),
    Vector3.new(-35, 0, 205),
    Vector3.new(-24, 0, 142),
    Vector3.new(-13, 0, 84),
    Vector3.new(-6, 0, 46),
    Vector3.new(-18, 0, -12),
    Vector3.new(-70, 0, -76),
    Vector3.new(-154, -1, -124),
    WORLD_ZONES.Waterfall + Vector3.new(28, 0, 30),
})

local BRIDGE_WEST = Vector3.new(-45, 3.3, 57)
local BRIDGE_EAST = Vector3.new(26, 2.8, 50)

local TRAVEL_ROUTE_SEGMENTS = {}
local function addTravelPolyline(points)
    for index = 1, #points - 1 do
        table.insert(TRAVEL_ROUTE_SEGMENTS, { points[index], points[index + 1] })
    end
end

addTravelPolyline(OPENING_ROUTE_POINTS)
addTravelPolyline(PROVING_SPUR_POINTS)
addTravelPolyline({ Vector3.new(-241, 1.4, 118), Vector3.new(-226, 1.5, 123) })
addTravelPolyline({
    WORLD_ZONES.Crossroads,
    Vector3.new(-145, 4.0, 70),
    Vector3.new(-112, 3.8, 64),
    BRIDGE_WEST,
    BRIDGE_EAST,
    Vector3.new(58, 2.8, 38),
})
addTravelPolyline({
    Vector3.new(58, 2.8, 38),
    Vector3.new(82, 3.0, 5),
    WORLD_ZONES.Ruins + Vector3.new(-30, 0, 18),
})
addTravelPolyline({
    Vector3.new(58, 2.8, 38),
    Vector3.new(105, 2.0, 78),
    Vector3.new(168, 1.5, 112),
    WORLD_ZONES.CombatGrove + Vector3.new(-45, 0, -5),
})
addTravelPolyline({
    WORLD_ZONES.Crossroads + Vector3.new(0, 0, 15),
    Vector3.new(-157, 3.4, 128),
    Vector3.new(-132, 2.5, 174),
    Vector3.new(-103, 1.4, 220),
    WORLD_ZONES.Glowmere + Vector3.new(-22, 0, -7),
})
addTravelPolyline({
    WORLD_ZONES.Crossroads + Vector3.new(-12, 0, -12),
    Vector3.new(-208, 3.0, 42),
    Vector3.new(-239, 1.5, 5),
    Vector3.new(-273, -0.5, -55),
    Vector3.new(-292, -2.3, -111),
    WORLD_ZONES.Waterfall + Vector3.new(24, 0, 30),
})
addTravelPolyline({
    WORLD_ZONES.Glowmere + Vector3.new(48, 0, -2),
    Vector3.new(38, 0.5, 252),
    Vector3.new(112, 0.8, 220),
    Vector3.new(185, 1.0, 178),
    WORLD_ZONES.CombatGrove + Vector3.new(-38, 0, 32),
})
addTravelPolyline({
    WORLD_ZONES.Ruins + Vector3.new(20, 0, -25),
    Vector3.new(178, 5.2, -132),
    Vector3.new(219, 7.8, -174),
    Vector3.new(257, 10.0, -210),
    WORLD_ZONES.Overlook + Vector3.new(-20, 0, 15),
})
addTravelPolyline({
    WORLD_ZONES.Overlook + Vector3.new(28, 0, 22),
    Vector3.new(327, 8.0, -168),
    Vector3.new(330, 4.0, -70),
    WORLD_ZONES.CombatGrove + Vector3.new(42, 0, -45),
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

local function makeCollisionProxy(parent, name, size, cframe)
    local proxy =
        makePart(parent, name, size, cframe, Enum.Material.SmoothPlastic, Color3.new(0, 0, 0))
    proxy.Transparency = 1
    proxy.CanCollide = true
    proxy.CanTouch = false
    proxy.CanQuery = false
    proxy.CastShadow = false
    proxy:SetAttribute("EverLeafCollisionProxy", true)
    return proxy
end

local function setInstanceCollision(instance, enabled)
    if instance:IsA("BasePart") then
        instance.CanCollide = enabled
        instance.CanTouch = false
    end
    for _, descendant in instance:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = enabled
            descendant.CanTouch = false
        end
    end
end

local function setRenderOnly(instance)
    if instance:IsA("BasePart") then
        instance.CanCollide = false
        instance.CanTouch = false
        instance.CanQuery = false
    end
    for _, descendant in instance:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
        end
    end
end

local function terrainSurfacePosition(position, offsetY)
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return position + Vector3.new(0, offsetY or 0, 0)
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = { terrain }
    rayParams.IgnoreWater = true

    local rayTop = math.max(position.Y + 160, 160)
    local result = Workspace:Raycast(
        Vector3.new(position.X, rayTop, position.Z),
        Vector3.new(0, -480, 0),
        rayParams
    )
    if not result then
        return position + Vector3.new(0, offsetY or 0, 0)
    end
    return Vector3.new(position.X, result.Position.Y + (offsetY or 0), position.Z)
end

local function placeGroundedPrefab(prefabName, parent, position, yaw, scale, offsetY)
    local grounded = terrainSurfacePosition(position, offsetY)
    local placed = EnvironmentPrefabService.Place(
        prefabName,
        parent,
        CFrame.new(grounded) * CFrame.Angles(0, yaw or 0, 0),
        scale
    )
    return placed, grounded
end

local function findTreeTrunkPart(instance)
    local best = nil
    local bestScore = -math.huge
    local candidates = { instance }
    for _, descendant in instance:GetDescendants() do
        table.insert(candidates, descendant)
    end

    for _, candidate in candidates do
        if candidate:IsA("BasePart") then
            local lower = string.lower(candidate.Name)
            local nameScore = 0
            if string.find(lower, "trunk", 1, true) then
                nameScore = 1000
            elseif string.find(lower, "stem", 1, true) then
                nameScore = 700
            elseif string.find(lower, "tree", 1, true) then
                nameScore = 250
            end
            local verticalScore = candidate.Size.Y * 2
            local score = nameScore + verticalScore
            if score > bestScore then
                best = candidate
                bestScore = score
            end
        end
    end
    return best
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

local TREE_VARIANT_COUNT = 12

local function chooseTreePrefab(variant)
    variant = math.max(1, math.floor(tonumber(variant) or 1))
    local startIndex = ((variant - 1) % TREE_VARIANT_COUNT) + 1
    for offset = 0, TREE_VARIANT_COUNT - 1 do
        local index = ((startIndex + offset - 1) % TREE_VARIANT_COUNT) + 1
        local name = "ForestTree" .. string.format("%02d", index)
        if EnvironmentPrefabService.Get(name) then
            return name
        end
    end
    if EnvironmentPrefabService.Get("TreePrimary") then
        return "TreePrimary"
    end
    return nil
end

local function placeImportedTree(parent, position, scale, variant, targetHeight, yaw)
    local prefabName = chooseTreePrefab(variant)
    if not prefabName then
        -- Production policy: missing visual assets must never degrade into
        -- placeholder sphere trees. Skip the placement and emit one warning.
        if not LumenreachWorldService._warnedMissingTreePrefab then
            LumenreachWorldService._warnedMissingTreePrefab = true
            warn(
                "[LumenreachWorldService] No approved tree prefab available; skipping tree placements"
            )
        end
        return nil
    end

    local placed, groundedPosition = placeGroundedPrefab(
        prefabName,
        parent,
        position,
        yaw or 0,
        prefabScaleForHeight(prefabName, targetHeight, scale),
        0
    )
    if not placed then
        return nil
    end

    -- Imported tree meshes are rendering only. Source mesh collision varies
    -- wildly between asset variants and can snag players on invisible branch
    -- hulls, so every production tree gets exactly one predictable trunk proxy.
    setInstanceCollision(placed, false)
    local finalHeight = targetHeight * math.max(0.1, tonumber(scale) or 1)
    local trunkHeight = math.clamp(finalHeight * 0.42, 5.5, 12.5)
    local trunkRadius = math.clamp(finalHeight * 0.065, 1.25, 2.5)
    local trunk = findTreeTrunkPart(placed)
    local trunkXZ = trunk and trunk.Position or groundedPosition
    makeCollisionProxy(
        placed,
        "EverLeafTrunkCollision",
        Vector3.new(trunkRadius * 2, trunkHeight, trunkRadius * 2),
        CFrame.new(trunkXZ.X, groundedPosition.Y + trunkHeight * 0.5, trunkXZ.Z)
    )
    return placed
end

local function makeTree(parent, position, scale, variant)
    variant = variant or 1
    return placeImportedTree(parent, position, scale, variant, 22, math.rad((variant * 47) % 360))
end

local function makeCanopyTree(parent, position, scale, yaw)
    yaw = yaw or 0
    local variant = (math.abs(math.floor(yaw * 1000)) % TREE_VARIANT_COUNT) + 1
    return placeImportedTree(parent, position, scale or 1, variant, 30, yaw)
end

local function makeFallenLog(parent, position, yaw, scale, variant)
    local prefabName = if variant == 2 then "FallenTreeTrunk2" else "FallenTreeTrunk"
    local prefab = placeGroundedPrefab(
        prefabName,
        parent,
        position,
        yaw,
        prefabScaleForLongest(prefabName, 10, scale),
        0.12
    )
    if prefab then
        return prefab
    end
    return nil
end

local function makeStump(parent, position, scale, variant)
    local prefabName = if variant == 2 then "TreeStump2" else "TreeStump"
    local prefab = placeGroundedPrefab(
        prefabName,
        parent,
        position,
        math.rad(17 + (variant or 1) * 23),
        prefabScaleForHeight(prefabName, 3, scale),
        0
    )
    if prefab then
        return prefab
    end
    return nil
end

local function makePineRoots(parent, position, yaw, scale)
    local prefab = placeGroundedPrefab(
        "PineRoots",
        parent,
        position,
        yaw,
        prefabScaleForLongest("PineRoots", 7, scale),
        0.02
    )
    if prefab then
        return prefab
    end
    return nil
end

local function makeFern(parent, position, scale, yaw)
    local prefab = placeGroundedPrefab(
        "FernPrimary",
        parent,
        position,
        yaw or math.rad((math.floor(position.X + position.Z) * 37) % 360),
        prefabScaleForLongest("FernPrimary", 4.2, scale),
        0.03
    )
    if prefab then
        return prefab
    end
    return nil
end

local function makeFlowerPatch(parent, position, scale, warm)
    position = terrainSurfacePosition(position, 0.02)
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
    local yaw = math.rad(((seed or 1) * 47) % 360)
    local prefab = placeGroundedPrefab(
        "MossyRockSet",
        parent,
        position,
        yaw,
        prefabScaleForLongest("MossyRockSet", 7.5, scale),
        -0.06
    )
    if prefab then
        for _, descendant in prefab:GetDescendants() do
            if descendant:IsA("BasePart") then
                descendant.CanCollide = false
                descendant.CanTouch = false
            end
        end
        return prefab
    end
    return nil
end

local function makeDryBranches(parent, position, yaw, scale)
    local prefab = placeGroundedPrefab(
        "DryBranches",
        parent,
        position,
        yaw,
        prefabScaleForLongest("DryBranches", 4.6, scale),
        0.05
    )
    if prefab then
        setInstanceCollision(prefab, false)
        return prefab
    end
    return nil
end

local function makeMossyRockSet(parent, position, yaw, scale)
    local prefab = placeGroundedPrefab(
        "MossyRockSet",
        parent,
        position,
        yaw,
        prefabScaleForLongest("MossyRockSet", 9, scale),
        -0.08
    )
    if prefab then
        -- Mossy rock sets are dressing, not traversal geometry. Imported mesh
        -- collision is too irregular for reliable player-height movement.
        setInstanceCollision(prefab, false)
        for _, descendant in prefab:GetDescendants() do
            if descendant:IsA("BasePart") then
                descendant.CanQuery = false
            end
        end
        return prefab
    end
    return nil
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
        setInstanceCollision(prefab, false)
        for _, descendant in prefab:GetDescendants() do
            if descendant:IsA("BasePart") then
                descendant.CanQuery = false
            end
        end
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
        rock.CanCollide = false
        rock.CanTouch = false
        rock.CanQuery = false
    end

    -- The authored silhouette stays visual-only while one broad hidden blocker
    -- provides predictable cliff collision. This mirrors the landmark-specific
    -- collision policy used by Veilfall, Sunmoss, and the Shattered Arch.
    makeCollisionProxy(
        model,
        "IntegratedRockFaceCollision",
        Vector3.new(13.5, 8.0, 8.0) * scale,
        base * CFrame.new(0, 3.8 * scale, 1.2 * scale)
    )

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
    mossShelf.CanQuery = false

    return model
end

local function makeMushroomCluster(parent, position, scale, seed)
    position = terrainSurfacePosition(position, 0.02)
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
    position = terrainSurfacePosition(position, 0)
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
    makePart(
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

    setRenderOnly(model)
    makeCollisionProxy(
        model,
        "WaystoneCollision",
        Vector3.new(1.95, 4.8, 1.45) * scale,
        base * CFrame.new(0, 2.4 * scale, 0)
    )
    return model
end

local function makeSupplyStack(parent, position, yaw)
    position = terrainSurfacePosition(position, 0)
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

    setRenderOnly(model)
    makeCollisionProxy(
        model,
        "SupplyCollision",
        Vector3.new(7.0, 3.0, 4.6),
        base * CFrame.new(0.65, 1.5, 0.35)
    )
    return model
end

local function makeSignpost(parent, position, yaw, primaryText, secondaryText)
    position = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = "WayfarerSignpost"
    model.Parent = parent

    local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
    primaryText = primaryText or "WAYFARER CAMP"
    secondaryText = secondaryText or "LUMEN ARCH"
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

    addBoard("PrimaryBoard", primaryText, 6.85, 1, 6.4, 1.5)
    addBoard("SecondaryBoard", secondaryText, 5.35, -1, 6.1, -1.5)

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

    setRenderOnly(model)
    makeCollisionProxy(
        model,
        "SignpostCollision",
        Vector3.new(0.78, 8.7, 0.78),
        base * CFrame.new(0, 4.35, 0)
    )
    return model
end

local function makeCrystal(parent, position)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = "LumenCrystalCluster"
    model.Parent = parent

    local baseStone = makeBall(
        model,
        "CrystalMossBase",
        Vector3.new(3.4, 0.58, 2.8),
        CFrame.new(ground + Vector3.new(0, 0.18, 0)),
        Enum.Material.Rock,
        Color3.fromRGB(73, 91, 82)
    )
    baseStone.CanCollide = false
    baseStone.CanTouch = false
    baseStone.CanQuery = false
    useMaterialVariant(baseStone, "MossyRock")

    local shardSpecs = {
        {
            Name = "CoreShard",
            Size = Vector3.new(1.15, 4.9, 1.05),
            Offset = Vector3.new(0, 2.45, 0),
            Rotation = CFrame.Angles(math.rad(-3), math.rad(18), math.rad(7)),
            Color = Color3.fromRGB(103, 206, 190),
        },
        {
            Name = "LeftShard",
            Size = Vector3.new(0.82, 3.25, 0.78),
            Offset = Vector3.new(-1.0, 1.65, 0.2),
            Rotation = CFrame.Angles(math.rad(8), math.rad(-22), math.rad(-18)),
            Color = Color3.fromRGB(89, 184, 176),
        },
        {
            Name = "RightShard",
            Size = Vector3.new(0.72, 2.65, 0.72),
            Offset = Vector3.new(0.92, 1.35, -0.35),
            Rotation = CFrame.Angles(math.rad(-6), math.rad(31), math.rad(21)),
            Color = Color3.fromRGB(126, 221, 197),
        },
        {
            Name = "FrontShard",
            Size = Vector3.new(0.54, 1.85, 0.58),
            Offset = Vector3.new(0.15, 0.95, -0.95),
            Rotation = CFrame.Angles(math.rad(14), math.rad(4), math.rad(-12)),
            Color = Color3.fromRGB(116, 198, 191),
        },
    }

    local core = nil
    for _, spec in shardSpecs do
        local shard = makePart(
            model,
            spec.Name,
            spec.Size,
            CFrame.new(ground + spec.Offset) * spec.Rotation,
            Enum.Material.Glass,
            spec.Color
        )
        shard.CanCollide = false
        shard.CanTouch = false
        shard.CanQuery = false
        shard.Transparency = spec.Name == "CoreShard" and 0.06 or 0.12
        if spec.Name == "CoreShard" then
            core = shard
        end
    end

    if core then
        local light = Instance.new("PointLight")
        light.Color = Color3.fromRGB(111, 231, 205)
        light.Brightness = 0.62
        light.Range = 10
        light.Shadows = false
        light.Parent = core

        local motes = Instance.new("ParticleEmitter")
        motes.Name = "CrystalMotes"
        motes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        motes.Rate = 0.35
        motes.Lifetime = NumberRange.new(1.8, 3.0)
        motes.Speed = NumberRange.new(0.15, 0.35)
        motes.SpreadAngle = Vector2.new(32, 32)
        motes.Color = ColorSequence.new(Color3.fromRGB(132, 244, 211))
        motes.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.28),
            NumberSequenceKeypoint.new(1, 1),
        })
        motes.Size = NumberSequence.new(0.07)
        motes.LightEmission = 0.35
        motes.Acceleration = Vector3.new(0, 0.18, 0)
        motes.Parent = core
    end
    return model
end

local function makeGrassTuft(parent, position, scale)
    position = terrainSurfacePosition(position, 0.02)
    local model = Instance.new("Model")
    model.Name = "GrassTuft"
    model.Parent = parent
    local placed = 0
    for index, offset in
        {
            Vector3.new(-0.65, 0, 0.15),
            Vector3.new(0.55, 0, -0.25),
        }
    do
        local fern = makeFern(
            model,
            position + offset * scale,
            0.34 * scale,
            math.rad(index * 83 + math.floor(position.X + position.Z) % 47)
        )
        if fern then
            placed += 1
        end
    end
    if placed == 0 then
        model:Destroy()
        return nil
    end
    return model
end

local function makeBush(parent, position, scale)
    position = terrainSurfacePosition(position, 0.03)
    local model = Instance.new("Model")
    model.Name = "LumenBush"
    model.Parent = parent
    local placed = 0
    for index, offset in
        {
            Vector3.new(-0.8, 0, 0.15),
            Vector3.new(0.65, 0, 0.55),
            Vector3.new(0.15, 0, -0.75),
        }
    do
        local fern = makeFern(
            model,
            position + offset * scale,
            (0.46 + index * 0.04) * scale,
            math.rad(index * 101 + math.floor(position.X - position.Z) % 53)
        )
        if fern then
            placed += 1
        end
    end
    if placed == 0 then
        model:Destroy()
        return nil
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
    position = terrainSurfacePosition(position, 0)
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
    position = terrainSurfacePosition(position, 0.18)
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
    -- The visible canvas is the physical tent wall. Keep the front opening
    -- passable, but do not let players phase through either side or the rear.
    leftCanvas.CanCollide = true
    rightCanvas.CanCollide = true
    makeCollisionProxy(
        model,
        "TentBackCollision",
        Vector3.new(10.8, 5.6, 0.8),
        base * CFrame.new(0, 2.8, canvasLength * 0.5 - 0.1)
    )

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
    position = terrainSurfacePosition(position, 0)
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
    setRenderOnly(model)
    makeCollisionProxy(
        model,
        "BenchCollision",
        Vector3.new(5.8, 1.5, 1.7),
        base * CFrame.new(0, 0.75, 0)
    )
    return model
end

local function makeMapTable(parent, position, yaw)
    position = terrainSurfacePosition(position, 0)
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
    setRenderOnly(model)
    makeCollisionProxy(
        model,
        "MapTableCollision",
        Vector3.new(6.35, 3.2, 3.95),
        base * CFrame.new(0, 1.6, 0)
    )
    return model
end

local function makeCampBanner(parent, position, yaw)
    position = terrainSurfacePosition(position, 0)
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
    setRenderOnly(model)
    for _, x in { -2.7, 2.7 } do
        makeCollisionProxy(
            model,
            "BannerPostCollision",
            Vector3.new(0.58, 7.7, 0.58),
            base * CFrame.new(x, 3.85, 0)
        )
    end
    return model
end

local function makeLantern(parent, position, yaw)
    position = terrainSurfacePosition(position, 0)
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
        Vector3.new(0.42, 8.8, 0.42),
        base * CFrame.new(0, 4.4, 0),
        Enum.Material.Wood,
        wood
    )
    makePart(
        model,
        "Arm",
        Vector3.new(2.35, 0.3, 0.3),
        base * CFrame.new(0.98, 8.22, 0),
        Enum.Material.Wood,
        wood
    )
    makePart(
        model,
        "Brace",
        Vector3.new(1.15, 0.2, 0.2),
        base * CFrame.new(0.57, 7.7, 0) * CFrame.Angles(0, 0, math.rad(-43)),
        Enum.Material.Wood,
        wood
    )
    makePart(
        model,
        "Hanger",
        Vector3.new(0.12, 0.72, 0.12),
        base * CFrame.new(2.02, 7.82, 0),
        Enum.Material.Metal,
        metal
    )

    makePart(
        model,
        "CageTop",
        Vector3.new(0.92, 0.12, 0.92),
        base * CFrame.new(2.02, 7.65, 0),
        Enum.Material.Metal,
        metal
    ).CanCollide =
        false
    makePart(
        model,
        "CageBottom",
        Vector3.new(0.78, 0.12, 0.78),
        base * CFrame.new(2.02, 6.63, 0),
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
            base * CFrame.new(2.02 + corner.X, 7.14, corner.Y),
            Enum.Material.Metal,
            metal
        )
        rail.CanCollide = false
    end

    local glow = makeBall(
        model,
        "Glow",
        Vector3.new(0.62, 0.62, 0.62),
        base * CFrame.new(2.02, 7.14, 0),
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

    setRenderOnly(model)
    makeCollisionProxy(
        model,
        "LanternPostCollision",
        Vector3.new(0.72, 8.9, 0.72),
        base * CFrame.new(0, 4.45, 0)
    )
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
        plank.CanCollide = false
        plank.CanTouch = false
        plank.CanQuery = false
    end

    -- Visible planks are deliberately irregular for silhouette, but traversal
    -- rides on a small set of overlapping smooth deck segments. This removes
    -- seam/rise snagging while keeping the slight authored bridge crown.
    local deckSegments = math.max(3, math.min(6, math.floor(length / 12) + 3))
    local deckSegmentLength = length / deckSegments
    for segmentIndex = 1, deckSegments do
        local alpha = (segmentIndex - 0.5) / deckSegments
        local z = -length * 0.5 + alpha * length
        local rise = math.sin(alpha * math.pi) * 0.55
        local previousAlpha = math.max(0, alpha - 0.5 / deckSegments)
        local nextAlpha = math.min(1, alpha + 0.5 / deckSegments)
        local previousRise = math.sin(previousAlpha * math.pi) * 0.55
        local nextRise = math.sin(nextAlpha * math.pi) * 0.55
        local pitch = -math.atan2(nextRise - previousRise, deckSegmentLength)
        makeCollisionProxy(
            model,
            "BridgeDeckCollision",
            Vector3.new(math.max(1, width - 0.55), 0.42, deckSegmentLength + 0.32),
            base * CFrame.new(0, 0.72 + rise, z) * CFrame.Angles(pitch, 0, 0)
        )
    end

    for _, side in { -1, 1 } do
        local rail = makePart(
            model,
            "Rail",
            Vector3.new(0.24, 0.24, length + 0.5),
            base * CFrame.new(side * (width * 0.5 - 0.1), 2.25, 0),
            Enum.Material.Wood,
            darkWood
        )
        rail.CanCollide = false
        rail.CanTouch = false
        rail.CanQuery = false

        local postCount = math.max(4, math.floor(length / 4))
        for index = 0, postCount do
            local z = -length * 0.5 + (length / postCount) * index
            local post = makePart(
                model,
                "RailPost",
                Vector3.new(0.28, 2.7, 0.28),
                base * CFrame.new(side * (width * 0.5 - 0.1), 1.45, z),
                Enum.Material.Wood,
                darkWood
            )
            post.CanCollide = false
            post.CanTouch = false
            post.CanQuery = false
        end

        -- One smooth hidden wall per side replaces dozens of tiny physical
        -- rail/post colliders. Players can brush the bridge edge without
        -- snagging while still being prevented from walking off the span.
        makeCollisionProxy(
            model,
            "BridgeRailCollision",
            Vector3.new(0.62, 3.25, length + 0.65),
            base * CFrame.new(side * (width * 0.5 - 0.02), 1.72, 0)
        )
    end

    return model
end

local function makeWaterfall(parent, position)
    local model = Instance.new("Model")
    model.Name = "LumenFalls"
    model.Parent = parent
    local ground = terrainSurfacePosition(position, -0.25)

    local cliffFaces = {
        { Offset = Vector3.new(-10.5, 6.0, -1.8), Yaw = math.rad(12), Longest = 22, Scale = 1.0 },
        { Offset = Vector3.new(10.2, 5.0, -1.0), Yaw = math.rad(-18), Longest = 20, Scale = 0.96 },
        { Offset = Vector3.new(-4.0, 15.5, -3.0), Yaw = math.rad(48), Longest = 17, Scale = 0.82 },
        { Offset = Vector3.new(5.4, 14.5, -2.7), Yaw = math.rad(-52), Longest = 16, Scale = 0.78 },
    }
    for index, spec in cliffFaces do
        local placed = EnvironmentPrefabService.Place(
            "RockFace",
            model,
            CFrame.new(ground + spec.Offset) * CFrame.Angles(0, spec.Yaw, 0),
            prefabScaleForLongest("RockFace", spec.Longest, spec.Scale)
        )
        if placed then
            placed.Name = "VeilfallRockFace" .. index
            setInstanceCollision(placed, false)
        end
    end

    makeMossyRockSet(model, ground + Vector3.new(-13.5, 0, 3.2), math.rad(24), 1.0)
    makeMossyRockSet(model, ground + Vector3.new(13.2, 0, 3.8), math.rad(-31), 0.94)
    makeFern(model, ground + Vector3.new(-15.2, 0, 6.2), 0.92, math.rad(17))
    makeFern(model, ground + Vector3.new(15.0, 0, 5.8), 0.86, math.rad(-26))

    -- Keep traversal collision simple and hidden. The imported rock faces are
    -- visual-only so camera/player movement never snags on mesh hull details.
    makeCollisionProxy(
        model,
        "VeilfallLeftCollision",
        Vector3.new(12.5, 22, 15),
        CFrame.new(ground + Vector3.new(-10, 11, -1.5)) * CFrame.Angles(0, math.rad(8), 0)
    )
    makeCollisionProxy(
        model,
        "VeilfallRightCollision",
        Vector3.new(12.5, 20, 15),
        CFrame.new(ground + Vector3.new(10, 10, -1.2)) * CFrame.Angles(0, math.rad(-10), 0)
    )

    -- Three narrow ribbons break the old flat rectangular waterfall silhouette.
    local ribbonSpecs = {
        { X = -2.35, Width = 2.45, Height = 18.4, Z = 7.65, Transparency = 0.34 },
        { X = 0.15, Width = 3.2, Height = 20.0, Z = 7.8, Transparency = 0.25 },
        { X = 2.75, Width = 1.85, Height = 17.0, Z = 7.7, Transparency = 0.38 },
    }
    for index, spec in ribbonSpecs do
        local water = makePart(
            model,
            "WaterRibbon" .. index,
            Vector3.new(spec.Width, spec.Height, 0.38),
            CFrame.new(ground + Vector3.new(spec.X, spec.Height * 0.5 + 0.35, spec.Z))
                * CFrame.Angles(math.rad(-2 + index), 0, math.rad((index - 2) * 1.2)),
            Enum.Material.Glass,
            Color3.fromRGB(79, 188, 204)
        )
        water.Transparency = spec.Transparency
        water.CanCollide = false
        water.CanTouch = false
        water.CanQuery = false
        water.Reflectance = 0.06
    end

    local foam = makePart(
        model,
        "Foam",
        Vector3.new(11, 0.32, 6),
        CFrame.new(ground + Vector3.new(0, 0.28, 6.8)),
        Enum.Material.Neon,
        Color3.fromRGB(198, 244, 236)
    )
    foam.Transparency = 0.52
    foam.CanCollide = false
    foam.CanTouch = false
    foam.CanQuery = false

    local spray = Instance.new("ParticleEmitter")
    spray.Name = "VeilfallSpray"
    spray.Texture = "rbxasset://textures/particles/smoke_main.dds"
    spray.Rate = 2.2
    spray.Lifetime = NumberRange.new(1.0, 1.8)
    spray.Speed = NumberRange.new(1.2, 2.6)
    spray.SpreadAngle = Vector2.new(50, 18)
    spray.Color = ColorSequence.new(Color3.fromRGB(207, 244, 237))
    spray.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(1, 1),
    })
    spray.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(1, 2.4),
    })
    spray.Acceleration = Vector3.new(0.2, 0.7, 0.1)
    spray.Parent = foam
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

local function makeAmbientParticleAnchor(parent, name, position, profile)
    local anchor = makePart(
        parent,
        name,
        Vector3.new(0.4, 0.4, 0.4),
        CFrame.new(position),
        Enum.Material.SmoothPlastic,
        Color3.new(0, 0, 0)
    )
    anchor.Transparency = 1
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.CastShadow = false

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = name .. "Emitter"
    emitter.Texture = profile.Texture
    emitter.Rate = profile.Rate
    emitter.Lifetime = profile.Lifetime
    emitter.Speed = profile.Speed
    emitter.SpreadAngle = profile.SpreadAngle or Vector2.new(30, 30)
    emitter.Color = ColorSequence.new(profile.Color)
    emitter.Transparency = profile.Transparency
    emitter.Size = profile.Size
    emitter.LightEmission = profile.LightEmission or 0
    emitter.LockedToPart = false
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.RotSpeed = profile.RotSpeed or NumberRange.new(-8, 8)
    emitter.Acceleration = profile.Acceleration or Vector3.zero
    emitter.Parent = anchor
    return anchor
end

local function makeLocalAtmosphere(world)
    local mistProfile = {
        Texture = "rbxasset://textures/particles/smoke_main.dds",
        Rate = 1.4,
        Lifetime = NumberRange.new(3.8, 5.8),
        Speed = NumberRange.new(0.45, 0.9),
        SpreadAngle = Vector2.new(42, 42),
        Color = Color3.fromRGB(194, 226, 219),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.82),
            NumberSequenceKeypoint.new(0.35, 0.7),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 2.8),
            NumberSequenceKeypoint.new(1, 6.5),
        }),
        LightEmission = 0.08,
        Acceleration = Vector3.new(0.18, 0.22, 0.06),
        RotSpeed = NumberRange.new(-3, 3),
    }
    local moteProfile = {
        Texture = "rbxasset://textures/particles/sparkles_main.dds",
        Rate = 0.8,
        Lifetime = NumberRange.new(4.5, 7.0),
        Speed = NumberRange.new(0.15, 0.45),
        SpreadAngle = Vector2.new(55, 55),
        Color = Color3.fromRGB(152, 235, 190),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.35),
            NumberSequenceKeypoint.new(0.7, 0.5),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.09),
            NumberSequenceKeypoint.new(0.6, 0.14),
            NumberSequenceKeypoint.new(1, 0.05),
        }),
        LightEmission = 0.35,
        Acceleration = Vector3.new(0.12, 0.1, 0.04),
        RotSpeed = NumberRange.new(-18, 18),
    }
    local highlandProfile = {
        Texture = "rbxasset://textures/particles/sparkles_main.dds",
        Rate = 0.55,
        Lifetime = NumberRange.new(3.5, 5.5),
        Speed = NumberRange.new(0.35, 0.75),
        SpreadAngle = Vector2.new(65, 35),
        Color = Color3.fromRGB(226, 232, 187),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.55),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.08),
            NumberSequenceKeypoint.new(1, 0.04),
        }),
        LightEmission = 0.18,
        Acceleration = Vector3.new(0.5, 0.05, 0.16),
        RotSpeed = NumberRange.new(-24, 24),
    }

    for index, offset in
        {
            Vector3.new(-14, 2.0, 17),
            Vector3.new(13, 1.8, 24),
            Vector3.new(2, 3.0, 8),
        }
    do
        makeAmbientParticleAnchor(
            world,
            "VeilfallMist" .. index,
            WORLD_ZONES.Waterfall + offset,
            mistProfile
        )
    end

    for index, offset in
        {
            Vector3.new(-24, 1.2, 9),
            Vector3.new(22, 1.1, -10),
        }
    do
        makeAmbientParticleAnchor(
            world,
            "GlowmereMist" .. index,
            WORLD_ZONES.Glowmere + offset,
            mistProfile
        )
    end

    for index, offset in
        {
            Vector3.new(-30, 3.2, -12),
            Vector3.new(18, 3.8, 21),
            Vector3.new(-10, 4.5, 30),
        }
    do
        makeAmbientParticleAnchor(
            world,
            "LumenMotes" .. index,
            WORLD_ZONES.Glowmere + offset,
            moteProfile
        )
    end

    for index, offset in
        {
            Vector3.new(-24, 7.0, 8),
            Vector3.new(18, 8.5, -4),
        }
    do
        makeAmbientParticleAnchor(
            world,
            "SunmossAir" .. index,
            WORLD_ZONES.Overlook + offset,
            highlandProfile
        )
    end

    makeFireflyCluster(world, WORLD_ZONES.Camp + Vector3.new(-42, 0, 31))
    makeFireflyCluster(world, WORLD_ZONES.Glowmere + Vector3.new(4, 0, -38))
end

local function makeRockSpire(parent, position, scale)
    scale = scale or 1
    local ground = terrainSurfacePosition(position, -0.18)
    local model = Instance.new("Model")
    model.Name = "LumenRockSpire"
    model.Parent = parent

    local faceSpecs = {
        { Offset = Vector3.new(-2.8, 0, 0.4), Yaw = math.rad(12), Size = 18.5, Scale = 0.95 },
        { Offset = Vector3.new(3.4, 1.4, 1.6), Yaw = math.rad(-34), Size = 15.5, Scale = 0.82 },
        { Offset = Vector3.new(0.6, 5.0, -1.8), Yaw = math.rad(67), Size = 12.5, Scale = 0.72 },
    }
    for index, spec in faceSpecs do
        local prefabName = "RockFace"
        local placed = EnvironmentPrefabService.Place(
            prefabName,
            model,
            CFrame.new(ground + spec.Offset * scale) * CFrame.Angles(0, spec.Yaw, 0),
            prefabScaleForLongest(prefabName, spec.Size, scale * spec.Scale)
        )
        if placed then
            placed.Name = "SpireRockFace" .. index
            setInstanceCollision(placed, false)
        end
    end

    makeMossyRockSet(model, ground + Vector3.new(-3.8, 0, 3.4) * scale, math.rad(21), 0.9 * scale)
    makeMossyRockSet(model, ground + Vector3.new(3.7, 0, -2.7) * scale, math.rad(-42), 0.78 * scale)
    makeFern(model, ground + Vector3.new(-5.2, 0, -1.8) * scale, 0.85 * scale, math.rad(31))
    makeFern(model, ground + Vector3.new(4.6, 0, 2.5) * scale, 0.76 * scale, math.rad(-54))

    -- Collision stays intentionally simple even though the visible silhouette is
    -- built from irregular imported rock faces. This prevents mesh-hull snagging.
    makeCollisionProxy(
        model,
        "SpireCollision",
        Vector3.new(10.5, 12.5, 9.5) * scale,
        CFrame.new(ground + Vector3.new(0, 6.0, 0) * scale)
    )
    return model
end

local function makeRuins(parent, origin)
    local model = Instance.new("Model")
    model.Name = "ShatteredLumenArch"
    model.Parent = parent
    origin = terrainSurfacePosition(origin or Vector3.zero, 0)

    local stone = Color3.fromRGB(104, 114, 108)
    local darkStone = Color3.fromRGB(76, 88, 82)

    local function ruinChunk(name, size, offset, rotation, color)
        local chunk = makePart(
            model,
            name,
            size,
            CFrame.new(origin + offset) * (rotation or CFrame.new()),
            Enum.Material.Rock,
            color or stone
        )
        chunk.CanCollide = false
        chunk.CanTouch = false
        useMaterialVariant(chunk, "MossyRock")
        return chunk
    end

    local westChunks = {
        { Vector3.new(5.8, 4.2, 5.4), Vector3.new(-11.0, 2.1, 0.2), math.rad(-4), math.rad(4) },
        { Vector3.new(5.3, 4.0, 5.0), Vector3.new(-10.7, 6.0, -0.2), math.rad(3), math.rad(-3) },
        { Vector3.new(5.6, 4.1, 5.2), Vector3.new(-11.3, 9.8, 0.25), math.rad(-5), math.rad(2) },
        { Vector3.new(4.9, 3.8, 4.7), Vector3.new(-10.8, 13.4, -0.25), math.rad(4), math.rad(-6) },
    }
    for index, spec in westChunks do
        ruinChunk(
            "WestPillarChunk" .. index,
            spec[1],
            spec[2],
            CFrame.Angles(0, spec[3], spec[4]),
            index % 2 == 0 and darkStone or stone
        )
    end

    local eastChunks = {
        { Vector3.new(5.6, 4.1, 5.4), Vector3.new(11.0, 2.05, 0.15), math.rad(5), math.rad(-2) },
        { Vector3.new(5.2, 4.0, 5.0), Vector3.new(10.7, 5.9, -0.2), math.rad(-4), math.rad(4) },
        { Vector3.new(5.0, 3.7, 4.8), Vector3.new(11.2, 9.5, 0.3), math.rad(6), math.rad(5) },
        { Vector3.new(4.4, 3.0, 4.3), Vector3.new(10.8, 12.6, -0.2), math.rad(-3), math.rad(-7) },
    }
    for index, spec in eastChunks do
        ruinChunk(
            "EastPillarChunk" .. index,
            spec[1],
            spec[2],
            CFrame.Angles(0, spec[3], spec[4]),
            index % 2 == 1 and darkStone or stone
        )
    end

    -- The shattered lintel is intentionally split and tilted so the gate reads
    -- as an old ruin rather than a rectangular doorway.
    ruinChunk(
        "WestArchCap",
        Vector3.new(10.2, 3.2, 5.1),
        Vector3.new(-6.4, 15.3, 0.1),
        CFrame.Angles(math.rad(2), math.rad(-2), math.rad(7)),
        stone
    )
    ruinChunk(
        "EastArchCap",
        Vector3.new(9.0, 3.0, 4.8),
        Vector3.new(6.9, 14.7, -0.15),
        CFrame.Angles(math.rad(-2), math.rad(3), math.rad(-10)),
        darkStone
    )
    ruinChunk(
        "BrokenCrownStone",
        Vector3.new(5.4, 2.8, 4.6),
        Vector3.new(-0.8, 17.0, 0.2),
        CFrame.Angles(math.rad(4), math.rad(-7), math.rad(19)),
        stone
    )

    -- Broken side walls use short offset chunks instead of monolithic slabs.
    for index, spec in
        {
            { Vector3.new(-18.0, 1.6, 4.5), Vector3.new(4.2, 3.2, 7.0), math.rad(12) },
            { Vector3.new(-18.8, 4.2, 8.8), Vector3.new(4.0, 3.3, 6.0), math.rad(8) },
            { Vector3.new(18.0, 1.5, 5.2), Vector3.new(4.1, 3.0, 6.8), math.rad(-15) },
            { Vector3.new(18.6, 3.9, 9.1), Vector3.new(3.8, 3.2, 5.7), math.rad(-10) },
        }
    do
        ruinChunk(
            "BrokenWallChunk" .. index,
            spec[2],
            spec[1],
            CFrame.Angles(0, spec[3], math.rad((index % 2 == 0) and 3 or -3)),
            index % 2 == 0 and darkStone or stone
        )
    end

    ruinChunk(
        "FallenLintel",
        Vector3.new(11.0, 2.6, 4.3),
        Vector3.new(-17.2, 1.5, -11.0),
        CFrame.Angles(math.rad(8), math.rad(32), math.rad(15)),
        darkStone
    )
    ruinChunk(
        "FallenPillar",
        Vector3.new(4.0, 12.5, 4.0),
        Vector3.new(14.0, 2.0, -14.0),
        CFrame.Angles(math.rad(82), math.rad(17), math.rad(5)),
        stone
    )

    -- Simple hidden blockers match only the main stone masses; visible chunks
    -- remain non-colliding so players do not snag on decorative broken edges.
    makeCollisionProxy(
        model,
        "WestPillarCollision",
        Vector3.new(5.0, 15.2, 5.0),
        CFrame.new(origin + Vector3.new(-11, 7.6, 0))
    )
    makeCollisionProxy(
        model,
        "EastPillarCollision",
        Vector3.new(5.0, 13.7, 5.0),
        CFrame.new(origin + Vector3.new(11, 6.85, 0))
    )
    makeCollisionProxy(
        model,
        "WestWallCollision",
        Vector3.new(4.2, 6.2, 13.5),
        CFrame.new(origin + Vector3.new(-18.3, 3.1, 7.0)) * CFrame.Angles(0, math.rad(10), 0)
    )
    makeCollisionProxy(
        model,
        "EastWallCollision",
        Vector3.new(4.2, 5.8, 12.8),
        CFrame.new(origin + Vector3.new(18.3, 2.9, 7.5)) * CFrame.Angles(0, math.rad(-12), 0)
    )

    makeMossyRockSet(model, origin + Vector3.new(-23, 0, -12), math.rad(24), 0.9)
    makeMossyRockSet(model, origin + Vector3.new(24, 0, -14), math.rad(-31), 0.82)
    makeFern(model, origin + Vector3.new(-14.5, 0, 5.8), 0.82, math.rad(23))
    makeFern(model, origin + Vector3.new(14.8, 0, 6.6), 0.78, math.rad(-29))
    makeCrystal(model, origin + Vector3.new(-7, 0, -8))
    makeCrystal(model, origin + Vector3.new(9, 0, 7))

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

    local totemGround = terrainSurfacePosition(center + Vector3.new(0, 0, 37), 0)
    local totem = Instance.new("Model")
    totem.Name = "MossglenWayfarerTotem"
    totem.Parent = model
    local wood = Color3.fromRGB(69, 50, 35)
    local darkWood = Color3.fromRGB(49, 38, 29)

    local segmentSpecs = {
        { Length = 3.6, Diameter = 1.65, Offset = Vector3.new(-0.15, 1.8, 0), Tilt = math.rad(-3) },
        {
            Length = 3.5,
            Diameter = 1.5,
            Offset = Vector3.new(0.12, 5.15, 0.05),
            Tilt = math.rad(4),
        },
        {
            Length = 2.8,
            Diameter = 1.3,
            Offset = Vector3.new(-0.08, 8.05, -0.03),
            Tilt = math.rad(-5),
        },
    }
    for index, spec in segmentSpecs do
        local segment = makePart(
            totem,
            "TotemSegment" .. index,
            Vector3.new(spec.Length, spec.Diameter, spec.Diameter),
            CFrame.new(totemGround + spec.Offset)
                * CFrame.Angles(0, math.rad(index * 17), math.rad(90) + spec.Tilt),
            Enum.Material.Wood,
            index % 2 == 0 and darkWood or wood
        )
        segment.Shape = Enum.PartType.Cylinder
        segment.CanCollide = false
        segment.CanTouch = false
        segment.CanQuery = false
        useMaterialVariant(segment, "MossWood")
    end

    for _, arm in
        {
            { Vector3.new(-1.45, 8.55, 0), math.rad(-22) },
            { Vector3.new(1.45, 8.4, 0), math.rad(24) },
        }
    do
        local branch = makePart(
            totem,
            "TotemFork",
            Vector3.new(3.2, 0.8, 0.8),
            CFrame.new(totemGround + arm[1]) * CFrame.Angles(0, 0, arm[2]),
            Enum.Material.Wood,
            darkWood
        )
        branch.CanCollide = false
        branch.CanTouch = false
        branch.CanQuery = false
        useMaterialVariant(branch, "MossWood")
    end

    makeMossyRockSet(totem, totemGround, math.rad(15), 0.66)
    makeFern(totem, totemGround + Vector3.new(-2.5, 0, 1.3), 0.62, math.rad(18))
    makeFern(totem, totemGround + Vector3.new(2.4, 0, -1.1), 0.58, math.rad(-31))

    local rune = makePart(
        totem,
        "GroveRune",
        Vector3.new(1.05, 3.0, 0.12),
        CFrame.new(totemGround + Vector3.new(0, 5.5, -0.78)) * CFrame.Angles(0, 0, math.rad(45)),
        Enum.Material.Neon,
        Color3.fromRGB(101, 226, 182)
    )
    rune.CanCollide = false
    rune.CanTouch = false
    rune.CanQuery = false
    local glow = Instance.new("PointLight")
    glow.Color = rune.Color
    glow.Brightness = 0.62
    glow.Range = 11
    glow.Shadows = false
    glow.Parent = rune
    makeCollisionProxy(
        totem,
        "TotemCollision",
        Vector3.new(2.2, 8.8, 2.2),
        CFrame.new(totemGround + Vector3.new(0, 4.4, 0))
    )

    -- Replace the old flat wooden arena markers with low moss/waystone accents.
    for index, offset in
        {
            Vector3.new(-18, 0, -31),
            Vector3.new(18, 0, -31),
        }
    do
        local markerGround = terrainSurfacePosition(center + offset, 0)
        makeMossyRockSet(model, markerGround, math.rad(index == 1 and 38 or -42), 0.54)
        makeFern(
            model,
            markerGround + Vector3.new(index == 1 and -2.2 or 2.2, 0, 1.3),
            0.58,
            math.rad(index * 57)
        )
    end

    return model
end

local function attachNpcPresentation(model, root, head, npcId, displayName, accent, promptText)
    local nameplate = Instance.new("BillboardGui")
    nameplate.Name = "NpcNameplate"
    nameplate.Size = UDim2.fromOffset(206, 34)
    nameplate.StudsOffsetWorldSpace = Vector3.new(0, 1.8, 0)
    nameplate.AlwaysOnTop = false
    nameplate.MaxDistance = 46
    nameplate.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 0.2
    label.BackgroundColor3 = Color3.fromRGB(15, 24, 22)
    label.Text = displayName
    label.TextColor3 = Color3.fromRGB(226, 243, 230)
    label.TextStrokeColor3 = Color3.fromRGB(22, 34, 30)
    label.TextStrokeTransparency = 0.32
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = nameplate

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label
    local stroke = Instance.new("UIStroke")
    stroke.Color = accent or Color3.fromRGB(84, 134, 111)
    stroke.Transparency = 0.38
    stroke.Thickness = 1
    stroke.Parent = label

    WorldObjectService.Register(model, "Npc", npcId)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "TalkPrompt"
    prompt.ActionText = "Talk"
    prompt.ObjectText = promptText or displayName
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
    prompt.Parent = root
    prompt.Triggered:Connect(function(player)
        InteractionService.Begin(player, npcId, model)
    end)
end

local function makeGuide(parent, position, yaw)
    local palette = {
        Cloth = Color3.fromRGB(48, 91, 80),
        DarkCloth = Color3.fromRGB(28, 58, 52),
        Accent = Color3.fromRGB(126, 146, 111),
        Skin = Color3.fromRGB(218, 187, 153),
        Leather = Color3.fromRGB(91, 61, 39),
        Hair = Color3.fromRGB(82, 48, 38),
        EyeColor = Color3.fromRGB(43, 77, 64),
        Lumen = Color3.fromRGB(105, 231, 194),
        Metal = Color3.fromRGB(166, 132, 67),
    }
    local model, root, head = StylizedNpcFactory.Create(parent, {
        Name = "LumenGuide",
        NpcId = "lumen_guide",
        Position = position,
        Yaw = yaw,
        Role = "Guide",
        HairStyle = "long",
        Build = 0.92,
        HeightScale = 1.03,
        HeadScale = 0.94,
        BodyTypeScale = 0.24,
        ProportionScale = 0.3,
        Palette = palette,
    })
    if not model or not root or not head then
        return nil
    end
    attachNpcPresentation(
        model,
        root,
        head,
        "lumen_guide",
        "ILYRA · WAYFARER GUIDE",
        palette.Lumen,
        "Ilyra · Wayfarer Guide"
    )
    return model
end

local function makeCampNpc(parent, npcId, displayName, position, yaw, palette, role)
    local roleStyle = {
        Quartermaster = {
            HairStyle = "short",
            Build = 1.08,
            HeightScale = 0.95,
            HeadScale = 1.02,
            BodyTypeScale = 0.34,
            ProportionScale = 0.12,
            Hair = Color3.fromRGB(78, 53, 37),
            Skin = Color3.fromRGB(198, 158, 123),
            Eye = Color3.fromRGB(72, 63, 48),
        },
        Scout = {
            HairStyle = "ponytail",
            Build = 0.9,
            HeightScale = 1.04,
            HeadScale = 0.92,
            BodyTypeScale = 0.42,
            ProportionScale = 0.5,
            Hair = Color3.fromRGB(92, 57, 39),
            Skin = Color3.fromRGB(221, 185, 145),
            Eye = Color3.fromRGB(49, 83, 61),
        },
        Archivist = {
            HairStyle = "bun",
            Build = 0.9,
            HeightScale = 0.94,
            HeadScale = 1.02,
            BodyTypeScale = 0.28,
            ProportionScale = 0.22,
            Hair = Color3.fromRGB(60, 47, 71),
            Skin = Color3.fromRGB(202, 165, 138),
            Eye = Color3.fromRGB(79, 64, 105),
        },
        Mentor = {
            HairStyle = "long",
            Build = 0.96,
            HeightScale = 1.07,
            HeadScale = 0.93,
            BodyTypeScale = 0.5,
            ProportionScale = 0.56,
            Hair = Color3.fromRGB(151, 157, 145),
            Skin = Color3.fromRGB(211, 178, 145),
            Eye = Color3.fromRGB(61, 105, 78),
        },
    }
    local style = roleStyle[role] or roleStyle.Scout
    local visualPalette = {
        Cloth = palette.Cloth,
        DarkCloth = palette.DarkCloth or palette.Cloth:Lerp(Color3.new(0, 0, 0), 0.24),
        Accent = palette.Accent,
        Skin = palette.Skin or style.Skin,
        Leather = palette.Leather or Color3.fromRGB(84, 58, 39),
        Hair = palette.Hair or style.Hair,
        EyeColor = palette.EyeColor or style.Eye,
        Lumen = palette.Lumen or Color3.fromRGB(113, 238, 170),
        Metal = palette.Metal or Color3.fromRGB(162, 132, 72),
    }
    local model, root, head = StylizedNpcFactory.Create(parent, {
        Name = npcId,
        NpcId = npcId,
        Position = position,
        Yaw = yaw,
        Role = role,
        HairStyle = style.HairStyle,
        Build = style.Build,
        HeightScale = style.HeightScale,
        HeadScale = style.HeadScale,
        BodyTypeScale = style.BodyTypeScale,
        ProportionScale = style.ProportionScale,
        Palette = visualPalette,
    })
    if not model or not root or not head then
        return nil
    end
    attachNpcPresentation(model, root, head, npcId, displayName, visualPalette.Accent, displayName)
    return model
end

local function makeProvingCircle(parent)
    local origin = terrainSurfacePosition(PROVING_CIRCLE_ORIGIN, 0)
    local model = Instance.new("Model")
    model.Name = "WayfarerProvingCircle"
    model.Parent = parent

    -- Preserve a predictable flat combat floor without leaving a giant visible
    -- Roblox cylinder. The authored ring/inlays below provide the visual read.
    local floor = makePart(
        model,
        "ProvingFloorCollision",
        Vector3.new(0.7, 23.5, 23.5),
        CFrame.new(origin + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Enum.Material.SmoothPlastic,
        Color3.new(0, 0, 0)
    )
    floor.Shape = Enum.PartType.Cylinder
    floor.Transparency = 1
    floor.CanCollide = true
    floor.CanTouch = false
    floor.CanQuery = false
    floor.CastShadow = false
    floor:SetAttribute("EverLeafCollisionProxy", true)

    -- Broken ring slabs sit just above the floor and make the trial space read
    -- as an old Wayfarer site integrated into the forest rather than a platform.
    for index = 1, 18 do
        local angle = (index - 1) * math.pi * 2 / 18
        local radius = 10.9 + ((index % 3) - 1) * 0.22
        local slab = makePart(
            model,
            "ProvingRingStone" .. index,
            Vector3.new(4.0 + (index % 2) * 0.35, 0.42 + (index % 3) * 0.05, 2.45),
            CFrame.new(
                origin
                    + Vector3.new(
                        math.cos(angle) * radius,
                        0.23 + (index % 2) * 0.03,
                        math.sin(angle) * radius
                    )
            )
                * CFrame.Angles(
                    math.rad((index % 3 - 1) * 1.4),
                    -angle + math.rad(90 + (index % 3 - 1) * 2),
                    math.rad((index % 4 - 2) * 1.2)
                ),
            Enum.Material.Rock,
            if index % 3 == 0 then Color3.fromRGB(73, 88, 80) else Color3.fromRGB(83, 96, 87)
        )
        slab.CanCollide = false
        slab.CanTouch = false
        useMaterialVariant(slab, "MossyRock")
    end

    local centerInlay = makePart(
        model,
        "LumenHeart",
        Vector3.new(0.12, 6.6, 6.6),
        CFrame.new(origin + Vector3.new(0, 0.39, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Enum.Material.Neon,
        Color3.fromRGB(65, 151, 111)
    )
    centerInlay.Shape = Enum.PartType.Cylinder
    centerInlay.Transparency = 0.5
    centerInlay.CanCollide = false
    centerInlay.CanTouch = false
    centerInlay.CanQuery = false

    local familyColors = {
        Color3.fromRGB(98, 157, 103),
        Color3.fromRGB(211, 156, 76),
        Color3.fromRGB(86, 188, 171),
        Color3.fromRGB(145, 105, 184),
        Color3.fromRGB(197, 151, 74),
    }
    for index, color in familyColors do
        local angle = math.rad(-90 + (index - 1) * 72)
        local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))

        local spoke = makePart(
            model,
            "PathSpoke" .. index,
            Vector3.new(0.18, 0.08, 5.2),
            CFrame.lookAt(
                origin + direction * 5.1 + Vector3.new(0, 0.43, 0),
                origin + direction * 10
            ),
            Enum.Material.Neon,
            color
        )
        spoke.Transparency = 0.28
        spoke.CanCollide = false
        spoke.CanTouch = false
        spoke.CanQuery = false

        local stonePosition = origin + direction * 15.5
        local stoneGround = terrainSurfacePosition(stonePosition, 0)
        local markerYaw = -angle + math.rad(90)
        local markerBase = CFrame.new(stoneGround) * CFrame.Angles(0, markerYaw, 0)
        local pathStone = Instance.new("Model")
        pathStone.Name = "PathStone" .. index
        pathStone.Parent = model

        local placed = EnvironmentPrefabService.Place(
            "RockFace",
            pathStone,
            markerBase
                * CFrame.new(0, 2.8, 0.15)
                * CFrame.Angles(
                    math.rad((index % 3 - 1) * 3),
                    0,
                    math.rad((index % 2 == 0) and 6 or -6)
                ),
            prefabScaleForLongest("RockFace", 8.4, 0.5)
        )
        if placed then
            placed.Name = "PathRock"
            setRenderOnly(placed)
        end

        makeMossyRockSet(
            pathStone,
            stoneGround - direction * 0.8,
            markerYaw + math.rad((index % 3 - 1) * 8),
            0.44
        )

        local rune = makePart(
            pathStone,
            "PathRune",
            Vector3.new(1.0, 2.45, 0.1),
            markerBase * CFrame.new(0, 3.75, -1.2) * CFrame.Angles(0, 0, math.rad(45)),
            Enum.Material.Neon,
            color
        )
        rune.CanCollide = false
        rune.CanTouch = false
        rune.CanQuery = false
        rune.Transparency = 0.06

        local runeLight = Instance.new("PointLight")
        runeLight.Color = color
        runeLight.Brightness = 0.34
        runeLight.Range = 5.5
        runeLight.Shadows = false
        runeLight.Parent = rune

        makeCollisionProxy(
            pathStone,
            "PathStoneCollision",
            Vector3.new(2.4, 6.0, 2.5),
            markerBase * CFrame.new(0, 3.0, 0.25)
        )
    end

    local beacon = makeBall(
        model,
        "PathkeeperBeacon",
        Vector3.new(0.82, 0.82, 0.82),
        CFrame.new(origin + Vector3.new(0, 1.65, 0)),
        Enum.Material.Neon,
        Color3.fromRGB(121, 244, 183)
    )
    beacon.CanCollide = false
    beacon.CanTouch = false
    beacon.CanQuery = false
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(121, 244, 183)
    light.Brightness = 0.9
    light.Range = 11
    light.Shadows = false
    light.Parent = beacon

    makeFern(model, origin + Vector3.new(-12.8, 0, 8.6), 0.56, math.rad(18))
    makeFern(model, origin + Vector3.new(12.1, 0, -8.9), 0.52, math.rad(-31))
    makeDryBranches(model, origin + Vector3.new(-13.2, 0, -6.8), math.rad(41), 0.46)
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
    local ground = terrainSurfacePosition(origin, 0)
    local model = Instance.new("Model")
    model.Name = "WhisperrootHollow"
    model.Parent = parent

    -- Ground dressing frames the entrance, while the elevated crown is placed
    -- directly instead of going through the terrain-grounded rock helper. This
    -- preserves the intended hollow/arch silhouette after terrain resolution.
    makeRockCluster(model, ground + Vector3.new(-8.5, 0, 0.5), 1.45, 31)
    makeRockCluster(model, ground + Vector3.new(8.2, 0, 0.8), 1.4, 32)
    makeMossyRockSet(model, ground + Vector3.new(-10.5, 0, 5.5), math.rad(31), 0.72)
    makeMossyRockSet(model, ground + Vector3.new(10.2, 0, 5.8), math.rad(-34), 0.68)

    local crownSpecs = {
        {
            Name = "WhisperrootCrownLeft",
            Offset = Vector3.new(-6.0, 6.2, 1.2),
            Rotation = CFrame.Angles(math.rad(4), math.rad(28), math.rad(-23)),
            Longest = 14.5,
            Scale = 0.76,
        },
        {
            Name = "WhisperrootCrownRight",
            Offset = Vector3.new(6.0, 6.0, 1.4),
            Rotation = CFrame.Angles(math.rad(-3), math.rad(-31), math.rad(24)),
            Longest = 14.0,
            Scale = 0.74,
        },
        {
            Name = "WhisperrootCrownTop",
            Offset = Vector3.new(0.2, 9.5, 2.0),
            Rotation = CFrame.Angles(math.rad(8), math.rad(83), math.rad(6)),
            Longest = 12.0,
            Scale = 0.62,
        },
    }
    for _, spec in crownSpecs do
        local placed = EnvironmentPrefabService.Place(
            "RockFace",
            model,
            CFrame.new(ground + spec.Offset) * spec.Rotation,
            prefabScaleForLongest("RockFace", spec.Longest, spec.Scale)
        )
        if placed then
            placed.Name = spec.Name
            setRenderOnly(placed)
        end
    end

    -- Smooth side blockers define the hollow without letting imported rock hulls
    -- snag the player. The center remains a wide, obvious walk-in opening.
    makeCollisionProxy(
        model,
        "WhisperrootLeftCollision",
        Vector3.new(6.5, 8.2, 8.0),
        CFrame.new(ground + Vector3.new(-8.0, 4.1, 1.8)) * CFrame.Angles(0, math.rad(10), 0)
    )
    makeCollisionProxy(
        model,
        "WhisperrootRightCollision",
        Vector3.new(6.5, 8.0, 8.0),
        CFrame.new(ground + Vector3.new(8.0, 4.0, 2.0)) * CFrame.Angles(0, math.rad(-12), 0)
    )

    makeDryBranches(model, ground + Vector3.new(-5, 0, 7), math.rad(24), 0.75)
    makePineRoots(model, ground + Vector3.new(7.2, 0, 6.8), math.rad(-28), 0.62)
    makeFern(model, ground + Vector3.new(-7.0, 0, 8.2), 0.72, math.rad(17))
    makeFern(model, ground + Vector3.new(7.5, 0, 8.0), 0.68, math.rad(-23))
    makeCrystal(model, ground + Vector3.new(0, 0, 9))
    makeCrystal(model, ground + Vector3.new(5, 0, 6))

    local cacheGround = terrainSurfacePosition(origin + Vector3.new(-2, 0, 11), 0)
    local cacheBase = CFrame.new(cacheGround) * CFrame.Angles(0, math.rad(-18), 0)
    local cache = makePart(
        model,
        "OldWayfarerCache",
        Vector3.new(4.6, 1.45, 3.0),
        cacheBase * CFrame.new(0, 0.72, 0),
        Enum.Material.Wood,
        Color3.fromRGB(89, 63, 42)
    )
    cache.CanCollide = false
    cache.CanTouch = false
    cache.CanQuery = false

    local lid = makePart(
        model,
        "CacheLid",
        Vector3.new(4.8, 0.48, 3.15),
        cacheBase * CFrame.new(0, 1.62, -0.08) * CFrame.Angles(math.rad(-3), 0, 0),
        Enum.Material.Wood,
        Color3.fromRGB(104, 74, 45)
    )
    lid.CanCollide = false
    lid.CanTouch = false
    lid.CanQuery = false

    for _, x in { -1.55, 1.55 } do
        local band = makePart(
            model,
            "CacheBand",
            Vector3.new(0.28, 1.75, 3.22),
            cacheBase * CFrame.new(x, 0.9, 0),
            Enum.Material.Metal,
            Color3.fromRGB(73, 79, 73)
        )
        band.CanCollide = false
        band.CanTouch = false
        band.CanQuery = false
    end

    local cacheRune = makePart(
        model,
        "CacheRune",
        Vector3.new(1.15, 0.72, 0.08),
        cacheBase * CFrame.new(0, 1.0, -1.54),
        Enum.Material.Neon,
        Color3.fromRGB(99, 220, 184)
    )
    cacheRune.CanCollide = false
    cacheRune.CanTouch = false
    cacheRune.CanQuery = false
    makeCollisionProxy(
        model,
        "WayfarerCacheCollision",
        Vector3.new(4.8, 1.9, 3.2),
        cacheBase * CFrame.new(0, 0.95, 0)
    )

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
        local claimed = ProfileTransaction.Run(profile, function(workingProfile)
            workingProfile.World.Secrets = workingProfile.World.Secrets or {}
            if workingProfile.World.Secrets.whisperroot_cache == true then
                return false, "already_claimed"
            end
            local added, addReason = InventoryService.Add(workingProfile, "old_wayfinder_page", 1)
            if not added then
                return false, addReason
            end
            workingProfile.World.Secrets.whisperroot_cache = true
            QuestService.Record(workingProfile, "Collect", "old_wayfinder_page", 1)
            return true
        end)
        if claimed then
            PlayerDataService.NotifyChanged(player)
        end
    end)

    for index = 1, 3 do
        local pageGround = terrainSurfacePosition(
            origin + Vector3.new(-5 + index * 2.1, 0, 9.5 + index * 0.4),
            0.05
        )
        local page = makePart(
            model,
            "WeatheredPage" .. index,
            Vector3.new(1.2, 0.05, 1.55),
            CFrame.new(pageGround)
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
    position = terrainSurfacePosition(position, 0.02)
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
    billboard.Size = UDim2.fromOffset(286, 32)
    billboard.AlwaysOnTop = false
    billboard.MaxDistance = 68
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

    -- Remove legacy/default place floors completely. The generated world uses
    -- Terrain plus its own invisible safety foundation, so a Roblox baseplate
    -- should never be visible beyond the playable region.
    for _, child in Workspace:GetChildren() do
        if child:IsA("BasePart") then
            local lowerName = string.lower(child.Name)
            local namedBaseplate = lowerName == "baseplate" or lowerName == "base plate"
            local legacyFloor = child.Size.X >= WORLD_WIDTH
                and child.Size.Z >= WORLD_DEPTH
                and child.Size.Y <= 24
                and child.Position.Y <= 6
                and child.Material == Enum.Material.Plastic
            if namedBaseplate or legacyFloor then
                child:Destroy()
            end
        end
    end

    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain:Clear()
        terrain:FillBlock(
            CFrame.new(0, -5, 0),
            Vector3.new(WORLD_WIDTH + 120, 10, WORLD_DEPTH + 120),
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
            local startPoint = Vector3.new(a.X, a.Y + 0.28, a.Z)
            local endPoint = Vector3.new(b.X, b.Y + 0.28, b.Z)
            local delta = endPoint - startPoint
            local length = delta.Magnitude
            if length < 0.1 then
                return
            end
            local midpoint = (startPoint + endPoint) * 0.5
            -- A wider, slightly lower mud/leaf-litter verge prevents the hard
            -- brown-road-to-tall-grass seam visible at player height.
            terrain:FillBlock(
                CFrame.lookAt(
                    midpoint - Vector3.new(0, 0.12, 0),
                    endPoint - Vector3.new(0, 0.12, 0)
                ),
                Vector3.new(width + 14, 1.05, length + 4),
                Enum.Material.Mud
            )
            terrain:FillBlock(
                CFrame.lookAt(midpoint, endPoint),
                Vector3.new(width, 1.25, length + 3),
                Enum.Material.Ground
            )
        end

        local function carveTrailPass(a, b, width)
            local startPoint = Vector3.new(a.X, a.Y + 6, a.Z)
            local endPoint = Vector3.new(b.X, b.Y + 6, b.Z)
            local delta = endPoint - startPoint
            local length = delta.Magnitude
            if length < 0.1 then
                return
            end
            local midpoint = (startPoint + endPoint) * 0.5
            terrain:FillBlock(
                CFrame.lookAt(midpoint, endPoint),
                Vector3.new(width + 10, 12, length + 7),
                Enum.Material.Air
            )
            fillTrail(a, b, width)
        end

        -- New macro layout: west-basin Camp, raised Crossroads saddle, a
        -- central Lumen Gorge, and the east-side ruins/combat/highland chapter.
        fillClearing(WORLD_ZONES.Camp, Vector3.new(88, 0, 60), Enum.Material.Ground)
        fillClearing(WORLD_ZONES.Ruins, Vector3.new(96, 0, 76), Enum.Material.Grass)
        fillClearing(WORLD_ZONES.CombatGrove, Vector3.new(140, 0, 108), Enum.Material.Grass)
        fillClearing(WORLD_ZONES.Glowmere, Vector3.new(116, 0, 88), Enum.Material.Grass)

        -- Veilfall is a genuinely lower ravine floor; clear the original ground
        -- volume before laying its lower basin.
        terrain:FillBlock(
            CFrame.new(WORLD_ZONES.Waterfall + Vector3.new(0, 3.0, 0)),
            Vector3.new(118, 14, 98),
            Enum.Material.Air
        )
        fillClearing(WORLD_ZONES.Waterfall, Vector3.new(104, 0, 82), Enum.Material.Grass)

        terrain:FillBall(
            WORLD_ZONES.Crossroads + Vector3.new(0, -19.6, 0),
            20.2,
            Enum.Material.Ground
        )
        terrain:FillBall(
            PROVING_CIRCLE_ORIGIN + Vector3.new(0, -16.0, 0),
            17.0,
            Enum.Material.Ground
        )

        -- Carve the Lumen Gorge through the middle of the region. This is the
        -- map's primary macro landmark and permanently breaks the old flat-lawn
        -- silhouette. The channel deepens as it runs south toward Veilfall.
        local function carveGorgeSegment(a, b, width)
            local delta = b - a
            local length = delta.Magnitude
            if length < 0.1 then
                return
            end
            local midpoint = (a + b) * 0.5
            local carveCenter = midpoint - Vector3.new(0, 5.3, 0)
            local carveTarget = b - Vector3.new(0, 5.3, 0)
            terrain:FillBlock(
                CFrame.lookAt(carveCenter, carveTarget),
                Vector3.new(width, 11.5, length + 5),
                Enum.Material.Air
            )
            terrain:FillBlock(
                CFrame.lookAt(midpoint - Vector3.new(0, 9.0, 0), b - Vector3.new(0, 9.0, 0)),
                Vector3.new(width - 2.5, 2.6, length + 3),
                Enum.Material.Rock
            )
            terrain:FillBlock(
                CFrame.lookAt(midpoint - Vector3.new(0, 5.6, 0), b - Vector3.new(0, 5.6, 0)),
                Vector3.new(width - 5.0, 3.2, length + 2),
                Enum.Material.Water
            )
        end
        for index = 1, #GORGE_POINTS - 1 do
            local width = 30 + math.min(index, 4) * 2.5
            carveGorgeSegment(GORGE_POINTS[index], GORGE_POINTS[index + 1], width)
        end

        -- Main opening route climbs out of Camp into Crossroads.
        local openingWidths = { 12.5, 11.5, 11, 10.5, 10.5, 10.5, 10.5 }
        for index = 1, #OPENING_ROUTE_POINTS - 1 do
            fillTrail(
                OPENING_ROUTE_POINTS[index],
                OPENING_ROUTE_POINTS[index + 1],
                openingWidths[index]
            )
        end

        -- Advancement training is a separate wooded spur south of Camp.
        for index = 1, #PROVING_SPUR_POINTS - 1 do
            fillTrail(PROVING_SPUR_POINTS[index], PROVING_SPUR_POINTS[index + 1], 9.0)
        end

        -- A small starter-combat pocket sits off the main climb rather than
        -- spawning enemies in the navigation saddle itself.
        local mosslingHollow = Vector3.new(-226, 1.5, 123)
        fillClearing(mosslingHollow, Vector3.new(30, 0, 24), Enum.Material.Grass)
        fillTrail(Vector3.new(-241, 1.4, 118), mosslingHollow, 7.5)

        local trails = {
            -- Raised Crossroads -> mandatory gorge bridge -> east landing.
            { WORLD_ZONES.Crossroads, Vector3.new(-145, 4.0, 70), 11 },
            { Vector3.new(-145, 4.0, 70), Vector3.new(-112, 3.8, 64), 10.5 },
            { Vector3.new(-112, 3.8, 64), BRIDGE_WEST, 10.0 },
            { BRIDGE_EAST, Vector3.new(58, 2.8, 38), 10.0 },

            -- East landing -> Shattered Lumen Arch.
            { Vector3.new(58, 2.8, 38), Vector3.new(82, 3.0, 5), 10.5 },
            { Vector3.new(82, 3.0, 5), WORLD_ZONES.Ruins + Vector3.new(-30, 0, 18), 11 },

            -- East landing -> Mossglen Combat Grove.
            { Vector3.new(58, 2.8, 38), Vector3.new(105, 2.0, 78), 11 },
            { Vector3.new(105, 2.0, 78), Vector3.new(168, 1.5, 112), 11.5 },
            { Vector3.new(168, 1.5, 112), WORLD_ZONES.CombatGrove + Vector3.new(-45, 0, -5), 12.5 },

            -- Crossroads -> Glowmere north basin.
            { WORLD_ZONES.Crossroads + Vector3.new(0, 0, 15), Vector3.new(-157, 3.4, 128), 10.5 },
            { Vector3.new(-157, 3.4, 128), Vector3.new(-132, 2.5, 174), 10.5 },
            { Vector3.new(-132, 2.5, 174), Vector3.new(-103, 1.4, 220), 10.5 },
            { Vector3.new(-103, 1.4, 220), WORLD_ZONES.Glowmere + Vector3.new(-22, 0, -7), 11 },

            -- Crossroads -> Veilfall lower ravine.
            { WORLD_ZONES.Crossroads + Vector3.new(-12, 0, -12), Vector3.new(-208, 3.0, 42), 10 },
            { Vector3.new(-208, 3.0, 42), Vector3.new(-239, 1.5, 5), 10 },
            { Vector3.new(-239, 1.5, 5), Vector3.new(-273, -0.5, -55), 10 },
            { Vector3.new(-273, -0.5, -55), Vector3.new(-292, -2.3, -111), 10 },
            { Vector3.new(-292, -2.3, -111), WORLD_ZONES.Waterfall + Vector3.new(24, 0, 30), 10 },

            -- Glowmere ridge -> Mossglen, completing the northern loop.
            { WORLD_ZONES.Glowmere + Vector3.new(48, 0, -2), Vector3.new(38, 0.5, 252), 10.5 },
            { Vector3.new(38, 0.5, 252), Vector3.new(112, 0.8, 220), 10.5 },
            { Vector3.new(112, 0.8, 220), Vector3.new(185, 1.0, 178), 11 },
            { Vector3.new(185, 1.0, 178), WORLD_ZONES.CombatGrove + Vector3.new(-38, 0, 32), 11.5 },

            -- Ruins -> genuinely elevated Sunmoss ridge.
            { WORLD_ZONES.Ruins + Vector3.new(20, 0, -25), Vector3.new(178, 5.2, -132), 10 },
            { Vector3.new(178, 5.2, -132), Vector3.new(219, 7.8, -174), 10 },
            { Vector3.new(219, 7.8, -174), Vector3.new(257, 10.0, -210), 10 },
            { Vector3.new(257, 10.0, -210), WORLD_ZONES.Overlook + Vector3.new(-20, 0, 15), 10 },

            -- Overlook returns north toward Mossglen on a high forest shelf.
            { WORLD_ZONES.Overlook + Vector3.new(28, 0, 22), Vector3.new(327, 8.0, -168), 9.5 },
            { Vector3.new(327, 8.0, -168), Vector3.new(330, 4.0, -70), 10 },
            { Vector3.new(330, 4.0, -70), WORLD_ZONES.CombatGrove + Vector3.new(42, 0, -45), 10.5 },
        }
        for _, trail in trails do
            fillTrail(trail[1], trail[2], trail[3])
        end

        -- Break the giant flat clearings into irregular, framed spaces. These
        -- low banks sit outside the main travel lanes and make paths feel cut
        -- through a forest rather than painted across a flat baseplate.
        local lowBanks = {
            -- Camp basin rim.
            { WORLD_ZONES.Camp + Vector3.new(-52, -9.0, -36), 13, Enum.Material.Grass },
            { WORLD_ZONES.Camp + Vector3.new(-50, -9.5, 36), 14, Enum.Material.Grass },
            { WORLD_ZONES.Camp + Vector3.new(2, -10.0, -45), 13, Enum.Material.Grass },
            { WORLD_ZONES.Camp + Vector3.new(40, -9.5, 38), 13, Enum.Material.Grass },

            -- Opening climb banks around the new switchback road.
            { Vector3.new(-286, -9.5, 148), 12, Enum.Material.Grass },
            { Vector3.new(-260, -9.0, 170), 12, Enum.Material.Grass },
            { Vector3.new(-248, -9.0, 111), 11, Enum.Material.Grass },
            { Vector3.new(-219, -8.5, 124), 11, Enum.Material.Grass },
            { Vector3.new(-211, -8.0, 72), 10, Enum.Material.Grass },
            { Vector3.new(-184, -7.5, 99), 10, Enum.Material.Grass },

            -- Raised Crossroads saddle.
            { WORLD_ZONES.Crossroads + Vector3.new(-28, -8.0, -24), 11, Enum.Material.Grass },
            { WORLD_ZONES.Crossroads + Vector3.new(-27, -8.0, 25), 11, Enum.Material.Grass },
            { WORLD_ZONES.Crossroads + Vector3.new(29, -8.0, -22), 11, Enum.Material.Grass },
            { WORLD_ZONES.Crossroads + Vector3.new(28, -8.0, 24), 11, Enum.Material.Grass },

            -- Proving-circle pocket.
            { PROVING_CIRCLE_ORIGIN + Vector3.new(-22, -10.0, -12), 10, Enum.Material.Grass },
            { PROVING_CIRCLE_ORIGIN + Vector3.new(22, -10.0, -10), 10, Enum.Material.Grass },
            { PROVING_CIRCLE_ORIGIN + Vector3.new(0, -10.0, -25), 11, Enum.Material.Grass },

            -- Bridge approach shelves.
            { BRIDGE_WEST + Vector3.new(-22, -7.0, 17), 11, Enum.Material.Grass },
            { BRIDGE_WEST + Vector3.new(-18, -7.0, -18), 11, Enum.Material.Grass },
            { BRIDGE_EAST + Vector3.new(22, -7.0, 18), 11, Enum.Material.Grass },
            { BRIDGE_EAST + Vector3.new(20, -7.0, -18), 11, Enum.Material.Grass },
        }
        for _, bank in lowBanks do
            terrain:FillBall(bank[1], bank[2], bank[3])
        end

        -- Rock shoulders make the central gorge read like an actual landform,
        -- not a water stripe painted into flat grass.
        local gorgeBanks = {
            { Vector3.new(-63, -5.0, 224), 13 },
            { Vector3.new(-10, -5.0, 218), 12 },
            { Vector3.new(-49, -5.0, 163), 12 },
            { Vector3.new(4, -5.0, 157), 12 },
            { Vector3.new(-39, -5.0, 103), 11 },
            { Vector3.new(14, -5.0, 99), 11 },
            { BRIDGE_WEST + Vector3.new(5, -5.5, -17), 10 },
            { BRIDGE_EAST + Vector3.new(-5, -5.5, 16), 10 },
            { Vector3.new(-43, -6.0, -32), 11 },
            { Vector3.new(7, -6.0, -16), 11 },
            { Vector3.new(-103, -6.0, -91), 12 },
            { Vector3.new(-63, -6.0, -61), 12 },
            { Vector3.new(-184, -6.0, -142), 13 },
            { Vector3.new(-147, -6.0, -111), 13 },
        }
        for _, bank in gorgeBanks do
            terrain:FillBall(bank[1], bank[2], Enum.Material.Basalt)
        end

        local edgeRock = {
            { WORLD_ZONES.Camp + Vector3.new(-58, -5.8, 4), 9 },
            { WORLD_ZONES.Camp + Vector3.new(47, -6.0, -34), 8 },
            { Vector3.new(-270, -5.8, 137), 8 },
            { Vector3.new(-229, -5.8, 93), 7 },
            { WORLD_ZONES.Crossroads + Vector3.new(-31, -4.5, 17), 8 },
            { WORLD_ZONES.Crossroads + Vector3.new(32, -4.5, -15), 8 },
            { PROVING_CIRCLE_ORIGIN + Vector3.new(-20, -6.2, 8), 7 },
        }
        for _, rock in edgeRock do
            terrain:FillBall(rock[1], rock[2], Enum.Material.Rock)
        end

        local grassIntrusions = {
            WORLD_ZONES.Camp + Vector3.new(-43, -6.0, -27),
            WORLD_ZONES.Camp + Vector3.new(-40, -6.0, 29),
            WORLD_ZONES.Camp + Vector3.new(13, -6.0, -33),
            WORLD_ZONES.Camp + Vector3.new(36, -6.0, 26),
            WORLD_ZONES.Crossroads + Vector3.new(-20, -4.5, -18),
            WORLD_ZONES.Crossroads + Vector3.new(-18, -4.5, 18),
            WORLD_ZONES.Crossroads + Vector3.new(20, -4.5, -17),
            WORLD_ZONES.Crossroads + Vector3.new(21, -4.5, 17),
            PROVING_CIRCLE_ORIGIN + Vector3.new(-15, -6.0, 13),
            PROVING_CIRCLE_ORIGIN + Vector3.new(16, -6.0, 12),
        }
        for index, intrusion in grassIntrusions do
            terrain:FillBall(intrusion, 5.5 + (index % 3) * 0.9, Enum.Material.Grass)
        end

        -- Interior terrain rooms replace the old ring-of-hills composition.
        -- Ridges live inside the playable space and create real sightline breaks,
        -- valleys, bowls, and passes. The outer boundary is intentionally quiet.
        local function fillRidge(points, radius, peakY, material)
            material = material or Enum.Material.Grass
            for index = 1, #points - 1 do
                local a = points[index]
                local b = points[index + 1]
                local distance = (b - a).Magnitude
                local steps = math.max(1, math.ceil(distance / 16))
                for step = 0, steps do
                    local alpha = step / steps
                    local point = a:Lerp(b, alpha)
                    local wobble = math.sin((index * 7 + step) * 1.31) * 1.3
                    terrain:FillBall(
                        Vector3.new(point.X, peakY - radius + wobble * 0.25, point.Z),
                        radius + wobble,
                        material
                    )
                end
            end
        end

        local function fillLayeredRidge(points, radius, peakY)
            fillRidge(points, radius, peakY, Enum.Material.Basalt)
            fillRidge(points, math.max(6, radius - 3.5), peakY + 0.6, Enum.Material.Grass)
        end

        -- Wayfarer Camp basin: three interior ridge arms form a sheltered bowl
        -- with deliberate east and south exits.
        fillLayeredRidge({
            Vector3.new(-402, 0, 246),
            Vector3.new(-384, 0, 206),
            Vector3.new(-378, 0, 160),
            Vector3.new(-366, 0, 124),
        }, 19, 7)
        fillLayeredRidge({
            Vector3.new(-382, 0, 258),
            Vector3.new(-338, 0, 266),
            Vector3.new(-294, 0, 258),
            Vector3.new(-260, 0, 240),
        }, 18, 6.5)
        fillLayeredRidge({
            Vector3.new(-380, 0, 130),
            Vector3.new(-346, 0, 108),
            Vector3.new(-308, 0, 105),
            Vector3.new(-280, 0, 120),
        }, 16, 5.5)

        -- Crossroads saddle: two rock-and-grass spurs pinch the climb and open
        -- onto the gorge overlook instead of a broad empty plateau.
        fillLayeredRidge({
            Vector3.new(-225, 4, 128),
            Vector3.new(-205, 5, 117),
            Vector3.new(-192, 5, 105),
        }, 14, 8)
        fillLayeredRidge({
            Vector3.new(-210, 4, 42),
            Vector3.new(-190, 5, 48),
            Vector3.new(-169, 5, 51),
        }, 14, 8)

        -- Glowmere wetland bowl on the north bank.
        fillLayeredRidge({
            Vector3.new(-142, 0, 320),
            Vector3.new(-100, 0, 340),
            Vector3.new(-48, 0, 346),
            Vector3.new(10, 0, 326),
        }, 18, 6)
        fillLayeredRidge({
            Vector3.new(-142, 0, 250),
            Vector3.new(-132, 0, 224),
            Vector3.new(-118, 0, 202),
        }, 14, 5)

        -- Veilfall canyon walls. These are inside the map and visually dominate
        -- the ravine instead of relying on the world perimeter.
        fillLayeredRidge({
            Vector3.new(-382, -2, -235),
            Vector3.new(-360, -2, -190),
            Vector3.new(-352, -1, -142),
            Vector3.new(-343, 0, -102),
        }, 18, 7)
        fillLayeredRidge({
            Vector3.new(-252, -2, -242),
            Vector3.new(-240, -2, -196),
            Vector3.new(-238, -1, -151),
            Vector3.new(-230, 0, -112),
        }, 17, 6.5)

        -- East-side forest spine separates the bridge landing, ruins, and
        -- Mossglen into distinct rooms while leaving authored passes between.
        fillLayeredRidge({
            Vector3.new(72, 0, 190),
            Vector3.new(105, 0, 204),
            Vector3.new(145, 1, 205),
            Vector3.new(178, 1, 190),
        }, 16, 6)
        fillLayeredRidge({
            Vector3.new(210, 0, 32),
            Vector3.new(233, 1, 0),
            Vector3.new(248, 2, -37),
            Vector3.new(250, 3, -76),
        }, 15, 7)

        -- Shattered Lumen Arch sits on a broken stone shelf.
        fillLayeredRidge({
            Vector3.new(72, 2, -126),
            Vector3.new(116, 3, -142),
            Vector3.new(160, 3, -135),
            Vector3.new(190, 3, -113),
        }, 15, 7)

        -- Mossglen amphitheater: three ridge arcs create a combat bowl with an
        -- open western entrance and high wooded shoulders.
        fillLayeredRidge({
            Vector3.new(238, 0, 214),
            Vector3.new(286, 0, 226),
            Vector3.new(330, 0, 207),
        }, 17, 6.5)
        fillLayeredRidge({
            Vector3.new(338, 0, 198),
            Vector3.new(358, 0, 152),
            Vector3.new(354, 0, 103),
            Vector3.new(338, 0, 66),
        }, 17, 7)
        fillLayeredRidge({
            Vector3.new(330, 0, 54),
            Vector3.new(286, 0, 42),
            Vector3.new(250, 0, 53),
        }, 16, 6)

        -- Sunmoss is supported by an interior highland spine, not just isolated
        -- terrain balls at the far edge.
        fillLayeredRidge({
            Vector3.new(185, 4, -188),
            Vector3.new(224, 7, -220),
            Vector3.new(268, 10, -245),
            Vector3.new(315, 11, -258),
            Vector3.new(352, 9, -238),
        }, 19, 13)

        -- Only a few low outer anchors remain. They prevent horizon emptiness
        -- without becoming the main visible topology.
        local boundaryAnchors = {
            { Vector3.new(-432, -25, 300), 48, Enum.Material.Grass },
            { Vector3.new(-438, -25, -270), 46, Enum.Material.Basalt },
            { Vector3.new(418, -25, 292), 46, Enum.Material.Grass },
            { Vector3.new(425, -25, -282), 48, Enum.Material.Basalt },
            { Vector3.new(40, -27, 365), 44, Enum.Material.Grass },
            { Vector3.new(-30, -27, -365), 44, Enum.Material.Basalt },
        }
        for _, anchor in boundaryAnchors do
            terrain:FillBall(anchor[1], anchor[2], anchor[3])
        end

        -- Re-cut all authored travel corridors after terrain massing. This
        -- creates deliberate mountain passes and guarantees ridges never swallow roads.
        for index = 1, #OPENING_ROUTE_POINTS - 1 do
            carveTrailPass(
                OPENING_ROUTE_POINTS[index],
                OPENING_ROUTE_POINTS[index + 1],
                openingWidths[index]
            )
        end
        for index = 1, #PROVING_SPUR_POINTS - 1 do
            carveTrailPass(PROVING_SPUR_POINTS[index], PROVING_SPUR_POINTS[index + 1], 9.0)
        end
        carveTrailPass(Vector3.new(-241, 1.4, 118), mosslingHollow, 7.5)
        for _, trail in trails do
            carveTrailPass(trail[1], trail[2], trail[3])
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
        -- The central Lumen Gorge now feeds this basin directly; the old
        -- duplicate flat stream was removed as part of the macro redesign.

        -- Sunmoss is a real highland ridge, not a flat clearing with raised props.
        terrain:FillBall(WORLD_ZONES.Overlook + Vector3.new(-28, -25, 18), 39, Enum.Material.Grass)
        terrain:FillBall(WORLD_ZONES.Overlook + Vector3.new(24, -24, 8), 37, Enum.Material.Grass)
        terrain:FillBall(WORLD_ZONES.Overlook + Vector3.new(0, -27, -24), 40, Enum.Material.Basalt)

        -- The overlook rises in walkable terraces along the supported ridge.
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

local function dressTravelCorridors(parent)
    local segmentIndex = 0
    for _, segment in TRAVEL_ROUTE_SEGMENTS do
        segmentIndex += 1
        local a = segment[1]
        local b = segment[2]
        local flatDelta = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
        local length = flatDelta.Magnitude
        if length >= 24 then
            local forward = flatDelta.Unit
            local right = Vector3.new(-forward.Z, 0, forward.X)
            local samples = math.clamp(math.floor(length / 44), 1, 3)
            for sample = 1, samples do
                local alpha = sample / (samples + 1)
                local center = a:Lerp(b, alpha)
                local alongJitter = (((segmentIndex * 17 + sample * 29) % 9) - 4) * 1.2
                for _, side in { -1, 1 } do
                    local seed = segmentIndex * 97 + sample * 31 + side * 13
                    local edgeDistance = 17 + (math.abs(seed) % 4) * 1.4
                    local edgePosition = center
                        + right * side * edgeDistance
                        + forward * alongJitter
                    local selector = math.abs(seed) % 5
                    if selector == 0 then
                        makeFern(parent, edgePosition, 0.72 + (sample % 2) * 0.08, seed * 0.11)
                    elseif selector == 1 then
                        makeBush(parent, edgePosition, 0.62 + (segmentIndex % 3) * 0.05)
                    elseif selector == 2 then
                        makeGrassTuft(parent, edgePosition, 0.72)
                    elseif selector == 3 then
                        makeMushroomCluster(parent, edgePosition, 0.58, seed)
                    else
                        makeFlowerPatch(parent, edgePosition, 0.58, seed % 2 == 0)
                    end

                    if (segmentIndex + sample + side) % 3 == 0 then
                        local treeDistance = 27 + (math.abs(seed) % 4) * 1.8
                        local treePosition = center
                            + right * side * treeDistance
                            + forward * (alongJitter * 0.55)
                        makeTree(
                            parent,
                            treePosition,
                            0.7 + (math.abs(seed) % 4) * 0.05,
                            (math.abs(seed) % 3) + 1
                        )
                    end
                end
            end
        end
    end
end

local function horizontalDistanceToSegment(point, a, b)
    local point2 = Vector2.new(point.X, point.Z)
    local a2 = Vector2.new(a.X, a.Z)
    local b2 = Vector2.new(b.X, b.Z)
    local delta = b2 - a2
    local lengthSquared = delta:Dot(delta)
    if lengthSquared <= 0.001 then
        return (point2 - a2).Magnitude
    end
    local alpha = math.clamp((point2 - a2):Dot(delta) / lengthSquared, 0, 1)
    return (point2 - (a2 + delta * alpha)).Magnitude
end

local function distanceToTravelRoute(position)
    local closest = math.huge
    for _, segment in TRAVEL_ROUTE_SEGMENTS do
        closest = math.min(closest, horizontalDistanceToSegment(position, segment[1], segment[2]))
    end
    return closest
end

local function travelDecorationClearance(instanceName)
    if string.sub(instanceName, 1, 10) == "ForestTree" or instanceName == "TreePrimary" then
        return 11.5
    end
    local clearances = {
        -- Route furniture belongs beside the lane, never inside it. These are
        -- scrubbed only when their actual bounds intrude into the walkable
        -- corridor after all world decoration has been placed.
        WayfarerSignpost = 5.5,
        LumenLantern = 4.5,
        LumenWaystone = 5.5,
        WayfarerBench = 5.0,
        WayfarerSupplies = 5.0,
        GrassTuft = 7.5,
        LumenBush = 8.0,
        WildflowerPatch = 6.5,
        LumenMushroomCluster = 6.0,
        RockCluster = 7.0,
        RockFace = 9.0,
        PineRoots = 7.0,
        DryBranches = 7.0,
        FallenTreeTrunk = 9.0,
        FallenTreeTrunk2 = 9.0,
        FallenLog = 9.0,
        MossyRockSet = 7.0,
        TreeStump = 6.5,
        TreeStump2 = 6.5,
        FernPrimary = 6.0,
        LumenCattails = 5.0,
        WayfarerRemnant = 10.0,
    }
    return clearances[instanceName]
end

local function horizontalBounds(instance)
    if instance:IsA("BasePart") then
        return instance.Position, math.max(instance.Size.X, instance.Size.Z) * 0.5
    end
    if instance:IsA("Model") then
        local ok, boundsCFrame, boundsSize = pcall(function()
            local cframe, size = instance:GetBoundingBox()
            return cframe, size
        end)
        if ok and boundsCFrame and boundsSize then
            return boundsCFrame.Position, math.max(boundsSize.X, boundsSize.Z) * 0.5
        end
        return instance:GetPivot().Position, 0
    end
    return nil, 0
end

local function clearTravelLaneDecor(world)
    local removed = 0
    for _, child in world:GetChildren() do
        local clearance = travelDecorationClearance(child.Name)
        if clearance then
            local position, radius = horizontalBounds(child)
            -- Use the actual horizontal footprint, not just the pivot. Clamp
            -- giant imported canopies so they do not erase whole forest bands.
            radius = math.clamp(radius or 0, 0, 8)
            if position and distanceToTravelRoute(position) < clearance + radius then
                child:Destroy()
                removed += 1
            end
        end
    end
    if removed > 0 then
        print(
            string.format(
                "[LumenreachWorldService] Cleared %d decorative objects from travel lanes",
                removed
            )
        )
    end
end

local function distanceXZ(a, b)
    local dx = a.X - b.X
    local dz = a.Z - b.Z
    return math.sqrt(dx * dx + dz * dz)
end

local function clearProtectedGameplayDecor(world)
    local removedByClearing = {}
    for _, child in world:GetChildren() do
        if travelDecorationClearance(child.Name) then
            local position, radius = horizontalBounds(child)
            if position then
                -- Imported meshes can have very broad visual canopies. For
                -- gameplay clearance we care about the local physical footprint,
                -- so cap the model radius just like the route scrub does.
                radius = math.clamp(radius or 0, 0, 8)
                for _, clearing in PROTECTED_GAMEPLAY_CLEARINGS do
                    if distanceXZ(position, clearing.Center) < clearing.Radius + radius then
                        child:Destroy()
                        removedByClearing[clearing.Id] = (removedByClearing[clearing.Id] or 0) + 1
                        break
                    end
                end
            end
        end
    end

    local total = 0
    for _, count in removedByClearing do
        total += count
    end
    if total > 0 then
        print(
            string.format(
                "[LumenreachWorldService] Cleared %d decorative objects from protected gameplay areas",
                total
            )
        )
    end
end

local function isOpeningRouteClear(position, clearance)
    for index = 1, #OPENING_ROUTE_POINTS - 1 do
        if
            horizontalDistanceToSegment(
                position,
                OPENING_ROUTE_POINTS[index],
                OPENING_ROUTE_POINTS[index + 1]
            ) < clearance
        then
            return false
        end
    end
    return true
end

local function makeWoodlandCluster(parent, center, seed, scale, protectOpeningRoute)
    scale = scale or 1
    local rotation = seed * 0.71
    local treeOffsets = {
        Vector3.new(math.cos(rotation) * 7.5, 0, math.sin(rotation) * 7.5),
        Vector3.new(math.cos(rotation + 2.05) * 9.2, 0, math.sin(rotation + 2.05) * 9.2),
        Vector3.new(math.cos(rotation + 4.2) * 6.4, 0, math.sin(rotation + 4.2) * 6.4),
    }
    for index, offset in treeOffsets do
        local treePosition = center + offset * scale
        if not protectOpeningRoute or isOpeningRouteClear(treePosition, 14.5) then
            makeTree(
                parent,
                treePosition,
                (0.82 + ((seed + index) % 4) * 0.08) * scale,
                ((seed + index) % 3) + 1
            )
        end
    end

    local bushPosition = center + Vector3.new(-3.2, 0, 1.8) * scale
    local fernPosition = center + Vector3.new(3.8, 0, -2.7) * scale
    local grassPosition = center + Vector3.new(1.4, 0, 4.2) * scale
    if not protectOpeningRoute or isOpeningRouteClear(bushPosition, 10.5) then
        makeBush(parent, bushPosition, 0.82 * scale)
    end
    if not protectOpeningRoute or isOpeningRouteClear(fernPosition, 9.5) then
        makeFern(parent, fernPosition, 0.78 * scale, rotation)
    end
    if not protectOpeningRoute or isOpeningRouteClear(grassPosition, 9.5) then
        makeGrassTuft(parent, grassPosition, 0.78 * scale)
    end
    local groundDetailPosition = center + Vector3.new(-4.7, 0, -3.8) * scale
    if not protectOpeningRoute or isOpeningRouteClear(groundDetailPosition, 8.5) then
        if seed % 2 == 0 then
            makeFlowerPatch(parent, groundDetailPosition, 0.68 * scale, seed % 4 == 0)
        else
            makeMushroomCluster(parent, groundDetailPosition, 0.7 * scale, seed)
        end
    end

    local heroDetailPosition = center + Vector3.new(5.8, 0.15, 4.8) * scale
    if not protectOpeningRoute or isOpeningRouteClear(heroDetailPosition, 12) then
        if seed % 3 == 0 then
            makeFallenLog(parent, heroDetailPosition, rotation + 0.45, 0.62 * scale, (seed % 2) + 1)
        elseif seed % 3 == 1 then
            makePineRoots(parent, heroDetailPosition, rotation, 0.58 * scale)
        else
            makeRockCluster(parent, heroDetailPosition, 0.5 * scale, seed)
        end
    end
end

local function makeHabitatPocket(parent, center, seed, scale)
    scale = scale or 1
    local rotation = seed * 0.83
    local forward = Vector3.new(math.sin(rotation), 0, math.cos(rotation))
    local right = Vector3.new(forward.Z, 0, -forward.X)

    makeCanopyTree(parent, center + right * (7.5 * scale), 0.82 * scale, rotation)
    makeTree(
        parent,
        center - right * (8.5 * scale) + forward * (2.5 * scale),
        0.88 * scale,
        (seed % 3) + 1
    )
    makeTree(parent, center - forward * (7.0 * scale), 0.74 * scale, ((seed + 1) % 3) + 1)
    makeMossyRockSet(parent, center + forward * (5.5 * scale), rotation + 0.35, 0.62 * scale)

    if seed % 3 == 0 then
        makeFallenLog(
            parent,
            center - right * (4.5 * scale) - forward * (4.0 * scale),
            rotation + 0.5,
            0.58 * scale,
            2
        )
    elseif seed % 3 == 1 then
        makePineRoots(
            parent,
            center - right * (5.2 * scale) - forward * (3.0 * scale),
            rotation,
            0.6 * scale
        )
    else
        makeDryBranches(
            parent,
            center - right * (5.0 * scale) - forward * (3.5 * scale),
            rotation,
            0.56 * scale
        )
    end

    makeBush(parent, center + right * (2.4 * scale) - forward * (2.0 * scale), 0.68 * scale)
    makeFern(
        parent,
        center - right * (2.8 * scale) + forward * (1.5 * scale),
        0.78 * scale,
        rotation
    )
    makeMushroomCluster(parent, center + forward * (1.8 * scale), 0.62 * scale, seed)
    makeFlowerPatch(
        parent,
        center - forward * (3.0 * scale) + right * (1.0 * scale),
        0.58 * scale,
        seed % 2 == 0
    )

    if seed % 4 == 0 then
        makeCrystal(parent, center + right * (4.0 * scale) + forward * (3.5 * scale))
    end
end

local function makeTrailThreshold(parent, center, direction, seed, scale)
    scale = scale or 1
    local flatDirection = Vector3.new(direction.X, 0, direction.Z)
    if flatDirection.Magnitude <= 0.001 then
        flatDirection = Vector3.new(0, 0, -1)
    else
        flatDirection = flatDirection.Unit
    end
    local frame = CFrame.lookAt(center, center + flatDirection)
    local right = frame.RightVector

    for _, side in { -1, 1 } do
        local treePosition = center
            + right * side * (21.5 * scale)
            + flatDirection * (((seed + side) % 3 - 1) * 1.8)
        makeCanopyTree(
            parent,
            treePosition,
            (0.86 + ((seed + side) % 4) * 0.04) * scale,
            math.rad((seed * 37 + side * 29) % 360)
        )

        local rockPosition = center + right * side * (14.5 * scale) - flatDirection * (2.0 * scale)
        makeMossyRockSet(
            parent,
            rockPosition,
            math.rad((seed * 23 + side * 41) % 360),
            0.52 * scale
        )

        local fernPosition = center + right * side * (11.8 * scale) + flatDirection * (3.2 * scale)
        makeFern(parent, fernPosition, 0.72 * scale, math.rad((seed * 17 + side * 61) % 360))
    end

    local waystoneSide = if seed % 2 == 0 then 1 else -1
    local waystonePosition = center
        + right * waystoneSide * (13.2 * scale)
        + flatDirection * (5.2 * scale)
    makeWaystone(
        parent,
        waystonePosition,
        math.atan2(flatDirection.X, flatDirection.Z),
        0.58 * scale
    )
end

local function makeCampDepartureFrame(parent)
    local startPoint = OPENING_ROUTE_POINTS[1]
    local nextPoint = OPENING_ROUTE_POINTS[2]
    local direction = nextPoint - startPoint
    direction = Vector3.new(direction.X, 0, direction.Z)
    if direction.Magnitude <= 0.001 then
        return
    end
    direction = direction.Unit

    local frame = CFrame.lookAt(startPoint, startPoint + direction)
    local right = frame.RightVector
    local yaw = math.atan2(direction.X, direction.Z)

    -- This is intentionally a low departure frame rather than an overhead
    -- gateway. The road stays completely open while the player gets a strong
    -- visual beat that says they are leaving the protected Wayfarer basin.
    local leftStone = startPoint - right * 13.6 - direction * 1.8
    local rightStone = startPoint + right * 13.8 + direction * 1.4
    makeWaystone(parent, leftStone, yaw + math.rad(8), 0.72)
    makeWaystone(parent, rightStone, yaw + math.pi - math.rad(10), 0.68)

    local lanternPosition = startPoint + right * 14.4 - direction * 1.2
    makeLantern(parent, lanternPosition, yaw + math.pi)

    makeMossyRockSet(parent, startPoint - right * 15.6 + direction * 2.0, yaw + math.rad(28), 0.5)
    makeFern(parent, startPoint - right * 13.2 + direction * 4.3, 0.72, yaw + math.rad(17))
    makeFlowerPatch(parent, startPoint + right * 13.5 + direction * 4.0, 0.62, false)
end

local function makeMosslingHollowFrame(parent)
    local center = Vector3.new(-226, 1.5, 123)
    local spurStart = Vector3.new(-241, 1.4, 118)
    local direction = center - spurStart
    direction = Vector3.new(direction.X, 0, direction.Z)
    if direction.Magnitude <= 0.001 then
        return
    end
    direction = direction.Unit

    local frame = CFrame.lookAt(center, center + direction)
    local right = frame.RightVector
    local yaw = math.atan2(direction.X, direction.Z)

    -- Keep the authored frame outside the 15.5-stud combat footprint. The
    -- entrance remains wide enough for dodge movement while the far edge gets
    -- a stronger forest silhouette behind the first encounter.
    local entranceBack = center - direction * 17.6
    makeMossyRockSet(parent, entranceBack - right * 16.2, yaw + math.rad(34), 0.58)
    makeMossyRockSet(parent, entranceBack + right * 16.4, yaw - math.rad(29), 0.54)
    makeFern(parent, entranceBack - right * 12.4 + direction * 1.0, 0.76, yaw + math.rad(22))
    makeFern(parent, entranceBack + right * 12.0 + direction * 0.6, 0.72, yaw - math.rad(31))

    local farEdge = center + direction * 19.5
    makeCanopyTree(parent, farEdge - right * 15.5, 0.9, yaw + math.rad(21))
    makeCanopyTree(parent, farEdge + right * 16.0, 0.86, yaw - math.rad(27))
    makeFallenLog(parent, farEdge + right * 12.8, yaw + math.rad(72), 0.58, 2)
    makeCrystal(parent, farEdge - right * 10.8)
    makeMushroomCluster(parent, farEdge + right * 7.8, 0.7, 613)
end

local function makeTrainingYardMark(parent)
    local center = terrainSurfacePosition(WORLD_ZONES.Camp + Vector3.new(31, 0, -5), 0)
    local model = Instance.new("Model")
    model.Name = "WayfarerTrainingYardMark"
    model.Parent = parent

    -- Keep the training space grounded and worn-in rather than adding another
    -- raised platform. These shallow scuffs are visual-only and intentionally
    -- irregular so the dummy reads as part of an actively used camp yard.
    local scuffs = {
        { Offset = Vector3.new(-1.8, 0.045, -1.0), Size = Vector3.new(4.8, 0.07, 1.45), Yaw = 18 },
        { Offset = Vector3.new(1.7, 0.05, 1.2), Size = Vector3.new(3.9, 0.065, 1.25), Yaw = -31 },
        { Offset = Vector3.new(-0.6, 0.055, 2.7), Size = Vector3.new(2.8, 0.06, 0.92), Yaw = 54 },
        { Offset = Vector3.new(2.8, 0.05, -2.2), Size = Vector3.new(2.35, 0.06, 0.78), Yaw = 9 },
        { Offset = Vector3.new(-3.1, 0.05, 2.0), Size = Vector3.new(2.1, 0.055, 0.72), Yaw = -52 },
    }
    for index, spec in scuffs do
        local scuff = makeBall(
            model,
            "TrainingScuff" .. index,
            spec.Size,
            CFrame.new(center + spec.Offset) * CFrame.Angles(0, math.rad(spec.Yaw), 0),
            Enum.Material.Ground,
            Color3.fromRGB(79, 67, 48)
        )
        scuff.Transparency = 0.18 + index * 0.025
        scuff.CanCollide = false
        scuff.CanTouch = false
        scuff.CanQuery = false
        scuff.CastShadow = false
    end

    local impactColor = Color3.fromRGB(94, 73, 47)
    for index, spec in
        {
            { Offset = Vector3.new(-2.4, 0.095, 0.55), Length = 2.2, Yaw = 72 },
            { Offset = Vector3.new(1.35, 0.095, -1.9), Length = 1.75, Yaw = -36 },
            { Offset = Vector3.new(3.05, 0.095, 0.4), Length = 1.45, Yaw = 28 },
        }
    do
        local mark = makePart(
            model,
            "TrainingImpactMark" .. index,
            Vector3.new(0.12, 0.035, spec.Length),
            CFrame.new(center + spec.Offset) * CFrame.Angles(0, math.rad(spec.Yaw), 0),
            Enum.Material.Wood,
            impactColor
        )
        mark.Transparency = 0.22
        mark.CanCollide = false
        mark.CanTouch = false
        mark.CanQuery = false
        mark.CastShadow = false
    end
    return model
end

local function makeCrossroadsWayfinderMark(parent)
    local center = terrainSurfacePosition(WORLD_ZONES.Crossroads, 0)
    local model = Instance.new("Model")
    model.Name = "LumenwoodWayfinderSigil"
    model.Parent = parent

    -- A weathered, almost-flush slate patch carries four Lumen inlays aligned
    -- to the actual route branches. It acts as navigation language without
    -- becoming a raised platform or adding collision at the hub center.
    local base = makePart(
        model,
        "WayfinderSlate",
        Vector3.new(0.08, 6.8, 6.8),
        CFrame.new(center + Vector3.new(0, 0.035, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Enum.Material.Slate,
        Color3.fromRGB(59, 72, 66)
    )
    base.Shape = Enum.PartType.Cylinder
    base.Transparency = 0.4
    base.CanCollide = false
    base.CanTouch = false
    base.CanQuery = false
    base.CastShadow = false

    local routeDirections = {
        OPENING_ROUTE_POINTS[#OPENING_ROUTE_POINTS - 1] - WORLD_ZONES.Crossroads,
        Vector3.new(-145, 4.0, 70) - WORLD_ZONES.Crossroads,
        Vector3.new(-157, 3.4, 128) - WORLD_ZONES.Crossroads,
        Vector3.new(-208, 3.0, 42) - WORLD_ZONES.Crossroads,
    }
    local runeColor = Color3.fromRGB(103, 224, 187)
    for index, rawDirection in routeDirections do
        local direction = Vector3.new(rawDirection.X, 0, rawDirection.Z)
        if direction.Magnitude > 0.001 then
            direction = direction.Unit
            local length = if index <= 2 then 2.95 else 2.45
            local midpoint = center + direction * (length * 0.5) + Vector3.new(0, 0.095, 0)
            local ray = makePart(
                model,
                "WayfinderRune" .. index,
                Vector3.new(0.24, 0.045, length),
                CFrame.lookAt(midpoint, midpoint + direction),
                Enum.Material.Neon,
                runeColor
            )
            ray.Transparency = 0.12 + index * 0.025
            ray.CanCollide = false
            ray.CanTouch = false
            ray.CanQuery = false
            ray.CastShadow = false
        end
    end

    local core = makeBall(
        model,
        "WayfinderCore",
        Vector3.new(0.72, 0.12, 0.72),
        CFrame.new(center + Vector3.new(0, 0.11, 0)),
        Enum.Material.Neon,
        Color3.fromRGB(132, 239, 204)
    )
    core.Transparency = 0.08
    core.CanCollide = false
    core.CanTouch = false
    core.CanQuery = false
    core.CastShadow = false

    local glow = Instance.new("PointLight")
    glow.Color = core.Color
    glow.Brightness = 0.22
    glow.Range = 5
    glow.Shadows = false
    glow.Parent = core
    return model
end

local function makeRouteThresholds(world)
    local thresholds = {
        {
            Vector3.new(-260, 1.0, 146),
            Vector3.new(-241, 1.4, 118) - Vector3.new(-281, 0.5, 169),
            401,
            0.94,
        },
        {
            Vector3.new(-112, 3.8, 64),
            BRIDGE_WEST - Vector3.new(-145, 4.0, 70),
            407,
            0.92,
        },
        {
            Vector3.new(58, 2.8, 38),
            Vector3.new(105, 2.0, 78) - BRIDGE_EAST,
            409,
            0.9,
        },
        {
            Vector3.new(-103, 1.4, 220),
            WORLD_ZONES.Glowmere - Vector3.new(-132, 2.5, 174),
            419,
            0.88,
        },
        {
            Vector3.new(-273, -0.5, -55),
            Vector3.new(-292, -2.3, -111) - Vector3.new(-239, 1.5, 5),
            421,
            0.92,
        },
        {
            Vector3.new(82, 3.0, 5),
            WORLD_ZONES.Ruins - Vector3.new(58, 2.8, 38),
            431,
            0.9,
        },
        {
            Vector3.new(168, 1.5, 112),
            WORLD_ZONES.CombatGrove - Vector3.new(105, 2.0, 78),
            433,
            0.94,
        },
        {
            Vector3.new(219, 7.8, -174),
            WORLD_ZONES.Overlook - Vector3.new(178, 5.2, -132),
            439,
            0.9,
        },
    }
    for _, threshold in thresholds do
        makeTrailThreshold(world, threshold[1], threshold[2], threshold[3], threshold[4])
    end
end

local function decorate(world)
    -- A forest belt frames the whole map. Major clearings stay readable instead of being carpeted with props.
    placeTreeArc(world, Vector3.zero, 365, 305, 28, 12, 336, 2)
    placeTreeArc(world, WORLD_ZONES.Camp, 78, 59, 26, 104, 262, 7)
    placeTreeArc(world, WORLD_ZONES.Crossroads, 57, 44, 20, 18, 320, 9)
    placeTreeArc(world, WORLD_ZONES.Ruins, 78, 65, 16, -45, 285, 11)
    placeTreeArc(world, WORLD_ZONES.CombatGrove, 96, 78, 18, 35, 285, 17)
    placeTreeArc(world, WORLD_ZONES.Glowmere, 91, 72, 16, 5, 320, 23)
    placeTreeArc(world, WORLD_ZONES.Waterfall, 82, 68, 14, 100, 250, 31)
    placeTreeArc(world, WORLD_ZONES.Overlook, 82, 62, 14, 10, 315, 37)

    dressZoneEdge(world, WORLD_ZONES.Camp, 61, 44, 26, 3)
    dressZoneEdge(world, WORLD_ZONES.Crossroads, 42, 31, 20, 7)
    dressZoneEdge(world, WORLD_ZONES.Ruins, 61, 48, 16, 11)
    dressZoneEdge(world, WORLD_ZONES.CombatGrove, 72, 58, 18, 15)
    dressZoneEdge(world, WORLD_ZONES.Glowmere, 67, 52, 19, 19)
    dressZoneEdge(world, WORLD_ZONES.Waterfall, 61, 48, 17, 23)
    dressZoneEdge(world, WORLD_ZONES.Overlook, 60, 44, 14, 29)

    -- Localized ambience gives Lumenreach its own atmosphere without changing
    -- global Lighting shared by Brasshaven. Particle budgets stay deliberately
    -- low until the in-Studio performance profile is complete.
    makeLocalAtmosphere(world)

    -- Fill the spaces between destinations with continuous forest instead of open grass fields.
    local forestPatches = {
        -- West basin / outer forest.
        { Vector3.new(-405, 0, 245), 38, 34, 11, 41 },
        { Vector3.new(-402, 0, 118), 40, 36, 11, 43 },
        { Vector3.new(-382, 0, -18), 42, 36, 11, 47 },
        { Vector3.new(-360, 0, -155), 44, 38, 12, 53 },
        { Vector3.new(-332, 0, 315), 44, 36, 11, 59 },
        { Vector3.new(-236, 0, 330), 48, 38, 12, 61 },
        { Vector3.new(-140, 0, 330), 44, 36, 11, 67 },

        -- North bank and east-side forests.
        { Vector3.new(18, 0, 326), 42, 36, 11, 71 },
        { Vector3.new(122, 0, 306), 45, 38, 12, 73 },
        { Vector3.new(232, 1, 282), 46, 38, 12, 79 },
        { Vector3.new(338, 0, 238), 44, 38, 11, 83 },
        { Vector3.new(392, 0, 132), 40, 36, 11, 89 },
        { Vector3.new(388, 0, 8), 42, 38, 11, 97 },
        { Vector3.new(370, 0, -132), 46, 40, 12, 101 },

        -- Southern highlands and Veilfall forest.
        { Vector3.new(318, 9, -306), 44, 36, 11, 103 },
        { Vector3.new(202, 2, -326), 46, 38, 12, 107 },
        { Vector3.new(82, 0, -330), 46, 40, 12, 109 },
        { Vector3.new(-54, 0, -326), 46, 40, 12, 113 },
        { Vector3.new(-190, 0, -310), 48, 40, 12, 127 },
        { Vector3.new(-310, -2, -270), 46, 38, 12, 131 },

        -- Interior forest rooms, kept away from roads/gorge.
        { Vector3.new(-285, 0, 250), 30, 26, 8, 137 },
        { Vector3.new(-272, 0, 56), 32, 28, 9, 139 },
        { Vector3.new(-246, -1, -84), 34, 28, 9, 149 },
        { Vector3.new(66, 0, 190), 34, 30, 9, 151 },
        { Vector3.new(150, 1, 246), 34, 30, 9, 157 },
        { Vector3.new(210, 2, 48), 34, 28, 9, 163 },
        { Vector3.new(236, 3, -54), 34, 28, 9, 167 },
    }
    for _, patch in forestPatches do
        scatterForestPatch(world, patch[1], patch[2], patch[3], patch[4], patch[5])
    end

    -- Mixed habitat pockets fill the playable interior with more than trees.
    -- These clusters create foreground/midground layers between named locations
    -- using deadfall, roots, mossy rocks, ferns, mushrooms, flowers, and Lumen crystals.
    local habitatPockets = {
        -- West basin and opening chapter.
        { Vector3.new(-390, 0, 210), 301, 0.92 },
        { Vector3.new(-372, 0, 150), 303, 0.88 },
        { Vector3.new(-305, 0, 292), 305, 0.95 },
        { Vector3.new(-274, 0, 230), 307, 0.86 },
        { Vector3.new(-252, 0, 38), 309, 0.9 },
        { Vector3.new(-232, -1, -78), 311, 0.9 },

        -- Glowmere north bank.
        { Vector3.new(-126, 0, 304), 313, 0.88 },
        { Vector3.new(6, 0, 286), 315, 0.92 },
        { Vector3.new(48, 0, 220), 317, 0.9 },

        -- East forest rooms between bridge, ruins, and Mossglen.
        { Vector3.new(82, 0, 150), 319, 0.9 },
        { Vector3.new(138, 0, 178), 321, 0.96 },
        { Vector3.new(205, 0, 228), 323, 0.94 },
        { Vector3.new(263, 0, 201), 325, 0.9 },
        { Vector3.new(318, 0, 186), 327, 0.96 },
        { Vector3.new(328, 0, 92), 329, 0.92 },
        { Vector3.new(205, 2, 2), 331, 0.88 },
        { Vector3.new(145, 3, -154), 333, 0.9 },

        -- Veilfall and highland transition.
        { Vector3.new(-365, -2, -190), 335, 0.92 },
        { Vector3.new(-250, -2, -190), 337, 0.9 },
        { Vector3.new(186, 6, -238), 339, 0.9 },
        { Vector3.new(332, 8, -226), 341, 0.92 },
    }
    for _, pocket in habitatPockets do
        makeHabitatPocket(world, pocket[1], pocket[2], pocket[3])
    end

    -- Keep the main travel lanes readable while filling the immediate
    -- foreground and midground on both sides. This makes traversal feel like
    -- moving through a living forest instead of crossing large empty fields.
    dressTravelCorridors(world)

    -- Major route transitions get paired vertical silhouettes and low ground
    -- detail outside the safe lane. This separates Camp, Glowmere, Veilfall,
    -- the Gorge crossing, Ruins/Mossglen, and Sunmoss without adding blockers.
    makeRouteThresholds(world)
    makeCampDepartureFrame(world)
    makeMosslingHollowFrame(world)
    makeTrainingYardMark(world)
    makeCrossroadsWayfinderMark(world)

    -- Rock shelves and exposed faces make the new interior ridges legible at
    -- player height. These are deliberately inside the region, not on its border.
    local interiorRockFaces = {
        { Vector3.new(-388, 0, 191), math.rad(78), 0.72 },
        { Vector3.new(-338, 0, 254), math.rad(-8), 0.68 },
        { Vector3.new(-330, 0, 108), math.rad(176), 0.66 },
        { Vector3.new(-214, 4, 119), math.rad(62), 0.58 },
        { Vector3.new(-224, 4, 30), math.rad(-112), 0.58 },
        { Vector3.new(-103, 0, 329), math.rad(10), 0.7 },
        { Vector3.new(-350, -2, -175), math.rad(92), 0.82 },
        { Vector3.new(-242, -2, -180), math.rad(-88), 0.78 },
        { Vector3.new(117, 0, 199), math.rad(8), 0.66 },
        { Vector3.new(236, 2, -31), math.rad(82), 0.64 },
        { Vector3.new(125, 3, -138), math.rad(4), 0.74 },
        { Vector3.new(338, 0, 147), math.rad(-88), 0.76 },
        { Vector3.new(287, 0, 220), math.rad(178), 0.72 },
        { Vector3.new(257, 9, -246), math.rad(14), 0.86 },
    }
    for _, face in interiorRockFaces do
        makeRockFace(world, face[1], face[2], face[3])
    end

    -- Dense authored clumps frame the west-basin climb without defining the
    -- layout themselves; geography and elevation now do that job.
    local openingClusters = {
        { WORLD_ZONES.Camp + Vector3.new(-50, 0, -31), 201, 1.0 },
        { WORLD_ZONES.Camp + Vector3.new(-48, 0, 39), 203, 0.94 },
        { WORLD_ZONES.Camp + Vector3.new(-7, 0, -50), 205, 0.9 },
        { WORLD_ZONES.Camp + Vector3.new(24, 0, 45), 207, 0.9 },
        { Vector3.new(-296, 0, 145), 211, 0.9 },
        { Vector3.new(-269, 1, 178), 213, 0.9 },
        { Vector3.new(-252, 1, 112), 215, 0.9 },
        { Vector3.new(-226, 2, 136), 217, 0.88 },
        { Vector3.new(-216, 2, 74), 219, 0.88 },
        { Vector3.new(-191, 3, 108), 221, 0.9 },
        { WORLD_ZONES.Crossroads + Vector3.new(-32, 0, 28), 223, 0.9 },
        { WORLD_ZONES.Crossroads + Vector3.new(-31, 0, -28), 225, 0.9 },
        { WORLD_ZONES.Crossroads + Vector3.new(31, 0, -26), 227, 0.9 },
        { WORLD_ZONES.Crossroads + Vector3.new(32, 0, 27), 229, 0.9 },
    }
    for _, cluster in openingClusters do
        makeWoodlandCluster(world, cluster[1], cluster[2], cluster[3], true)
    end

    local openingCanopyTrees = {
        { WORLD_ZONES.Camp + Vector3.new(-47, 0, -42), 0.94, math.rad(15) },
        { WORLD_ZONES.Camp + Vector3.new(-45, 0, 42), 1.0, math.rad(-28) },
        { Vector3.new(-299, 0, 143), 0.96, math.rad(31) },
        { Vector3.new(-266, 1, 180), 0.94, math.rad(-12) },
        { Vector3.new(-251, 1, 109), 1.0, math.rad(24) },
        { Vector3.new(-225, 2, 139), 0.96, math.rad(-37) },
        { Vector3.new(-214, 2, 72), 0.98, math.rad(42) },
        { Vector3.new(-189, 3, 110), 0.94, math.rad(-22) },
        { WORLD_ZONES.Crossroads + Vector3.new(33, 0, 29), 0.98, math.rad(-26) },
        { WORLD_ZONES.Crossroads + Vector3.new(-34, 0, -29), 0.94, math.rad(33) },
    }
    for _, tree in openingCanopyTrees do
        if isOpeningRouteClear(tree[1], 15.5) then
            makeCanopyTree(world, tree[1], tree[2], tree[3])
        end
    end

    -- Purposeful roadside clusters on the new regional routes.
    local trailClusters = {
        { Vector3.new(-160, 4, 139), math.rad(28), 11 },
        { Vector3.new(-126, 2.5, 198), math.rad(-32), 12 },
        { Vector3.new(-93, 1, 239), math.rad(54), 13 },
        { Vector3.new(-218, 2.5, 26), math.rad(-12), 14 },
        { Vector3.new(-255, 0, -27), math.rad(61), 15 },
        { Vector3.new(-286, -2, -92), math.rad(-46), 16 },
        { Vector3.new(-121, 4, 54), math.rad(24), 17 },
        { Vector3.new(68, 3, 56), math.rad(-68), 18 },
        { Vector3.new(132, 2, 93), math.rad(37), 19 },
        { Vector3.new(204, 1, 123), math.rad(-28), 20 },
        { Vector3.new(48, 0, 246), math.rad(48), 21 },
        { Vector3.new(133, 1, 211), math.rad(-53), 22 },
        { Vector3.new(207, 1, 168), math.rad(17), 23 },
        { Vector3.new(164, 5, -119), math.rad(-36), 24 },
        { Vector3.new(211, 8, -170), math.rad(62), 25 },
        { Vector3.new(256, 10, -209), math.rad(-41), 26 },
    }
    for _, cluster in trailClusters do
        makeTrailsideCluster(world, cluster[1], cluster[2], cluster[3])
    end

    -- The bridge is the hard geographic transition between the west and east
    -- halves of Lumenreach.
    local bridgeDelta = BRIDGE_EAST - BRIDGE_WEST
    local bridgeFlat = Vector3.new(bridgeDelta.X, 0, bridgeDelta.Z)
    local bridgeMid = (BRIDGE_WEST + BRIDGE_EAST) * 0.5
    local bridgeYaw = math.atan2(bridgeFlat.X, bridgeFlat.Z)
    makeBridge(world, bridgeMid - Vector3.new(0, 0.72, 0), bridgeYaw, bridgeFlat.Magnitude + 5, 7.4)
    makeMossyRockSet(world, BRIDGE_WEST + Vector3.new(-7, -0.2, 6), bridgeYaw, 0.72)
    makeMossyRockSet(world, BRIDGE_EAST + Vector3.new(7, -0.2, -6), bridgeYaw, 0.72)
    makeLantern(world, BRIDGE_WEST + Vector3.new(-8, 0, -8), bridgeYaw + math.pi)
    makeLantern(world, BRIDGE_EAST + Vector3.new(8, 0, 8), bridgeYaw)
    makeWaystone(world, BRIDGE_WEST + Vector3.new(-10, 0, 8), bridgeYaw, 0.7)
    makeWaystone(world, BRIDGE_EAST + Vector3.new(10, 0, -8), bridgeYaw + math.pi, 0.7)

    local routeBeacons = {
        { Vector3.new(-260, 1, 146), math.rad(40), 0.58, 1 },
        { Vector3.new(-219, 2, 97), math.rad(62), 0.6, -1 },
        { Vector3.new(-112, 3.8, 64), math.rad(88), 0.58, 1 },
        { Vector3.new(58, 2.8, 38), math.rad(-88), 0.6, -1 },
        { Vector3.new(-132, 2.5, 174), math.rad(18), 0.58, -1 },
        { Vector3.new(-239, 1.5, 5), math.rad(42), 0.58, 1 },
        { Vector3.new(168, 1.5, 112), math.rad(-74), 0.62, 1 },
        { Vector3.new(219, 7.8, -174), math.rad(34), 0.62, -1 },
    }
    for index, beacon in routeBeacons do
        local localFrame = CFrame.new(beacon[1]) * CFrame.Angles(0, beacon[2], 0)
        local side = beacon[4]
        local waystonePosition = (localFrame * CFrame.new(9.5 * side, 0, 0)).Position
        makeWaystone(world, waystonePosition, beacon[2], beacon[3])
        if index == 1 or index == 3 or index == 5 or index == 7 then
            local lampPosition = (localFrame * CFrame.new(14 * side, 0, 0)).Position
            local lampYaw = beacon[2] + if side > 0 then math.pi else 0
            makeLantern(world, lampPosition, lampYaw)
        end
    end

    -- Wayfarer Camp is a compact west-basin camp, with the main road leaving
    -- east and the Proving Circle spur peeling south.
    makeCampfire(world, WORLD_ZONES.Camp + Vector3.new(8, 0, -2))
    makeTent(world, WORLD_ZONES.Camp + Vector3.new(-24, 0.2, -20), math.rad(25))
    makeTent(world, WORLD_ZONES.Camp + Vector3.new(-27, 0.2, 22), math.rad(-20))
    makeTent(world, WORLD_ZONES.Camp + Vector3.new(-37, 0.2, 1), math.rad(69))
    makeCampBench(world, WORLD_ZONES.Camp + Vector3.new(10, 0, -13), math.rad(7))
    makeCampBench(world, WORLD_ZONES.Camp + Vector3.new(20, 0, 7), math.rad(78))
    makeMapTable(world, WORLD_ZONES.Camp + Vector3.new(-8, 0, 8), math.rad(10))
    makeSupplyStack(world, WORLD_ZONES.Camp + Vector3.new(-34, 0, 3), math.rad(-8))
    makeSupplyStack(world, WORLD_ZONES.Camp + Vector3.new(-19, 0, 27), math.rad(18))
    makeCampBanner(world, WORLD_ZONES.Camp + Vector3.new(-7, 0, 27), math.rad(3))
    makeSignpost(
        world,
        WORLD_ZONES.Camp + Vector3.new(33, 0, -15),
        math.rad(-30),
        "LUMENWOOD",
        "PROVING CIRCLE"
    )
    for _, offset in
        {
            { Vector3.new(29, 0, -23), math.rad(126) },
            { Vector3.new(34, 0, 10), math.rad(-58) },
            { Vector3.new(-10, 0, 26), math.rad(-82) },
            { Vector3.new(-36, 0, -22), math.rad(32) },
        }
    do
        makeLantern(world, WORLD_ZONES.Camp + offset[1], offset[2])
    end
    makeWaystone(world, WORLD_ZONES.Camp + Vector3.new(32, 0, 20), math.rad(33), 0.68)
    makeFallenLog(world, WORLD_ZONES.Camp + Vector3.new(38, 0.2, 27), math.rad(-29), 0.62, 1)
    makeMossyRockSet(world, WORLD_ZONES.Camp + Vector3.new(-39, 0, 24), math.rad(18), 0.66)
    makePineRoots(world, WORLD_ZONES.Camp + Vector3.new(39, 0, 23), math.rad(-31), 0.64)

    -- Player-height foreground dressing stays on the basin rim, not in the road.
    makeMossyRockSet(world, WORLD_ZONES.Camp + Vector3.new(-40, 0, 15), math.rad(24), 0.52)
    makeFern(world, WORLD_ZONES.Camp + Vector3.new(-35, 0, 13), 0.78, math.rad(14))
    makeBush(world, WORLD_ZONES.Camp + Vector3.new(-29, 0, 28), 0.65)
    makeFlowerPatch(world, WORLD_ZONES.Camp + Vector3.new(-23, 0, 27), 0.65, false)
    makeStump(world, WORLD_ZONES.Camp + Vector3.new(29, 0, -27), 0.58, 2)
    makeFern(world, WORLD_ZONES.Camp + Vector3.new(34, 0, -29), 0.74, math.rad(-37))
    makeRockCluster(world, WORLD_ZONES.Camp + Vector3.new(39, 0, -15), 0.42, 241)

    -- Lumenwood Crossroads sits on a raised saddle overlooking the gorge.
    makeSignpost(
        world,
        WORLD_ZONES.Crossroads + Vector3.new(-14, 0, 10),
        math.rad(-48),
        "LUMEN GORGE",
        "GLOWMERE"
    )
    makeWaystone(world, WORLD_ZONES.Crossroads + Vector3.new(12, 0, 9), math.rad(-24), 0.86)
    makeLantern(world, WORLD_ZONES.Crossroads + Vector3.new(-20, 0, -17), math.rad(38))
    makeRockCluster(world, WORLD_ZONES.Crossroads + Vector3.new(18, 0, -15), 0.52, 12)
    makeMossyRockSet(world, WORLD_ZONES.Crossroads + Vector3.new(-20, 0, 18), math.rad(-18), 0.56)
    makeStump(world, WORLD_ZONES.Crossroads + Vector3.new(20, 0, 17), 0.54, 2)
    makeFlowerPatch(world, WORLD_ZONES.Crossroads + Vector3.new(15, 0, 13), 0.65, true)

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
    makeSignpost(
        world,
        WORLD_ZONES.Glowmere + Vector3.new(-57, 0, -38),
        math.rad(36),
        "LUMENWOOD",
        "MOSSGLEN"
    )

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
    makeSignpost(
        world,
        WORLD_ZONES.CombatGrove + Vector3.new(-47, 0, -51),
        math.rad(67),
        "LUMENWOOD",
        "SUNMOSS"
    )

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
    makeSignpost(
        world,
        WORLD_ZONES.Overlook + Vector3.new(-48, 0, 28),
        math.rad(54),
        "LUMEN ARCH",
        "MOSSGLEN"
    )

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

local function makeWayfarerArrivalMarker(world, groundPosition, yaw)
    local model = Instance.new("Model")
    model.Name = "WayfarerArrivalMarker"
    model.Parent = world
    local base = CFrame.new(groundPosition) * CFrame.Angles(0, yaw, 0)

    -- The arrival mark is a ground sigil, not a platform. Keep the slate nearly
    -- flush with Terrain and break the perimeter with imported moss stones so a
    -- fresh spawn reads as an old Wayfarer site rather than a Roblox spawn pad.
    local disc = makePart(
        model,
        "ArrivalRuneBase",
        Vector3.new(0.1, 4.8, 4.8),
        base * CFrame.new(0, 0.05, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Enum.Material.Slate,
        Color3.fromRGB(61, 77, 69)
    )
    disc.Shape = Enum.PartType.Cylinder
    disc.CanCollide = false
    disc.CanTouch = false
    disc.CanQuery = false
    disc.Transparency = 0.28

    local runeColor = Color3.fromRGB(104, 221, 181)
    local runeSegments = {
        { Size = Vector3.new(0.06, 2.9, 0.32), Offset = Vector3.new(0, 0.13, 0), Yaw = 0 },
        { Size = Vector3.new(0.06, 2.15, 0.28), Offset = Vector3.new(-0.72, 0.14, 0.18), Yaw = 58 },
        { Size = Vector3.new(0.06, 2.15, 0.28), Offset = Vector3.new(0.72, 0.14, 0.18), Yaw = -58 },
        { Size = Vector3.new(0.06, 1.55, 0.24), Offset = Vector3.new(0, 0.15, 0.95), Yaw = 90 },
    }
    local glowParent = nil
    for index, spec in runeSegments do
        local rune = makePart(
            model,
            "ArrivalLumenRune" .. index,
            spec.Size,
            base * CFrame.new(spec.Offset) * CFrame.Angles(0, math.rad(spec.Yaw), math.rad(90)),
            Enum.Material.Neon,
            runeColor
        )
        rune.CanCollide = false
        rune.CanTouch = false
        rune.CanQuery = false
        rune.Transparency = 0.12 + index * 0.02
        glowParent = glowParent or rune
    end

    for index, localOffset in
        {
            Vector3.new(-3.4, 0, -1.4),
            Vector3.new(3.2, 0, -1.7),
            Vector3.new(-2.8, 0, 2.4),
            Vector3.new(3.0, 0, 2.2),
        }
    do
        local worldPosition = (base * CFrame.new(localOffset)).Position
        makeMossyRockSet(
            model,
            worldPosition,
            yaw + math.rad(index * 37),
            0.2 + (index % 2) * 0.035
        )
    end

    makeFern(model, (base * CFrame.new(-3.7, 0, 2.8)).Position, 0.42, yaw + math.rad(16))
    makeFern(model, (base * CFrame.new(3.8, 0, -2.4)).Position, 0.38, yaw + math.rad(-31))

    if glowParent then
        local glow = Instance.new("PointLight")
        glow.Color = runeColor
        glow.Brightness = 0.3
        glow.Range = 7
        glow.Shadows = false
        glow.Parent = glowParent
    end
    return model
end

local function makeSpawn(world)
    local yaw = math.rad(128)
    local groundPosition = terrainSurfacePosition(WORLD_ZONES.Camp + Vector3.new(-31, 0, 19), 0)
    makeWayfarerArrivalMarker(world, groundPosition, yaw)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "LumenreachSpawn"
    spawn.Size = Vector3.new(6, 0.5, 6)
    spawn.CFrame = CFrame.new(groundPosition + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, yaw, 0)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.CanCollide = false
    spawn.CanTouch = false
    spawn.CanQuery = false
    spawn.Transparency = 1
    spawn.Duration = 0
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
        WORLD_ZONES.Camp + Vector3.new(29, 0, 19),
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

    makeStoryRemnant(world, WORLD_ZONES.Crossroads + Vector3.new(17, 0, -16), math.rad(26))
    makeStoryRemnant(world, WORLD_ZONES.Ruins + Vector3.new(-34, 0, -42), math.rad(-41))
    makeStoryRemnant(world, WORLD_ZONES.Overlook + Vector3.new(46, 2.0, 12), math.rad(79))
    makeWhisperrootHollow(world)

    -- Run final scene clearance only after all authored world props exist. This
    -- prevents late-added remnants/landmarks from bypassing the route and
    -- protected-gameplay readability rules established by the decoration pass.
    clearTravelLaneDecor(world)
    clearProtectedGameplayDecor(world)

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

    EnemySpawnerService.Spawn(
        "training_dummy",
        WORLD_ZONES.Camp + Vector3.new(31, 0, -5),
        world,
        { GroundToTerrain = true, GroundClearance = 0.1 }
    )

    makeMonsterSpawnTrigger(world, "LumenwoodMosslings", Vector3.new(-226, 1.5, 123), {
        MonsterType = "LumenMossling",
        SpawnAmount = 4,
        TriggerRadius = 25,
        SpawnRadius = 12,
        MaxAliveMonster = 4,
        SpawnDelay = 0.34,
        RespawnTime = 18,
    })
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
