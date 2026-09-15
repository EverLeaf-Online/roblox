local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local EnemySpawnerService = require(script.Parent.EnemySpawnerService)
local EnvironmentPrefabService = require(script.Parent.EnvironmentPrefabService)
local InteractionService = require(script.Parent.InteractionService)
local InventoryService = require(script.Parent.InventoryService)
local PBRMaterialService = require(script.Parent.PBRMaterialService)
local EnvironmentClearanceRules = require(ReplicatedStorage.Shared.Logic.EnvironmentClearanceRules)
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
local WORLD_WIDTH = 2200
local WORLD_DEPTH = 1700
local FOLIAGE_MATERIAL = Enum.Material.SmoothPlastic

-- Lumenreach is the complete Level 1-10 MMORPG starter region. The macro layout
-- is intentionally large enough to feel like a world rather than a showcase:
-- a western town, a safe opening field, a central crossroads and river crossing,
-- three optional adventure loops, a group-combat valley, and a far-eastern gate.
local WORLD_ZONES = table.freeze({
    Camp = Vector3.new(-860, 0, 40),
    Crossroads = Vector3.new(-520, 8, 70),
    Glowmere = Vector3.new(-500, -2, 430),
    CombatGrove = Vector3.new(-80, 2, 300),
    Overlook = Vector3.new(300, 24, 430),
    Waterfall = Vector3.new(80, -14, -330),
    Ruins = Vector3.new(700, 8, 70),
})

local STARTER_FIELD_ORIGIN = Vector3.new(-680, 0, 85)
local MOSS_HOLLOW_ORIGIN = Vector3.new(-640, 0, 220)
local BRAMBLE_TRAIL_ORIGIN = Vector3.new(270, 4, 210)
local PROVING_CIRCLE_ORIGIN = WORLD_ZONES.Camp + Vector3.new(20, 0, -260)
local TRAINING_YARD_ORIGIN = WORLD_ZONES.Camp + Vector3.new(72, 0, -18)
local ARRIVAL_SPAWN_ORIGIN = WORLD_ZONES.Camp + Vector3.new(-100, 0, 15)
local EAST_LANDING = Vector3.new(-260, 6, 120)
local GRAVEBONE_WATCH_ORIGIN = Vector3.new(-155, 4, 85)

local BRIDGE_WEST = Vector3.new(-390, 5.4, 118)
local BRIDGE_EAST = Vector3.new(-315, 5.0, 118)

local OPENING_ROUTE_POINTS = table.freeze({
    WORLD_ZONES.Camp + Vector3.new(60, 0, 10),
    Vector3.new(-760, 1.0, 65),
    STARTER_FIELD_ORIGIN,
    Vector3.new(-610, 4.0, 80),
    WORLD_ZONES.Crossroads + Vector3.new(-45, 0, 5),
    WORLD_ZONES.Crossroads,
})

local PROVING_SPUR_POINTS = table.freeze({
    WORLD_ZONES.Camp + Vector3.new(5, 0, -50),
    WORLD_ZONES.Camp + Vector3.new(20, 0, -135),
    PROVING_CIRCLE_ORIGIN + Vector3.new(0, 0, 38),
    PROVING_CIRCLE_ORIGIN,
})

local MOSS_HOLLOW_ROUTE_POINTS = table.freeze({
    STARTER_FIELD_ORIGIN,
    Vector3.new(-665, 0, 150),
    MOSS_HOLLOW_ORIGIN,
})

local EASTBRIDGE_ROUTE_POINTS = table.freeze({
    WORLD_ZONES.Crossroads,
    Vector3.new(-470, 8, 90),
    Vector3.new(-430, 6, 105),
    BRIDGE_WEST,
    BRIDGE_EAST,
    EAST_LANDING,
})

local GRAVEBONE_ROUTE_POINTS = table.freeze({
    EAST_LANDING,
    Vector3.new(-220, 5, 108),
    Vector3.new(-185, 4, 96),
    GRAVEBONE_WATCH_ORIGIN,
})

local MOSSGLEN_ROUTE_POINTS = table.freeze({
    EAST_LANDING,
    Vector3.new(-210, 5, 175),
    Vector3.new(-150, 3, 245),
    WORLD_ZONES.CombatGrove + Vector3.new(-65, 0, -35),
    WORLD_ZONES.CombatGrove,
})

local GLOWMERE_ROUTE_POINTS = table.freeze({
    WORLD_ZONES.Crossroads,
    Vector3.new(-515, 7, 180),
    Vector3.new(-510, 3, 300),
    WORLD_ZONES.Glowmere + Vector3.new(0, 0, -55),
    WORLD_ZONES.Glowmere,
})

local GLOWMERE_RETURN_POINTS = table.freeze({
    WORLD_ZONES.Glowmere,
    Vector3.new(-390, 0, 440),
    Vector3.new(-250, 1, 400),
    WORLD_ZONES.CombatGrove + Vector3.new(-80, 0, 45),
    WORLD_ZONES.CombatGrove,
})

local SUNMOSS_ROUTE_POINTS = table.freeze({
    WORLD_ZONES.CombatGrove,
    Vector3.new(20, 6, 335),
    Vector3.new(130, 14, 380),
    WORLD_ZONES.Overlook + Vector3.new(-55, 0, -5),
    WORLD_ZONES.Overlook,
})

local RUINS_ROUTE_POINTS = table.freeze({
    WORLD_ZONES.CombatGrove,
    Vector3.new(60, 3, 270),
    BRAMBLE_TRAIL_ORIGIN,
    Vector3.new(400, 5, 180),
    Vector3.new(540, 7, 120),
    WORLD_ZONES.Ruins + Vector3.new(-80, 0, 25),
    WORLD_ZONES.Ruins,
})

local VEILFALL_ROUTE_POINTS = table.freeze({
    EAST_LANDING,
    Vector3.new(-200, 4, 60),
    Vector3.new(-120, 0, -40),
    Vector3.new(-40, -6, -170),
    WORLD_ZONES.Waterfall + Vector3.new(-50, 0, 40),
    WORLD_ZONES.Waterfall,
})

local VEILFALL_RETURN_POINTS = table.freeze({
    WORLD_ZONES.Waterfall,
    Vector3.new(200, -8, -260),
    Vector3.new(360, -2, -160),
    Vector3.new(500, 4, -40),
    WORLD_ZONES.Ruins + Vector3.new(-70, 0, -20),
    WORLD_ZONES.Ruins,
})

local SUNMOSS_RETURN_POINTS = table.freeze({
    WORLD_ZONES.Overlook,
    Vector3.new(390, 20, 390),
    Vector3.new(500, 15, 300),
    Vector3.new(590, 10, 190),
    WORLD_ZONES.Ruins + Vector3.new(-55, 0, 45),
    WORLD_ZONES.Ruins,
})

-- The Lumen River / gorge cuts diagonally through the region and makes the
-- Eastbridge a real geographic threshold instead of a decorative bridge.
local GORGE_POINTS = table.freeze({
    WORLD_ZONES.Glowmere + Vector3.new(30, 0, -40),
    Vector3.new(-455, -1, 320),
    Vector3.new(-420, -2, 235),
    Vector3.new(-365, -3, 150),
    Vector3.new(-335, -4, 95),
    Vector3.new(-270, -5, 20),
    Vector3.new(-180, -7, -90),
    Vector3.new(-70, -9, -200),
    WORLD_ZONES.Waterfall + Vector3.new(-35, 0, 55),
})

local ROAD_NETWORK = table.freeze({
    table.freeze({ Id = "greenway", Points = OPENING_ROUTE_POINTS, Width = 20.0 }),
    table.freeze({ Id = "proving_spur", Points = PROVING_SPUR_POINTS, Width = 14.5 }),
    table.freeze({ Id = "moss_hollow", Points = MOSS_HOLLOW_ROUTE_POINTS, Width = 13.5 }),
    table.freeze({ Id = "eastbridge", Points = EASTBRIDGE_ROUTE_POINTS, Width = 19.0 }),
    table.freeze({ Id = "gravebone_watch", Points = GRAVEBONE_ROUTE_POINTS, Width = 13.5 }),
    table.freeze({ Id = "mossglen", Points = MOSSGLEN_ROUTE_POINTS, Width = 17.5 }),
    table.freeze({ Id = "glowmere_out", Points = GLOWMERE_ROUTE_POINTS, Width = 15.0 }),
    table.freeze({ Id = "glowmere_return", Points = GLOWMERE_RETURN_POINTS, Width = 14.5 }),
    table.freeze({ Id = "sunmoss_up", Points = SUNMOSS_ROUTE_POINTS, Width = 14.5 }),
    table.freeze({ Id = "ruins_main", Points = RUINS_ROUTE_POINTS, Width = 17.0 }),
    table.freeze({ Id = "veilfall_down", Points = VEILFALL_ROUTE_POINTS, Width = 14.5 }),
    table.freeze({ Id = "veilfall_return", Points = VEILFALL_RETURN_POINTS, Width = 15.0 }),
    table.freeze({ Id = "sunmoss_return", Points = SUNMOSS_RETURN_POINTS, Width = 14.5 }),
})

local PROTECTED_GAMEPLAY_CLEARINGS = table.freeze({
    table.freeze({ Id = "arrival_spawn", Center = ARRIVAL_SPAWN_ORIGIN, Radius = 22.0 }),
    table.freeze({ Id = "training_dummy", Center = TRAINING_YARD_ORIGIN, Radius = 16.0 }),
    table.freeze({ Id = "proving_circle", Center = PROVING_CIRCLE_ORIGIN, Radius = 34.0 }),
    table.freeze({
        Id = "proving_entrance",
        Center = PROVING_CIRCLE_ORIGIN + Vector3.new(0, 0, 36),
        Radius = 18.0,
    }),
    table.freeze({ Id = "mossling_hollow", Center = MOSS_HOLLOW_ORIGIN, Radius = 28.0 }),
    table.freeze({ Id = "greenway_field", Center = STARTER_FIELD_ORIGIN, Radius = 52.0 }),
    table.freeze({ Id = "gravebone_watch", Center = GRAVEBONE_WATCH_ORIGIN, Radius = 46.0 }),
    table.freeze({
        Id = "shattered_arch",
        Center = WORLD_ZONES.Ruins + Vector3.new(-20, 0, 30),
        Radius = 38.0,
    }),
    table.freeze({ Id = "ruins_field", Center = WORLD_ZONES.Ruins, Radius = 78.0 }),
    table.freeze({
        Id = "glowmere_slimes",
        Center = WORLD_ZONES.Glowmere + Vector3.new(45, 0, -20),
        Radius = 28.0,
    }),
    table.freeze({ Id = "glowmere_field", Center = WORLD_ZONES.Glowmere, Radius = 70.0 }),
    table.freeze({
        Id = "mossglen_ridgebeaks",
        Center = WORLD_ZONES.CombatGrove + Vector3.new(-20, 0, -25),
        Radius = 32.0,
    }),
    table.freeze({ Id = "mossglen_field", Center = WORLD_ZONES.CombatGrove, Radius = 82.0 }),
    table.freeze({ Id = "brambleback_trail", Center = BRAMBLE_TRAIL_ORIGIN, Radius = 30.0 }),
    table.freeze({
        Id = "veilfall_wisps",
        Center = WORLD_ZONES.Waterfall + Vector3.new(25, 0, 20),
        Radius = 30.0,
    }),
    table.freeze({
        Id = "gravebone_captain",
        Center = GRAVEBONE_WATCH_ORIGIN + Vector3.new(30, 0, -20),
        Radius = 18.0,
    }),
    table.freeze({
        Id = "royal_glowcap",
        Center = WORLD_ZONES.Glowmere + Vector3.new(-38, 0, 32),
        Radius = 18.0,
    }),
    table.freeze({
        Id = "mosswarden",
        Center = WORLD_ZONES.CombatGrove + Vector3.new(38, 0, 35),
        Radius = 38.0,
    }),
})

local TRAVEL_ROUTE_SEGMENTS = {}
local function addTravelPolyline(points)
    for index = 1, #points - 1 do
        table.insert(TRAVEL_ROUTE_SEGMENTS, { points[index], points[index + 1] })
    end
end

for _, route in ROAD_NETWORK do
    addTravelPolyline(route.Points)
end

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
    -- Production first: prefer the EverLeaf-owned Poly Haven tree because its
    -- bark/needle maps are explicitly normalized. Creator Store variants are
    -- fallback-only until they receive the same controlled appearance pass.
    if EnvironmentPrefabService.Get("TreePrimary") then
        return "TreePrimary"
    end

    variant = math.max(1, math.floor(tonumber(variant) or 1))
    local startIndex = ((variant - 1) % TREE_VARIANT_COUNT) + 1
    for offset = 0, TREE_VARIANT_COUNT - 1 do
        local index = ((startIndex + offset - 1) % TREE_VARIANT_COUNT) + 1
        local name = "ForestTree" .. string.format("%02d", index)
        if EnvironmentPrefabService.Get(name) then
            return name
        end
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

local function makeAngularRock(parent, position, size, rotation, color)
    local rock = makePart(
        parent,
        "AngularRock",
        size,
        CFrame.new(position) * CFrame.Angles(rotation.X, rotation.Y, rotation.Z),
        Enum.Material.Slate,
        color or Color3.fromRGB(95, 105, 100)
    )
    rock.CanCollide = false
    rock.CanTouch = false
    rock.CanQuery = false
    rock.TopSurface = Enum.SurfaceType.Smooth
    rock.BottomSurface = Enum.SurfaceType.Smooth
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
    scale = scale or 1
    local ground = terrainSurfacePosition(position, -0.12)
    local model = Instance.new("Model")
    model.Name = "IntegratedRockFace"
    model:SetAttribute("EverLeafTravelClearance", 9.0)
    model.Parent = parent

    local base = CFrame.new(ground) * CFrame.Angles(0, yaw, 0)
    local specs = {
        {
            Offset = Vector3.new(-4.4, 2.0, 0.5),
            Size = Vector3.new(8.8, 4.8, 6.4),
            Rot = Vector3.new(4, -8, 9),
        },
        {
            Offset = Vector3.new(3.9, 1.8, 0.8),
            Size = Vector3.new(7.6, 4.4, 6.0),
            Rot = Vector3.new(-5, 13, -7),
        },
        {
            Offset = Vector3.new(-0.8, 4.3, -0.5),
            Size = Vector3.new(9.2, 5.0, 5.8),
            Rot = Vector3.new(7, 5, 5),
        },
        {
            Offset = Vector3.new(4.6, 5.1, 0.2),
            Size = Vector3.new(6.4, 4.2, 5.2),
            Rot = Vector3.new(-8, -11, 11),
        },
        {
            Offset = Vector3.new(-4.7, 6.0, 0.0),
            Size = Vector3.new(6.5, 4.5, 5.0),
            Rot = Vector3.new(6, 16, -10),
        },
    }
    for index, spec in specs do
        local worldPosition = (base * CFrame.new(spec.Offset * scale)).Position
        local rock = makeAngularRock(
            model,
            worldPosition,
            spec.Size * scale,
            Vector3.new(math.rad(spec.Rot.X), yaw + math.rad(spec.Rot.Y), math.rad(spec.Rot.Z))
        )
        rock.Name = "RockFaceChunk" .. index
        rock.Color = if index % 2 == 0
            then Color3.fromRGB(91, 101, 95)
            else Color3.fromRGB(80, 92, 86)
        rock.CanCollide = false
        rock.CanTouch = false
        rock.CanQuery = false
    end

    makeCollisionProxy(
        model,
        "IntegratedRockFaceCollision",
        Vector3.new(13.2, 8.2, 7.2) * scale,
        base * CFrame.new(0, 3.9 * scale, 0.7 * scale)
    )

    makeMossyRockSet(
        model,
        ground + (base.RightVector * -5.4 + base.LookVector * 2.1) * scale,
        yaw + 0.3,
        0.42 * scale
    )
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

    local cliffRocks = {
        {
            Offset = Vector3.new(-11.0, 3.2, -2.2),
            Size = Vector3.new(13.5, 8.0, 9.5),
            Rot = Vector3.new(4, 10, 7),
        },
        {
            Offset = Vector3.new(10.8, 3.0, -2.0),
            Size = Vector3.new(13.0, 7.6, 9.0),
            Rot = Vector3.new(-5, -12, -6),
        },
        {
            Offset = Vector3.new(-8.0, 9.0, -2.8),
            Size = Vector3.new(10.8, 8.0, 8.0),
            Rot = Vector3.new(8, 21, -8),
        },
        {
            Offset = Vector3.new(7.8, 8.5, -2.6),
            Size = Vector3.new(10.4, 7.5, 7.8),
            Rot = Vector3.new(-7, -24, 9),
        },
        {
            Offset = Vector3.new(-3.5, 14.6, -3.2),
            Size = Vector3.new(8.6, 6.8, 7.0),
            Rot = Vector3.new(6, 34, 4),
        },
        {
            Offset = Vector3.new(3.9, 14.0, -3.1),
            Size = Vector3.new(8.2, 6.4, 6.8),
            Rot = Vector3.new(-5, -37, -5),
        },
    }
    for index, spec in cliffRocks do
        local rock = makeAngularRock(
            model,
            ground + spec.Offset,
            spec.Size,
            Vector3.new(math.rad(spec.Rot.X), math.rad(spec.Rot.Y), math.rad(spec.Rot.Z))
        )
        rock.Name = "VeilfallCliffRock" .. index
        rock.Color = if index % 2 == 0
            then Color3.fromRGB(79, 91, 86)
            else Color3.fromRGB(88, 99, 93)
        rock.CanCollide = false
        rock.CanTouch = false
        rock.CanQuery = false
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

    -- Camera-facing beams read as flowing water instead of stacked cyan blocks.
    local ribbonSpecs = {
        { X = -2.6, Width = 1.45, Height = 17.6, Z = 7.72, Drift = -0.35 },
        { X = -0.9, Width = 1.8, Height = 19.2, Z = 7.82, Drift = 0.15 },
        { X = 0.85, Width = 2.0, Height = 20.0, Z = 7.86, Drift = -0.2 },
        { X = 2.65, Width = 1.3, Height = 17.2, Z = 7.74, Drift = 0.3 },
    }
    for index, spec in ribbonSpecs do
        local bottom = makePart(
            model,
            "WaterBottom" .. index,
            Vector3.new(0.12, 0.12, 0.12),
            CFrame.new(ground + Vector3.new(spec.X, 0.55, spec.Z)),
            Enum.Material.SmoothPlastic,
            Color3.new(1, 1, 1)
        )
        bottom.Transparency = 1
        bottom.CanCollide = false
        bottom.CanTouch = false
        bottom.CanQuery = false

        local top = makePart(
            model,
            "WaterTop" .. index,
            Vector3.new(0.12, 0.12, 0.12),
            CFrame.new(ground + Vector3.new(spec.X + spec.Drift, spec.Height, spec.Z - 0.15)),
            Enum.Material.SmoothPlastic,
            Color3.new(1, 1, 1)
        )
        top.Transparency = 1
        top.CanCollide = false
        top.CanTouch = false
        top.CanQuery = false

        local bottomAttachment = Instance.new("Attachment")
        bottomAttachment.Name = "WaterBottomAttachment"
        bottomAttachment.Parent = bottom
        local topAttachment = Instance.new("Attachment")
        topAttachment.Name = "WaterTopAttachment"
        topAttachment.Parent = top

        local beam = Instance.new("Beam")
        beam.Name = "WaterRibbon" .. index
        beam.Attachment0 = topAttachment
        beam.Attachment1 = bottomAttachment
        beam.FaceCamera = true
        beam.Width0 = spec.Width * 0.78
        beam.Width1 = spec.Width
        beam.Segments = 8
        beam.CurveSize0 = spec.Drift * 0.35
        beam.CurveSize1 = -spec.Drift * 0.2
        beam.LightEmission = 0.18
        beam.LightInfluence = 0.35
        beam.Color = ColorSequence.new(Color3.fromRGB(126, 213, 226), Color3.fromRGB(185, 238, 237))
        beam.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.72, 0.58),
            NumberSequenceKeypoint.new(1, 0.72),
        })
        beam.Parent = model
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
    local forestPollenProfile = {
        Texture = "rbxasset://textures/particles/sparkles_main.dds",
        Rate = 0.42,
        Lifetime = NumberRange.new(4.8, 7.2),
        Speed = NumberRange.new(0.08, 0.24),
        SpreadAngle = Vector2.new(70, 45),
        Color = Color3.fromRGB(205, 230, 176),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.72),
            NumberSequenceKeypoint.new(0.45, 0.5),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.045),
            NumberSequenceKeypoint.new(0.55, 0.095),
            NumberSequenceKeypoint.new(1, 0.035),
        }),
        LightEmission = 0.08,
        Acceleration = Vector3.new(0.11, 0.035, 0.05),
        RotSpeed = NumberRange.new(-12, 12),
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
            Vector3.new(-18, 4.2, 8),
            Vector3.new(16, 4.8, -11),
            Vector3.new(-4, 5.1, 24),
        }
    do
        makeAmbientParticleAnchor(
            world,
            "CampForestPollen" .. index,
            WORLD_ZONES.Camp + offset,
            forestPollenProfile
        )
    end

    for index, offset in
        {
            Vector3.new(-17, 5.1, 7),
            Vector3.new(16, 5.5, -6),
        }
    do
        makeAmbientParticleAnchor(
            world,
            "CrossroadsForestPollen" .. index,
            WORLD_ZONES.Crossroads + offset,
            forestPollenProfile
        )
    end

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

    local spireRocks = {
        {
            Offset = Vector3.new(-2.5, 2.2, 0.4),
            Size = Vector3.new(7.5, 8.2, 6.4),
            Rot = Vector3.new(5, 12, 8),
        },
        {
            Offset = Vector3.new(2.8, 3.1, 1.1),
            Size = Vector3.new(6.8, 9.4, 5.8),
            Rot = Vector3.new(-4, -31, -7),
        },
        {
            Offset = Vector3.new(0.4, 7.2, -1.0),
            Size = Vector3.new(5.8, 8.0, 5.1),
            Rot = Vector3.new(7, 51, 6),
        },
        {
            Offset = Vector3.new(-1.3, 10.2, 0.2),
            Size = Vector3.new(4.8, 6.2, 4.5),
            Rot = Vector3.new(-6, -15, -8),
        },
    }
    for index, spec in spireRocks do
        local rock = makeAngularRock(
            model,
            ground + spec.Offset * scale,
            spec.Size * scale,
            Vector3.new(math.rad(spec.Rot.X), math.rad(spec.Rot.Y), math.rad(spec.Rot.Z))
        )
        rock.Name = "SpireRock" .. index
        rock.Color = if index % 2 == 0
            then Color3.fromRGB(90, 101, 94)
            else Color3.fromRGB(80, 92, 86)
        rock.CanCollide = false
        rock.CanTouch = false
        rock.CanQuery = false
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

        local markerRock = makeAngularRock(
            pathStone,
            (markerBase * CFrame.new(0, 2.55, 0.1)).Position,
            Vector3.new(3.9, 5.4, 2.8),
            Vector3.new(
                math.rad((index % 3 - 1) * 4),
                markerYaw + math.rad((index % 2 == 0) and 7 or -7),
                math.rad((index % 2 == 0) and 5 or -5)
            )
        )
        markerRock.Name = "PathRock"
        markerRock.Color = Color3.fromRGB(86, 99, 91)
        markerRock.CanCollide = false
        markerRock.CanTouch = false
        markerRock.CanQuery = false

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
    local origin = WORLD_ZONES.Waterfall + Vector3.new(-62, 0, -58)
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
            Offset = Vector3.new(-6.2, 5.4, 1.4),
            Size = Vector3.new(7.6, 10.0, 7.0),
            Rot = Vector3.new(4, 28, -13),
        },
        {
            Name = "WhisperrootCrownRight",
            Offset = Vector3.new(6.1, 5.2, 1.5),
            Size = Vector3.new(7.4, 9.6, 6.8),
            Rot = Vector3.new(-3, -31, 14),
        },
        {
            Name = "WhisperrootCrownTop",
            Offset = Vector3.new(0.1, 9.2, 1.8),
            Size = Vector3.new(10.8, 5.2, 6.2),
            Rot = Vector3.new(7, 4, 2),
        },
    }
    for _, spec in crownSpecs do
        local rock = makeAngularRock(
            model,
            ground + spec.Offset,
            spec.Size,
            Vector3.new(math.rad(spec.Rot.X), math.rad(spec.Rot.Y), math.rad(spec.Rot.Z))
        )
        rock.Name = spec.Name
        rock.Color = Color3.fromRGB(82, 95, 88)
        rock.CanCollide = false
        rock.CanTouch = false
        rock.CanQuery = false
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

local function makeWayfarerHall(parent, position, yaw)
    position = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = "WayfarerHall"
    model.Parent = parent
    local base = CFrame.new(position) * CFrame.Angles(0, yaw or 0, 0)
    local timber = Color3.fromRGB(82, 59, 39)
    local plaster = Color3.fromRGB(127, 128, 105)
    local roof = Color3.fromRGB(49, 72, 62)

    local floor = makePart(
        model,
        "HallFloor",
        Vector3.new(28, 0.8, 18),
        base * CFrame.new(0, 0.4, 0),
        Enum.Material.WoodPlanks,
        timber
    )
    floor.CanCollide = true

    local wallSpecs = {
        { "HallBack", Vector3.new(28, 8, 1), Vector3.new(0, 4.4, 8.5) },
        { "HallLeft", Vector3.new(1, 8, 16), Vector3.new(-13.5, 4.4, 0) },
        { "HallRight", Vector3.new(1, 8, 16), Vector3.new(13.5, 4.4, 0) },
        { "HallFrontLeft", Vector3.new(9.2, 8, 1), Vector3.new(-9.4, 4.4, -8.5) },
        { "HallFrontRight", Vector3.new(9.2, 8, 1), Vector3.new(9.4, 4.4, -8.5) },
    }
    for _, spec in wallSpecs do
        local wall = makePart(
            model,
            spec[1],
            spec[2],
            base * CFrame.new(spec[3]),
            Enum.Material.WoodPlanks,
            plaster
        )
        wall.CanCollide = true
    end

    for _, side in { -1, 1 } do
        local roofPanel = makePart(
            model,
            "HallRoof",
            Vector3.new(15.5, 0.75, 20),
            base * CFrame.new(side * 6.0, 10.2, 0) * CFrame.Angles(0, 0, math.rad(side * 24)),
            Enum.Material.WoodPlanks,
            roof
        )
        roofPanel.CanCollide = false
        roofPanel.CanTouch = false
        roofPanel.CanQuery = false
    end

    local lintel = makePart(
        model,
        "HallEntryLintel",
        Vector3.new(8, 0.8, 1.1),
        base * CFrame.new(0, 8.0, -8.55),
        Enum.Material.Wood,
        timber
    )
    lintel.CanCollide = false
    makeLantern(model, (base * CFrame.new(-4.8, 0, -10.5)).Position, yaw or 0)
    makeLantern(model, (base * CFrame.new(4.8, 0, -10.5)).Position, yaw or 0)
    return model
end

local function makeServiceStall(parent, position, yaw, accent)
    position = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = "WayfarerServiceStall"
    model.Parent = parent
    local base = CFrame.new(position) * CFrame.Angles(0, yaw or 0, 0)
    local wood = Color3.fromRGB(91, 65, 43)
    accent = accent or Color3.fromRGB(65, 115, 91)

    local floor = makePart(
        model,
        "StallFloor",
        Vector3.new(12, 0.5, 8),
        base * CFrame.new(0, 0.25, 0),
        Enum.Material.WoodPlanks,
        wood
    )
    floor.CanCollide = true
    for _, x in { -5.2, 5.2 } do
        for _, z in { -3.2, 3.2 } do
            local post = makePart(
                model,
                "StallPost",
                Vector3.new(0.45, 6.5, 0.45),
                base * CFrame.new(x, 3.25, z),
                Enum.Material.Wood,
                wood
            )
            post.CanCollide = false
        end
    end
    local canopy = makePart(
        model,
        "StallCanopy",
        Vector3.new(13, 0.35, 9),
        base * CFrame.new(0, 6.55, 0),
        Enum.Material.Fabric,
        accent
    )
    canopy.CanCollide = false
    canopy.CanTouch = false
    canopy.CanQuery = false
    local counter = makePart(
        model,
        "StallCounter",
        Vector3.new(10.5, 1.1, 1.2),
        base * CFrame.new(0, 2.0, -2.5),
        Enum.Material.WoodPlanks,
        wood
    )
    counter.CanCollide = true
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
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.CastShadow = false

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "LandmarkLabel"
    billboard.Size = UDim2.fromOffset(310, 40)
    billboard.AlwaysOnTop = false
    billboard.MaxDistance = 130
    billboard.Parent = anchor

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 30)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(226, 244, 230)
    label.TextStrokeColor3 = Color3.fromRGB(18, 30, 26)
    label.TextStrokeTransparency = 0.24
    label.Font = Enum.Font.GothamMedium
    label.TextScaled = true
    label.TextWrapped = false
    label.Parent = billboard

    local accent = Instance.new("Frame")
    accent.Name = "LumenAccent"
    accent.AnchorPoint = Vector2.new(0.5, 0)
    accent.Position = UDim2.fromScale(0.5, 0.82)
    accent.Size = UDim2.fromOffset(78, 2)
    accent.BackgroundColor3 = Color3.fromRGB(103, 224, 187)
    accent.BackgroundTransparency = 0.24
    accent.BorderSizePixel = 0
    accent.Parent = billboard
end

local function makeZoneMarker(parent, id, displayName, center, radius, minLevel, maxLevel, role)
    local marker = makePart(
        parent,
        "Zone_" .. id,
        Vector3.new(2, 0.4, 2),
        CFrame.new(center + Vector3.new(0, 0.2, 0)),
        Enum.Material.SmoothPlastic,
        Color3.new(1, 1, 1)
    )
    marker.Transparency = 1
    marker.CanCollide = false
    marker.CanTouch = false
    marker.CanQuery = false
    marker:SetAttribute("ZoneId", id)
    marker:SetAttribute("DisplayName", displayName)
    marker:SetAttribute("Radius", radius)
    marker:SetAttribute("RecommendedLevelMin", minLevel)
    marker:SetAttribute("RecommendedLevelMax", maxLevel)
    marker:SetAttribute("ZoneRole", role)
    CollectionService:AddTag(marker, "MMOZone")
    return marker
end

local function prepareGround(_world)
    for _, child in Workspace:GetChildren() do
        if child:IsA("SpawnLocation") then
            child:Destroy()
        end
    end

    for _, child in Workspace:GetChildren() do
        if child:IsA("BasePart") then
            local lowerName = string.lower(child.Name)
            local namedBaseplate = lowerName == "baseplate" or lowerName == "base plate"
            local legacyFloor = child.Size.X >= 700
                and child.Size.Z >= 600
                and child.Size.Y <= 24
                and child.Position.Y <= 6
                and child.Material == Enum.Material.Plastic
            if namedBaseplate or legacyFloor then
                child:Destroy()
            end
        end
    end

    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return
    end

    terrain:Clear()
    terrain:FillBlock(
        CFrame.new(-40, -6, 35),
        Vector3.new(WORLD_WIDTH + 180, 12, WORLD_DEPTH + 180),
        Enum.Material.Grass
    )

    local function fillClearing(center, size, material)
        terrain:FillBlock(
            CFrame.new(center + Vector3.new(0, -0.9, 0)),
            Vector3.new(size.X, 3.4, size.Z),
            material
        )
    end

    local function fillTrail(a, b, width)
        local startPoint = Vector3.new(a.X, a.Y + 0.22, a.Z)
        local endPoint = Vector3.new(b.X, b.Y + 0.22, b.Z)
        local length = (endPoint - startPoint).Magnitude
        if length < 0.1 then
            return
        end
        local midpoint = (startPoint + endPoint) * 0.5
        terrain:FillBlock(
            CFrame.lookAt(midpoint - Vector3.new(0, 0.18, 0), endPoint - Vector3.new(0, 0.18, 0)),
            Vector3.new(width + 12, 0.9, length + 5),
            Enum.Material.Mud
        )
        terrain:FillBlock(
            CFrame.lookAt(midpoint, endPoint),
            Vector3.new(width, 1.2, length + 4),
            Enum.Material.Ground
        )
    end

    local function carveTrailPass(a, b, width)
        local startPoint = Vector3.new(a.X, a.Y + 8, a.Z)
        local endPoint = Vector3.new(b.X, b.Y + 8, b.Z)
        local length = (endPoint - startPoint).Magnitude
        if length < 0.1 then
            return
        end
        local midpoint = (startPoint + endPoint) * 0.5
        terrain:FillBlock(
            CFrame.lookAt(midpoint, endPoint),
            Vector3.new(width + 16, 17, length + 10),
            Enum.Material.Air
        )
        fillTrail(a, b, width)
    end

    local function fillRidge(points, radius, peakY, material)
        material = material or Enum.Material.Grass
        for index = 1, #points - 1 do
            local a = points[index]
            local b = points[index + 1]
            local steps = math.max(1, math.ceil((b - a).Magnitude / 22))
            for step = 0, steps do
                local alpha = step / steps
                local point = a:Lerp(b, alpha)
                local wobble = math.sin((index * 13 + step) * 0.87) * 1.9
                terrain:FillBall(
                    Vector3.new(point.X, peakY - radius + wobble * 0.16, point.Z),
                    radius + wobble,
                    material
                )
            end
        end
    end

    local function fillLayeredRidge(points, radius, peakY)
        fillRidge(points, radius, peakY - 1.2, Enum.Material.Basalt)
        fillRidge(points, math.max(8, radius - 6), peakY + 0.8, Enum.Material.Grass)
    end

    -- Natural mountain walls define the 2200x1700 play space without a visible
    -- ring of arbitrary blockers.
    fillLayeredRidge({
        Vector3.new(-1060, 0, 720),
        Vector3.new(-860, 0, 790),
        Vector3.new(-620, 0, 810),
        Vector3.new(-360, 0, 800),
        Vector3.new(-100, 0, 815),
        Vector3.new(160, 0, 800),
        Vector3.new(410, 0, 770),
        Vector3.new(650, 0, 720),
        Vector3.new(890, 0, 640),
    }, 48, 31)
    fillLayeredRidge({
        Vector3.new(900, 0, 620),
        Vector3.new(1010, 0, 430),
        Vector3.new(1030, 0, 200),
        Vector3.new(1020, 0, -60),
        Vector3.new(970, 0, -310),
        Vector3.new(870, 0, -560),
    }, 50, 33)
    fillLayeredRidge({
        Vector3.new(850, 0, -600),
        Vector3.new(620, 0, -710),
        Vector3.new(350, 0, -760),
        Vector3.new(60, 0, -780),
        Vector3.new(-230, 0, -770),
        Vector3.new(-520, 0, -730),
        Vector3.new(-790, 0, -650),
        Vector3.new(-1010, 0, -520),
    }, 51, 31)
    fillLayeredRidge({
        Vector3.new(-1030, 0, -500),
        Vector3.new(-1090, 0, -270),
        Vector3.new(-1100, 0, -20),
        Vector3.new(-1090, 0, 240),
        Vector3.new(-1080, 0, 480),
        Vector3.new(-1060, 0, 700),
    }, 49, 30)

    -- Camp basin, starter fields, and advancement spur.
    fillLayeredRidge({
        Vector3.new(-1010, 0, 200),
        Vector3.new(-990, 0, 100),
        Vector3.new(-980, 0, -20),
        Vector3.new(-945, 0, -120),
    }, 29, 15)
    fillLayeredRidge({
        Vector3.new(-1010, 0, 230),
        Vector3.new(-900, 0, 270),
        Vector3.new(-790, 0, 260),
        Vector3.new(-720, 0, 225),
    }, 27, 14)
    fillLayeredRidge({
        Vector3.new(-790, 0, -30),
        Vector3.new(-705, 0, -15),
        Vector3.new(-620, 0, 15),
    }, 22, 12)
    fillLayeredRidge({
        Vector3.new(-760, 0, 275),
        Vector3.new(-690, 0, 310),
        Vector3.new(-610, 0, 295),
    }, 20, 11)

    -- Crossroads saddle and Glowmere bowl.
    fillLayeredRidge({
        Vector3.new(-600, 5, 20),
        Vector3.new(-530, 8, 5),
        Vector3.new(-455, 7, 20),
    }, 20, 14)
    fillLayeredRidge({
        Vector3.new(-650, 0, 390),
        Vector3.new(-630, 0, 500),
        Vector3.new(-560, 0, 555),
    }, 28, 15)
    fillLayeredRidge({
        Vector3.new(-430, 0, 565),
        Vector3.new(-320, 0, 575),
        Vector3.new(-220, 0, 540),
    }, 26, 15)

    -- Mossglen valley is deliberately broad enough for shared encounters.
    fillLayeredRidge({
        Vector3.new(-210, 0, 465),
        Vector3.new(-80, 0, 500),
        Vector3.new(65, 0, 485),
        Vector3.new(165, 0, 435),
    }, 29, 16)
    fillLayeredRidge({
        Vector3.new(120, 0, 390),
        Vector3.new(180, 0, 315),
        Vector3.new(175, 0, 240),
    }, 25, 14)
    fillLayeredRidge({
        Vector3.new(-225, 0, 230),
        Vector3.new(-120, 0, 205),
        Vector3.new(-5, 0, 215),
    }, 23, 12)

    -- Sunmoss highland has actual supporting terrain rather than floating props.
    fillLayeredRidge({
        Vector3.new(130, 6, 380),
        Vector3.new(235, 16, 430),
        Vector3.new(330, 24, 455),
        Vector3.new(430, 20, 425),
        Vector3.new(500, 14, 350),
    }, 32, 29)
    terrain:FillBall(WORLD_ZONES.Overlook + Vector3.new(0, -31, 0), 54, Enum.Material.Basalt)
    terrain:FillBall(WORLD_ZONES.Overlook + Vector3.new(0, -25, 0), 47, Enum.Material.Grass)

    -- Long eastern approach makes the Brasshaven gate a zone capstone.
    fillLayeredRidge({
        Vector3.new(210, 1, 115),
        Vector3.new(340, 4, 80),
        Vector3.new(470, 6, 45),
        Vector3.new(610, 8, 30),
        Vector3.new(760, 7, 45),
        Vector3.new(835, 5, 100),
    }, 28, 18)
    fillLayeredRidge({
        Vector3.new(510, 2, 205),
        Vector3.new(635, 5, 220),
        Vector3.new(760, 5, 190),
    }, 24, 15)

    -- Veilfall is a low late-starter ravine with tall shoulders.
    terrain:FillBlock(
        CFrame.new(WORLD_ZONES.Waterfall + Vector3.new(0, 5, 0)),
        Vector3.new(260, 38, 210),
        Enum.Material.Air
    )
    fillLayeredRidge({
        Vector3.new(-80, -5, -420),
        Vector3.new(20, -10, -455),
        Vector3.new(130, -12, -450),
        Vector3.new(240, -7, -410),
    }, 31, 9)
    fillLayeredRidge({
        Vector3.new(-70, -4, -235),
        Vector3.new(30, -9, -215),
        Vector3.new(145, -11, -220),
        Vector3.new(260, -5, -255),
    }, 29, 10)

    fillLayeredRidge({
        Vector3.new(-350, 0, -55),
        Vector3.new(-250, 0, -70),
        Vector3.new(-155, 0, -35),
    }, 21, 11)
    fillLayeredRidge({
        Vector3.new(260, 0, -70),
        Vector3.new(350, 1, -20),
        Vector3.new(435, 3, 25),
    }, 20, 12)

    local function carveGorgeSegment(a, b, width)
        local length = (b - a).Magnitude
        if length < 0.1 then
            return
        end
        local midpoint = (a + b) * 0.5
        terrain:FillBlock(
            CFrame.lookAt(midpoint - Vector3.new(0, 5.3, 0), b - Vector3.new(0, 5.3, 0)),
            Vector3.new(width, 15.0, length + 8),
            Enum.Material.Air
        )
        terrain:FillBlock(
            CFrame.lookAt(midpoint - Vector3.new(0, 12.0, 0), b - Vector3.new(0, 12.0, 0)),
            Vector3.new(width - 3, 3.2, length + 5),
            Enum.Material.Basalt
        )
        terrain:FillBlock(
            CFrame.lookAt(midpoint - Vector3.new(0, 8.2, 0), b - Vector3.new(0, 8.2, 0)),
            Vector3.new(width - 9, 3.2, length + 4),
            Enum.Material.Water
        )
    end
    for index = 1, #GORGE_POINTS - 1 do
        carveGorgeSegment(
            GORGE_POINTS[index],
            GORGE_POINTS[index + 1],
            54 + math.min(index, 5) * 2.5
        )
    end

    -- Broad MMO rooms keep town services and party combat readable.
    fillClearing(WORLD_ZONES.Camp, Vector3.new(220, 0, 158), Enum.Material.Ground)
    fillClearing(STARTER_FIELD_ORIGIN, Vector3.new(190, 0, 132), Enum.Material.Ground)
    fillClearing(MOSS_HOLLOW_ORIGIN, Vector3.new(96, 0, 82), Enum.Material.Ground)
    fillClearing(GRAVEBONE_WATCH_ORIGIN, Vector3.new(112, 0, 92), Enum.Material.Ground)
    fillClearing(WORLD_ZONES.Crossroads, Vector3.new(138, 0, 108), Enum.Material.Ground)
    fillClearing(WORLD_ZONES.Glowmere, Vector3.new(220, 0, 170), Enum.Material.Ground)
    fillClearing(WORLD_ZONES.CombatGrove, Vector3.new(250, 0, 198), Enum.Material.Ground)
    fillClearing(BRAMBLE_TRAIL_ORIGIN, Vector3.new(116, 0, 92), Enum.Material.Ground)
    fillClearing(WORLD_ZONES.Overlook, Vector3.new(190, 0, 142), Enum.Material.Ground)
    fillClearing(WORLD_ZONES.Waterfall, Vector3.new(220, 0, 158), Enum.Material.Ground)
    fillClearing(WORLD_ZONES.Ruins, Vector3.new(240, 0, 178), Enum.Material.Ground)
    fillClearing(PROVING_CIRCLE_ORIGIN, Vector3.new(120, 0, 120), Enum.Material.Ground)

    -- Glowmere has a real lake with usable shoreline and an authored crossing.
    terrain:FillBall(WORLD_ZONES.Glowmere + Vector3.new(10, -9, 10), 58, Enum.Material.Air)
    terrain:FillBlock(
        CFrame.new(WORLD_ZONES.Glowmere + Vector3.new(10, -3.6, 10)),
        Vector3.new(100, 6.2, 90),
        Enum.Material.Water
    )

    local function samePoint(a, b)
        return (a - b).Magnitude < 0.1
    end

    for _, route in ROAD_NETWORK do
        for index = 1, #route.Points - 1 do
            local a = route.Points[index]
            local b = route.Points[index + 1]
            local bridgeSpan = (samePoint(a, BRIDGE_WEST) and samePoint(b, BRIDGE_EAST))
                or (samePoint(a, BRIDGE_EAST) and samePoint(b, BRIDGE_WEST))
            if not bridgeSpan then
                carveTrailPass(a, b, route.Width)
            end
        end
    end

    -- Roads are cut last, then main gameplay floors are restored to keep grass
    -- away from NPC prompts and combat telegraphs.
    fillClearing(WORLD_ZONES.Camp, Vector3.new(210, 0, 148), Enum.Material.Ground)
    fillClearing(STARTER_FIELD_ORIGIN, Vector3.new(180, 0, 122), Enum.Material.Ground)
    fillClearing(MOSS_HOLLOW_ORIGIN, Vector3.new(90, 0, 76), Enum.Material.Ground)
    fillClearing(GRAVEBONE_WATCH_ORIGIN, Vector3.new(104, 0, 84), Enum.Material.Ground)
    fillClearing(WORLD_ZONES.CombatGrove, Vector3.new(235, 0, 185), Enum.Material.Ground)
    fillClearing(BRAMBLE_TRAIL_ORIGIN, Vector3.new(108, 0, 86), Enum.Material.Ground)
    fillClearing(WORLD_ZONES.Ruins, Vector3.new(228, 0, 166), Enum.Material.Ground)
    fillClearing(PROVING_CIRCLE_ORIGIN, Vector3.new(112, 0, 112), Enum.Material.Ground)
    fillClearing(WORLD_ZONES.Waterfall, Vector3.new(205, 0, 145), Enum.Material.Ground)
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

local function travelDecorationClearance(instance)
    if typeof(instance) ~= "Instance" then
        return nil
    end
    return EnvironmentClearanceRules.Resolve(
        instance.Name,
        instance:GetAttribute("SourcePrefabName"),
        instance:GetAttribute("EverLeafTravelClearance")
    )
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
        local clearance = travelDecorationClearance(child)
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
        if travelDecorationClearance(child) then
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
        if protectOpeningRoute then
            makeMossyRockSet(parent, bushPosition, rotation + 0.2, 0.28 * scale)
        else
            makeBush(parent, bushPosition, 0.82 * scale)
        end
    end
    if not protectOpeningRoute or isOpeningRouteClear(fernPosition, 9.5) then
        makeFern(parent, fernPosition, 0.78 * scale, rotation)
    end
    if not protectOpeningRoute or isOpeningRouteClear(grassPosition, 9.5) then
        if protectOpeningRoute then
            makeDryBranches(parent, grassPosition, rotation - 0.25, 0.32 * scale)
        else
            makeGrassTuft(parent, grassPosition, 0.78 * scale)
        end
    end
    local groundDetailPosition = center + Vector3.new(-4.7, 0, -3.8) * scale
    if not protectOpeningRoute or isOpeningRouteClear(groundDetailPosition, 8.5) then
        if protectOpeningRoute then
            -- The opening route uses only production imported ground dressing.
            -- Keep the small procedural flowers/mushrooms deeper in Lumenreach
            -- where they read as whimsical accents instead of first-impression
            -- placeholder geometry.
            makeFern(
                parent,
                groundDetailPosition + Vector3.new(1.1, 0, 0.8) * scale,
                0.56 * scale,
                rotation + 0.28
            )
            if seed % 2 == 0 then
                makeDryBranches(parent, groundDetailPosition, rotation - 0.32, 0.4 * scale)
            else
                makeMossyRockSet(parent, groundDetailPosition, rotation + 0.18, 0.33 * scale)
            end
        elseif seed % 2 == 0 then
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
    makeDryBranches(parent, startPoint + right * 14.2 + direction * 4.0, yaw - math.rad(24), 0.42)
    makeFern(parent, startPoint + right * 12.8 + direction * 5.2, 0.56, yaw - math.rad(31))
end

local function makeMosslingHollowFrame(parent)
    local center = MOSS_HOLLOW_ORIGIN
    local spurStart = STARTER_FIELD_ORIGIN
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
    makePineRoots(parent, farEdge + right * 8.6, yaw - math.rad(17), 0.48)
    makeFern(parent, farEdge + right * 6.6 + direction * 1.2, 0.64, yaw + math.rad(14))
end

local function makeTrainingYardMark(parent)
    local center = terrainSurfacePosition(TRAINING_YARD_ORIGIN, 0)
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
        GLOWMERE_ROUTE_POINTS[2] - WORLD_ZONES.Crossroads,
        EASTBRIDGE_ROUTE_POINTS[2] - WORLD_ZONES.Crossroads,
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
        { STARTER_FIELD_ORIGIN, OPENING_ROUTE_POINTS[4] - OPENING_ROUTE_POINTS[2], 401, 1.08 },
        { EASTBRIDGE_ROUTE_POINTS[3], BRIDGE_WEST - WORLD_ZONES.Crossroads, 407, 1.04 },
        { EAST_LANDING, MOSSGLEN_ROUTE_POINTS[2] - EAST_LANDING, 409, 1.06 },
        { GRAVEBONE_ROUTE_POINTS[3], GRAVEBONE_WATCH_ORIGIN - EAST_LANDING, 413, 0.96 },
        { GLOWMERE_ROUTE_POINTS[3], WORLD_ZONES.Glowmere - WORLD_ZONES.Crossroads, 419, 1.0 },
        { SUNMOSS_ROUTE_POINTS[3], WORLD_ZONES.Overlook - WORLD_ZONES.CombatGrove, 421, 1.02 },
        { BRAMBLE_TRAIL_ORIGIN, WORLD_ZONES.Ruins - WORLD_ZONES.CombatGrove, 431, 1.08 },
        { VEILFALL_ROUTE_POINTS[4], WORLD_ZONES.Waterfall - EAST_LANDING, 433, 1.04 },
        { VEILFALL_RETURN_POINTS[4], WORLD_ZONES.Ruins - WORLD_ZONES.Waterfall, 439, 1.08 },
    }
    for _, threshold in thresholds do
        makeTrailThreshold(world, threshold[1], threshold[2], threshold[3], threshold[4])
    end
end

local function decorate(world)
    placeTreeArc(world, Vector3.new(-40, 0, 50), 1010, 760, 58, 5, 355, 2)
    placeTreeArc(world, WORLD_ZONES.Camp, 142, 100, 26, 90, 280, 7)
    placeTreeArc(world, STARTER_FIELD_ORIGIN, 118, 82, 20, 65, 300, 9)
    placeTreeArc(world, WORLD_ZONES.Crossroads, 92, 68, 16, 25, 325, 11)
    placeTreeArc(world, WORLD_ZONES.Glowmere, 138, 108, 20, 10, 335, 13)
    placeTreeArc(world, WORLD_ZONES.CombatGrove, 158, 122, 24, 15, 335, 17)
    placeTreeArc(world, WORLD_ZONES.Overlook, 126, 94, 18, 15, 330, 21)
    placeTreeArc(world, WORLD_ZONES.Waterfall, 132, 104, 20, 85, 280, 25)
    placeTreeArc(world, WORLD_ZONES.Ruins, 142, 106, 20, -45, 290, 29)

    dressZoneEdge(world, WORLD_ZONES.Camp, 100, 70, 22, 3)
    dressZoneEdge(world, STARTER_FIELD_ORIGIN, 82, 58, 16, 5)
    dressZoneEdge(world, WORLD_ZONES.Crossroads, 62, 48, 13, 7)
    dressZoneEdge(world, WORLD_ZONES.Glowmere, 98, 72, 17, 9)
    dressZoneEdge(world, WORLD_ZONES.CombatGrove, 110, 82, 19, 11)
    dressZoneEdge(world, WORLD_ZONES.Overlook, 86, 62, 13, 13)
    dressZoneEdge(world, WORLD_ZONES.Waterfall, 92, 68, 16, 15)
    dressZoneEdge(world, WORLD_ZONES.Ruins, 104, 76, 16, 17)
    makeLocalAtmosphere(world)

    local forestPatches = {
        { Vector3.new(-1000, 0, 380), 70, 58, 14, 41 },
        { Vector3.new(-900, 0, 520), 72, 58, 14, 43 },
        { Vector3.new(-760, 0, 520), 68, 56, 13, 47 },
        { Vector3.new(-900, 0, -250), 72, 60, 14, 53 },
        { Vector3.new(-720, 0, -420), 72, 60, 14, 59 },
        { Vector3.new(-520, 0, -520), 70, 58, 13, 61 },
        { Vector3.new(-330, 0, 650), 68, 56, 13, 67 },
        { Vector3.new(-120, 0, 640), 70, 58, 14, 71 },
        { Vector3.new(100, 0, 620), 72, 58, 14, 73 },
        { Vector3.new(350, 10, 610), 68, 56, 13, 79 },
        { Vector3.new(570, 6, 500), 70, 58, 13, 83 },
        { Vector3.new(780, 4, 390), 68, 56, 13, 89 },
        { Vector3.new(850, 2, 210), 66, 54, 12, 97 },
        { Vector3.new(850, 0, -80), 70, 58, 13, 101 },
        { Vector3.new(700, 0, -330), 74, 60, 14, 103 },
        { Vector3.new(480, -2, -500), 72, 58, 13, 107 },
        { Vector3.new(230, -6, -560), 70, 58, 13, 109 },
        { Vector3.new(-20, -4, -570), 72, 58, 13, 113 },
        { Vector3.new(-280, 0, -550), 74, 60, 14, 127 },
        { Vector3.new(-705, 0, 355), 54, 46, 10, 131 },
        { Vector3.new(-350, 0, 320), 56, 46, 10, 137 },
        { Vector3.new(-250, 0, 245), 54, 44, 10, 139 },
        { Vector3.new(120, 1, 225), 58, 48, 11, 149 },
        { Vector3.new(440, 3, 120), 58, 48, 11, 151 },
        { Vector3.new(480, -2, -130), 58, 48, 11, 157 },
    }
    for _, patch in forestPatches do
        scatterForestPatch(world, patch[1], patch[2], patch[3], patch[4], patch[5])
    end

    local habitatPockets = {
        { Vector3.new(-965, 0, 230), 301, 0.95 },
        { Vector3.new(-785, 0, 330), 303, 0.9 },
        { Vector3.new(-700, 0, -95), 305, 0.88 },
        { Vector3.new(-610, 0, 485), 307, 0.92 },
        { Vector3.new(-355, 0, 510), 309, 0.9 },
        { Vector3.new(-285, 1, 330), 311, 0.88 },
        { Vector3.new(55, 1, 445), 313, 0.92 },
        { Vector3.new(175, 4, 315), 315, 0.88 },
        { Vector3.new(335, 5, 250), 317, 0.9 },
        { Vector3.new(505, 5, 145), 319, 0.88 },
        { Vector3.new(365, -3, -145), 321, 0.92 },
        { Vector3.new(175, -9, -260), 323, 0.9 },
        { Vector3.new(-160, -5, -300), 325, 0.88 },
    }
    for _, pocket in habitatPockets do
        makeHabitatPocket(world, pocket[1], pocket[2], pocket[3])
    end

    dressTravelCorridors(world)

    local openingClusters = {
        { WORLD_ZONES.Camp + Vector3.new(82, 0, 58), 201, 0.86 },
        { WORLD_ZONES.Camp + Vector3.new(78, 0, -60), 203, 0.84 },
        { STARTER_FIELD_ORIGIN + Vector3.new(-62, 0, 48), 205, 0.84 },
        { STARTER_FIELD_ORIGIN + Vector3.new(68, 0, 50), 207, 0.86 },
        { WORLD_ZONES.Crossroads + Vector3.new(-54, 0, 46), 211, 0.82 },
    }
    for _, cluster in openingClusters do
        makeWoodlandCluster(world, cluster[1], cluster[2], cluster[3], true)
    end

    local trailClusters = {
        { OPENING_ROUTE_POINTS[4] + Vector3.new(0, 0, 24), math.rad(32), 21 },
        { EASTBRIDGE_ROUTE_POINTS[3] + Vector3.new(0, 0, 28), math.rad(-24), 23 },
        { MOSSGLEN_ROUTE_POINTS[3] + Vector3.new(18, 0, 0), math.rad(48), 25 },
        { GLOWMERE_ROUTE_POINTS[3] + Vector3.new(-20, 0, 0), math.rad(-38), 27 },
        { GLOWMERE_RETURN_POINTS[3] + Vector3.new(0, 0, 24), math.rad(22), 29 },
        { SUNMOSS_ROUTE_POINTS[3] + Vector3.new(22, 0, 0), math.rad(-31), 31 },
        { RUINS_ROUTE_POINTS[5] + Vector3.new(0, 0, 26), math.rad(42), 33 },
        { VEILFALL_ROUTE_POINTS[4] + Vector3.new(-24, 0, 0), math.rad(-48), 35 },
        { VEILFALL_RETURN_POINTS[4] + Vector3.new(20, 0, 0), math.rad(21), 37 },
    }
    for _, cluster in trailClusters do
        makeTrailsideCluster(world, cluster[1], cluster[2], cluster[3])
    end

    makeRouteThresholds(world)
    makeCampDepartureFrame(world)
    makeMosslingHollowFrame(world)
    makeTrainingYardMark(world)
    makeCrossroadsWayfinderMark(world)

    -- Wayfarer Camp is a starter town: hub hall, services, social plaza, training,
    -- map table, and two clear exits.
    makeWayfarerHall(world, WORLD_ZONES.Camp + Vector3.new(-28, 0, -20), math.rad(8))
    makeServiceStall(
        world,
        WORLD_ZONES.Camp + Vector3.new(-8, 0, 42),
        math.rad(176),
        Color3.fromRGB(104, 83, 52)
    )
    makeServiceStall(
        world,
        WORLD_ZONES.Camp + Vector3.new(-55, 0, -38),
        math.rad(30),
        Color3.fromRGB(76, 71, 108)
    )
    makeCampfire(world, WORLD_ZONES.Camp + Vector3.new(12, 0, 8))
    makeTent(world, WORLD_ZONES.Camp + Vector3.new(-70, 0.2, 40), math.rad(-20))
    makeTent(world, WORLD_ZONES.Camp + Vector3.new(-76, 0.2, -2), math.rad(68))
    makeCampBench(world, WORLD_ZONES.Camp + Vector3.new(14, 0, -18), math.rad(5))
    makeCampBench(world, WORLD_ZONES.Camp + Vector3.new(32, 0, 12), math.rad(80))
    makeMapTable(world, WORLD_ZONES.Camp + Vector3.new(4, 0, 31), math.rad(-8))
    makeSupplyStack(world, WORLD_ZONES.Camp + Vector3.new(-20, 0, 48), math.rad(12))
    makeSupplyStack(world, WORLD_ZONES.Camp + Vector3.new(-62, 0, -22), math.rad(-18))
    makeCampBanner(world, WORLD_ZONES.Camp + Vector3.new(8, 0, 48), math.rad(3))
    makeSignpost(
        world,
        WORLD_ZONES.Camp + Vector3.new(76, 0, 24),
        math.rad(-55),
        "GREENWAY / LUMENWOOD",
        "PROVING CIRCLE"
    )
    makeSignpost(
        world,
        WORLD_ZONES.Camp + Vector3.new(-4, 0, -68),
        math.rad(180),
        "PROVING CIRCLE",
        "WAYFARER CAMP"
    )
    for _, entry in
        {
            { Vector3.new(58, 0, 30), math.rad(-50) },
            { Vector3.new(60, 0, -32), math.rad(-115) },
            { Vector3.new(-38, 0, 58), math.rad(178) },
            { Vector3.new(-70, 0, 15), math.rad(65) },
        }
    do
        makeLantern(world, WORLD_ZONES.Camp + entry[1], entry[2])
    end

    -- Greenway Fields / Mossling Hollow are the first open combat step.
    makeWaystone(world, STARTER_FIELD_ORIGIN + Vector3.new(-58, 0, -30), math.rad(62), 0.78)
    makeLantern(world, STARTER_FIELD_ORIGIN + Vector3.new(-54, 0, 31), math.rad(80))
    makeSignpost(
        world,
        STARTER_FIELD_ORIGIN + Vector3.new(54, 0, -34),
        math.rad(-68),
        "LUMENWOOD CROSSROADS",
        "MOSSLING HOLLOW"
    )
    makeFallenLog(world, STARTER_FIELD_ORIGIN + Vector3.new(42, 0.2, 44), math.rad(-35), 0.68, 1)
    makeMossyRockSet(world, STARTER_FIELD_ORIGIN + Vector3.new(-48, 0, 38), math.rad(18), 0.58)
    makeFern(world, STARTER_FIELD_ORIGIN + Vector3.new(48, 0, -42), 0.7, math.rad(-30))

    -- Crossroads exposes the three major regional routes at a glance.
    makeSignpost(
        world,
        WORLD_ZONES.Crossroads + Vector3.new(-22, 0, 14),
        math.rad(-35),
        "GLOWMERE",
        "EASTBRIDGE / MOSSGLEN"
    )
    makeWaystone(world, WORLD_ZONES.Crossroads + Vector3.new(21, 0, 13), math.rad(-24), 0.94)
    makeLantern(world, WORLD_ZONES.Crossroads + Vector3.new(-30, 0, -24), math.rad(38))
    makeCampBench(world, WORLD_ZONES.Crossroads + Vector3.new(30, 0, -22), math.rad(82))

    -- Eastbridge is the hard geographic threshold across the Lumen River.
    local bridgeDelta = BRIDGE_EAST - BRIDGE_WEST
    local bridgeFlat = Vector3.new(bridgeDelta.X, 0, bridgeDelta.Z)
    local bridgeMid = (BRIDGE_WEST + BRIDGE_EAST) * 0.5
    local bridgeYaw = math.atan2(bridgeFlat.X, bridgeFlat.Z)
    makeBridge(world, bridgeMid - Vector3.new(0, 0.7, 0), bridgeYaw, bridgeFlat.Magnitude + 7, 10.0)
    makeLantern(world, BRIDGE_WEST + Vector3.new(-9, 0, -10), bridgeYaw + math.pi)
    makeLantern(world, BRIDGE_EAST + Vector3.new(9, 0, 10), bridgeYaw)
    makeWaystone(world, BRIDGE_WEST + Vector3.new(-13, 0, 11), bridgeYaw, 0.8)
    makeWaystone(world, BRIDGE_EAST + Vector3.new(13, 0, -11), bridgeYaw + math.pi, 0.8)
    makeSignpost(
        world,
        EAST_LANDING + Vector3.new(18, 0, 8),
        math.rad(-68),
        "MOSSGLEN / SUNMOSS",
        "GRAVEBONE WATCH / VEILFALL"
    )

    -- Gravebone Watch is the first ruined-combat pocket after Eastbridge. It
    -- gives the level-3 skeleton quest a believable destination without sending
    -- new players all the way to the Level-10 Shattered Arch capstone.
    makeStoryRemnant(world, GRAVEBONE_WATCH_ORIGIN + Vector3.new(-12, 0, 58), math.rad(24))
    makeStoryRemnant(world, GRAVEBONE_WATCH_ORIGIN + Vector3.new(18, 0, -58), math.rad(-38))
    makeWaystone(world, GRAVEBONE_WATCH_ORIGIN + Vector3.new(-50, 0, -40), math.rad(52), 0.7)
    makeLantern(world, GRAVEBONE_WATCH_ORIGIN + Vector3.new(-52, 0, 38), math.rad(138))
    makeMossyRockSet(world, GRAVEBONE_WATCH_ORIGIN + Vector3.new(54, 0, 38), math.rad(-28), 0.62)
    makeDryBranches(world, GRAVEBONE_WATCH_ORIGIN + Vector3.new(50, 0, -44), math.rad(31), 0.58)

    -- Glowmere is a substantial wetland exploration loop with its own crossing.
    makeBridge(world, WORLD_ZONES.Glowmere + Vector3.new(10, 0.5, 10), math.rad(8), 84, 8.0)
    makeWaystone(world, WORLD_ZONES.Glowmere + Vector3.new(-82, 0, -42), math.rad(-48), 0.82)
    makeFallenLog(world, WORLD_ZONES.Glowmere + Vector3.new(72, 0.2, 46), math.rad(-38), 0.8, 1)
    for index, offset in
        {
            Vector3.new(-60, 0, -26),
            Vector3.new(-65, 0, 16),
            Vector3.new(-44, 0, 54),
            Vector3.new(46, 0, 54),
            Vector3.new(67, 0, 16),
            Vector3.new(62, 0, -34),
        }
    do
        makeCattailCluster(
            world,
            WORLD_ZONES.Glowmere + offset,
            0.8 + (index % 3) * 0.05,
            index + 10
        )
    end
    makeCrystal(world, WORLD_ZONES.Glowmere + Vector3.new(-44, 2.0, 18))
    makeCrystal(world, WORLD_ZONES.Glowmere + Vector3.new(48, 2.0, -14))
    makeFireflyCluster(world, WORLD_ZONES.Glowmere + Vector3.new(-32, 0, -44))
    makeCampBench(world, WORLD_ZONES.Glowmere + Vector3.new(-84, 0, 42), math.rad(28))

    -- Mossglen is the shared combat valley and field-boss room.
    makeCombatGrove(world, WORLD_ZONES.CombatGrove)
    makeMossyRockSet(world, WORLD_ZONES.CombatGrove + Vector3.new(-102, 0, -62), math.rad(21), 0.9)
    makeMossyRockSet(world, WORLD_ZONES.CombatGrove + Vector3.new(104, 0, 54), math.rad(-44), 0.84)
    makeFallenLog(world, WORLD_ZONES.CombatGrove + Vector3.new(-94, 0.2, 62), math.rad(48), 0.82, 2)
    makeCampBench(world, WORLD_ZONES.CombatGrove + Vector3.new(-108, 0, 10), math.rad(84))
    makeCampBench(world, WORLD_ZONES.CombatGrove + Vector3.new(108, 0, 7), math.rad(-84))
    makeSignpost(
        world,
        WORLD_ZONES.CombatGrove + Vector3.new(94, 0, -68),
        math.rad(-62),
        "SUNMOSS RIDGE",
        "SHATTERED ARCH"
    )

    makeWaystone(world, BRAMBLE_TRAIL_ORIGIN + Vector3.new(-42, 0, 30), math.rad(40), 0.72)
    makeFallenLog(world, BRAMBLE_TRAIL_ORIGIN + Vector3.new(40, 0.2, -26), math.rad(56), 0.78, 2)
    makePineRoots(world, BRAMBLE_TRAIL_ORIGIN + Vector3.new(-36, 0, -31), math.rad(-24), 0.7)

    -- Sunmoss is an elevated exploration branch and alternate eastern route.
    makeRockSpire(world, WORLD_ZONES.Overlook + Vector3.new(-52, 0, 10), 0.96)
    makeRockSpire(world, WORLD_ZONES.Overlook + Vector3.new(54, 0, -14), 0.84)
    makeWaystone(world, WORLD_ZONES.Overlook + Vector3.new(-10, 2.0, 36), math.rad(8), 0.9)
    makeCrystal(world, WORLD_ZONES.Overlook + Vector3.new(30, 4.5, 20))
    makeCampBench(world, WORLD_ZONES.Overlook + Vector3.new(-16, 2.0, 50), math.rad(176))
    makeSignpost(
        world,
        WORLD_ZONES.Overlook + Vector3.new(66, 0, 38),
        math.rad(-52),
        "SHATTERED ARCH",
        "MOSSGLEN"
    )

    -- Veilfall is the lower late-starter ravine and Whisperroot access point.
    makeWaterfall(world, WORLD_ZONES.Waterfall)
    makeRockFace(world, WORLD_ZONES.Waterfall + Vector3.new(-66, 0, -18), math.rad(18), 0.9)
    makeRockFace(world, WORLD_ZONES.Waterfall + Vector3.new(70, 0, -10), math.rad(-22), 0.86)
    makeFallenLog(world, WORLD_ZONES.Waterfall + Vector3.new(74, 0.2, -52), math.rad(61), 0.88, 2)
    makePineRoots(world, WORLD_ZONES.Waterfall + Vector3.new(-72, 0, 40), math.rad(-24), 0.82)
    for index, offset in
        {
            Vector3.new(-48, 0, 58),
            Vector3.new(-18, 0, 64),
            Vector3.new(22, 0, 62),
            Vector3.new(52, 0, 46),
        }
    do
        makeCattailCluster(world, WORLD_ZONES.Waterfall + offset, 0.78 + index * 0.03, index)
    end
    makeFireflyCluster(world, WORLD_ZONES.Waterfall + Vector3.new(-38, 0, 36))
    makeCampBench(world, WORLD_ZONES.Waterfall + Vector3.new(78, 0, 30), math.rad(-72))

    -- Shattered Arch is the far-east capstone and Brasshaven gate.
    makeRuins(world, WORLD_ZONES.Ruins)
    makeMossyRockSet(world, WORLD_ZONES.Ruins + Vector3.new(-84, 0, 54), math.rad(28), 0.86)
    makeDryBranches(world, WORLD_ZONES.Ruins + Vector3.new(72, 0.1, 54), math.rad(-31), 0.78)
    makeWaystone(world, WORLD_ZONES.Ruins + Vector3.new(-82, 0, -8), math.rad(76), 0.82)
    makeCampBench(world, WORLD_ZONES.Ruins + Vector3.new(-88, 0, 66), math.rad(28))
    makeLantern(world, WORLD_ZONES.Ruins + Vector3.new(-76, 0, 58))

    local routeBeacons = {
        { OPENING_ROUTE_POINTS[2], math.rad(55), 0.66 },
        { OPENING_ROUTE_POINTS[4], math.rad(70), 0.66 },
        { EASTBRIDGE_ROUTE_POINTS[3], math.rad(88), 0.66 },
        { EAST_LANDING, math.rad(-80), 0.7 },
        { GLOWMERE_ROUTE_POINTS[3], math.rad(8), 0.66 },
        { GLOWMERE_RETURN_POINTS[3], math.rad(-70), 0.66 },
        { MOSSGLEN_ROUTE_POINTS[3], math.rad(-45), 0.68 },
        { SUNMOSS_ROUTE_POINTS[3], math.rad(-55), 0.7 },
        { BRAMBLE_TRAIL_ORIGIN, math.rad(-60), 0.7 },
        { RUINS_ROUTE_POINTS[5], math.rad(-52), 0.72 },
        { VEILFALL_ROUTE_POINTS[4], math.rad(-40), 0.68 },
        { VEILFALL_RETURN_POINTS[4], math.rad(-55), 0.72 },
        { SUNMOSS_RETURN_POINTS[3], math.rad(-50), 0.7 },
    }
    for index, beacon in routeBeacons do
        makeWaystone(world, beacon[1], beacon[2], beacon[3])
        if index % 2 == 1 then
            makeLantern(world, beacon[1] + Vector3.new(8, 0, 6), beacon[2])
        end
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
    local groundPosition = terrainSurfacePosition(ARRIVAL_SPAWN_ORIGIN, 0)
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

    -- Town NPCs are clustered by service around the hub plaza so the starter
    -- settlement works like an MMO town instead of scattered quest mannequins.
    makeGuide(world, WORLD_ZONES.Camp + Vector3.new(30, 0, 10), math.rad(112))
    makeCampNpc(
        world,
        "camp_quartermaster",
        "Orin · Quartermaster",
        WORLD_ZONES.Camp + Vector3.new(-28, 0, 32),
        math.rad(178),
        { Cloth = Color3.fromRGB(105, 83, 58), Accent = Color3.fromRGB(154, 115, 68) },
        "Quartermaster"
    )
    makeCampNpc(
        world,
        "moss_scout",
        "Tovin · Mossglen Scout",
        WORLD_ZONES.Camp + Vector3.new(55, 0, -13),
        math.rad(-122),
        { Cloth = Color3.fromRGB(56, 84, 65), Accent = Color3.fromRGB(86, 126, 79) },
        "Scout"
    )
    makeCampNpc(
        world,
        "archive_keeper",
        "Maela · Archive Keeper",
        WORLD_ZONES.Camp + Vector3.new(-30, 0, -31),
        math.rad(26),
        { Cloth = Color3.fromRGB(67, 65, 92), Accent = Color3.fromRGB(132, 104, 157) },
        "Archivist"
    )
    makeCampNpc(
        world,
        "path_mentor",
        "Seren · Pathkeeper",
        WORLD_ZONES.Camp + Vector3.new(20, 0, -55),
        math.rad(16),
        { Cloth = Color3.fromRGB(51, 74, 65), Accent = Color3.fromRGB(87, 151, 116) },
        "Mentor"
    )

    local provingCircleOrigin = makeProvingCircle(world)
    makeStoryRemnant(world, WORLD_ZONES.Crossroads + Vector3.new(28, 0, -18), math.rad(26))
    makeStoryRemnant(world, BRAMBLE_TRAIL_ORIGIN + Vector3.new(-38, 0, -22), math.rad(-41))
    makeStoryRemnant(world, WORLD_ZONES.Overlook + Vector3.new(56, 2, 16), math.rad(79))
    makeWhisperrootHollow(world)

    clearTravelLaneDecor(world)
    clearProtectedGameplayDecor(world)

    makeLandmarkLabel(world, WORLD_ZONES.Camp + Vector3.new(0, 18, 0), "WAYFARER CAMP")
    makeLandmarkLabel(world, STARTER_FIELD_ORIGIN + Vector3.new(0, 13, 0), "GREENWAY FIELDS")
    makeLandmarkLabel(world, provingCircleOrigin + Vector3.new(0, 13, 0), "WAYFARER PROVING CIRCLE")
    makeLandmarkLabel(world, WORLD_ZONES.Crossroads + Vector3.new(0, 13, 0), "LUMENWOOD CROSSROADS")
    makeLandmarkLabel(world, GRAVEBONE_WATCH_ORIGIN + Vector3.new(0, 14, 0), "GRAVEBONE WATCH")
    makeLandmarkLabel(world, WORLD_ZONES.Glowmere + Vector3.new(0, 13, 0), "GLOWMERE WETLAND")
    makeLandmarkLabel(world, WORLD_ZONES.CombatGrove + Vector3.new(0, 15, 0), "MOSSGLEN VALLEY")
    makeLandmarkLabel(world, WORLD_ZONES.Overlook + Vector3.new(0, 26, 0), "SUNMOSS RIDGE")
    makeLandmarkLabel(world, WORLD_ZONES.Waterfall + Vector3.new(0, 30, 4), "VEILFALL RAVINE")
    makeLandmarkLabel(world, WORLD_ZONES.Ruins + Vector3.new(0, 26, 0), "SHATTERED LUMEN ARCH")

    -- Explicit subzone metadata keeps world design, future minimap/UI work, and
    -- encounter pacing aligned around the same MMO progression bands.
    makeZoneMarker(world, "wayfarer_camp", "Wayfarer Camp", WORLD_ZONES.Camp, 115, 1, 10, "Town")
    makeZoneMarker(
        world,
        "greenway_fields",
        "Greenway Fields",
        STARTER_FIELD_ORIGIN,
        90,
        1,
        2,
        "StarterField"
    )
    makeZoneMarker(
        world,
        "mossling_hollow",
        "Mossling Hollow",
        MOSS_HOLLOW_ORIGIN,
        50,
        1,
        3,
        "StarterCombat"
    )
    makeZoneMarker(
        world,
        "lumenwood_crossroads",
        "Lumenwood Crossroads",
        WORLD_ZONES.Crossroads,
        80,
        2,
        4,
        "NavigationHub"
    )
    makeZoneMarker(
        world,
        "gravebone_watch",
        "Gravebone Watch",
        GRAVEBONE_WATCH_ORIGIN,
        62,
        3,
        7,
        "RuinsCombat"
    )
    makeZoneMarker(
        world,
        "glowmere_wetland",
        "Glowmere Wetland",
        WORLD_ZONES.Glowmere,
        110,
        2,
        5,
        "ExplorationLoop"
    )
    makeZoneMarker(
        world,
        "mossglen_valley",
        "Mossglen Valley",
        WORLD_ZONES.CombatGrove,
        135,
        4,
        7,
        "PartyField"
    )
    makeZoneMarker(
        world,
        "brambleback_trail",
        "Brambleback Trail",
        BRAMBLE_TRAIL_ORIGIN,
        65,
        4,
        7,
        "SideCombat"
    )
    makeZoneMarker(
        world,
        "sunmoss_ridge",
        "Sunmoss Ridge",
        WORLD_ZONES.Overlook,
        105,
        6,
        9,
        "HighlandLoop"
    )
    makeZoneMarker(
        world,
        "veilfall_ravine",
        "Veilfall Ravine",
        WORLD_ZONES.Waterfall,
        115,
        7,
        9,
        "DangerLoop"
    )
    makeZoneMarker(
        world,
        "shattered_lumen_arch",
        "Shattered Lumen Arch",
        WORLD_ZONES.Ruins,
        125,
        8,
        10,
        "RegionCapstone"
    )
    makeZoneMarker(
        world,
        "wayfarer_proving_circle",
        "Wayfarer Proving Circle",
        provingCircleOrigin,
        60,
        7,
        10,
        "Advancement"
    )

    makeExplorationTrigger(world, "lumenwood_crossroads", WORLD_ZONES.Crossroads, 24)
    makeExplorationTrigger(world, "wayfarer_proving_circle", provingCircleOrigin, 22)
    makeExplorationTrigger(world, "gravebone_watch", GRAVEBONE_WATCH_ORIGIN, 28)
    makeExplorationTrigger(world, "eastbridge_crossing", (BRIDGE_WEST + BRIDGE_EAST) * 0.5, 24)
    makeExplorationTrigger(world, "mossglen_valley", WORLD_ZONES.CombatGrove, 34)
    makeExplorationTrigger(world, "glowmere_pool", WORLD_ZONES.Glowmere, 28)
    makeExplorationTrigger(world, "shattered_lumen_arch", WORLD_ZONES.Ruins, 30)
    makeExplorationTrigger(
        world,
        "veilfall_cascade",
        WORLD_ZONES.Waterfall + Vector3.new(0, 0, 18),
        28
    )
    makeExplorationTrigger(world, "sunmoss_overlook", WORLD_ZONES.Overlook, 28)

    EnemySpawnerService.Spawn(
        "training_dummy",
        TRAINING_YARD_ORIGIN,
        world,
        { GroundToTerrain = true, GroundClearance = 0.1 }
    )

    makeMonsterSpawnTrigger(
        world,
        "GreenwayMosslings",
        STARTER_FIELD_ORIGIN + Vector3.new(28, 0, -14),
        {
            MonsterType = "LumenMossling",
            SpawnAmount = 4,
            TriggerRadius = 42,
            SpawnRadius = 22,
            MaxAliveMonster = 4,
            SpawnDelay = 0.32,
            RespawnTime = 20,
        }
    )
    makeMonsterSpawnTrigger(world, "LumenwoodMosslings", MOSS_HOLLOW_ORIGIN, {
        MonsterType = "LumenMossling",
        SpawnAmount = 6,
        TriggerRadius = 40,
        SpawnRadius = 22,
        MaxAliveMonster = 6,
        SpawnDelay = 0.26,
        RespawnTime = 18,
    })
    makeMonsterSpawnTrigger(
        world,
        "GlowmereSlimes",
        WORLD_ZONES.Glowmere + Vector3.new(45, 0, -20),
        {
            MonsterType = "Slime",
            SpawnAmount = 6,
            TriggerRadius = 44,
            SpawnRadius = 24,
            MaxAliveMonster = 6,
            SpawnDelay = 0.3,
            RespawnTime = 28,
        }
    )
    makeMonsterSpawnTrigger(
        world,
        "MossglenRidgebeaks",
        WORLD_ZONES.CombatGrove + Vector3.new(-45, 0, -28),
        {
            MonsterType = "PecoPeco",
            SpawnAmount = 6,
            TriggerRadius = 48,
            SpawnRadius = 24,
            MaxAliveMonster = 6,
            SpawnDelay = 0.2,
            RespawnTime = 28,
        }
    )
    makeMonsterSpawnTrigger(
        world,
        "MossglenRidgebeaksEast",
        WORLD_ZONES.CombatGrove + Vector3.new(58, 0, -32),
        {
            MonsterType = "PecoPeco",
            SpawnAmount = 4,
            TriggerRadius = 38,
            SpawnRadius = 18,
            MaxAliveMonster = 4,
            SpawnDelay = 0.24,
            RespawnTime = 30,
        }
    )
    makeMonsterSpawnTrigger(world, "BramblebackTrail", BRAMBLE_TRAIL_ORIGIN, {
        MonsterType = "Brambleback",
        SpawnAmount = 5,
        TriggerRadius = 44,
        SpawnRadius = 22,
        MaxAliveMonster = 5,
        SpawnDelay = 0.26,
        RespawnTime = 32,
    })
    makeMonsterSpawnTrigger(
        world,
        "VeilfallWisps",
        WORLD_ZONES.Waterfall + Vector3.new(25, 0, 20),
        {
            MonsterType = "LumenWisp",
            SpawnAmount = 5,
            TriggerRadius = 44,
            SpawnRadius = 22,
            MaxAliveMonster = 5,
            SpawnDelay = 0.22,
            RespawnTime = 31,
        }
    )
    makeMonsterSpawnTrigger(
        world,
        "GraveboneWatchSkeletons",
        GRAVEBONE_WATCH_ORIGIN + Vector3.new(-14, 0, 6),
        {
            MonsterType = "Skeleton",
            SpawnAmount = 5,
            TriggerRadius = 42,
            SpawnRadius = 21,
            MaxAliveMonster = 5,
            SpawnDelay = 0.24,
            RespawnTime = 29,
        }
    )
    makeMonsterSpawnTrigger(
        world,
        "ShatteredArchSkeletons",
        WORLD_ZONES.Ruins + Vector3.new(-46, 0, 30),
        {
            MonsterType = "Skeleton",
            SpawnAmount = 6,
            TriggerRadius = 48,
            SpawnRadius = 24,
            MaxAliveMonster = 6,
            SpawnDelay = 0.24,
            RespawnTime = 30,
        }
    )
    makeMonsterSpawnTrigger(
        world,
        "GraveboneCaptainRare",
        GRAVEBONE_WATCH_ORIGIN + Vector3.new(30, 0, -20),
        {
            MonsterType = "GraveboneCaptain",
            SpawnAmount = 1,
            TriggerRadius = 30,
            SpawnRadius = 8,
            MaxAliveMonster = 1,
            SpawnDelay = 0,
            RespawnTime = 80,
        }
    )
    makeMonsterSpawnTrigger(
        world,
        "RoyalGlowcapRare",
        WORLD_ZONES.Glowmere + Vector3.new(-38, 0, 32),
        {
            MonsterType = "RoyalGlowcap",
            SpawnAmount = 1,
            TriggerRadius = 26,
            SpawnRadius = 8,
            MaxAliveMonster = 1,
            SpawnDelay = 0,
            RespawnTime = 85,
        }
    )
    makeMonsterSpawnTrigger(
        world,
        "MosswardenFieldBoss",
        WORLD_ZONES.CombatGrove + Vector3.new(38, 0, 35),
        {
            MonsterType = "Mosswarden",
            SpawnAmount = 1,
            TriggerRadius = 48,
            SpawnRadius = 10,
            MaxAliveMonster = 1,
            SpawnDelay = 0,
            RespawnTime = 180,
        }
    )
end

return LumenreachWorldService
