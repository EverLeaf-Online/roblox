local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local EnemySpawnerService = require(script.Parent.EnemySpawnerService)
local EnvironmentPrefabService = require(script.Parent.EnvironmentPrefabService)
local InteractionService = require(script.Parent.InteractionService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local PortalService = require(script.Parent.PortalService)
local StylizedNpcFactory = require(script.Parent.StylizedNpcFactory)
local WorldNoticeService = require(script.Parent.WorldNoticeService)
local WorldObjectService = require(script.Parent.WorldObjectService)
local WorldTravelService = require(script.Parent.WorldTravelService)

local LumenreachWorldService = {}

local GENERATED_NAME = "EverLeafGeneratedWorld"
local WORLD_WIDTH = 2200
local WORLD_DEPTH = 1250
local WORLD_DESIGN_VERSION = 21

-- Lumenreach is authored as a terrain-first MMORPG region. The generator below
-- replaces the previous showcase composition completely: terrain is cleared,
-- the macro topography is rebuilt, roads are cut into the land, and only then
-- are town/encounter structures placed. Nothing is layered on top of the old map.
local ZONES = table.freeze({
    Camp = Vector3.new(-950, 2, 0),
    Greenway = Vector3.new(-720, 1, 40),
    Crossroads = Vector3.new(-480, 4, 50),
    Glowmere = Vector3.new(-420, -4, 430),
    EastLanding = Vector3.new(-120, 6, 90),
    Gravebone = Vector3.new(120, 6, -220),
    Mossglen = Vector3.new(130, 6, 300),
    Sunmoss = Vector3.new(500, 34, 430),
    Veilfall = Vector3.new(420, -18, -360),
    Ruins = Vector3.new(900, 10, 60),
    Proving = Vector3.new(-930, 4, -330),
})

local EASTBRIDGE_WEST = Vector3.new(-292, 4, 92)
local EASTBRIDGE_EAST = Vector3.new(-205, 6, 92)
local REEDBRIDGE_WEST = Vector3.new(-315, 0, 350)
local REEDBRIDGE_EAST = Vector3.new(-228, 6, 350)
local ARRIVAL_ORIGIN = ZONES.Camp + Vector3.new(-65, 0, 12)
local TRAINING_ORIGIN = ZONES.Camp + Vector3.new(68, 0, -18)
local BRAMBLE_ORIGIN = ZONES.Mossglen + Vector3.new(150, 0, -30)

local ROUTES = table.freeze({
    table.freeze({
        Id = "greenway",
        Width = 22,
        Points = table.freeze({
            ZONES.Camp + Vector3.new(88, 0, 12),
            Vector3.new(-835, 2, 20),
            ZONES.Greenway,
            Vector3.new(-610, 3, 52),
            ZONES.Crossroads,
        }),
    }),
    table.freeze({
        Id = "proving_road",
        Width = 15,
        Points = table.freeze({
            ZONES.Camp + Vector3.new(5, 0, -82),
            Vector3.new(-945, 3, -190),
            Vector3.new(-940, 4, -270),
            ZONES.Proving,
        }),
    }),
    table.freeze({
        Id = "glowmere_road",
        Width = 16,
        Points = table.freeze({
            ZONES.Crossroads,
            Vector3.new(-490, 3, 175),
            Vector3.new(-470, 0, 300),
            ZONES.Glowmere,
        }),
    }),
    table.freeze({
        Id = "eastbridge_west",
        Width = 20,
        Points = table.freeze({
            ZONES.Crossroads,
            Vector3.new(-395, 4, 75),
            Vector3.new(-335, 4, 88),
            EASTBRIDGE_WEST,
        }),
    }),
    table.freeze({
        Id = "eastbridge_east",
        Width = 20,
        Points = table.freeze({
            EASTBRIDGE_EAST,
            ZONES.EastLanding,
        }),
    }),
    table.freeze({
        Id = "reedbridge_west",
        Width = 15,
        Points = table.freeze({
            ZONES.Glowmere,
            Vector3.new(-360, -1, 390),
            REEDBRIDGE_WEST,
        }),
    }),
    table.freeze({
        Id = "reedbridge_east",
        Width = 15,
        Points = table.freeze({
            REEDBRIDGE_EAST,
            Vector3.new(-110, 6, 345),
            ZONES.Mossglen,
        }),
    }),
    table.freeze({
        Id = "gravebone_road",
        Width = 16,
        Points = table.freeze({
            ZONES.EastLanding,
            Vector3.new(-20, 6, 20),
            Vector3.new(58, 6, -90),
            ZONES.Gravebone,
        }),
    }),
    table.freeze({
        Id = "mossglen_road",
        Width = 19,
        Points = table.freeze({
            ZONES.EastLanding,
            Vector3.new(-30, 6, 185),
            Vector3.new(40, 6, 255),
            ZONES.Mossglen,
        }),
    }),
    table.freeze({
        Id = "sunmoss_road",
        Width = 16,
        Points = table.freeze({
            ZONES.Mossglen,
            Vector3.new(260, 14, 350),
            Vector3.new(385, 26, 395),
            ZONES.Sunmoss,
        }),
    }),
    table.freeze({
        Id = "bramble_road",
        Width = 14,
        Points = table.freeze({
            ZONES.Mossglen + Vector3.new(75, 0, -12),
            BRAMBLE_ORIGIN,
        }),
    }),
    table.freeze({
        Id = "veilfall_road",
        Width = 16,
        Points = table.freeze({
            ZONES.Gravebone,
            Vector3.new(225, 1, -270),
            Vector3.new(320, -8, -330),
            ZONES.Veilfall,
        }),
    }),
    table.freeze({
        Id = "ruins_main",
        Width = 20,
        Points = table.freeze({
            ZONES.Mossglen + Vector3.new(70, 0, -75),
            Vector3.new(350, 7, 200),
            Vector3.new(540, 8, 150),
            Vector3.new(720, 9, 100),
            ZONES.Ruins,
        }),
    }),
    table.freeze({
        Id = "sunmoss_return",
        Width = 15,
        Points = table.freeze({
            ZONES.Sunmoss,
            Vector3.new(620, 27, 360),
            Vector3.new(735, 18, 235),
            ZONES.Ruins + Vector3.new(-45, 0, 38),
        }),
    }),
    table.freeze({
        Id = "veilfall_return",
        Width = 16,
        Points = table.freeze({
            ZONES.Veilfall,
            Vector3.new(570, -10, -290),
            Vector3.new(700, 1, -170),
            Vector3.new(810, 8, -40),
            ZONES.Ruins + Vector3.new(-35, 0, -38),
        }),
    }),
})

local GORGE_POINTS = table.freeze({
    Vector3.new(-370, -6, 560),
    Vector3.new(-325, -7, 410),
    Vector3.new(-265, -8, 265),
    Vector3.new(-250, -9, 95),
    Vector3.new(-155, -10, -20),
    Vector3.new(-30, -11, -135),
    Vector3.new(150, -13, -245),
    Vector3.new(335, -16, -330),
    ZONES.Veilfall + Vector3.new(-20, 0, -5),
})

-- Environment density is authored around gameplay rather than sprayed uniformly.
-- These pockets remain deliberately open for spawn safety, readable combat, bosses,
-- bridges, and the advancement trial.
local DRESSING_EXCLUSIONS = table.freeze({
    table.freeze({ Center = ARRIVAL_ORIGIN, Radius = 54 }),
    table.freeze({ Center = TRAINING_ORIGIN, Radius = 34 }),
    table.freeze({ Center = ZONES.Camp, Radius = 136 }),
    table.freeze({ Center = ZONES.Crossroads, Radius = 82 }),
    table.freeze({ Center = ZONES.EastLanding, Radius = 88 }),
    table.freeze({ Center = ZONES.Proving, Radius = 50 }),
    table.freeze({ Center = ZONES.Greenway + Vector3.new(0, 0, 72), Radius = 48 }),
    table.freeze({ Center = ZONES.Glowmere + Vector3.new(-90, 0, 70), Radius = 50 }),
    table.freeze({ Center = ZONES.Glowmere + Vector3.new(-62, 0, 48), Radius = 24 }),
    table.freeze({ Center = ZONES.Gravebone + Vector3.new(70, 0, 70), Radius = 48 }),
    table.freeze({ Center = ZONES.Gravebone + Vector3.new(-60, 0, -60), Radius = 28 }),
    table.freeze({ Center = ZONES.Mossglen + Vector3.new(-20, 0, -90), Radius = 54 }),
    table.freeze({ Center = BRAMBLE_ORIGIN, Radius = 48 }),
    table.freeze({ Center = ZONES.Mossglen + Vector3.new(-10, 0, 100), Radius = 58 }),
    table.freeze({ Center = ZONES.Veilfall + Vector3.new(0, 0, -80), Radius = 52 }),
    table.freeze({ Center = ZONES.Ruins + Vector3.new(88, 0, 55), Radius = 56 }),
})

local function makePart(parent, name, size, cframe, material, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.Material = material
    part.Color = color
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    -- Render geometry never owns physics by accident. Intentional collision is
    -- assigned later by the Lumenreach collision policy or an explicit proxy.
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Parent = parent
    return part
end

local function makeWedge(parent, name, size, cframe, material, color)
    local wedge = Instance.new("WedgePart")
    wedge.Name = name
    wedge.Size = size
    wedge.CFrame = cframe
    wedge.Anchored = true
    wedge.Material = material
    wedge.Color = color
    wedge.CanCollide = false
    wedge.CanTouch = false
    wedge.CanQuery = false
    wedge.Parent = parent
    return wedge
end

local function makeCollisionProxy(parent, name, size, cframe)
    local part =
        makePart(parent, name, size, cframe, Enum.Material.SmoothPlastic, Color3.new(0, 0, 0))
    part.Transparency = 1
    part.CanCollide = true
    part.CanTouch = false
    -- Collision proxies represent actual world solids. Keep them queryable so
    -- camera/LOS/projectile raycasts obey the same geometry players collide with.
    part.CanQuery = true
    part.CastShadow = false
    part:SetAttribute("EverLeafCollisionProxy", true)
    return part
end

local function makePartSurfaceCollisionProxy(parent, source, name, extraSize)
    local extra = extraSize or Vector3.zero
    return makeCollisionProxy(
        parent,
        name,
        Vector3.new(
            math.max(0.25, source.Size.X + extra.X),
            math.max(0.25, source.Size.Y + extra.Y),
            math.max(0.25, source.Size.Z + extra.Z)
        ),
        source.CFrame
    )
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

local function setArchitectureVisual(instance)
    -- Architecture must stay non-physical, but unlike foliage/dressing it must
    -- participate in camera and line-of-sight queries. Turning CanQuery off on
    -- the imported buildings let the third-person camera pass through roofs and
    -- walls, which produced the interior/clipping views seen in Studio.
    if instance:IsA("BasePart") then
        instance.CanCollide = false
        instance.CanTouch = false
        instance.CanQuery = true
    end
    for _, descendant in instance:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = true
        end
    end
end

local function makeBoundingCollisionProxy(parent, source, name, scale)
    local boxCFrame
    local boxSize
    if source:IsA("Model") then
        boxCFrame, boxSize = source:GetBoundingBox()
    elseif source:IsA("BasePart") then
        boxCFrame = source.CFrame
        boxSize = source.Size
    else
        return nil
    end

    scale = scale or Vector3.new(1, 1, 1)
    local size = Vector3.new(
        math.max(0.5, boxSize.X * scale.X),
        math.max(0.5, boxSize.Y * scale.Y),
        math.max(0.5, boxSize.Z * scale.Z)
    )
    return makeCollisionProxy(parent, name, size, boxCFrame)
end

local function distanceToSegmentXZ(point, a, b)
    local p = Vector2.new(point.X, point.Z)
    local av = Vector2.new(a.X, a.Z)
    local bv = Vector2.new(b.X, b.Z)
    local ab = bv - av
    local lengthSquared = ab:Dot(ab)
    if lengthSquared <= 0.001 then
        return (p - av).Magnitude
    end
    local alpha = math.clamp((p - av):Dot(ab) / lengthSquared, 0, 1)
    return (p - (av + ab * alpha)).Magnitude
end

local function clearOfTravelLanes(position, padding)
    padding = padding or 9
    for _, route in ROUTES do
        for index = 1, #route.Points - 1 do
            if
                distanceToSegmentXZ(position, route.Points[index], route.Points[index + 1])
                < route.Width * 0.5 + padding
            then
                return false
            end
        end
    end
    return true
end

local function clearOfDressingExclusions(position, padding)
    padding = padding or 0
    local point = Vector2.new(position.X, position.Z)
    for _, exclusion in DRESSING_EXCLUSIONS do
        local center = Vector2.new(exclusion.Center.X, exclusion.Center.Z)
        if (point - center).Magnitude < exclusion.Radius + padding then
            return false
        end
    end
    return true
end

local function isInsideAnyZoneCore(position, radius)
    for _, center in ZONES do
        local dx = position.X - center.X
        local dz = position.Z - center.Z
        if dx * dx + dz * dz < radius * radius then
            return true
        end
    end
    return false
end

local function terrainSurfacePosition(position, offsetY)
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return position + Vector3.new(0, offsetY or 0, 0)
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { terrain }
    params.IgnoreWater = true
    local startY = math.max(position.Y + 180, 180)
    local hit = Workspace:Raycast(
        Vector3.new(position.X, startY, position.Z),
        Vector3.new(0, -420, 0),
        params
    )
    if hit then
        return hit.Position + Vector3.new(0, offsetY or 0, 0)
    end
    return position + Vector3.new(0, offsetY or 0, 0)
end

local function flattenTerrain(center, size, topY, material)
    local terrain = Workspace.Terrain
    terrain:FillBlock(
        CFrame.new(center.X, topY + 36, center.Z),
        Vector3.new(size.X, 72, size.Z),
        Enum.Material.Air
    )
    terrain:FillBlock(
        CFrame.new(center.X, topY - 6, center.Z),
        Vector3.new(size.X, 12, size.Z),
        material
    )
end

local function fillTerrainSegment(a, b, width, thickness, material)
    local delta = b - a
    if delta.Magnitude < 1 then
        return
    end
    local midpoint = (a + b) * 0.5 - Vector3.new(0, thickness * 0.5, 0)
    Workspace.Terrain:FillBlock(
        CFrame.lookAt(midpoint, midpoint + delta),
        Vector3.new(width, thickness, delta.Magnitude + 3),
        material
    )
end

local function fillTerrainRoute(points, width, material)
    for index = 1, #points - 1 do
        fillTerrainSegment(points[index], points[index + 1], width, 4, material)
    end
end

local function fillMountainRidge(points, width, height, material)
    local terrain = Workspace.Terrain
    local sampleSpacing = math.max(28, width * 0.34)

    -- Mountains are built from tightly overlapping terrain masses instead of
    -- rotated rectangular slabs. The old block-based ridge produced sheer
    -- walls, visible seams, and sky-shaped holes at segment joins in Studio.
    for segmentIndex = 1, #points - 1 do
        local a = points[segmentIndex]
        local b = points[segmentIndex + 1]
        local flatDelta = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
        if flatDelta.Magnitude > 1 then
            local direction = flatDelta.Unit
            local right = Vector3.new(-direction.Z, 0, direction.X)
            local samples = math.max(2, math.ceil(flatDelta.Magnitude / sampleSpacing))

            for sample = 0, samples do
                local alpha = sample / samples
                local point = a:Lerp(b, alpha)
                local noiseSeed = segmentIndex * 37 + sample * 19
                local lateral = (((noiseSeed * 13) % 17) - 8) * width * 0.012
                local baseRadius = width * (0.38 + ((noiseSeed * 7) % 7) * 0.012)
                local shoulderRadius = width * (0.21 + ((noiseSeed * 5) % 5) * 0.009)
                local summitRadius = math.min(width * 0.29, height * 0.27)
                local ridgeHeight = height * (0.78 + ((noiseSeed * 11) % 9) * 0.018)
                local center = point + right * lateral

                terrain:FillBall(
                    center + Vector3.new(0, baseRadius * 0.18, 0),
                    baseRadius,
                    material
                )

                for _, side in { -1, 1 } do
                    terrain:FillBall(
                        center
                            + right * side * width * 0.22
                            + Vector3.new(0, shoulderRadius * 0.08, 0),
                        shoulderRadius,
                        material
                    )
                end

                terrain:FillBall(
                    center + Vector3.new(0, ridgeHeight * 0.48, 0),
                    summitRadius,
                    if (noiseSeed % 4) == 0 then Enum.Material.Rock else material
                )
                terrain:FillBall(
                    center + Vector3.new(0, ridgeHeight * 0.66, 0),
                    summitRadius * 0.62,
                    Enum.Material.Rock
                )
            end
        end
    end
end

local function carveGorge(points)
    local terrain = Workspace.Terrain
    for index = 1, #points - 1 do
        local a = points[index]
        local b = points[index + 1]
        local length = (b - a).Magnitude
        local samples = math.max(2, math.ceil(length / 26))
        for step = 0, samples do
            local alpha = step / samples
            local point = a:Lerp(b, alpha)
            terrain:FillBall(point + Vector3.new(0, 9, 0), 43, Enum.Material.Air)
            terrain:FillBall(point + Vector3.new(0, -18, 0), 28, Enum.Material.Rock)
            terrain:FillBall(point + Vector3.new(0, -8, 0), 15, Enum.Material.Water)
        end
    end
end

local function buildTerrain()
    local terrain = Workspace.Terrain
    terrain:Clear()

    terrain:FillBlock(
        CFrame.new(-50, -20, 20),
        Vector3.new(WORLD_WIDTH, 40, WORLD_DEPTH),
        Enum.Material.Grass
    )
    terrain:FillBlock(
        CFrame.new(-50, -44, 20),
        Vector3.new(WORLD_WIDTH, 18, WORLD_DEPTH),
        Enum.Material.Rock
    )

    -- Distinct MMO rooms are flattened first. The roads are carved into these
    -- spaces, while the mountain belts and gorge define macro navigation.
    flattenTerrain(ZONES.Camp, Vector3.new(285, 0, 220), 2, Enum.Material.Ground)
    flattenTerrain(ZONES.Greenway, Vector3.new(250, 0, 220), 1, Enum.Material.Grass)
    flattenTerrain(ZONES.Crossroads, Vector3.new(185, 0, 165), 4, Enum.Material.Ground)
    flattenTerrain(ZONES.Glowmere, Vector3.new(240, 0, 205), -4, Enum.Material.Grass)
    flattenTerrain(ZONES.EastLanding, Vector3.new(135, 0, 130), 6, Enum.Material.Ground)
    flattenTerrain(ZONES.Gravebone, Vector3.new(210, 0, 185), 6, Enum.Material.Ground)
    flattenTerrain(ZONES.Mossglen, Vector3.new(330, 0, 265), 6, Enum.Material.Grass)
    flattenTerrain(BRAMBLE_ORIGIN, Vector3.new(150, 0, 120), 6, Enum.Material.Grass)
    flattenTerrain(ZONES.Sunmoss, Vector3.new(235, 0, 185), 34, Enum.Material.Grass)
    flattenTerrain(ZONES.Veilfall, Vector3.new(255, 0, 220), -18, Enum.Material.Ground)
    flattenTerrain(ZONES.Ruins, Vector3.new(290, 0, 235), 10, Enum.Material.Ground)
    flattenTerrain(ZONES.Proving, Vector3.new(175, 0, 175), 4, Enum.Material.Ground)

    -- Sunmoss is a true elevated shelf rather than a pile of props.
    terrain:FillBlock(
        CFrame.new(ZONES.Sunmoss.X, 12, ZONES.Sunmoss.Z),
        Vector3.new(310, 44, 260),
        Enum.Material.Rock
    )
    terrain:FillBlock(
        CFrame.new(ZONES.Sunmoss.X, 31, ZONES.Sunmoss.Z),
        Vector3.new(250, 8, 200),
        Enum.Material.Grass
    )

    -- Broad perimeter mountain belts provide natural map limits.
    local north = {}
    local south = {}
    for x = -1060, 1040, 120 do
        table.insert(north, Vector3.new(x, 25, 590 + ((x / 120) % 3) * 12))
        table.insert(south, Vector3.new(x, 20, -575 - ((x / 120) % 4) * 9))
    end
    local west = {}
    for z = -520, 540, 110 do
        table.insert(west, Vector3.new(-1080, 18, z))
    end
    local east = {}
    for z = -520, 540, 110 do
        table.insert(east, Vector3.new(1060, 28, z))
    end
    fillMountainRidge(north, 88, 78, Enum.Material.Grass)
    fillMountainRidge(south, 90, 80, Enum.Material.Grass)
    fillMountainRidge(west, 86, 72, Enum.Material.Grass)
    fillMountainRidge(east, 94, 92, Enum.Material.Rock)

    -- Internal terrain ridges divide rooms without arbitrary invisible walls.
    fillMountainRidge({
        Vector3.new(-830, 18, 270),
        Vector3.new(-760, 22, 350),
        Vector3.new(-680, 26, 430),
        Vector3.new(-600, 25, 520),
    }, 62, 46, Enum.Material.Grass)
    fillMountainRidge({
        Vector3.new(245, 8, -105),
        Vector3.new(330, 5, -135),
        Vector3.new(430, 8, -135),
        Vector3.new(540, 13, -110),
        Vector3.new(650, 18, -75),
    }, 58, 44, Enum.Material.Rock)

    for _, route in ROUTES do
        fillTerrainRoute(route.Points, route.Width + 7, Enum.Material.Ground)
        fillTerrainRoute(route.Points, route.Width, Enum.Material.Ground)
    end

    -- The river is carved after roads so only actual bridge spans cross it.
    carveGorge(GORGE_POINTS)

    -- Glowmere's wetland is a shallow basin connected visually to the gorge.
    terrain:FillBall(ZONES.Glowmere + Vector3.new(20, -8, 18), 72, Enum.Material.Air)
    terrain:FillBall(ZONES.Glowmere + Vector3.new(20, -18, 18), 64, Enum.Material.Mud)
    terrain:FillBall(ZONES.Glowmere + Vector3.new(20, -8, 18), 52, Enum.Material.Water)

    -- Re-cut room floors and bridge approaches after the gorge/wetland pass.
    flattenTerrain(ZONES.Camp, Vector3.new(270, 0, 205), 2, Enum.Material.Ground)
    flattenTerrain(ZONES.Crossroads, Vector3.new(170, 0, 150), 4, Enum.Material.Ground)
    flattenTerrain(ZONES.Gravebone, Vector3.new(195, 0, 170), 6, Enum.Material.Ground)
    flattenTerrain(ZONES.Mossglen, Vector3.new(300, 0, 235), 6, Enum.Material.Grass)
    flattenTerrain(BRAMBLE_ORIGIN, Vector3.new(138, 0, 108), 6, Enum.Material.Grass)
    flattenTerrain(ZONES.Ruins, Vector3.new(270, 0, 215), 10, Enum.Material.Ground)
    flattenTerrain(ZONES.Proving, Vector3.new(160, 0, 160), 4, Enum.Material.Ground)

    fillTerrainRoute(
        { ZONES.Crossroads, Vector3.new(-335, 4, 88), EASTBRIDGE_WEST },
        20,
        Enum.Material.Ground
    )
    fillTerrainRoute({ EASTBRIDGE_EAST, ZONES.EastLanding }, 20, Enum.Material.Ground)
    fillTerrainRoute(
        { ZONES.Glowmere + Vector3.new(45, 0, -35), REEDBRIDGE_WEST },
        15,
        Enum.Material.Ground
    )
    fillTerrainRoute({ REEDBRIDGE_EAST, ZONES.Mossglen }, 15, Enum.Material.Ground)
end

local function clearOldGeneratedContent()
    local old = Workspace:FindFirstChild(GENERATED_NAME)
    if old then
        old:Destroy()
    end
    for _, child in Workspace:GetChildren() do
        if child:IsA("SpawnLocation") and child.Name ~= "BrasshavenSpawn" then
            child:Destroy()
        elseif child:IsA("BasePart") then
            local lower = string.lower(child.Name)
            if lower == "baseplate" or lower == "base plate" then
                child:Destroy()
            end
        end
    end
end

local function makeBridge(parent, name, a, b, width)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local delta = b - a
    local length = delta.Magnitude
    local midpoint = (a + b) * 0.5 + Vector3.new(0, 0.65, 0)
    local frame = CFrame.lookAt(midpoint, midpoint + delta)
    local wood = Color3.fromRGB(104, 77, 50)
    local dark = Color3.fromRGB(63, 49, 36)

    local count = math.max(8, math.floor(length / 3.1))
    for index = 0, count do
        local alpha = index / count
        local z = -length * 0.5 + length * alpha
        local crown = math.sin(alpha * math.pi) * 1.0
        local plank = makePart(
            model,
            "DeckPlank",
            Vector3.new(width, 0.42, math.max(2.4, length / count - 0.18)),
            frame * CFrame.new(0, crown, z),
            Enum.Material.WoodPlanks,
            if index % 4 == 0 then dark else wood
        )
        plank.CanCollide = false
        plank.CanTouch = false
        plank.CanQuery = false
    end

    local deckSegments = 5
    for index = 1, deckSegments do
        local alpha = (index - 0.5) / deckSegments
        local z = -length * 0.5 + length * alpha
        local crown = math.sin(alpha * math.pi) * 1.0
        makeCollisionProxy(
            model,
            "BridgeDeckCollision",
            Vector3.new(width - 0.8, 0.7, length / deckSegments + 0.7),
            frame * CFrame.new(0, crown - 0.15, z)
        )
    end

    for _, side in { -1, 1 } do
        local railX = side * (width * 0.5 - 0.3)
        local rail = makePart(
            model,
            "BridgeRail",
            Vector3.new(0.35, 0.35, length),
            frame * CFrame.new(railX, 3.0, 0),
            Enum.Material.Wood,
            dark
        )
        rail.CanCollide = false
        rail.CanTouch = false
        rail.CanQuery = false
        makeCollisionProxy(
            model,
            "BridgeRailCollision",
            Vector3.new(0.7, 4.0, length + 1),
            frame * CFrame.new(railX, 2.0, 0)
        )
    end
    return model
end

local function prefabScaleForHeight(prefabName, targetHeight)
    local prefab = EnvironmentPrefabService.Get(prefabName)
    if not prefab then
        return 1
    end
    local size = if prefab:IsA("Model") then prefab:GetExtentsSize() else prefab.Size
    if size.Y <= 0.01 then
        return 1
    end
    return targetHeight / size.Y
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
            local score = nameScore + candidate.Size.Y * 2
            if score > bestScore then
                best = candidate
                bestScore = score
            end
        end
    end
    return best
end

local function placeTree(parent, position, targetHeight, yaw)
    local prefab = EnvironmentPrefabService.Get("TreePrimary")
    if not prefab then
        return nil
    end
    local ground = terrainSurfacePosition(position, 0)
    local placed = EnvironmentPrefabService.Place(
        "TreePrimary",
        parent,
        CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0),
        prefabScaleForHeight("TreePrimary", targetHeight)
    )
    if not placed then
        return nil
    end
    setRenderOnly(placed)
    local trunk = findTreeTrunkPart(placed)
    local trunkHeight = math.clamp(targetHeight * 0.42, 6.5, 13)
    local trunkRadius = math.clamp(targetHeight * 0.065, 1.25, 2.5)
    local trunkPosition = if trunk then trunk.Position else ground
    makeCollisionProxy(
        placed,
        "TreeTrunkCollision",
        Vector3.new(trunkRadius * 2, trunkHeight, trunkRadius * 2),
        CFrame.new(trunkPosition.X, ground.Y + trunkHeight * 0.5, trunkPosition.Z)
    )
    return placed
end

local function placeTreeArc(parent, center, radiusX, radiusZ, count, startDeg, endDeg, seed)
    if count <= 0 then
        return
    end
    for index = 1, count do
        local t = if count == 1 then 0.5 else (index - 1) / (count - 1)
        local angle = math.rad(startDeg + (endDeg - startDeg) * t)
        local jitter = ((index * 41 + seed * 19) % 17 - 8) * 0.75
        local position = center
            + Vector3.new(
                math.cos(angle) * (radiusX + jitter),
                0,
                math.sin(angle) * (radiusZ + jitter * 0.55)
            )
        if clearOfTravelLanes(position, 10) then
            local height = 24 + ((index * 13 + seed * 7) % 9)
            placeTree(parent, position, height, math.rad((index * 53 + seed * 31) % 360))
        end
    end
end

local function prefabScaleForLongest(prefabName, targetLongest)
    local prefab = EnvironmentPrefabService.Get(prefabName)
    if not prefab then
        return 1
    end
    local size = if prefab:IsA("Model") then prefab:GetExtentsSize() else prefab.Size
    local longest = math.max(size.X, size.Y, size.Z)
    if longest <= 0.01 then
        return 1
    end
    return targetLongest / longest
end

local function placeDressingPrefab(parent, prefabName, position, yaw, targetLongest)
    if not EnvironmentPrefabService.Get(prefabName) then
        return nil
    end
    local ground = terrainSurfacePosition(position, 0.02)
    local placed = EnvironmentPrefabService.Place(
        prefabName,
        parent,
        CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0),
        prefabScaleForLongest(prefabName, targetLongest)
    )
    if placed then
        setRenderOnly(placed)
        placed:SetAttribute("LumenreachDressing", true)

        -- Large scenery is physical, but imported mesh hulls are not trusted for
        -- gameplay collision. Use one predictable shrunken box per solid prop.
        local collisionScale = nil
        if prefabName == "MossyRockSet" then
            collisionScale = Vector3.new(0.72, 0.72, 0.72)
        elseif prefabName == "TreeStump" or prefabName == "TreeStump2" then
            collisionScale = Vector3.new(0.70, 0.82, 0.70)
        elseif prefabName == "FallenTreeTrunk" or prefabName == "FallenTreeTrunk2" then
            collisionScale = Vector3.new(0.80, 0.62, 0.76)
        elseif prefabName == "PineRoots" then
            collisionScale = Vector3.new(0.74, 0.46, 0.74)
        end
        if collisionScale then
            local collisionParent = if placed:IsA("Model") then placed else parent
            makeBoundingCollisionProxy(
                collisionParent,
                placed,
                prefabName .. "Collision",
                collisionScale
            )
        end
    end
    return placed
end

local function placeArchitecturePrefabBuilding(
    parent,
    name,
    prefabName,
    position,
    yaw,
    targetLongest,
    collisionSpecs
)
    local ground = terrainSurfacePosition(position, 0)
    local wrapper = Instance.new("Model")
    wrapper.Name = name
    wrapper:SetAttribute("EverLeafArchitecture", true)
    wrapper:SetAttribute("ArchitecturePrefab", prefabName)
    wrapper.Parent = parent

    local prefab = EnvironmentPrefabService.Get(prefabName)
    if not prefab then
        wrapper:SetAttribute("ArchitecturePrefabMissing", true)
        warn(
            string.format(
                "[LumenreachWorldService] Missing architecture prefab %s for %s",
                prefabName,
                name
            )
        )
        return wrapper
    end

    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    local architectureScale = prefabScaleForLongest(prefabName, targetLongest)
    local visual = EnvironmentPrefabService.Place(prefabName, wrapper, base, architectureScale)
    if not visual then
        wrapper:SetAttribute("ArchitecturePrefabMissing", true)
        return wrapper
    end
    visual.Name = "ArchitectureVisual"
    setArchitectureVisual(visual)

    for index, spec in collisionSpecs do
        -- Collision specs are authored in the same source-space dimensions as
        -- the Blender models. Scale both size and offset with the visual so
        -- collision stays aligned after prefab normalization.
        makeCollisionProxy(
            wrapper,
            "ArchitectureCollision" .. index,
            spec.Size * architectureScale,
            base * CFrame.new(spec.Offset * architectureScale)
        )
    end
    return wrapper
end

local function makeFernDressing(parent, position, yaw, scale)
    return placeDressingPrefab(parent, "FernPrimary", position, yaw, 4.2 * (scale or 1))
end

local function makeMossyRockDressing(parent, position, yaw, scale)
    return placeDressingPrefab(parent, "MossyRockSet", position, yaw, 7.2 * (scale or 1))
end

local function makeRootsDressing(parent, position, yaw, scale)
    return placeDressingPrefab(parent, "PineRoots", position, yaw, 6.5 * (scale or 1))
end

local function makeStumpDressing(parent, position, yaw, scale, variant)
    local prefabName = if variant == 2 then "TreeStump2" else "TreeStump"
    return placeDressingPrefab(parent, prefabName, position, yaw, 4.6 * (scale or 1))
end

local function makeFallenLogDressing(parent, position, yaw, scale, variant)
    local prefabName = if variant == 2 then "FallenTreeTrunk2" else "FallenTreeTrunk"
    return placeDressingPrefab(parent, prefabName, position, yaw, 11.5 * (scale or 1))
end

local function makeDryBranchesDressing(parent, position, yaw, scale)
    return placeDressingPrefab(parent, "DryBranches", position, yaw, 5.0 * (scale or 1))
end

local function placeGroundDetail(parent, position, seed, theme)
    if not clearOfTravelLanes(position, 6) or not clearOfDressingExclusions(position, 4) then
        return
    end

    local yaw = math.rad((seed * 71 + 19) % 360)
    local scale = 0.72 + ((seed * 17) % 28) / 100
    local choice = seed % 6

    if theme == "dry" then
        if choice <= 1 then
            makeDryBranchesDressing(parent, position, yaw, scale)
        elseif choice == 2 then
            makeStumpDressing(parent, position, yaw, scale, (seed % 2) + 1)
        elseif choice <= 4 then
            makeMossyRockDressing(parent, position, yaw, scale * 0.9)
        else
            makeRootsDressing(parent, position, yaw, scale * 0.85)
        end
    elseif theme == "wet" then
        if choice <= 2 then
            makeFernDressing(parent, position, yaw, scale)
        elseif choice == 3 then
            makeRootsDressing(parent, position, yaw, scale * 0.85)
        else
            makeMossyRockDressing(parent, position, yaw, scale * 0.8)
        end
    else
        if choice <= 2 then
            makeFernDressing(parent, position, yaw, scale)
        elseif choice == 3 then
            makeMossyRockDressing(parent, position, yaw, scale * 0.8)
        elseif choice == 4 then
            makeStumpDressing(parent, position, yaw, scale, (seed % 2) + 1)
        else
            makeRootsDressing(parent, position, yaw, scale * 0.8)
        end
    end
end

local function scatterForestBand(parent, center, radiusX, radiusZ, count, seed, theme)
    for index = 1, count do
        local angle = (index * 2.3999632297 + seed * 0.613) % (math.pi * 2)
        local radial = 0.68 + ((index * 29 + seed * 13) % 33) / 100
        local jitterX = ((index * 43 + seed * 17) % 19 - 9) * 1.3
        local jitterZ = ((index * 31 + seed * 23) % 17 - 8) * 1.15
        local position = center
            + Vector3.new(
                math.cos(angle) * radiusX * radial + jitterX,
                0,
                math.sin(angle) * radiusZ * radial + jitterZ
            )

        if clearOfTravelLanes(position, 8) and clearOfDressingExclusions(position, 7) then
            local height = 21 + ((index * 11 + seed * 5) % 13)
            placeTree(parent, position, height, math.rad((index * 47 + seed * 37) % 360))

            if index % 2 == 0 then
                local offsetAngle = angle + math.rad(35 + (index % 5) * 9)
                local detailPosition = position
                    + Vector3.new(math.cos(offsetAngle) * 6.5, 0, math.sin(offsetAngle) * 6.5)
                placeGroundDetail(parent, detailPosition, seed * 100 + index, theme)
            end
            if index % 7 == 0 then
                local logPosition = position
                    + Vector3.new(math.cos(angle + 1.2) * 9, 0, math.sin(angle + 1.2) * 9)
                if
                    clearOfTravelLanes(logPosition, 7) and clearOfDressingExclusions(logPosition, 5)
                then
                    makeFallenLogDressing(
                        parent,
                        logPosition,
                        angle + math.rad(58),
                        0.82,
                        (index % 2) + 1
                    )
                end
            end
        end
    end
end

local function dressRouteEdges(parent, route, seed)
    for segmentIndex = 1, #route.Points - 1 do
        local a = route.Points[segmentIndex]
        local b = route.Points[segmentIndex + 1]
        local delta = b - a
        local horizontal = Vector3.new(delta.X, 0, delta.Z)
        local length = horizontal.Magnitude
        if length > 1 then
            local direction = horizontal.Unit
            local right = Vector3.new(-direction.Z, 0, direction.X)
            local samples = math.max(1, math.floor(length / 40))
            for sample = 1, samples do
                local alpha = sample / (samples + 1)
                local center = a:Lerp(b, alpha)
                local side = if (sample + segmentIndex + seed) % 2 == 0 then -1 else 1
                local edgeDistance = route.Width * 0.5 + 13 + ((sample * 7 + seed) % 8)
                local position = center + right * side * edgeDistance
                placeGroundDetail(
                    parent,
                    position,
                    seed * 1000 + segmentIndex * 41 + sample,
                    "forest"
                )

                if sample % 3 == 0 and clearOfTravelLanes(position, 9) then
                    local treePosition = position + right * side * 8
                    if clearOfDressingExclusions(treePosition, 8) then
                        placeTree(
                            parent,
                            treePosition,
                            20 + ((sample * 5 + seed) % 8),
                            math.rad((sample * 67 + seed * 19) % 360)
                        )
                    end
                end
            end
        end
    end
end

local function scatterWorldFiller(parent)
    local halfWidth = WORLD_WIDTH * 0.5
    local halfDepth = WORLD_DEPTH * 0.5
    local cellSize = 105
    local zoneCoreRadius = 135
    local wetlandCenter = ZONES.Glowmere + Vector3.new(20, 0, 18)
    local wetlandRadius = 95

    local columns = math.floor((WORLD_WIDTH - cellSize * 3) / cellSize)
    local rows = math.floor((WORLD_DEPTH - cellSize * 3) / cellSize)
    local seed = 900

    for column = 0, columns do
        for row = 0, rows do
            seed += 1

            -- Intentionally leave some cells open so filler breaks up dead space
            -- without becoming a visible grid or choking traversal/combat.
            if (seed * 17) % 3 ~= 0 then
                local baseX = -halfWidth + cellSize * 1.5 + column * cellSize
                local baseZ = -halfDepth + cellSize * 1.5 + row * cellSize
                local jitterSpan = cellSize - 20
                local jitterX = ((seed * 53) % jitterSpan) - jitterSpan * 0.5
                local jitterZ = ((seed * 37) % jitterSpan) - jitterSpan * 0.5
                local position = Vector3.new(baseX + jitterX, 0, baseZ + jitterZ)

                local wetDx = position.X - wetlandCenter.X
                local wetDz = position.Z - wetlandCenter.Z
                local clearOfWetland = wetDx * wetDx + wetDz * wetDz > wetlandRadius * wetlandRadius

                if
                    clearOfWetland
                    and not isInsideAnyZoneCore(position, zoneCoreRadius)
                    and clearOfTravelLanes(position, 6)
                    and clearOfDressingExclusions(position, 6)
                then
                    local theme = if (seed % 5) == 0
                        then "dry"
                        elseif (seed % 3) == 0 then "wet"
                        else "forest"

                    if seed % 2 == 0 then
                        local height = 20 + (seed % 12)
                        placeTree(parent, position, height, math.rad((seed * 61) % 360))
                    else
                        placeGroundDetail(parent, position, seed, theme)
                    end
                end
            end
        end
    end
end

local function makeWaystone(parent, position, yaw, scale)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = "LumenWaystone"
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    scale = scale or 1
    local stone = makePart(
        model,
        "Stone",
        Vector3.new(2.4, 6.4, 1.9) * scale,
        base * CFrame.new(0, 3.2 * scale, 0),
        Enum.Material.Slate,
        Color3.fromRGB(74, 87, 80)
    )
    stone.CanCollide = false
    local rune = makePart(
        model,
        "Rune",
        Vector3.new(0.7, 2.6, 0.1) * scale,
        base * CFrame.new(0, 3.35 * scale, -1.0 * scale) * CFrame.Angles(0, 0, math.rad(18)),
        Enum.Material.Neon,
        Color3.fromRGB(107, 228, 185)
    )
    rune.CanCollide = false
    rune.CanTouch = false
    rune.CanQuery = false
    local light = Instance.new("PointLight")
    light.Color = rune.Color
    light.Brightness = 0.35
    light.Range = 7 * scale
    light.Shadows = false
    light.Parent = rune
    makeCollisionProxy(
        model,
        "WaystoneCollision",
        Vector3.new(2.5, 6.5, 2.0) * scale,
        base * CFrame.new(0, 3.25 * scale, 0)
    )
    return model
end

local function makeLantern(parent, position, yaw)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = "WayfarerLantern"
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    local post = makePart(
        model,
        "Post",
        Vector3.new(0.45, 7.4, 0.45),
        base * CFrame.new(0, 3.7, 0),
        Enum.Material.Wood,
        Color3.fromRGB(72, 52, 37)
    )
    post.CanCollide = false
    local glow = makePart(
        model,
        "Lamp",
        Vector3.new(0.85, 1.15, 0.85),
        base * CFrame.new(0, 7.0, 0),
        Enum.Material.Neon,
        Color3.fromRGB(132, 239, 194)
    )
    glow.CanCollide = false
    glow.CanTouch = false
    glow.CanQuery = false
    local light = Instance.new("PointLight")
    light.Color = glow.Color
    light.Brightness = 1.85
    light.Range = 22
    light.Shadows = true
    light.Parent = glow
    makeCollisionProxy(
        model,
        "LanternCollision",
        Vector3.new(0.8, 7.5, 0.8),
        base * CFrame.new(0, 3.75, 0)
    )
    return model
end

local function makeSign(parent, position, yaw, text)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = "WayfarerSign"
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    local post = makePart(
        model,
        "Post",
        Vector3.new(0.45, 6.2, 0.45),
        base * CFrame.new(0, 3.1, 0),
        Enum.Material.Wood,
        Color3.fromRGB(72, 52, 37)
    )
    post.CanCollide = false
    local board = makePart(
        model,
        "Board",
        Vector3.new(7.2, 1.7, 0.35),
        base * CFrame.new(0, 5.0, 0),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(112, 82, 49)
    )
    board.CanCollide = false
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.CanvasSize = Vector2.new(700, 150)
    gui.LightInfluence = 0.3
    gui.Parent = board
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(237, 226, 190)
    label.TextStrokeTransparency = 0.25
    label.TextStrokeColor3 = Color3.fromRGB(40, 30, 22)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui
    makeCollisionProxy(
        model,
        "SignPostCollision",
        Vector3.new(0.8, 6.3, 0.8),
        base * CFrame.new(0, 3.15, 0)
    )
    makePartSurfaceCollisionProxy(model, board, "SignBoardCollision", Vector3.new(0.2, 0.2, 0.3))
    return model
end

local function makeBench(parent, position, yaw)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = "WayfarerBench"
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    local wood = Color3.fromRGB(91, 67, 45)
    makePart(
        model,
        "Seat",
        Vector3.new(7.5, 0.55, 2.1),
        base * CFrame.new(0, 2.0, 0),
        Enum.Material.WoodPlanks,
        wood
    )
    local back = makePart(
        model,
        "Back",
        Vector3.new(7.5, 2.6, 0.45),
        base * CFrame.new(0, 3.0, 0.9),
        Enum.Material.Wood,
        wood
    )
    back.CanCollide = false
    for _, x in { -2.8, 2.8 } do
        makePart(
            model,
            "Leg",
            Vector3.new(0.6, 1.8, 0.6),
            base * CFrame.new(x, 0.9, 0),
            Enum.Material.Wood,
            wood
        )
    end
    makeCollisionProxy(
        model,
        "BenchCollision",
        Vector3.new(7.7, 2.5, 2.2),
        base * CFrame.new(0, 1.25, 0)
    )
    return model
end

local function makeHearth(parent, position)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = "WayfarerHearth"
    model.Parent = parent
    for index = 1, 10 do
        local angle = (index - 1) * math.pi * 2 / 10
        local stone = makePart(
            model,
            "HearthStone",
            Vector3.new(2.6, 1.0, 1.8),
            CFrame.new(ground + Vector3.new(math.cos(angle) * 4.2, 0.5, math.sin(angle) * 4.2))
                * CFrame.Angles(0, -angle, 0),
            Enum.Material.Slate,
            Color3.fromRGB(76, 84, 80)
        )
        stone.CanCollide = false
    end
    local ember = makePart(
        model,
        "EmberBed",
        Vector3.new(5.5, 0.45, 5.5),
        CFrame.new(ground + Vector3.new(0, 0.35, 0)),
        Enum.Material.Slate,
        Color3.fromRGB(66, 57, 48)
    )
    ember.CanCollide = false
    local fire = Instance.new("Fire")
    fire.Name = "HearthFire"
    fire.Color = Color3.fromRGB(255, 188, 92)
    fire.SecondaryColor = Color3.fromRGB(92, 229, 178)
    fire.Heat = 4
    fire.Size = 4.5
    fire.Parent = ember
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 195, 118)
    light.Brightness = 1.35
    light.Range = 22
    light.Shadows = true
    light.Parent = ember
    makeCollisionProxy(
        model,
        "HearthCollision",
        Vector3.new(8.6, 1.8, 8.6),
        CFrame.new(ground + Vector3.new(0, 0.9, 0))
    )
    return model
end

local function makeMarketStall(parent, position, yaw, accent)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = "WayfarerMarketStall"
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    local timber = Color3.fromRGB(79, 57, 39)
    local cloth = accent or Color3.fromRGB(82, 132, 104)

    for _, x in { -5.4, 5.4 } do
        for _, z in { -2.5, 2.5 } do
            local post = makePart(
                model,
                "Post",
                Vector3.new(0.65, 8.6, 0.65),
                base * CFrame.new(x, 4.3, z),
                Enum.Material.Wood,
                timber
            )
            post.CanCollide = false
            makePartSurfaceCollisionProxy(
                model,
                post,
                "MarketPostCollision",
                Vector3.new(0.25, 0, 0.25)
            )
        end
    end

    local counter = makePart(
        model,
        "Counter",
        Vector3.new(11.4, 0.65, 2.4),
        base * CFrame.new(0, 2.45, -0.55),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(104, 76, 49)
    )
    counter.CanCollide = false
    counter.CanTouch = false
    counter.CanQuery = false
    local lowerShelf = makePart(
        model,
        "LowerShelf",
        Vector3.new(10.8, 0.45, 2.8),
        base * CFrame.new(0, 0.9, 0.9),
        Enum.Material.WoodPlanks,
        timber
    )
    lowerShelf.CanCollide = false
    local backShelf = makePart(
        model,
        "BackShelf",
        Vector3.new(10.8, 3.0, 0.45),
        base * CFrame.new(0, 4.0, 2.55),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(92, 69, 47)
    )
    backShelf.CanCollide = false

    -- Full avatar clearance; the old canopy intersected player heads/cameras.
    local canopy = makePart(
        model,
        "Canopy",
        Vector3.new(13.4, 0.42, 7.4),
        base * CFrame.new(0, 8.45, 0) * CFrame.Angles(math.rad(-7), 0, 0),
        Enum.Material.Fabric,
        cloth
    )
    canopy.CanCollide = false
    canopy.CanTouch = false
    canopy.CanQuery = false
    makePartSurfaceCollisionProxy(
        model,
        canopy,
        "MarketCanopyCollision",
        Vector3.new(0.15, 0.18, 0.15)
    )
    local valance = makePart(
        model,
        "CanopyValance",
        Vector3.new(13.0, 1.05, 0.22),
        base * CFrame.new(0, 7.55, -3.45),
        Enum.Material.Fabric,
        cloth:Lerp(Color3.new(0, 0, 0), 0.12)
    )
    valance.CanCollide = false
    valance.CanTouch = false
    valance.CanQuery = false

    for index, x in { -3.6, 0, 3.6 } do
        local crate = makePart(
            model,
            "DisplayCrate" .. index,
            Vector3.new(2.3, 1.0, 1.8),
            base * CFrame.new(x, 3.25, 0.1),
            Enum.Material.WoodPlanks,
            Color3.fromRGB(118, 87, 53)
        )
        crate.CanCollide = false
        crate.CanTouch = false
        crate.CanQuery = false
    end
    makeCollisionProxy(
        model,
        "MarketCounterCollision",
        Vector3.new(11.6, 2.8, 2.6),
        base * CFrame.new(0, 1.4, -0.55)
    )
    makeCollisionProxy(
        model,
        "MarketBackCollision",
        Vector3.new(10.9, 4.9, 0.7),
        base * CFrame.new(0, 2.45, 2.55)
    )
    return model
end

local function makeWatchtower(parent, position, yaw)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = "WayfarerWatchtower"
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    local wood = Color3.fromRGB(75, 56, 40)
    for _, x in { -1, 1 } do
        for _, z in { -1, 1 } do
            makePart(
                model,
                "TowerPost",
                Vector3.new(1, 13, 1),
                base * CFrame.new(x * 4.4, 6.5, z * 4.4),
                Enum.Material.Wood,
                wood
            )
        end
    end
    makePart(
        model,
        "TowerDeck",
        Vector3.new(11, 0.8, 11),
        base * CFrame.new(0, 12.3, 0),
        Enum.Material.WoodPlanks,
        wood
    )
    for _, side in { -1, 1 } do
        local railA = makePart(
            model,
            "TowerRail",
            Vector3.new(11, 1.0, 0.45),
            base * CFrame.new(0, 14.0, side * 5.0),
            Enum.Material.Wood,
            wood
        )
        railA.CanCollide = false
        local railB = makePart(
            model,
            "TowerRail",
            Vector3.new(0.45, 1.0, 11),
            base * CFrame.new(side * 5.0, 14.0, 0),
            Enum.Material.Wood,
            wood
        )
        railB.CanCollide = false
    end
    for _, x in { -1, 1 } do
        for _, z in { -1, 1 } do
            makeCollisionProxy(
                model,
                "WatchtowerPostCollision",
                Vector3.new(1.35, 13, 1.35),
                base * CFrame.new(x * 4.4, 6.5, z * 4.4)
            )
        end
    end
    makeCollisionProxy(
        model,
        "WatchtowerDeckCollision",
        Vector3.new(11, 0.9, 11),
        base * CFrame.new(0, 12.3, 0)
    )
    return model
end

local function makeBoardwalk(parent, name, a, b, width)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local groundA = terrainSurfacePosition(a, 0)
    local groundB = terrainSurfacePosition(b, 0)
    local delta = groundB - groundA
    local length = delta.Magnitude
    local frame = CFrame.lookAt(
        (groundA + groundB) * 0.5 + Vector3.new(0, 1.0, 0),
        groundB + Vector3.new(0, 1.0, 0)
    )
    local count = math.max(6, math.ceil(length / 3.0))
    local wood = Color3.fromRGB(88, 68, 47)
    for index = 0, count - 1 do
        local alpha = (index + 0.5) / count
        local z = -length * 0.5 + length * alpha
        local plank = makePart(
            model,
            "BoardwalkPlank",
            Vector3.new(width, 0.45, length / count - 0.12),
            frame * CFrame.new(0, 0, z),
            Enum.Material.WoodPlanks,
            wood
        )
        plank.CanCollide = false
        plank.CanTouch = false
        plank.CanQuery = false
    end
    makeCollisionProxy(
        model,
        "BoardwalkCollision",
        Vector3.new(width - 0.6, 0.8, length),
        frame * CFrame.new(0, -0.1, 0)
    )
    return model
end

local function makeRuinWall(parent, position, yaw, length, height)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = "WayfarerRuinWall"
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    local segments = math.max(3, math.floor(length / 5))
    for index = 1, segments do
        local alpha = (index - 0.5) / segments
        local x = -length * 0.5 + length * alpha
        local broken = height * (0.55 + ((index * 37) % 40) / 100)
        makePart(
            model,
            "RuinStone",
            Vector3.new(length / segments - 0.25, broken, 2.8),
            base * CFrame.new(x, broken * 0.5, 0),
            Enum.Material.Slate,
            Color3.fromRGB(75, 84, 82)
        )
    end
    makeCollisionProxy(
        model,
        "RuinWallCollision",
        Vector3.new(length, math.max(2.5, height * 0.78), 3.0),
        base * CFrame.new(0, math.max(2.5, height * 0.78) * 0.5, 0)
    )
    return model
end

local function makeOverlookDeck(parent, position, yaw, width, depth)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = "WayfarerOverlook"
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    local wood = Color3.fromRGB(78, 59, 43)
    makePart(
        model,
        "Deck",
        Vector3.new(width, 0.7, depth),
        base * CFrame.new(0, 0.6, 0),
        Enum.Material.WoodPlanks,
        wood
    )
    for _, side in { -1, 1 } do
        local rail = makePart(
            model,
            "Rail",
            Vector3.new(0.5, 2.2, depth),
            base * CFrame.new(side * width * 0.5, 1.7, 0),
            Enum.Material.Wood,
            wood
        )
        rail.CanCollide = false
    end
    local front = makePart(
        model,
        "Rail",
        Vector3.new(width, 2.2, 0.5),
        base * CFrame.new(0, 1.7, -depth * 0.5),
        Enum.Material.Wood,
        wood
    )
    front.CanCollide = false
    makeCollisionProxy(
        model,
        "OverlookDeckCollision",
        Vector3.new(width, 0.8, depth),
        base * CFrame.new(0, 0.6, 0)
    )
    for _, side in { -1, 1 } do
        makeCollisionProxy(
            model,
            "OverlookRailCollision",
            Vector3.new(0.65, 2.3, depth),
            base * CFrame.new(side * width * 0.5, 1.7, 0)
        )
    end
    makeCollisionProxy(
        model,
        "OverlookFrontRailCollision",
        Vector3.new(width, 2.3, 0.65),
        base * CFrame.new(0, 1.7, -depth * 0.5)
    )
    return model
end

local function makeLumenPylon(parent, position, height)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = "LumenPylon"
    model.Parent = parent
    makePart(
        model,
        "Pillar",
        Vector3.new(3.3, height, 3.3),
        CFrame.new(ground + Vector3.new(0, height * 0.5, 0)),
        Enum.Material.Slate,
        Color3.fromRGB(75, 86, 82)
    )
    local glow = makePart(
        model,
        "Lumen",
        Vector3.new(2.0, 2.8, 2.0),
        CFrame.new(ground + Vector3.new(0, height - 1.6, 0)),
        Enum.Material.Neon,
        Color3.fromRGB(105, 232, 194)
    )
    glow.CanCollide = false
    glow.CanTouch = false
    glow.CanQuery = false
    local light = Instance.new("PointLight")
    light.Color = glow.Color
    light.Brightness = 1.0
    light.Range = 15
    light.Parent = glow
    makeCollisionProxy(
        model,
        "PylonCollision",
        Vector3.new(3.5, height, 3.5),
        CFrame.new(ground + Vector3.new(0, height * 0.5, 0))
    )
    return model
end

local function makeFenceLine(parent, name, a, b, spacing, height)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local groundA = terrainSurfacePosition(a, 0)
    local groundB = terrainSurfacePosition(b, 0)
    local delta = groundB - groundA
    local length = delta.Magnitude
    local frame = CFrame.lookAt((groundA + groundB) * 0.5, groundB)
    local postSpacing = spacing or 8
    local postHeight = height or 5
    local posts = math.max(2, math.ceil(length / postSpacing))
    local wood = Color3.fromRGB(72, 52, 37)
    for index = 0, posts do
        local alpha = index / posts
        local z = -length * 0.5 + length * alpha
        local post = makePart(
            model,
            "FencePost",
            Vector3.new(0.7, postHeight, 0.7),
            frame * CFrame.new(0, postHeight * 0.5, z),
            Enum.Material.Wood,
            wood
        )
        post.CanCollide = false
        post.CanTouch = false
        post.CanQuery = false
    end
    for _, y in { 1.8, 3.7 } do
        local rail = makePart(
            model,
            "FenceRail",
            Vector3.new(0.5, 0.45, length),
            frame * CFrame.new(0, y, 0),
            Enum.Material.Wood,
            wood
        )
        rail.CanCollide = false
        rail.CanTouch = false
        rail.CanQuery = false
    end
    makeCollisionProxy(
        model,
        "FenceCollision",
        Vector3.new(0.7, postHeight, length + 0.7),
        frame * CFrame.new(0, postHeight * 0.5, 0)
    )
    return model
end

local function makeSupplyStack(parent, position, yaw, scale)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = "WayfarerSupplyStack"
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    scale = scale or 1
    local crateColor = Color3.fromRGB(106, 79, 50)
    for index, spec in
        {
            { -2.2, 1.1, 0.0, 3.4, 2.2, 3.0 },
            { 1.5, 1.0, 0.8, 2.8, 2.0, 2.6 },
            { -0.4, 3.0, 0.4, 2.5, 1.9, 2.4 },
        }
    do
        local crate = makePart(
            model,
            "SupplyCrate" .. index,
            Vector3.new(spec[4], spec[5], spec[6]) * scale,
            base * CFrame.new(spec[1] * scale, spec[2] * scale, spec[3] * scale),
            Enum.Material.WoodPlanks,
            crateColor
        )
        crate.CanCollide = false
        crate.CanTouch = false
        crate.CanQuery = false
    end
    local barrel = makePart(
        model,
        "SupplyBarrel",
        Vector3.new(2.2, 3.0, 2.2) * scale,
        base
            * CFrame.new(3.2 * scale, 1.5 * scale, -0.8 * scale)
            * CFrame.Angles(0, 0, math.rad(90)),
        Enum.Material.Wood,
        Color3.fromRGB(87, 63, 43)
    )
    barrel.Shape = Enum.PartType.Cylinder
    barrel.CanCollide = false
    barrel.CanTouch = false
    barrel.CanQuery = false
    makeCollisionProxy(
        model,
        "SupplyStackCollision",
        Vector3.new(7.4, 3.8, 5.2) * scale,
        base * CFrame.new(0.45 * scale, 1.9 * scale, 0.15 * scale)
    )
    return model
end

local function makeRoadsideShelter(parent, name, position, yaw)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    local wood = Color3.fromRGB(78, 58, 40)
    for _, x in { -5.5, 5.5 } do
        local post = makePart(
            model,
            "ShelterPost",
            Vector3.new(0.8, 7.2, 0.8),
            base * CFrame.new(x, 3.6, 0),
            Enum.Material.Wood,
            wood
        )
        post.CanCollide = false
    end
    local roof = makePart(
        model,
        "ShelterRoof",
        Vector3.new(13.5, 0.7, 8.5),
        base * CFrame.new(0, 7.2, 0) * CFrame.Angles(0, 0, math.rad(-5)),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(48, 67, 57)
    )
    roof.CanCollide = false
    roof.CanTouch = false
    roof.CanQuery = false
    makePartSurfaceCollisionProxy(
        model,
        roof,
        "ShelterRoofCollision",
        Vector3.new(0.15, 0.15, 0.15)
    )
    for _, x in { -5.5, 5.5 } do
        makeCollisionProxy(
            model,
            "ShelterPostCollision",
            Vector3.new(1.0, 7.2, 1.0),
            base * CFrame.new(x, 3.6, 0)
        )
    end
    makeBench(model, position + Vector3.new(0, 0, 1), yaw or 0)
    return model
end

local function makeStoneShrine(parent, name, position, yaw, _accent)
    return placeArchitecturePrefabBuilding(parent, name, "LumenStoneShrine", position, yaw, 22, {
        { Size = Vector3.new(15, 1.4, 11), Offset = Vector3.new(0, 0.7, 0) },
        { Size = Vector3.new(2.4, 10, 2.4), Offset = Vector3.new(-5, 5, 0) },
        { Size = Vector3.new(2.4, 10, 2.4), Offset = Vector3.new(5, 5, 0) },
    })
end

local function makeRuinedHall(parent, name, center, width, depth, yaw)
    local longest = math.max(width or 30, depth or 22) + 4
    return placeArchitecturePrefabBuilding(parent, name, "LumenRuinedHall", center, yaw, longest, {
        { Size = Vector3.new(width or 30, 1.2, depth or 22), Offset = Vector3.new(0, 0.6, 0) },
        {
            Size = Vector3.new((width or 30) * 0.72, 9, 2),
            Offset = Vector3.new(-2, 4.5, (depth or 22) * 0.43),
        },
        {
            Size = Vector3.new(2, 8, (depth or 22) * 0.68),
            Offset = Vector3.new(-(width or 30) * 0.46, 4, 2),
        },
    })
end

local function makeGatehouse(parent, name, position, yaw, width)
    width = width or 30
    return placeArchitecturePrefabBuilding(
        parent,
        name,
        "LumenFrontierGatehouse",
        position,
        yaw,
        width + 16,
        {
            { Size = Vector3.new(9, 18, 11), Offset = Vector3.new(-width * 0.5, 9, 0) },
            { Size = Vector3.new(9, 18, 11), Offset = Vector3.new(width * 0.5, 9, 0) },
            { Size = Vector3.new(math.max(8, width - 9), 4, 8), Offset = Vector3.new(0, 15, 0) },
        }
    )
end

local SIGNATURE = table.freeze({
    Timber = Color3.fromRGB(68, 50, 36),
    TimberLight = Color3.fromRGB(103, 76, 51),
    Slate = Color3.fromRGB(70, 82, 79),
    SlateDark = Color3.fromRGB(53, 65, 62),
    Plaster = Color3.fromRGB(120, 132, 111),
    Bronze = Color3.fromRGB(151, 112, 62),
    Lumen = Color3.fromRGB(100, 236, 194),
    Cloth = Color3.fromRGB(56, 101, 82),
    ClothGold = Color3.fromRGB(166, 123, 62),
})

local function makeSignatureCrystal(parent, name, base, height, color)
    local crystal = makePart(
        parent,
        name,
        Vector3.new(1.2, height, 1.2),
        base * CFrame.new(0, height * 0.5, 0) * CFrame.Angles(0, math.rad(45), math.rad(7)),
        Enum.Material.Neon,
        color or SIGNATURE.Lumen
    )
    crystal.CanCollide = false
    crystal.CanTouch = false
    crystal.CanQuery = false
    local light = Instance.new("PointLight")
    light.Color = crystal.Color
    light.Brightness = 0.8
    light.Range = 12
    light.Shadows = false
    light.Parent = crystal
    makeCollisionProxy(
        parent,
        name .. "Collision",
        Vector3.new(1.45, height, 1.45),
        base * CFrame.new(0, height * 0.5, 0)
    )
    return crystal
end

local function makeWayfarerBanner(parent, name, position, yaw, accent)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    local pole = makePart(
        model,
        "BannerPole",
        Vector3.new(0.45, 10.5, 0.45),
        base * CFrame.new(0, 5.25, 0),
        Enum.Material.Wood,
        SIGNATURE.Timber
    )
    pole.CanCollide = false
    local cross = makePart(
        model,
        "BannerCrossbar",
        Vector3.new(5.2, 0.4, 0.4),
        base * CFrame.new(2.25, 9.2, 0),
        Enum.Material.Wood,
        SIGNATURE.Timber
    )
    cross.CanCollide = false
    local cloth = makePart(
        model,
        "BannerCloth",
        Vector3.new(4.4, 5.8, 0.18),
        base * CFrame.new(2.25, 6.25, -0.2),
        Enum.Material.Fabric,
        accent or SIGNATURE.Cloth
    )
    cloth.CanCollide = false
    cloth.CanTouch = false
    cloth.CanQuery = false
    local sigil = makePart(
        model,
        "BannerLumenSigil",
        Vector3.new(0.55, 3.0, 0.12),
        base * CFrame.new(2.25, 6.45, -0.34) * CFrame.Angles(0, 0, math.rad(25)),
        Enum.Material.Neon,
        SIGNATURE.Lumen
    )
    sigil.CanCollide = false
    sigil.CanTouch = false
    sigil.CanQuery = false
    makeCollisionProxy(
        model,
        "BannerPoleCollision",
        Vector3.new(0.8, 10.5, 0.8),
        base * CFrame.new(0, 5.25, 0)
    )
    return model
end

local function makeWayfarerStreetArch(parent, name, position, yaw, width, accent)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    width = width or 24
    accent = accent or SIGNATURE.Lumen

    for _, side in { -1, 1 } do
        local post = makePart(
            model,
            "ArchPost",
            Vector3.new(2.2, 12, 2.2),
            base * CFrame.new(side * width * 0.5, 6, 0),
            Enum.Material.Slate,
            SIGNATURE.Slate
        )
        post.CanCollide = false
        local timber = makePart(
            model,
            "ArchTimber",
            Vector3.new(0.65, 12.7, 2.7),
            base * CFrame.new(side * width * 0.5, 6.35, -0.15),
            Enum.Material.Wood,
            SIGNATURE.Timber
        )
        timber.CanCollide = false
        makeSignatureCrystal(
            model,
            "ArchCrystal",
            base * CFrame.new(side * width * 0.5, 10.9, -1.25),
            2.6,
            accent
        )
    end

    local beam = makePart(
        model,
        "ArchBeam",
        Vector3.new(width + 3, 1.8, 3.1),
        base * CFrame.new(0, 11.65, 0),
        Enum.Material.WoodPlanks,
        SIGNATURE.Timber
    )
    beam.CanCollide = false
    beam.CanTouch = false
    beam.CanQuery = false
    makePartSurfaceCollisionProxy(model, beam, "ArchBeamCollision", Vector3.new(0.1, 0.1, 0.1))

    -- Two continuous roof planes replace the detached wedge plates visible in Studio.
    local pitch = math.rad(18)
    local halfRun = width * 0.5 + 1.6
    local slopeLength = halfRun / math.cos(pitch)
    local rise = halfRun * math.tan(pitch)
    local eaveY = 12.55
    for _, side in { -1, 1 } do
        local roof = makePart(
            model,
            "ArchRoof",
            Vector3.new(slopeLength + 0.1, 0.58, 5.6),
            base
                * CFrame.new(side * halfRun * 0.5, eaveY + rise * 0.5, 0)
                * CFrame.Angles(0, 0, -side * pitch),
            Enum.Material.WoodPlanks,
            SIGNATURE.SlateDark
        )
        roof.CanCollide = false
        roof.CanTouch = false
        roof.CanQuery = false
        makePartSurfaceCollisionProxy(model, roof, "ArchRoofCollision", Vector3.new(0.1, 0.1, 0.1))
    end
    local crest = makePart(
        model,
        "ArchRoofCrest",
        Vector3.new(0.7, 0.7, 5.9),
        base * CFrame.new(0, eaveY + rise, 0),
        Enum.Material.Metal,
        SIGNATURE.Bronze
    )
    crest.CanCollide = false
    crest.CanTouch = false
    crest.CanQuery = false
    for _, side in { -1, 1 } do
        makeCollisionProxy(
            model,
            "ArchPostCollision",
            Vector3.new(2.45, 12, 2.45),
            base * CFrame.new(side * width * 0.5, 6, 0)
        )
    end
    return model
end

local function makeWayfarerCart(parent, name, position, yaw, loaded)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    local bed = makePart(
        model,
        "CartBed",
        Vector3.new(8.5, 1.2, 5.2),
        base * CFrame.new(0, 2.9, 0),
        Enum.Material.WoodPlanks,
        SIGNATURE.TimberLight
    )
    bed.CanCollide = false
    for _, x in { -4.4, 4.4 } do
        local side = makePart(
            model,
            "CartSide",
            Vector3.new(0.6, 3.1, 5.4),
            base * CFrame.new(x, 4.1, 0),
            Enum.Material.Wood,
            SIGNATURE.Timber
        )
        side.CanCollide = false
    end
    for _, z in { -2.9, 2.9 } do
        for _, x in { -3.25, 3.25 } do
            local wheel = makePart(
                model,
                "CartWheel",
                Vector3.new(0.7, 4.2, 4.2),
                base * CFrame.new(x, 2.0, z) * CFrame.Angles(0, 0, math.rad(90)),
                Enum.Material.Wood,
                SIGNATURE.Timber
            )
            wheel.Shape = Enum.PartType.Cylinder
            wheel.CanCollide = false
        end
    end
    for _, x in { -1.6, 1.6 } do
        local shaft = makePart(
            model,
            "CartShaft",
            Vector3.new(0.45, 0.45, 10),
            base * CFrame.new(x, 2.2, -7.0),
            Enum.Material.Wood,
            SIGNATURE.Timber
        )
        shaft.CanCollide = false
    end
    if loaded ~= false then
        for index, spec in
            {
                { -1.9, 3.9, -0.8, 2.4, 1.8, 2.3 },
                { 1.2, 3.8, 0.8, 2.1, 1.6, 2.0 },
                { 0.1, 5.1, -0.2, 2.0, 1.5, 1.8 },
            }
        do
            local cargo = makePart(
                model,
                "CartCargo" .. index,
                Vector3.new(spec[4], spec[5], spec[6]),
                base * CFrame.new(spec[1], spec[2], spec[3]),
                Enum.Material.WoodPlanks,
                Color3.fromRGB(111, 82, 52)
            )
            cargo.CanCollide = false
            cargo.CanTouch = false
            cargo.CanQuery = false
        end
    end
    makeCollisionProxy(
        model,
        "CartBodyCollision",
        Vector3.new(9.5, 5.0, 6.2),
        base * CFrame.new(0, 2.5, 0)
    )
    makeCollisionProxy(
        model,
        "CartShaftCollision",
        Vector3.new(4.2, 1.2, 10.0),
        base * CFrame.new(0, 2.2, -7.0)
    )
    return model
end

local function makeForgeYard(parent, name, position, yaw)
    return placeArchitecturePrefabBuilding(parent, name, "LumenForgeYard", position, yaw, 34, {
        { Size = Vector3.new(8, 13, 7), Offset = Vector3.new(-5, 6.5, 1) },
        { Size = Vector3.new(5.5, 4.5, 2.5), Offset = Vector3.new(5, 2.25, -1) },
        { Size = Vector3.new(1, 8, 1), Offset = Vector3.new(-10, 4, 6) },
        { Size = Vector3.new(1, 8, 1), Offset = Vector3.new(10, 4, 6) },
    })
end

local function makeLumenWell(parent, name, position, accent)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground)
    for index = 1, 12 do
        local angle = (index - 1) * math.pi * 2 / 12
        local stone = makePart(
            model,
            "WellStone",
            Vector3.new(3.2, 1.4, 1.7),
            base
                * CFrame.new(math.cos(angle) * 5.2, 0.7, math.sin(angle) * 5.2)
                * CFrame.Angles(0, -angle, 0),
            Enum.Material.Slate,
            SIGNATURE.Slate
        )
        stone.CanCollide = false
    end
    local water = makePart(
        model,
        "WellLumenWater",
        Vector3.new(8.5, 0.28, 8.5),
        base * CFrame.new(0, 0.72, 0),
        Enum.Material.Glass,
        accent or SIGNATURE.Lumen
    )
    water.Shape = Enum.PartType.Cylinder
    water.Transparency = 0.25
    water.CanCollide = false
    water.CanTouch = false
    water.CanQuery = false
    makeSignatureCrystal(
        model,
        "WellHeart",
        base * CFrame.new(0, 0.8, 0),
        4.2,
        accent or SIGNATURE.Lumen
    )
    makeCollisionProxy(
        model,
        "WellCollision",
        Vector3.new(10.8, 2.6, 10.8),
        base * CFrame.new(0, 1.3, 0)
    )
    return model
end

local function makeTrainingGround(parent, name, position, yaw)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    for index, x in { -10, 0, 10 } do
        local post = makePart(
            model,
            "TrainingPost" .. index,
            Vector3.new(1.4, 7.2, 1.4),
            base * CFrame.new(x, 3.6, 0),
            Enum.Material.Wood,
            SIGNATURE.Timber
        )
        post.CanCollide = false
        local arm = makePart(
            model,
            "TrainingArm" .. index,
            Vector3.new(5.0, 0.8, 0.8),
            base * CFrame.new(x, 5.1, 0) * CFrame.Angles(0, math.rad(18 * index), 0),
            Enum.Material.Wood,
            SIGNATURE.TimberLight
        )
        arm.CanCollide = false
        local core = makePart(
            model,
            "TrainingLumen" .. index,
            Vector3.new(1.8, 1.8, 0.4),
            base * CFrame.new(x, 4.1, -0.9),
            Enum.Material.Neon,
            SIGNATURE.Lumen
        )
        core.CanCollide = false
        core.CanTouch = false
        core.CanQuery = false
    end
    for index, x in { -10, 0, 10 } do
        makeCollisionProxy(
            model,
            "TrainingPostCollision" .. index,
            Vector3.new(1.7, 7.2, 1.7),
            base * CFrame.new(x, 3.6, 0)
        )
    end
    for _, z in { -9, 9 } do
        makeFenceLine(
            model,
            "TrainingRail",
            position + base.RightVector * -16 + base.LookVector * z,
            position + base.RightVector * 16 + base.LookVector * z,
            8,
            3.4
        )
    end
    return model
end

local function makeGlowmereStiltHouse(parent, name, position, yaw, _accent)
    return placeArchitecturePrefabBuilding(
        parent,
        name,
        "LumenGlowmereStiltHouse",
        position,
        yaw,
        36,
        {
            { Size = Vector3.new(15, 1, 12), Offset = Vector3.new(0, 5.8, 0) },
            { Size = Vector3.new(1, 8, 1), Offset = Vector3.new(-6.5, 4, -5) },
            { Size = Vector3.new(1, 8, 1), Offset = Vector3.new(6.5, 4, -5) },
            { Size = Vector3.new(1, 8, 1), Offset = Vector3.new(-6.5, 4, 5) },
            { Size = Vector3.new(1, 8, 1), Offset = Vector3.new(6.5, 4, 5) },
            { Size = Vector3.new(10, 1, 5.5), Offset = Vector3.new(0, 5.8, -8.3) },
        }
    )
end

local function makeReedDock(parent, name, position, yaw, length)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    length = length or 24
    for index = 0, math.floor(length / 3) do
        local plank = makePart(
            model,
            "DockPlank",
            Vector3.new(8, 0.45, 2.7),
            base * CFrame.new(0, 1.0, -index * 3),
            Enum.Material.WoodPlanks,
            SIGNATURE.TimberLight
        )
        plank.CanCollide = false
    end
    for _, side in { -3.6, 3.6 } do
        for index = 0, math.floor(length / 9) do
            local post = makePart(
                model,
                "DockPost",
                Vector3.new(0.55, 4.0, 0.55),
                base * CFrame.new(side, 0.1, -index * 9),
                Enum.Material.Wood,
                SIGNATURE.Timber
            )
            post.CanCollide = false
        end
    end
    makeCollisionProxy(
        model,
        "DockCollision",
        Vector3.new(7.6, 0.7, length + 2.5),
        base * CFrame.new(0, 0.95, -length * 0.5)
    )
    local skiffCFrame = base
        * CFrame.new(8.2, 0.7, -length * 0.55)
        * CFrame.Angles(math.rad(4), 0, 0)
    local skiff = makePart(
        model,
        "WayfarerSkiff",
        Vector3.new(5.2, 1.2, 13.0),
        skiffCFrame,
        Enum.Material.WoodPlanks,
        Color3.fromRGB(92, 68, 45)
    )
    skiff.CanCollide = false
    makeCollisionProxy(model, "SkiffCollision", Vector3.new(5.4, 1.5, 13.0), skiffCFrame)
    return model
end

local function makeGraveboneMausoleum(parent, name, position, yaw)
    return placeArchitecturePrefabBuilding(
        parent,
        name,
        "LumenGraveboneMausoleum",
        position,
        yaw,
        30,
        {
            { Size = Vector3.new(20, 1.5, 18), Offset = Vector3.new(0, 0.75, 0) },
            { Size = Vector3.new(18, 11, 2.5), Offset = Vector3.new(0, 6, 7) },
            { Size = Vector3.new(3.4, 11, 3.4), Offset = Vector3.new(-7, 6, -5.5) },
            { Size = Vector3.new(3.4, 11, 3.4), Offset = Vector3.new(7, 6, -5.5) },
        }
    )
end

local function makeMossglenRangerHall(parent, name, position, yaw)
    return placeArchitecturePrefabBuilding(
        parent,
        name,
        "LumenMossglenRangerHall",
        position,
        yaw,
        52,
        {
            { Size = Vector3.new(34, 10, 22), Offset = Vector3.new(0, 5, 0) },
            { Size = Vector3.new(9, 8, 9), Offset = Vector3.new(21, 4, 2) },
        }
    )
end

local function makeSunmossObservatory(parent, name, position, yaw)
    return placeArchitecturePrefabBuilding(
        parent,
        name,
        "LumenSunmossObservatory",
        position,
        yaw,
        42,
        {
            { Size = Vector3.new(27, 2, 27), Offset = Vector3.new(0, 1, 0) },
            { Size = Vector3.new(2.5, 15, 2.5), Offset = Vector3.new(-8, 7.5, -8) },
            { Size = Vector3.new(2.5, 15, 2.5), Offset = Vector3.new(8, 7.5, -8) },
            { Size = Vector3.new(2.5, 15, 2.5), Offset = Vector3.new(-8, 7.5, 8) },
            { Size = Vector3.new(2.5, 15, 2.5), Offset = Vector3.new(8, 7.5, 8) },
            { Size = Vector3.new(27, 1.2, 27), Offset = Vector3.new(0, 15.2, 0) },
        }
    )
end

local function makeVeilfallSanctuary(parent, name, position, yaw)
    return placeArchitecturePrefabBuilding(
        parent,
        name,
        "LumenVeilfallSanctuary",
        position,
        yaw,
        42,
        {
            { Size = Vector3.new(34, 1.4, 27), Offset = Vector3.new(0, 0.7, 0) },
            { Size = Vector3.new(2.5, 13, 2.5), Offset = Vector3.new(-12, 6.5, -9) },
            { Size = Vector3.new(2.5, 13, 2.5), Offset = Vector3.new(0, 6.5, -9) },
            { Size = Vector3.new(2.5, 13, 2.5), Offset = Vector3.new(12, 6.5, -9) },
            { Size = Vector3.new(2.5, 13, 2.5), Offset = Vector3.new(-12, 6.5, 9) },
            { Size = Vector3.new(2.5, 13, 2.5), Offset = Vector3.new(0, 6.5, 9) },
            { Size = Vector3.new(2.5, 13, 2.5), Offset = Vector3.new(12, 6.5, 9) },
        }
    )
end

local function makeShatteredFortressTower(parent, name, position, yaw, _brokenSide)
    return placeArchitecturePrefabBuilding(
        parent,
        name,
        "LumenShatteredFortressTower",
        position,
        yaw,
        38,
        {
            { Size = Vector3.new(18.5, 28, 18.5), Offset = Vector3.new(0, 14, 0) },
        }
    )
end

local function makeProvingGrandstand(parent, name, position, yaw, width)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    width = width or 28
    for tier = 0, 3 do
        local bench = makePart(
            model,
            "StandTier",
            Vector3.new(width, 1.2, 4.5),
            base * CFrame.new(0, 0.6 + tier * 1.5, tier * 3.7),
            Enum.Material.WoodPlanks,
            SIGNATURE.TimberLight
        )
        bench.CanCollide = false
    end
    for tier = 0, 3 do
        makeCollisionProxy(
            model,
            "GrandstandTierCollision" .. tier,
            Vector3.new(width, 1.2, 4.5),
            base * CFrame.new(0, 0.6 + tier * 1.5, tier * 3.7)
        )
    end
    for _, x in { -width * 0.46, width * 0.46 } do
        local support = makePart(
            model,
            "StandSupport",
            Vector3.new(0.8, 7.2, 0.8),
            base * CFrame.new(x, 3.6, 5.2),
            Enum.Material.Wood,
            SIGNATURE.Timber
        )
        support.CanCollide = false
    end
    return model
end

local function makeFivePathMonument(parent, position)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = "FivePathMonument"
    model.Parent = parent
    local colors = {
        Color3.fromRGB(121, 244, 183),
        Color3.fromRGB(230, 170, 82),
        Color3.fromRGB(99, 236, 209),
        Color3.fromRGB(187, 145, 229),
        Color3.fromRGB(241, 187, 82),
    }
    makePart(
        model,
        "MonumentDais",
        Vector3.new(26, 1.2, 26),
        CFrame.new(ground + Vector3.new(0, 0.6, 0)),
        Enum.Material.Slate,
        SIGNATURE.SlateDark
    )
    for index = 1, 5 do
        local angle = math.rad(-90 + (index - 1) * 72)
        local offset = Vector3.new(math.cos(angle) * 8.2, 0, math.sin(angle) * 8.2)
        local base = CFrame.new(ground + offset)
        makeSignatureCrystal(model, "PathCrystal" .. index, base, 8.5, colors[index])
    end
    makeSignatureCrystal(model, "ConvergenceCrystal", CFrame.new(ground), 12.0, SIGNATURE.Lumen)
    makeCollisionProxy(
        model,
        "MonumentDaisCollision",
        Vector3.new(26, 1.3, 26),
        CFrame.new(ground + Vector3.new(0, 0.65, 0))
    )
    return model
end

local function makeSignatureWorldContent(parent)
    local camp = ZONES.Camp

    -- Wayfarer Camp: a bespoke settlement core, not a row of generic houses.
    makeLumenWell(parent, "WayfarerLumenWell", camp + Vector3.new(-4, 0, -19), SIGNATURE.Lumen)
    makeForgeYard(parent, "WayfarerForgeYard", camp + Vector3.new(38, 0, 84), math.rad(178))
    makeTrainingGround(
        parent,
        "WayfarerTrainingGround",
        TRAINING_ORIGIN + Vector3.new(2, 0, 5),
        math.rad(90)
    )
    makeWayfarerStreetArch(
        parent,
        "WayfarerArrivalArch",
        camp + Vector3.new(-116, 0, 12),
        math.rad(90),
        26
    )
    makeWayfarerStreetArch(
        parent,
        "WayfarerGreenwayArch",
        camp + Vector3.new(126, 0, 12),
        math.rad(90),
        28
    )
    makeWayfarerStreetArch(parent, "WayfarerProvingArch", camp + Vector3.new(4, 0, -120), 0, 22)
    makeWayfarerCart(
        parent,
        "QuartermasterWagon",
        camp + Vector3.new(-88, 0, 54),
        math.rad(112),
        true
    )
    makeWayfarerCart(parent, "CraftsmanWagon", camp + Vector3.new(75, 0, 76), math.rad(-156), true)
    makeWayfarerCart(parent, "TravelerWagon", camp + Vector3.new(-72, 0, -72), math.rad(35), false)
    for index, spec in
        {
            { Vector3.new(-90, 0, -8), math.rad(88), SIGNATURE.Cloth },
            { Vector3.new(88, 0, -8), math.rad(-88), SIGNATURE.ClothGold },
            { Vector3.new(-34, 0, 67), math.rad(180), Color3.fromRGB(98, 86, 137) },
            { Vector3.new(36, 0, 67), math.rad(180), Color3.fromRGB(120, 79, 58) },
        }
    do
        makeWayfarerBanner(parent, "WayfarerTownBanner" .. index, camp + spec[1], spec[2], spec[3])
    end

    -- Greenway: road culture and farming infrastructure.
    makeWayfarerStreetArch(
        parent,
        "GreenwayOldMileArch",
        ZONES.Greenway + Vector3.new(-118, 0, 22),
        math.rad(78),
        20
    )
    makeWayfarerCart(
        parent,
        "GreenwayProduceCart",
        ZONES.Greenway + Vector3.new(-82, 0, -44),
        math.rad(56),
        true
    )
    makeTrainingGround(
        parent,
        "GreenwayMilitiaYard",
        ZONES.Greenway + Vector3.new(88, 0, 48),
        math.rad(-32)
    )
    makeWayfarerBanner(
        parent,
        "GreenwayBanner",
        ZONES.Greenway + Vector3.new(-18, 0, -88),
        math.rad(5),
        Color3.fromRGB(87, 123, 74)
    )

    -- Crossroads: recognizable travel hub visible from all branches.
    makeWayfarerStreetArch(
        parent,
        "CrossroadsNorthArch",
        ZONES.Crossroads + Vector3.new(6, 0, 84),
        math.rad(180),
        20
    )
    makeWayfarerStreetArch(
        parent,
        "CrossroadsEastArch",
        ZONES.Crossroads + Vector3.new(92, 0, 4),
        math.rad(90),
        20
    )
    makeWayfarerCart(
        parent,
        "CrossroadsCourierCart",
        ZONES.Crossroads + Vector3.new(56, 0, -54),
        math.rad(-128),
        true
    )
    makeLumenWell(
        parent,
        "CrossroadsTravelWell",
        ZONES.Crossroads + Vector3.new(-24, 0, -48),
        SIGNATURE.Lumen
    )

    -- Glowmere: a bespoke stilt hamlet and working dock line.
    makeGlowmereStiltHouse(
        parent,
        "GlowmereStiltHouseA",
        ZONES.Glowmere + Vector3.new(-126, 0, -34),
        math.rad(32),
        Color3.fromRGB(102, 230, 216)
    )
    makeGlowmereStiltHouse(
        parent,
        "GlowmereStiltHouseB",
        ZONES.Glowmere + Vector3.new(118, 0, 10),
        math.rad(-52),
        Color3.fromRGB(102, 230, 216)
    )
    makeGlowmereStiltHouse(
        parent,
        "GlowmereStiltHouseC",
        ZONES.Glowmere + Vector3.new(70, 0, 104),
        math.rad(-138),
        Color3.fromRGB(102, 230, 216)
    )
    makeReedDock(
        parent,
        "GlowmereWestDock",
        ZONES.Glowmere + Vector3.new(-108, 0, 32),
        math.rad(18),
        28
    )
    makeReedDock(
        parent,
        "GlowmereEastDock",
        ZONES.Glowmere + Vector3.new(98, 0, 48),
        math.rad(-32),
        24
    )
    makeWayfarerBanner(
        parent,
        "GlowmereKeeperBanner",
        ZONES.Glowmere + Vector3.new(-82, 0, -72),
        math.rad(28),
        Color3.fromRGB(70, 118, 110)
    )

    -- Eastbridge: real defended frontier crossing.
    makeWayfarerStreetArch(
        parent,
        "EastbridgeInnerArch",
        ZONES.EastLanding + Vector3.new(-92, 0, 4),
        math.rad(90),
        22,
        Color3.fromRGB(121, 224, 173)
    )
    makeForgeYard(
        parent,
        "EastbridgeFieldForge",
        ZONES.EastLanding + Vector3.new(72, 0, 34),
        math.rad(-90)
    )
    makeWayfarerCart(
        parent,
        "EastbridgeSupplyWagon",
        ZONES.EastLanding + Vector3.new(40, 0, 58),
        math.rad(-128),
        true
    )
    makeTrainingGround(
        parent,
        "EastbridgeGuardDrill",
        ZONES.EastLanding + Vector3.new(-16, 0, -62),
        math.rad(180)
    )

    -- Gravebone: dense cemetery architecture rather than an open brown field.
    makeGraveboneMausoleum(
        parent,
        "GraveboneMausoleumA",
        ZONES.Gravebone + Vector3.new(-105, 0, 36),
        math.rad(72)
    )
    makeGraveboneMausoleum(
        parent,
        "GraveboneMausoleumB",
        ZONES.Gravebone + Vector3.new(102, 0, 34),
        math.rad(-68)
    )
    makeGraveboneMausoleum(
        parent,
        "GraveboneMausoleumC",
        ZONES.Gravebone + Vector3.new(15, 0, -112),
        math.rad(4)
    )
    makeWayfarerStreetArch(
        parent,
        "GraveboneFuneraryArch",
        ZONES.Gravebone + Vector3.new(-5, 0, 104),
        math.rad(180),
        24,
        Color3.fromRGB(128, 190, 167)
    )
    makeWayfarerCart(
        parent,
        "GraveboneAbandonedCart",
        ZONES.Gravebone + Vector3.new(88, 0, 92),
        math.rad(-54),
        false
    )

    -- Mossglen: dedicated ranger settlement and field infrastructure.
    makeMossglenRangerHall(
        parent,
        "MossglenRangerHall",
        ZONES.Mossglen + Vector3.new(-136, 0, -74),
        math.rad(40)
    )
    makeTrainingGround(
        parent,
        "MossglenRangerRange",
        ZONES.Mossglen + Vector3.new(142, 0, -18),
        math.rad(-90)
    )
    makeWayfarerStreetArch(
        parent,
        "MossglenEnclaveArch",
        ZONES.Mossglen + Vector3.new(-74, 0, -122),
        math.rad(25),
        22,
        Color3.fromRGB(116, 220, 146)
    )
    makeWayfarerCart(
        parent,
        "MossglenGameCart",
        ZONES.Mossglen + Vector3.new(-104, 0, -36),
        math.rad(48),
        true
    )

    -- Sunmoss: a visible vertical landmark, not another tree ring.
    makeSunmossObservatory(
        parent,
        "SunmossLumenObservatory",
        ZONES.Sunmoss + Vector3.new(-10, 0, 86),
        math.rad(16)
    )
    makeWayfarerStreetArch(
        parent,
        "SunmossAscendingArch",
        ZONES.Sunmoss + Vector3.new(-88, 0, -54),
        math.rad(40),
        20,
        Color3.fromRGB(207, 225, 112)
    )
    makeWayfarerBanner(
        parent,
        "SunmossResearchBanner",
        ZONES.Sunmoss + Vector3.new(72, 0, -48),
        math.rad(-72),
        Color3.fromRGB(141, 132, 69)
    )

    -- Veilfall: bespoke sanctuary skyline around the ravine refuge.
    makeVeilfallSanctuary(
        parent,
        "VeilfallSanctuary",
        ZONES.Veilfall + Vector3.new(86, 0, 12),
        math.rad(-24)
    )
    makeWayfarerStreetArch(
        parent,
        "VeilfallRefugeArch",
        ZONES.Veilfall + Vector3.new(-88, 0, -46),
        math.rad(52),
        20,
        Color3.fromRGB(114, 222, 226)
    )
    makeWayfarerBanner(
        parent,
        "VeilfallRefugeBanner",
        ZONES.Veilfall + Vector3.new(-70, 0, 36),
        math.rad(48),
        Color3.fromRGB(69, 105, 104)
    )

    -- Shattered Arch: a regional fortress silhouette visible before the portal.
    makeShatteredFortressTower(
        parent,
        "ShatteredNorthTower",
        ZONES.Ruins + Vector3.new(-148, 0, 102),
        math.rad(8),
        true
    )
    makeShatteredFortressTower(
        parent,
        "ShatteredSouthTower",
        ZONES.Ruins + Vector3.new(-146, 0, -106),
        math.rad(-8),
        true
    )
    makeShatteredFortressTower(
        parent,
        "ShatteredInnerTower",
        ZONES.Ruins + Vector3.new(92, 0, 105),
        math.rad(12),
        false
    )
    makeWayfarerStreetArch(
        parent,
        "ShatteredProcessionalArch",
        ZONES.Ruins + Vector3.new(-188, 0, -2),
        math.rad(90),
        30,
        Color3.fromRGB(95, 231, 194)
    )
    makeWayfarerBanner(
        parent,
        "ShatteredWarBannerA",
        ZONES.Ruins + Vector3.new(-102, 0, 58),
        math.rad(90),
        Color3.fromRGB(63, 86, 76)
    )
    makeWayfarerBanner(
        parent,
        "ShatteredWarBannerB",
        ZONES.Ruins + Vector3.new(-102, 0, -58),
        math.rad(90),
        Color3.fromRGB(63, 86, 76)
    )

    -- Proving Circle: full advancement venue with monument, stands and entrance.
    makeFivePathMonument(parent, ZONES.Proving)
    makeProvingGrandstand(
        parent,
        "ProvingNorthStand",
        ZONES.Proving + Vector3.new(0, 0, 58),
        math.rad(180),
        34
    )
    makeProvingGrandstand(
        parent,
        "ProvingWestStand",
        ZONES.Proving + Vector3.new(-58, 0, -2),
        math.rad(90),
        28
    )
    makeProvingGrandstand(
        parent,
        "ProvingEastStand",
        ZONES.Proving + Vector3.new(58, 0, -2),
        math.rad(-90),
        28
    )
    makeWayfarerStreetArch(
        parent,
        "ProvingGrandEntrance",
        ZONES.Proving + Vector3.new(0, 0, -88),
        0,
        28
    )
    for index, spec in
        {
            { Vector3.new(-44, 0, -58), math.rad(20), Color3.fromRGB(121, 244, 183) },
            { Vector3.new(-22, 0, -68), math.rad(10), Color3.fromRGB(230, 170, 82) },
            { Vector3.new(0, 0, -72), 0, Color3.fromRGB(99, 236, 209) },
            { Vector3.new(22, 0, -68), math.rad(-10), Color3.fromRGB(187, 145, 229) },
            { Vector3.new(44, 0, -58), math.rad(-20), Color3.fromRGB(241, 187, 82) },
        }
    do
        makeWayfarerBanner(
            parent,
            "ProvingPathBanner" .. index,
            ZONES.Proving + spec[1],
            spec[2],
            spec[3]
        )
    end

    -- Route-side authored landmarks. Each one has a named purpose/silhouette;
    -- none are random Marketplace prop dumps.
    makeWayfarerCart(parent, "GreenwayBrokenCourier", Vector3.new(-610, 0, 82), math.rad(64), false)
    makeStoneShrine(
        parent,
        "CrossroadsPilgrimShrine",
        Vector3.new(-380, 0, 142),
        math.rad(-22),
        SIGNATURE.Lumen
    )
    makeWayfarerStreetArch(
        parent,
        "EastbridgeTollArch",
        Vector3.new(-330, 0, 118),
        math.rad(90),
        18
    )
    makeReedDock(parent, "ReedbridgeFerryLanding", Vector3.new(-325, 0, 392), math.rad(18), 18)
    makeWayfarerCart(parent, "MossglenHunterLayby", Vector3.new(22, 0, 205), math.rad(42), true)
    makeStoneShrine(
        parent,
        "SunmossPilgrimMarker",
        Vector3.new(352, 0, 370),
        math.rad(-20),
        Color3.fromRGB(207, 225, 112)
    )
    makeWayfarerStreetArch(
        parent,
        "VeilfallDescentArch",
        Vector3.new(262, 0, -298),
        math.rad(56),
        18,
        Color3.fromRGB(114, 222, 226)
    )
    makeGraveboneMausoleum(parent, "OldRoadMemorial", Vector3.new(698, 0, -120), math.rad(-18))
    makeRoadsideShelter(
        parent,
        "ProvingRoadAspirantShelter",
        Vector3.new(-947, 0, -232),
        math.rad(6)
    )
    makeWayfarerBanner(
        parent,
        "ProvingRoadStandard",
        Vector3.new(-932, 0, -266),
        math.rad(175),
        SIGNATURE.Cloth
    )
    makeWayfarerCart(parent, "EastbridgePatrolCart", Vector3.new(-180, 0, 68), math.rad(-72), true)
    makeStoneShrine(
        parent,
        "GraveboneRoadMemorial",
        Vector3.new(42, 0, -108),
        math.rad(24),
        Color3.fromRGB(133, 195, 169)
    )
    makeWayfarerStreetArch(
        parent,
        "GraveboneRoadBrokenArch",
        Vector3.new(176, 0, -244),
        math.rad(72),
        17,
        Color3.fromRGB(127, 186, 161)
    )
    makeRoadsideShelter(parent, "MossglenRoadRest", Vector3.new(-4, 0, 174), math.rad(18))
    makeWayfarerBanner(
        parent,
        "MossglenRoadRangerStandard",
        Vector3.new(70, 0, 246),
        math.rad(-25),
        Color3.fromRGB(77, 119, 74)
    )
    makeWayfarerCart(
        parent,
        "BrambleGathererCart",
        BRAMBLE_ORIGIN + Vector3.new(-20, 0, 26),
        math.rad(55),
        true
    )
    makeStoneShrine(
        parent,
        "SunmossAscentShrine",
        Vector3.new(444, 0, 414),
        math.rad(-38),
        Color3.fromRGB(207, 225, 112)
    )
    makeRoadsideShelter(parent, "RuinsRoadPatrolShelter", Vector3.new(510, 0, 185), math.rad(-82))
    makeWayfarerStreetArch(
        parent,
        "RuinsRoadFallenGate",
        Vector3.new(735, 0, 112),
        math.rad(82),
        21,
        Color3.fromRGB(95, 205, 173)
    )
    makeShatteredFortressTower(
        parent,
        "RuinsReturnWatchtower",
        Vector3.new(748, 0, 260),
        math.rad(-18),
        true
    )
    makeStoneShrine(
        parent,
        "VeilfallReturnShrine",
        Vector3.new(690, 0, -184),
        math.rad(30),
        Color3.fromRGB(114, 222, 226)
    )
end

local function districtPoint(center, yaw, offset)
    return center + CFrame.Angles(0, yaw or 0, 0):VectorToWorldSpace(offset)
end

local function makeCroftPlot(parent, name, position, yaw, width, depth, accent)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    width = width or 30
    depth = depth or 24
    accent = accent or Color3.fromRGB(113, 126, 75)

    local soil = makePart(
        model,
        "CroftSoil",
        Vector3.new(width, 0.35, depth),
        base * CFrame.new(0, 0.18, 0),
        Enum.Material.Ground,
        Color3.fromRGB(74, 62, 44)
    )
    soil.CanCollide = false
    soil.CanTouch = false
    soil.CanQuery = false

    for row = -3, 3 do
        local strip = makePart(
            model,
            "CropRow",
            Vector3.new(1.15, 0.45, depth - 3),
            base * CFrame.new(row * (width / 8.5), 0.48, 0),
            Enum.Material.LeafyGrass,
            accent
        )
        strip.CanCollide = false
        strip.CanTouch = false
        strip.CanQuery = false
    end

    local fenceInset = 1.4
    makeFenceLine(
        model,
        "CroftFenceNorth",
        districtPoint(position, yaw, Vector3.new(-width * 0.5 + fenceInset, 0, depth * 0.5)),
        districtPoint(position, yaw, Vector3.new(width * 0.5 - fenceInset, 0, depth * 0.5)),
        7,
        3.2
    )
    makeFenceLine(
        model,
        "CroftFenceWest",
        districtPoint(position, yaw, Vector3.new(-width * 0.5, 0, -depth * 0.5)),
        districtPoint(position, yaw, Vector3.new(-width * 0.5, 0, depth * 0.5)),
        7,
        3.2
    )
    makeFenceLine(
        model,
        "CroftFenceEast",
        districtPoint(position, yaw, Vector3.new(width * 0.5, 0, -depth * 0.5)),
        districtPoint(position, yaw, Vector3.new(width * 0.5, 0, depth * 0.5)),
        7,
        3.2
    )

    local scarecrow = makePart(
        model,
        "CroftScarecrowPost",
        Vector3.new(0.6, 6.5, 0.6),
        base * CFrame.new(width * 0.31, 3.25, -depth * 0.24),
        Enum.Material.Wood,
        SIGNATURE.Timber
    )
    scarecrow.CanCollide = false
    local arms = makePart(
        model,
        "CroftScarecrowArms",
        Vector3.new(5.5, 0.55, 0.55),
        base * CFrame.new(width * 0.31, 4.8, -depth * 0.24),
        Enum.Material.Wood,
        SIGNATURE.Timber
    )
    arms.CanCollide = false
    makeCollisionProxy(
        model,
        "ScarecrowCollision",
        Vector3.new(0.9, 6.5, 0.9),
        base * CFrame.new(width * 0.31, 3.25, -depth * 0.24)
    )
    return model
end

local function placeArchitectureBuilding(
    parent,
    name,
    prefabName,
    position,
    yaw,
    targetLongest,
    collisionSpecs
)
    return placeArchitecturePrefabBuilding(
        parent,
        name,
        prefabName,
        position,
        yaw,
        targetLongest,
        collisionSpecs
    )
end

local function makeWayfarerCivicHall(parent, name, position, yaw)
    return placeArchitectureBuilding(parent, name, "LumenCivicHall", position, yaw, 48, {
        { Size = Vector3.new(31, 12, 21), Offset = Vector3.new(0, 6, 0) },
        { Size = Vector3.new(8, 15, 7), Offset = Vector3.new(0, 7.5, -14) },
        { Size = Vector3.new(7, 8, 10), Offset = Vector3.new(18, 4, 3) },
    })
end

local function makeQuartermasterDepot(parent, name, position, yaw)
    return placeArchitectureBuilding(parent, name, "LumenQuartermasterDepot", position, yaw, 42, {
        { Size = Vector3.new(27, 10, 19), Offset = Vector3.new(0, 5, 0) },
        { Size = Vector3.new(7, 7, 13), Offset = Vector3.new(17, 3.5, 1) },
    })
end

local function makeArchiveResearchLodge(parent, name, position, yaw)
    return placeArchitectureBuilding(parent, name, "LumenArchiveLodge", position, yaw, 42, {
        { Size = Vector3.new(25, 10, 18), Offset = Vector3.new(0, 5, 0) },
        { Size = Vector3.new(9, 12, 9), Offset = Vector3.new(15, 6, 3) },
    })
end

local function makeWayfarerInn(parent, name, position, yaw)
    return placeArchitectureBuilding(parent, name, "LumenWayfarerInn", position, yaw, 50, {
        { Size = Vector3.new(30, 10, 19), Offset = Vector3.new(0, 5, 0) },
        { Size = Vector3.new(10, 9, 15), Offset = Vector3.new(18, 4.5, 5) },
    })
end

local function makeHealerApothecary(parent, name, position, yaw)
    return placeArchitectureBuilding(parent, name, "LumenHealerLodge", position, yaw, 38, {
        { Size = Vector3.new(22, 9, 15), Offset = Vector3.new(0, 4.5, 0) },
    })
end

local function makeCraftWorkshop(parent, name, position, yaw)
    return placeArchitectureBuilding(parent, name, "LumenCraftWorkshop", position, yaw, 42, {
        { Size = Vector3.new(29, 9, 5), Offset = Vector3.new(0, 4.5, 8) },
        { Size = Vector3.new(4, 9, 13), Offset = Vector3.new(-13, 4.5, 2) },
        { Size = Vector3.new(11, 3, 4), Offset = Vector3.new(5, 1.5, 3) },
    })
end

local function makeOpenStable(parent, name, position, yaw)
    return placeArchitectureBuilding(parent, name, "LumenOpenStable", position, yaw, 44, {
        { Size = Vector3.new(30, 8, 4), Offset = Vector3.new(0, 4, 8) },
        { Size = Vector3.new(7, 7, 9), Offset = Vector3.new(18, 3.5, 3) },
    })
end

local function makeProvingLodge(parent, name, position, yaw)
    return placeArchitectureBuilding(parent, name, "LumenProvingLodge", position, yaw, 42, {
        { Size = Vector3.new(28, 9, 16), Offset = Vector3.new(0, 4.5, 0) },
    })
end

local function makeRoadWayhouse(parent, name, position, yaw, _accent)
    return placeArchitecturePrefabBuilding(parent, name, "LumenRoadWayhouse", position, yaw, 34, {
        { Size = Vector3.new(14, 8, 13), Offset = Vector3.new(-5, 4, 1) },
        { Size = Vector3.new(2, 7, 2), Offset = Vector3.new(4, 3.5, -5) },
        { Size = Vector3.new(2, 7, 2), Offset = Vector3.new(14, 3.5, -5) },
    })
end

local function makeFarmBarn(parent, name, position, yaw, _accent)
    return placeArchitecturePrefabBuilding(parent, name, "LumenFarmBarn", position, yaw, 42, {
        { Size = Vector3.new(27, 11, 19), Offset = Vector3.new(0, 5.5, 0) },
        { Size = Vector3.new(8, 7, 13), Offset = Vector3.new(18, 3.5, 2) },
    })
end

local function makeCroftCottage(parent, name, position, yaw, _accent, mirror)
    local prefabName = if mirror == true then "LumenCroftCottageB" else "LumenCroftCottageA"
    return placeArchitecturePrefabBuilding(parent, name, prefabName, position, yaw, 34, {
        { Size = Vector3.new(21, 10, 16), Offset = Vector3.new(0, 5, 0) },
        {
            Size = Vector3.new(7, 7, 10),
            Offset = Vector3.new(if mirror == true then -13 else 13, 3.5, 1),
        },
    })
end

local function makeOccupiedHamlet(parent, name, center, yaw, accent, cropAccent)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    accent = accent or Color3.fromRGB(96, 112, 88)
    cropAccent = cropAccent or Color3.fromRGB(113, 126, 75)

    local plaza = terrainSurfacePosition(center, 0)
    Workspace.Terrain:FillBlock(
        CFrame.new(plaza + Vector3.new(0, -0.45, 0)) * CFrame.Angles(0, yaw or 0, 0),
        Vector3.new(78, 1.2, 62),
        Enum.Material.Ground
    )

    makeCroftCottage(
        model,
        name .. "Cottage1",
        districtPoint(center, yaw, Vector3.new(-27, 0, -20)),
        (yaw or 0) + math.rad(20),
        accent,
        false
    )
    makeCroftCottage(
        model,
        name .. "Cottage2",
        districtPoint(center, yaw, Vector3.new(25, 0, -21)),
        (yaw or 0) + math.rad(-18),
        accent:Lerp(Color3.fromRGB(145, 111, 73), 0.18),
        true
    )
    makeFarmBarn(
        model,
        name .. "Barn",
        districtPoint(center, yaw, Vector3.new(-28, 0, 21)),
        (yaw or 0) + math.rad(158),
        accent:Lerp(Color3.fromRGB(132, 101, 67), 0.32)
    )
    makeRoadWayhouse(
        model,
        name .. "Wayhouse",
        districtPoint(center, yaw, Vector3.new(26, 0, 22)),
        (yaw or 0) + math.rad(-160),
        accent
    )

    makeLumenWell(
        model,
        name .. "Well",
        districtPoint(center, yaw, Vector3.new(0, 0, 0)),
        SIGNATURE.Lumen
    )
    makeHearth(model, districtPoint(center, yaw, Vector3.new(0, 0, 22)))
    makeMarketStall(
        model,
        districtPoint(center, yaw, Vector3.new(2, 0, -30)),
        (yaw or 0) + math.rad(180),
        accent:Lerp(SIGNATURE.ClothGold, 0.18)
    )
    makeSupplyStack(model, districtPoint(center, yaw, Vector3.new(39, 0, 7)), yaw or 0, 0.85)
    makeWayfarerCart(
        model,
        name .. "Wagon",
        districtPoint(center, yaw, Vector3.new(-41, 0, 4)),
        (yaw or 0) + math.rad(90),
        true
    )
    makeCroftPlot(
        model,
        name .. "CroftA",
        districtPoint(center, yaw, Vector3.new(-52, 0, -28)),
        yaw or 0,
        28,
        22,
        cropAccent
    )
    makeCroftPlot(
        model,
        name .. "CroftB",
        districtPoint(center, yaw, Vector3.new(52, 0, 28)),
        yaw or 0,
        28,
        22,
        cropAccent:Lerp(Color3.fromRGB(164, 141, 71), 0.18)
    )
    makeWayfarerStreetArch(
        model,
        name .. "EntryArch",
        districtPoint(center, yaw, Vector3.new(0, 0, -47)),
        yaw or 0,
        18,
        SIGNATURE.Lumen
    )
    return model
end

local function makePatrolPost(parent, name, center, yaw, accent)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    accent = accent or Color3.fromRGB(79, 105, 84)

    Workspace.Terrain:FillBlock(
        CFrame.new(terrainSurfacePosition(center, -0.35)) * CFrame.Angles(0, yaw or 0, 0),
        Vector3.new(66, 1.0, 48),
        Enum.Material.Ground
    )
    makeProvingLodge(
        model,
        name .. "Guardhouse",
        districtPoint(center, yaw, Vector3.new(-20, 0, 4)),
        (yaw or 0) + math.rad(12)
    )
    makeQuartermasterDepot(
        model,
        name .. "Storehouse",
        districtPoint(center, yaw, Vector3.new(20, 0, 8)),
        (yaw or 0) - math.rad(15)
    )
    makeWatchtower(model, districtPoint(center, yaw, Vector3.new(-27, 0, -25)), yaw or 0)
    makeRoadsideShelter(
        model,
        name .. "Shelter",
        districtPoint(center, yaw, Vector3.new(26, 0, -23)),
        (yaw or 0) + math.rad(180)
    )
    makeHearth(model, districtPoint(center, yaw, Vector3.new(2, 0, 17)))
    makeSupplyStack(model, districtPoint(center, yaw, Vector3.new(30, 0, 22)), yaw or 0, 0.8)
    makeWayfarerCart(
        model,
        name .. "PatrolWagon",
        districtPoint(center, yaw, Vector3.new(-5, 0, -31)),
        yaw or 0,
        true
    )
    makeWayfarerStreetArch(
        model,
        name .. "Gate",
        districtPoint(center, yaw, Vector3.new(0, 0, -40)),
        yaw or 0,
        17,
        SIGNATURE.Lumen
    )
    return model
end

local function makeRuinedDistrict(parent, name, center, yaw)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local rotation = yaw or 0

    Workspace.Terrain:FillBlock(
        CFrame.new(terrainSurfacePosition(center, -0.3)) * CFrame.Angles(0, rotation, 0),
        Vector3.new(78, 1.0, 62),
        Enum.Material.Ground
    )
    makeRuinedHall(
        model,
        name .. "HallA",
        districtPoint(center, rotation, Vector3.new(-24, 0, -12)),
        30,
        22,
        rotation + math.rad(8)
    )
    makeRuinedHall(
        model,
        name .. "HallB",
        districtPoint(center, rotation, Vector3.new(23, 0, 15)),
        27,
        20,
        rotation - math.rad(14)
    )
    makeRuinWall(model, districtPoint(center, rotation, Vector3.new(0, 0, -35)), rotation, 55, 7)
    makeRuinWall(
        model,
        districtPoint(center, rotation, Vector3.new(-38, 0, 8)),
        rotation + math.rad(90),
        40,
        6
    )
    makeStoneShrine(
        model,
        name .. "BrokenShrine",
        districtPoint(center, rotation, Vector3.new(34, 0, -22)),
        rotation - math.rad(18),
        Color3.fromRGB(118, 194, 169)
    )
    makeGraveboneMausoleum(
        model,
        name .. "Crypt",
        districtPoint(center, rotation, Vector3.new(-5, 0, 37)),
        rotation + math.rad(180)
    )
    makeWayfarerCart(
        model,
        name .. "AbandonedCart",
        districtPoint(center, rotation, Vector3.new(39, 0, 27)),
        rotation + math.rad(60),
        false
    )
    return model
end

local function makeDistrictResident(parent, name, position, yaw, role, cloth, hairStyle)
    local palette = {
        Cloth = cloth,
        DarkCloth = cloth:Lerp(Color3.new(0, 0, 0), 0.24),
        Accent = cloth:Lerp(Color3.fromRGB(117, 235, 192), 0.32),
        Skin = Color3.fromRGB(211, 176, 143),
        Leather = Color3.fromRGB(84, 58, 39),
        Hair = Color3.fromRGB(78, 52, 39),
        EyeColor = Color3.fromRGB(58, 88, 68),
        Lumen = Color3.fromRGB(111, 234, 185),
        Metal = Color3.fromRGB(158, 128, 69),
    }
    local model = StylizedNpcFactory.Create(parent, {
        Name = name,
        Position = terrainSurfacePosition(position, 0),
        Yaw = yaw or 0,
        Role = role or "Scout",
        HairStyle = hairStyle or "short",
        Build = 0.96,
        HeightScale = 1.0,
        HeadScale = 0.96,
        BodyTypeScale = 0.32,
        ProportionScale = 0.32,
        Palette = palette,
    })
    if model then
        model:SetAttribute("AmbientResident", true)
        model:SetAttribute("DistrictResident", true)
        model:SetAttribute("DisplayRole", name)
    end
    return model
end

local function makeLumenreachDistrictNetwork(parent)
    -- This is the population pass the region was missing: occupied places are
    -- deliberately placed between the headline zones so walking the map never
    -- becomes hundreds of studs of grass/road/trees with nothing to do or see.
    local districts = {
        {
            Kind = "hamlet",
            Name = "WayfarerLowerWard",
            Center = Vector3.new(-875, 0, -145),
            Yaw = math.rad(8),
            Accent = Color3.fromRGB(92, 113, 91),
            Crop = Color3.fromRGB(120, 136, 76),
            Connector = ZONES.Camp + Vector3.new(18, 0, -104),
        },
        {
            Kind = "hamlet",
            Name = "GreenwayCrofts",
            Center = Vector3.new(-785, 0, -102),
            Yaw = math.rad(18),
            Accent = Color3.fromRGB(104, 119, 82),
            Crop = Color3.fromRGB(132, 146, 74),
            Connector = ZONES.Greenway + Vector3.new(-45, 0, -40),
        },
        {
            Kind = "patrol",
            Name = "OldMileWatch",
            Center = Vector3.new(-620, 0, 145),
            Yaw = math.rad(72),
            Accent = Color3.fromRGB(75, 101, 78),
            Connector = Vector3.new(-610, 3, 52),
        },
        {
            Kind = "hamlet",
            Name = "GlowmereDrybank",
            Center = Vector3.new(-535, 0, 350),
            Yaw = math.rad(26),
            Accent = Color3.fromRGB(75, 112, 103),
            Crop = Color3.fromRGB(102, 138, 105),
            Connector = Vector3.new(-470, 0, 300),
        },
        {
            Kind = "patrol",
            Name = "EastbridgeWestWard",
            Center = Vector3.new(-350, 0, 28),
            Yaw = math.rad(88),
            Accent = Color3.fromRGB(78, 103, 82),
            Connector = Vector3.new(-395, 4, 75),
        },
        {
            Kind = "hamlet",
            Name = "EastbridgeSouthWard",
            Center = Vector3.new(-80, 0, 178),
            Yaw = math.rad(-25),
            Accent = Color3.fromRGB(86, 111, 88),
            Crop = Color3.fromRGB(117, 132, 74),
            Connector = Vector3.new(-30, 6, 185),
        },
        {
            Kind = "ruin",
            Name = "GraveboneOuterWard",
            Center = Vector3.new(18, 0, -168),
            Yaw = math.rad(22),
            Connector = Vector3.new(58, 6, -90),
        },
        {
            Kind = "hamlet",
            Name = "MossglenTrailhead",
            Center = Vector3.new(-35, 0, 330),
            Yaw = math.rad(-18),
            Accent = Color3.fromRGB(76, 108, 76),
            Crop = Color3.fromRGB(105, 139, 72),
            Connector = Vector3.new(40, 6, 255),
        },
        {
            Kind = "patrol",
            Name = "MossglenWoodcamp",
            Center = Vector3.new(235, 0, 242),
            Yaw = math.rad(-65),
            Accent = Color3.fromRGB(77, 104, 75),
            Connector = Vector3.new(350, 7, 200),
        },
        {
            Kind = "hamlet",
            Name = "SunmossAscentCamp",
            Center = Vector3.new(345, 0, 455),
            Yaw = math.rad(-30),
            Accent = Color3.fromRGB(111, 115, 76),
            Crop = Color3.fromRGB(154, 144, 74),
            Connector = Vector3.new(385, 26, 395),
        },
        {
            Kind = "patrol",
            Name = "VeilfallUpperRefuge",
            Center = Vector3.new(300, 0, -245),
            Yaw = math.rad(45),
            Accent = Color3.fromRGB(72, 106, 104),
            Connector = Vector3.new(320, -8, -330),
        },
        {
            Kind = "patrol",
            Name = "ShatteredForwardCamp",
            Center = Vector3.new(555, 0, 220),
            Yaw = math.rad(-82),
            Accent = Color3.fromRGB(72, 96, 80),
            Connector = Vector3.new(540, 8, 150),
        },
        {
            Kind = "ruin",
            Name = "ShatteredBarracksRuins",
            Center = Vector3.new(748, 0, 10),
            Yaw = math.rad(82),
            Connector = Vector3.new(720, 9, 100),
        },
        {
            Kind = "hamlet",
            Name = "ProvingAspirantWard",
            Center = Vector3.new(-845, 0, -360),
            Yaw = math.rad(10),
            Accent = Color3.fromRGB(85, 104, 90),
            Crop = Color3.fromRGB(118, 132, 76),
            Connector = Vector3.new(-940, 4, -270),
        },
    }

    for _, district in districts do
        fillTerrainRoute({ district.Connector, district.Center }, 10, Enum.Material.Ground)
        if district.Kind == "hamlet" then
            makeOccupiedHamlet(
                parent,
                district.Name,
                district.Center,
                district.Yaw,
                district.Accent,
                district.Crop
            )
        elseif district.Kind == "patrol" then
            makePatrolPost(parent, district.Name, district.Center, district.Yaw, district.Accent)
        else
            makeRuinedDistrict(parent, district.Name, district.Center, district.Yaw)
        end
    end

    local residents = {
        {
            "Lower Ward Trader",
            Vector3.new(-890, 0, -135),
            math.rad(35),
            "Quartermaster",
            Color3.fromRGB(103, 82, 60),
            "bun",
        },
        {
            "Lower Ward Guard",
            Vector3.new(-855, 0, -160),
            math.rad(-20),
            "Guard",
            Color3.fromRGB(65, 92, 72),
            "short",
        },
        {
            "Greenway Farmer",
            Vector3.new(-805, 0, -93),
            math.rad(18),
            "Quartermaster",
            Color3.fromRGB(98, 104, 65),
            "short",
        },
        {
            "Greenway Carter",
            Vector3.new(-758, 0, -117),
            math.rad(-35),
            "Scout",
            Color3.fromRGB(84, 94, 69),
            "ponytail",
        },
        {
            "Old Mile Ranger",
            Vector3.new(-628, 0, 138),
            math.rad(70),
            "Guard",
            Color3.fromRGB(62, 91, 70),
            "short",
        },
        {
            "Glowmere Reedworker",
            Vector3.new(-548, 0, 363),
            math.rad(20),
            "Quartermaster",
            Color3.fromRGB(66, 102, 95),
            "bun",
        },
        {
            "Glowmere Ferryman",
            Vector3.new(-510, 0, 340),
            math.rad(-30),
            "Scout",
            Color3.fromRGB(72, 101, 94),
            "short",
        },
        {
            "Westbridge Patrol",
            Vector3.new(-362, 0, 20),
            math.rad(88),
            "Guard",
            Color3.fromRGB(63, 89, 70),
            "short",
        },
        {
            "Eastbridge Settler",
            Vector3.new(-92, 0, 188),
            math.rad(-20),
            "Guide",
            Color3.fromRGB(88, 108, 88),
            "long",
        },
        {
            "Gravebone Survivor",
            Vector3.new(5, 0, -156),
            math.rad(25),
            "Guide",
            Color3.fromRGB(78, 91, 83),
            "long",
        },
        {
            "Mossglen Woodcutter",
            Vector3.new(222, 0, 252),
            math.rad(-60),
            "Quartermaster",
            Color3.fromRGB(82, 93, 61),
            "short",
        },
        {
            "Mossglen Trail Ranger",
            Vector3.new(-48, 0, 340),
            math.rad(10),
            "Scout",
            Color3.fromRGB(64, 96, 69),
            "ponytail",
        },
        {
            "Sunmoss Pilgrim",
            Vector3.new(330, 0, 462),
            math.rad(-20),
            "Archivist",
            Color3.fromRGB(110, 109, 72),
            "bun",
        },
        {
            "Veilfall Sentry",
            Vector3.new(286, 0, -238),
            math.rad(45),
            "Guard",
            Color3.fromRGB(61, 91, 89),
            "short",
        },
        {
            "Forward Camp Scout",
            Vector3.new(544, 0, 230),
            math.rad(-80),
            "Scout",
            Color3.fromRGB(62, 89, 72),
            "ponytail",
        },
        {
            "Proving Aspirant",
            Vector3.new(-860, 0, -350),
            math.rad(15),
            "Scout",
            Color3.fromRGB(78, 96, 79),
            "short",
        },
    }
    for _, resident in residents do
        makeDistrictResident(
            parent,
            resident[1],
            resident[2],
            resident[3],
            resident[4],
            resident[5],
            resident[6]
        )
    end
end

local function makeRoadsideMicroSite(parent, spec)
    local model = Instance.new("Model")
    model.Name = spec.Name
    model.Parent = parent
    local center = spec.Center
    local yaw = spec.Yaw or 0
    local accent = spec.Accent or Color3.fromRGB(82, 104, 80)

    Workspace.Terrain:FillBlock(
        CFrame.new(terrainSurfacePosition(center, -0.28)) * CFrame.Angles(0, yaw, 0),
        Vector3.new(spec.Width or 44, 0.9, spec.Depth or 34),
        Enum.Material.Ground
    )

    if spec.Kind == "croft" then
        makeCroftPlot(model, spec.Name .. "Field", center, yaw, 30, 23, accent)
        makeRoadsideShelter(
            model,
            spec.Name .. "Shelter",
            districtPoint(center, yaw, Vector3.new(-22, 0, 16)),
            yaw + math.rad(20)
        )
        makeWayfarerCart(
            model,
            spec.Name .. "Cart",
            districtPoint(center, yaw, Vector3.new(22, 0, -12)),
            yaw - math.rad(55),
            true
        )
    elseif spec.Kind == "watch" then
        makeWatchtower(model, districtPoint(center, yaw, Vector3.new(-15, 0, 5)), yaw)
        makeRoadsideShelter(
            model,
            spec.Name .. "Shelter",
            districtPoint(center, yaw, Vector3.new(15, 0, 4)),
            yaw + math.rad(180)
        )
        makeSupplyStack(model, districtPoint(center, yaw, Vector3.new(18, 0, -14)), yaw, 0.72)
        makeHearth(model, districtPoint(center, yaw, Vector3.new(0, 0, 14)))
    elseif spec.Kind == "ruin" then
        makeRuinWall(model, center, yaw, 34, 6)
        makeStoneShrine(
            model,
            spec.Name .. "Shrine",
            districtPoint(center, yaw, Vector3.new(15, 0, 13)),
            yaw + math.rad(22),
            accent
        )
        makeWayfarerCart(
            model,
            spec.Name .. "AbandonedCart",
            districtPoint(center, yaw, Vector3.new(-18, 0, -12)),
            yaw + math.rad(62),
            false
        )
    else
        makeRoadWayhouse(
            model,
            spec.Name .. "Wayhouse",
            districtPoint(center, yaw, Vector3.new(-10, 0, 2)),
            yaw + math.rad(8),
            accent
        )
        makeMarketStall(
            model,
            districtPoint(center, yaw, Vector3.new(17, 0, -8)),
            yaw + math.rad(170),
            accent:Lerp(SIGNATURE.ClothGold, 0.16)
        )
        makeLumenWell(
            model,
            spec.Name .. "Well",
            districtPoint(center, yaw, Vector3.new(14, 0, 13)),
            SIGNATURE.Lumen
        )
    end

    makeWaystone(model, districtPoint(center, yaw, Vector3.new(0, 0, -20)), yaw, 0.72)
    return model
end

local function makeWorldMicroSites(parent)
    -- Small authored destinations occupy the gaps between the larger districts.
    -- These are deliberately structures/activities, not another foliage-density pass.
    local sites = {
        {
            Name = "SouthgateCroft",
            Kind = "croft",
            Center = Vector3.new(-1010, 0, -245),
            Yaw = math.rad(18),
            Accent = Color3.fromRGB(117, 132, 75),
        },
        {
            Name = "OldWayShelter",
            Kind = "wayhouse",
            Center = Vector3.new(-760, 0, 175),
            Yaw = math.rad(72),
            Accent = Color3.fromRGB(84, 110, 83),
        },
        {
            Name = "GreenwayNorthCroft",
            Kind = "croft",
            Center = Vector3.new(-665, 0, 270),
            Yaw = math.rad(-18),
            Accent = Color3.fromRGB(122, 139, 76),
        },
        {
            Name = "LumenwoodWatch",
            Kind = "watch",
            Center = Vector3.new(-565, 0, -120),
            Yaw = math.rad(16),
            Accent = Color3.fromRGB(74, 99, 78),
        },
        {
            Name = "CrossroadsSouthStop",
            Kind = "wayhouse",
            Center = Vector3.new(-445, 0, -110),
            Yaw = math.rad(-4),
            Accent = Color3.fromRGB(91, 109, 85),
        },
        {
            Name = "GlowmereReedCamp",
            Kind = "croft",
            Center = Vector3.new(-330, 0, 515),
            Yaw = math.rad(-35),
            Accent = Color3.fromRGB(93, 132, 106),
        },
        {
            Name = "ReedbridgeWatch",
            Kind = "watch",
            Center = Vector3.new(-235, 0, 300),
            Yaw = math.rad(82),
            Accent = Color3.fromRGB(70, 103, 92),
        },
        {
            Name = "EastbridgeNorthPost",
            Kind = "watch",
            Center = Vector3.new(-105, 0, -35),
            Yaw = math.rad(110),
            Accent = Color3.fromRGB(75, 100, 78),
        },
        {
            Name = "GraveboneRoadRuins",
            Kind = "ruin",
            Center = Vector3.new(35, 0, -335),
            Yaw = math.rad(24),
            Accent = Color3.fromRGB(111, 154, 136),
        },
        {
            Name = "GravebonePilgrimStop",
            Kind = "wayhouse",
            Center = Vector3.new(180, 0, -95),
            Yaw = math.rad(-40),
            Accent = Color3.fromRGB(87, 102, 86),
        },
        {
            Name = "MossglenWestCamp",
            Kind = "watch",
            Center = Vector3.new(-10, 0, 455),
            Yaw = math.rad(-16),
            Accent = Color3.fromRGB(69, 102, 72),
        },
        {
            Name = "MossglenCroft",
            Kind = "croft",
            Center = Vector3.new(275, 0, 365),
            Yaw = math.rad(44),
            Accent = Color3.fromRGB(105, 136, 73),
        },
        {
            Name = "BramblewoodStop",
            Kind = "wayhouse",
            Center = Vector3.new(345, 0, 145),
            Yaw = math.rad(65),
            Accent = Color3.fromRGB(77, 104, 75),
        },
        {
            Name = "SunmossLowerWatch",
            Kind = "watch",
            Center = Vector3.new(430, 0, 285),
            Yaw = math.rad(-20),
            Accent = Color3.fromRGB(105, 111, 74),
        },
        {
            Name = "SunmossPilgrimCroft",
            Kind = "croft",
            Center = Vector3.new(610, 0, 515),
            Yaw = math.rad(-62),
            Accent = Color3.fromRGB(151, 145, 75),
        },
        {
            Name = "VeilfallWestRefuge",
            Kind = "wayhouse",
            Center = Vector3.new(250, 0, -455),
            Yaw = math.rad(30),
            Accent = Color3.fromRGB(70, 106, 103),
        },
        {
            Name = "VeilfallRoadWatch",
            Kind = "watch",
            Center = Vector3.new(535, 0, -260),
            Yaw = math.rad(-55),
            Accent = Color3.fromRGB(65, 99, 96),
        },
        {
            Name = "ShatteredRoadStop",
            Kind = "wayhouse",
            Center = Vector3.new(690, 0, 255),
            Yaw = math.rad(-78),
            Accent = Color3.fromRGB(82, 101, 82),
        },
        {
            Name = "ArchSouthRuins",
            Kind = "ruin",
            Center = Vector3.new(820, 0, -155),
            Yaw = math.rad(72),
            Accent = Color3.fromRGB(109, 149, 133),
        },
        {
            Name = "ArchNorthWatch",
            Kind = "watch",
            Center = Vector3.new(870, 0, 230),
            Yaw = math.rad(-72),
            Accent = Color3.fromRGB(73, 98, 80),
        },
    }

    for _, spec in sites do
        makeRoadsideMicroSite(parent, spec)
    end
end

local function makeDistrictCourt(parent, spec)
    local model = Instance.new("Model")
    model.Name = spec.Name .. "MMOCourt"
    model:SetAttribute("MMOComposition", true)
    model.Parent = parent

    local center = spec.Center
    local yaw = spec.Yaw or 0
    local court = terrainSurfacePosition(center, 0)
    local width = spec.Width or 72
    local depth = spec.Depth or 50
    local accent = spec.Accent or SIGNATURE.Lumen

    Workspace.Terrain:FillBlock(
        CFrame.new(court + Vector3.new(0, -0.45, 0)) * CFrame.Angles(0, yaw, 0),
        Vector3.new(width, 1.1, depth),
        spec.Material or Enum.Material.Slate
    )

    local forward = districtPoint(center, yaw, Vector3.new(0, 0, -depth * 0.68))
    local back = districtPoint(center, yaw, Vector3.new(0, 0, depth * 0.68))
    local left = districtPoint(center, yaw, Vector3.new(-width * 0.62, 0, 0))
    local right = districtPoint(center, yaw, Vector3.new(width * 0.62, 0, 0))
    fillTerrainRoute({ forward, center, back }, spec.RoadWidth or 10, Enum.Material.Ground)
    fillTerrainRoute({ left, center, right }, spec.RoadWidth or 10, Enum.Material.Ground)

    makeWayfarerStreetArch(
        model,
        spec.Name .. "ApproachArch",
        districtPoint(center, yaw, Vector3.new(0, 0, -depth * 0.58)),
        yaw,
        spec.ArchWidth or 18,
        accent
    )
    makeWaystone(model, districtPoint(center, yaw, Vector3.new(0, 0, -depth * 0.32)), yaw, 0.8)

    for _, offset in
        {
            Vector3.new(-width * 0.34, 0, -depth * 0.30),
            Vector3.new(width * 0.34, 0, -depth * 0.30),
            Vector3.new(-width * 0.34, 0, depth * 0.30),
            Vector3.new(width * 0.34, 0, depth * 0.30),
        }
    do
        makeLantern(model, districtPoint(center, yaw, offset), yaw)
    end

    if spec.Kind == "market" then
        makeMarketStall(
            model,
            districtPoint(center, yaw, Vector3.new(-22, 0, 10)),
            yaw + math.rad(90),
            accent
        )
        makeMarketStall(
            model,
            districtPoint(center, yaw, Vector3.new(22, 0, 10)),
            yaw - math.rad(90),
            accent:Lerp(SIGNATURE.ClothGold, 0.25)
        )
        makeWayfarerCart(
            model,
            spec.Name .. "TradeCart",
            districtPoint(center, yaw, Vector3.new(30, 0, -12)),
            yaw + math.rad(70),
            true
        )
        makeBench(model, districtPoint(center, yaw, Vector3.new(-12, 0, -4)), yaw + math.rad(90))
        makeBench(model, districtPoint(center, yaw, Vector3.new(12, 0, -4)), yaw - math.rad(90))
    elseif spec.Kind == "wetland" then
        makeBoardwalk(model, spec.Name .. "CrosswalkA", left, right, 8)
        makeBoardwalk(model, spec.Name .. "CrosswalkB", forward, back, 7)
        makeReedDock(
            model,
            spec.Name .. "PublicDock",
            districtPoint(center, yaw, Vector3.new(width * 0.44, 0, depth * 0.24)),
            yaw + math.rad(90),
            22
        )
        makeSupplyStack(model, districtPoint(center, yaw, Vector3.new(-24, 0, 12)), yaw, 0.75)
    elseif spec.Kind == "fort" then
        makeFenceLine(
            model,
            spec.Name .. "NorthWall",
            districtPoint(center, yaw, Vector3.new(-width * 0.48, 0, depth * 0.44)),
            districtPoint(center, yaw, Vector3.new(width * 0.48, 0, depth * 0.44)),
            8,
            5.5
        )
        makeFenceLine(
            model,
            spec.Name .. "SouthWall",
            districtPoint(center, yaw, Vector3.new(-width * 0.48, 0, -depth * 0.44)),
            districtPoint(center, yaw, Vector3.new(width * 0.48, 0, -depth * 0.44)),
            8,
            5.5
        )
        makeSupplyStack(model, districtPoint(center, yaw, Vector3.new(-24, 0, 14)), yaw, 0.9)
        makeSupplyStack(model, districtPoint(center, yaw, Vector3.new(24, 0, 14)), yaw, 0.9)
        makeHearth(model, districtPoint(center, yaw, Vector3.new(0, 0, 10)))
    elseif spec.Kind == "ruin" then
        makeRuinWall(
            model,
            districtPoint(center, yaw, Vector3.new(-22, 0, 8)),
            yaw + math.rad(90),
            34,
            7
        )
        makeRuinWall(model, districtPoint(center, yaw, Vector3.new(20, 0, -4)), yaw, 30, 6)
        makeStoneShrine(
            model,
            spec.Name .. "CourtShrine",
            districtPoint(center, yaw, Vector3.new(0, 0, 14)),
            yaw + math.rad(180),
            accent
        )
        makeWayfarerCart(
            model,
            spec.Name .. "BrokenWagon",
            districtPoint(center, yaw, Vector3.new(27, 0, -15)),
            yaw + math.rad(38),
            false
        )
    elseif spec.Kind == "research" then
        makeStoneShrine(
            model,
            spec.Name .. "StudyShrine",
            districtPoint(center, yaw, Vector3.new(0, 0, 12)),
            yaw + math.rad(180),
            accent
        )
        makeBench(model, districtPoint(center, yaw, Vector3.new(-18, 0, 3)), yaw + math.rad(90))
        makeBench(model, districtPoint(center, yaw, Vector3.new(18, 0, 3)), yaw - math.rad(90))
        makeSupplyStack(model, districtPoint(center, yaw, Vector3.new(26, 0, -13)), yaw, 0.7)
    elseif spec.Kind == "ranger" then
        makeHearth(model, districtPoint(center, yaw, Vector3.new(0, 0, 9)))
        makeSupplyStack(model, districtPoint(center, yaw, Vector3.new(-25, 0, 12)), yaw, 0.8)
        makeWayfarerCart(
            model,
            spec.Name .. "RangerCart",
            districtPoint(center, yaw, Vector3.new(25, 0, -13)),
            yaw - math.rad(65),
            true
        )
        makeBench(model, districtPoint(center, yaw, Vector3.new(-14, 0, -5)), yaw + math.rad(90))
    else
        makeHearth(model, districtPoint(center, yaw, Vector3.new(0, 0, 8)))
        makeBench(model, districtPoint(center, yaw, Vector3.new(-15, 0, -3)), yaw + math.rad(90))
        makeBench(model, districtPoint(center, yaw, Vector3.new(15, 0, -3)), yaw - math.rad(90))
    end

    return model
end

local function makeWorldMMOComposition(parent)
    local courts = {
        {
            Name = "Greenway",
            Center = ZONES.Greenway + Vector3.new(0, 0, -28),
            Yaw = math.rad(2),
            Kind = "market",
            Width = 86,
            Depth = 54,
            Accent = Color3.fromRGB(113, 159, 91),
            Material = Enum.Material.Ground,
        },
        {
            Name = "Crossroads",
            Center = ZONES.Crossroads + Vector3.new(0, 0, 4),
            Yaw = 0,
            Kind = "market",
            Width = 82,
            Depth = 62,
            Accent = SIGNATURE.Lumen,
        },
        {
            Name = "Glowmere",
            Center = ZONES.Glowmere + Vector3.new(0, 0, 18),
            Yaw = math.rad(-10),
            Kind = "wetland",
            Width = 92,
            Depth = 60,
            Accent = Color3.fromRGB(112, 226, 211),
            Material = Enum.Material.Ground,
        },
        {
            Name = "Eastbridge",
            Center = ZONES.EastLanding + Vector3.new(5, 0, 2),
            Yaw = math.rad(90),
            Kind = "fort",
            Width = 94,
            Depth = 62,
            Accent = Color3.fromRGB(108, 220, 180),
        },
        {
            Name = "Gravebone",
            Center = ZONES.Gravebone + Vector3.new(0, 0, 2),
            Yaw = math.rad(8),
            Kind = "ruin",
            Width = 90,
            Depth = 66,
            Accent = Color3.fromRGB(142, 198, 172),
        },
        {
            Name = "Mossglen",
            Center = ZONES.Mossglen + Vector3.new(-18, 0, -18),
            Yaw = math.rad(-8),
            Kind = "ranger",
            Width = 98,
            Depth = 64,
            Accent = Color3.fromRGB(107, 173, 103),
            Material = Enum.Material.Ground,
        },
        {
            Name = "Sunmoss",
            Center = ZONES.Sunmoss + Vector3.new(0, 0, 5),
            Yaw = math.rad(-18),
            Kind = "research",
            Width = 82,
            Depth = 58,
            Accent = Color3.fromRGB(207, 217, 113),
        },
        {
            Name = "Veilfall",
            Center = ZONES.Veilfall + Vector3.new(-5, 0, 0),
            Yaw = math.rad(20),
            Kind = "research",
            Width = 76,
            Depth = 54,
            Accent = Color3.fromRGB(114, 222, 226),
        },
        {
            Name = "ShatteredArch",
            Center = ZONES.Ruins + Vector3.new(-18, 0, 4),
            Yaw = math.rad(90),
            Kind = "fort",
            Width = 104,
            Depth = 72,
            Accent = Color3.fromRGB(96, 229, 193),
        },
        {
            Name = "Proving",
            Center = ZONES.Proving + Vector3.new(0, 0, 8),
            Yaw = math.rad(180),
            Kind = "fort",
            Width = 88,
            Depth = 60,
            Accent = Color3.fromRGB(111, 235, 188),
        },
    }
    for _, spec in courts do
        makeDistrictCourt(parent, spec)
    end
end

local function makeWorldSettlements(parent)
    -- Greenway settlement edge: visible habitation immediately outside town.
    makeRoadWayhouse(
        parent,
        "GreenwayWayhouse",
        ZONES.Greenway + Vector3.new(-92, 0, -62),
        math.rad(48),
        Color3.fromRGB(97, 112, 80)
    )
    makeFarmBarn(
        parent,
        "GreenwayStoreShed",
        ZONES.Greenway + Vector3.new(92, 0, -54),
        math.rad(-42),
        Color3.fromRGB(112, 91, 62)
    )
    makeRoadsideShelter(
        parent,
        "GreenwayTravelShelter",
        ZONES.Greenway + Vector3.new(18, 0, -92),
        math.rad(8)
    )
    makeSupplyStack(parent, ZONES.Greenway + Vector3.new(-70, 0, -72), math.rad(32), 0.85)

    -- Crossroads is a staffed Wayfarer waystation, not a sign in a field.
    makeRoadWayhouse(
        parent,
        "CrossroadsWaystation",
        ZONES.Crossroads + Vector3.new(-70, 0, -58),
        math.rad(38),
        Color3.fromRGB(84, 108, 87)
    )
    makeQuartermasterDepot(
        parent,
        "CrossroadsCourierHouse",
        ZONES.Crossroads + Vector3.new(70, 0, 55),
        math.rad(-142)
    )
    makeRoadsideShelter(
        parent,
        "CrossroadsRestShelter",
        ZONES.Crossroads + Vector3.new(74, 0, -38),
        math.rad(-65)
    )
    makeStoneShrine(
        parent,
        "CrossroadsWayfarerShrine",
        ZONES.Crossroads + Vector3.new(-52, 0, 55),
        math.rad(30),
        Color3.fromRGB(104, 231, 188)
    )

    -- Glowmere has an actual wetland community around the shoreline.
    makeGlowmereStiltHouse(
        parent,
        "GlowmereKeeperHut",
        ZONES.Glowmere + Vector3.new(-112, 0, -74),
        math.rad(32),
        Color3.fromRGB(73, 107, 91)
    )
    makeGlowmereStiltHouse(
        parent,
        "GlowmereReedHouse",
        ZONES.Glowmere + Vector3.new(102, 0, -80),
        math.rad(-30),
        Color3.fromRGB(92, 112, 86)
    )
    makeRoadsideShelter(
        parent,
        "GlowmereFisherShelter",
        ZONES.Glowmere + Vector3.new(105, 0, 62),
        math.rad(-118)
    )
    makeSupplyStack(parent, ZONES.Glowmere + Vector3.new(-90, 0, -82), math.rad(8), 0.8)

    -- Eastbridge is a fortified frontier hamlet with several occupied structures.
    makeProvingLodge(
        parent,
        "EastbridgeBarracks",
        ZONES.EastLanding + Vector3.new(-58, 0, 48),
        math.rad(136)
    )
    makeQuartermasterDepot(
        parent,
        "EastbridgeStorehouse",
        ZONES.EastLanding + Vector3.new(62, 0, -52),
        math.rad(-46)
    )
    makeHealerApothecary(
        parent,
        "EastbridgeMedicLodge",
        ZONES.EastLanding + Vector3.new(-52, 0, -55),
        math.rad(44)
    )
    makeGatehouse(
        parent,
        "EastbridgeGatehouse",
        ZONES.EastLanding + Vector3.new(-82, 0, 0),
        math.rad(90),
        34
    )
    makeFenceLine(
        parent,
        "EastbridgeNorthWall",
        ZONES.EastLanding + Vector3.new(-64, 0, 66),
        ZONES.EastLanding + Vector3.new(64, 0, 66),
        8,
        5
    )
    makeFenceLine(
        parent,
        "EastbridgeSouthWall",
        ZONES.EastLanding + Vector3.new(-64, 0, -68),
        ZONES.EastLanding + Vector3.new(64, 0, -68),
        8,
        5
    )
    makeSupplyStack(parent, ZONES.EastLanding + Vector3.new(56, 0, 18), math.rad(-20), 0.9)

    -- Gravebone reads as a destroyed fortified settlement and cemetery.
    makeRuinedHall(
        parent,
        "GraveboneRuinedChapel",
        ZONES.Gravebone + Vector3.new(-62, 0, 70),
        34,
        25,
        math.rad(16)
    )
    makeRuinedHall(
        parent,
        "GraveboneGuardHall",
        ZONES.Gravebone + Vector3.new(92, 0, -76),
        28,
        21,
        math.rad(-24)
    )
    makeGatehouse(parent, "GraveboneBrokenGate", ZONES.Gravebone + Vector3.new(-5, 0, -105), 0, 30)
    makeStoneShrine(
        parent,
        "GraveboneMemorial",
        ZONES.Gravebone + Vector3.new(-92, 0, 18),
        math.rad(88),
        Color3.fromRGB(142, 198, 172)
    )

    -- Mossglen has a ranger enclave on the edge of its large party field.
    makeMossglenRangerHall(
        parent,
        "MossglenRangerLodge",
        ZONES.Mossglen + Vector3.new(-128, 0, -92),
        math.rad(42)
    )
    makeCroftCottage(
        parent,
        "MossglenHunterCabin",
        ZONES.Mossglen + Vector3.new(128, 0, -105),
        math.rad(-38),
        Color3.fromRGB(100, 91, 61),
        true
    )
    makeFarmBarn(
        parent,
        "MossglenSupplyHouse",
        ZONES.Mossglen + Vector3.new(-150, 0, 12),
        math.rad(90),
        Color3.fromRGB(109, 86, 58)
    )
    makeRoadsideShelter(
        parent,
        "MossglenRestShelter",
        ZONES.Mossglen + Vector3.new(148, 0, 55),
        math.rad(-90)
    )
    makeSupplyStack(parent, ZONES.Mossglen + Vector3.new(-112, 0, -64), math.rad(25), 0.9)

    -- Sunmoss is an old highland observation/research site.
    makeArchiveResearchLodge(
        parent,
        "SunmossObservatoryLodge",
        ZONES.Sunmoss + Vector3.new(-92, 0, -72),
        math.rad(35)
    )
    makeCroftCottage(
        parent,
        "SunmossKeeperHouse",
        ZONES.Sunmoss + Vector3.new(88, 0, 72),
        math.rad(-145),
        Color3.fromRGB(84, 104, 79),
        false
    )
    makeStoneShrine(
        parent,
        "SunmossHighShrine",
        ZONES.Sunmoss + Vector3.new(-75, 0, 68),
        math.rad(30),
        Color3.fromRGB(207, 217, 113)
    )
    makeWatchtower(parent, ZONES.Sunmoss + Vector3.new(112, 0, -62), math.rad(-55))

    -- Veilfall contains a surviving refuge beside older ruined infrastructure.
    makeRoadWayhouse(
        parent,
        "VeilfallRefuge",
        ZONES.Veilfall + Vector3.new(-104, 0, -68),
        math.rad(45),
        Color3.fromRGB(69, 98, 92)
    )
    makeArchiveResearchLodge(
        parent,
        "VeilfallSurveyHut",
        ZONES.Veilfall + Vector3.new(108, 0, 68),
        math.rad(-132)
    )
    makeRuinedHall(
        parent,
        "VeilfallOldSanctuary",
        ZONES.Veilfall + Vector3.new(100, 0, -65),
        30,
        22,
        math.rad(-38)
    )
    makeStoneShrine(
        parent,
        "VeilfallLumenShrine",
        ZONES.Veilfall + Vector3.new(-105, 0, 54),
        math.rad(58),
        Color3.fromRGB(114, 222, 226)
    )

    -- The Shattered Arch is the remains of a true border fortress.
    makeGatehouse(
        parent,
        "ShatteredArchOuterGate",
        ZONES.Ruins + Vector3.new(-116, 0, -4),
        math.rad(90),
        34
    )
    makeRuinedHall(
        parent,
        "ShatteredArchGuardhouseNorth",
        ZONES.Ruins + Vector3.new(-90, 0, 92),
        34,
        24,
        math.rad(12)
    )
    makeRuinedHall(
        parent,
        "ShatteredArchGuardhouseSouth",
        ZONES.Ruins + Vector3.new(-82, 0, -88),
        32,
        23,
        math.rad(-10)
    )
    makeWatchtower(parent, ZONES.Ruins + Vector3.new(-132, 0, 92), math.rad(20))
    makeWatchtower(parent, ZONES.Ruins + Vector3.new(-130, 0, -94), math.rad(-20))
    makeStoneShrine(
        parent,
        "ShatteredArchThresholdShrine",
        ZONES.Ruins + Vector3.new(58, 0, -88),
        math.rad(-12),
        Color3.fromRGB(96, 229, 193)
    )

    -- Proving Circle has a mentor compound instead of an isolated ritual ring.
    makeProvingLodge(
        parent,
        "ProvingMentorLodge",
        ZONES.Proving + Vector3.new(-72, 0, 58),
        math.rad(48)
    )
    makeRoadsideShelter(
        parent,
        "ProvingPreparationShelter",
        ZONES.Proving + Vector3.new(76, 0, 56),
        math.rad(-52)
    )
    makeStoneShrine(
        parent,
        "ProvingOathShrine",
        ZONES.Proving + Vector3.new(0, 0, 70),
        math.rad(180),
        Color3.fromRGB(111, 235, 188)
    )
end

local function makeTown(parent)
    local camp = ZONES.Camp

    -- V20: Wayfarer is composed as an MMO hub, not a collection of buildings
    -- scattered across one giant open rectangle. Grade first, then build a
    -- compact civic square, service street, market lane, training court, and
    -- two readable gates around a clear pedestrian spine.
    flattenTerrain(camp, Vector3.new(300, 0, 240), 2.0, Enum.Material.Ground)

    -- Main east/west Wayfarer street and north/south civic lane.
    Workspace.Terrain:FillBlock(
        CFrame.new(camp.X, 1.25, camp.Z + 4),
        Vector3.new(250, 1.5, 34),
        Enum.Material.Ground
    )
    Workspace.Terrain:FillBlock(
        CFrame.new(camp.X - 4, 1.25, camp.Z - 18),
        Vector3.new(34, 1.5, 182),
        Enum.Material.Ground
    )
    -- Central square: deliberately much smaller than the old empty plaza.
    Workspace.Terrain:FillBlock(
        CFrame.new(camp.X - 2, 1.3, camp.Z + 4),
        Vector3.new(88, 1.6, 72),
        Enum.Material.Slate
    )
    -- Market and service courts use different ground material to read as
    -- destinations rather than leftover open terrain.
    Workspace.Terrain:FillBlock(
        CFrame.new(camp.X + 63, 1.25, camp.Z + 49),
        Vector3.new(80, 1.5, 56),
        Enum.Material.Ground
    )
    Workspace.Terrain:FillBlock(
        CFrame.new(camp.X - 70, 1.25, camp.Z + 47),
        Vector3.new(62, 1.5, 58),
        Enum.Material.Ground
    )

    -- Civic edge. Entrances face the square at short player-readable distances.
    makeWayfarerCivicHall(parent, "WayfarerHall", camp + Vector3.new(-30, 0, -62), math.rad(180))
    makeArchiveResearchLodge(parent, "ArchiveLodge", camp + Vector3.new(33, 0, -61), math.rad(180))
    makeQuartermasterDepot(
        parent,
        "QuartermasterHouse",
        camp + Vector3.new(-64, 0, 34),
        math.rad(22)
    )
    makeWayfarerInn(parent, "WayfarerInn", camp + Vector3.new(65, 0, 35), math.rad(-22))

    -- The hearth/well court is the visual and social center of the settlement.
    makeHearth(parent, camp + Vector3.new(-3, 0, 1))
    makeLumenWell(
        parent,
        "WayfarerSquareWell",
        camp + Vector3.new(13, 0, 4),
        Color3.fromRGB(100, 236, 194)
    )
    for _, spec in
        {
            { Vector3.new(-27, 0, 16), math.rad(24) },
            { Vector3.new(29, 0, 16), math.rad(-24) },
            { Vector3.new(-27, 0, -18), math.rad(155) },
            { Vector3.new(28, 0, -18), math.rad(-155) },
        }
    do
        makeBench(parent, camp + spec[1], spec[2])
    end

    -- Market lane: multiple stalls, cargo and lighting make this a real service
    -- cluster rather than two isolated props in the middle of the road.
    for _, spec in
        {
            { Vector3.new(43, 0, 67), math.rad(180), Color3.fromRGB(128, 101, 62) },
            { Vector3.new(66, 0, 69), math.rad(180), Color3.fromRGB(94, 81, 128) },
            { Vector3.new(88, 0, 64), math.rad(180), Color3.fromRGB(82, 118, 94) },
            { Vector3.new(48, 0, 88), 0, Color3.fromRGB(112, 76, 58) },
        }
    do
        makeMarketStall(parent, camp + spec[1], spec[2], spec[3])
    end
    makeSupplyStack(parent, camp + Vector3.new(78, 0, 89), math.rad(-12), 1.0)
    makeSupplyStack(parent, camp + Vector3.new(94, 0, 43), math.rad(26), 0.85)

    -- West-side service court.
    makeHealerApothecary(
        parent,
        "WayfarerHealerLodge",
        camp + Vector3.new(-105, 0, -24),
        math.rad(-90)
    )
    makeQuartermasterDepot(
        parent,
        "WayfarerStorehouse",
        camp + Vector3.new(-111, 0, 55),
        math.rad(-90)
    )
    makeSupplyStack(parent, camp + Vector3.new(-82, 0, 50), math.rad(16), 1.0)
    makeStoneShrine(
        parent,
        "WayfarerWestShrine",
        camp + Vector3.new(-81, 0, -45),
        math.rad(90),
        Color3.fromRGB(104, 231, 188)
    )

    -- South/east production and stable lane.
    makeCraftWorkshop(parent, "WayfarerCraftHall", camp + Vector3.new(5, 0, 91), 0)
    makeForgeYard(parent, "WayfarerForgeYard", camp + Vector3.new(-32, 0, 91), math.rad(180))
    makeOpenStable(parent, "WayfarerStable", camp + Vector3.new(108, 0, 80), math.rad(90))
    makeProvingLodge(parent, "PathkeeperLodge", camp + Vector3.new(4, 0, -108), math.rad(180))

    -- Training court remains readable and open for dodge/combat practice, but
    -- it is framed by architecture rather than floating in a blank field.
    for _, offset in
        {
            Vector3.new(55, 0, -35),
            Vector3.new(86, 0, -35),
            Vector3.new(55, 0, 9),
            Vector3.new(86, 0, 9),
        }
    do
        makeLumenPylon(parent, camp + offset, 7)
    end
    makeSign(parent, camp + Vector3.new(70, 0, -20), math.rad(-90), "TRAINING COURT")

    -- Strong town thresholds. The mesh gatehouses make entering/leaving the hub
    -- feel like crossing a defended settlement boundary.
    makeGatehouse(parent, "WayfarerEastGate", camp + Vector3.new(122, 0, 3), math.rad(90), 32)
    makeGatehouse(parent, "WayfarerSouthGate", camp + Vector3.new(2, 0, -116), math.rad(180), 30)
    makeWatchtower(parent, camp + Vector3.new(-124, 0, -88), math.rad(25))
    makeWatchtower(parent, camp + Vector3.new(124, 0, -82), math.rad(-25))

    -- Palisade frames the hub but leaves the two gate openings clear.
    makeFenceLine(
        parent,
        "CampNorthPalisade",
        camp + Vector3.new(-122, 0, 105),
        camp + Vector3.new(114, 0, 105),
        8,
        5.5
    )
    makeFenceLine(
        parent,
        "CampSouthPalisadeWest",
        camp + Vector3.new(-122, 0, -116),
        camp + Vector3.new(-22, 0, -116),
        8,
        5.5
    )
    makeFenceLine(
        parent,
        "CampSouthPalisadeEast",
        camp + Vector3.new(25, 0, -116),
        camp + Vector3.new(114, 0, -116),
        8,
        5.5
    )
    makeFenceLine(
        parent,
        "CampWestPalisade",
        camp + Vector3.new(-134, 0, -98),
        camp + Vector3.new(-134, 0, 96),
        8,
        5.5
    )

    -- Street rhythm and service readability.
    for _, offset in
        {
            Vector3.new(-55, 0, 18),
            Vector3.new(-31, 0, 41),
            Vector3.new(28, 0, 41),
            Vector3.new(54, 0, 18),
            Vector3.new(-31, 0, -38),
            Vector3.new(33, 0, -38),
            Vector3.new(93, 0, 18),
            Vector3.new(-93, 0, 17),
            Vector3.new(18, 0, 72),
            Vector3.new(-17, 0, 72),
        }
    do
        makeLantern(parent, camp + offset, 0)
    end
    makeWayfarerBanner(
        parent,
        "HallBannerA",
        camp + Vector3.new(-44, 0, -39),
        0,
        Color3.fromRGB(72, 133, 104)
    )
    makeWayfarerBanner(
        parent,
        "HallBannerB",
        camp + Vector3.new(-16, 0, -39),
        0,
        Color3.fromRGB(72, 133, 104)
    )
    makeWayfarerStreetArch(
        parent,
        "MarketArch",
        camp + Vector3.new(63, 0, 49),
        math.rad(90),
        18,
        Color3.fromRGB(166, 123, 62)
    )

    makeSign(parent, camp + Vector3.new(98, 0, 20), math.rad(-76), "GREENWAY  →")
    makeSign(parent, camp + Vector3.new(10, 0, -92), math.rad(180), "PROVING CIRCLE")
    makeSign(parent, camp + Vector3.new(-70, 0, -28), math.rad(90), "HEALER / STOREHOUSE")
    makeSign(parent, camp + Vector3.new(49, 0, 48), math.rad(180), "MARKET LANE")

    -- Carts and cargo imply actual travel/economy traffic through the hub.
    makeWayfarerCart(parent, "MarketCart", camp + Vector3.new(98, 0, 52), math.rad(-15), true)
    makeWayfarerCart(parent, "ArrivalCart", camp + Vector3.new(-87, 0, 13), math.rad(92), false)
end

local function makeStoneCircle(parent, center, radius, count, name)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local ground = terrainSurfacePosition(center, 0)
    for index = 1, count do
        local angle = (index - 1) * math.pi * 2 / count
        local pos = ground + Vector3.new(math.cos(angle) * radius, 0.7, math.sin(angle) * radius)
        local stone = makePart(
            model,
            "RingStone",
            Vector3.new(4.5, 1.4, 2.5),
            CFrame.new(pos) * CFrame.Angles(0, -angle + math.rad(90), math.rad((index % 3 - 1) * 2)),
            Enum.Material.Slate,
            if index % 2 == 0 then Color3.fromRGB(80, 93, 86) else Color3.fromRGB(91, 101, 94)
        )
        stone.CanCollide = false
        stone.CanTouch = false
        stone.CanQuery = false
        makeCollisionProxy(
            model,
            "RingStoneCollision" .. index,
            Vector3.new(4.5, 1.45, 2.5),
            stone.CFrame
        )
    end
    return model
end

local function makeProvingCircle(parent)
    makeStoneCircle(parent, ZONES.Proving, 30, 18, "WayfarerProvingCircle")
    local pathColors = {
        Color3.fromRGB(121, 244, 183), -- Ironbloom
        Color3.fromRGB(230, 170, 82), -- Thornrunner
        Color3.fromRGB(99, 236, 209), -- Lumenweaver
        Color3.fromRGB(187, 145, 229), -- Veilstrider
        Color3.fromRGB(241, 187, 82), -- Brasshand
    }
    for index = 1, 5 do
        local angle = math.rad(-90 + (index - 1) * 72)
        local pos = ZONES.Proving + Vector3.new(math.cos(angle) * 20, 0, math.sin(angle) * 20)
        makeWaystone(parent, pos, -angle + math.rad(90), 0.7)

        local ground = terrainSurfacePosition(pos + Vector3.new(0, 0, 7), 0)
        local plinth = makePart(
            parent,
            "PathDisciplinePlinth",
            Vector3.new(7, 0.8, 7),
            CFrame.new(ground + Vector3.new(0, 0.4, 0)),
            Enum.Material.Slate,
            Color3.fromRGB(72, 80, 77)
        )
        plinth.CanCollide = false
        local lumen = makePart(
            parent,
            "PathDisciplineLumen",
            Vector3.new(3.6, 0.32, 3.6),
            CFrame.new(ground + Vector3.new(0, 0.84, 0)),
            Enum.Material.Neon,
            pathColors[index]
        )
        lumen.CanCollide = false
        lumen.CanTouch = false
        lumen.CanQuery = false
        makeCollisionProxy(
            parent,
            "PathDisciplinePlinthCollision" .. index,
            Vector3.new(7, 0.9, 7),
            CFrame.new(ground + Vector3.new(0, 0.45, 0))
        )
    end
end

local function makeRuins(parent)
    local origin = terrainSurfacePosition(ZONES.Ruins, 0)
    local model = Instance.new("Model")
    model.Name = "ShatteredLumenArch"
    model.Parent = parent
    local stone = Color3.fromRGB(82, 91, 86)
    local dark = Color3.fromRGB(64, 72, 69)

    for _, x in { -18, 18 } do
        local pillarCFrame = CFrame.new(origin + Vector3.new(x, 12.5, 0))
        makePart(
            model,
            "ArchPillar",
            Vector3.new(8, 25, 8),
            pillarCFrame,
            Enum.Material.Slate,
            stone
        )
        makeCollisionProxy(model, "ArchPillarCollision", Vector3.new(8.2, 25, 8.2), pillarCFrame)
    end
    makePart(
        model,
        "ArchLintel",
        Vector3.new(44, 7, 8),
        CFrame.new(origin + Vector3.new(0, 24, 0)) * CFrame.Angles(0, 0, math.rad(-5)),
        Enum.Material.Slate,
        dark
    )
    makeWedge(
        model,
        "BrokenCrown",
        Vector3.new(18, 8, 10),
        CFrame.new(origin + Vector3.new(11, 30, 0)) * CFrame.Angles(0, math.rad(90), math.rad(8)),
        Enum.Material.Slate,
        stone
    ).CanCollide =
        false

    local gate = makePart(
        model,
        "BrasshavenGate",
        Vector3.new(22, 15, 1),
        CFrame.new(origin + Vector3.new(0, 8.0, 2.6)),
        Enum.Material.ForceField,
        Color3.fromRGB(88, 202, 177)
    )
    gate.Transparency = 0.42
    gate.CanCollide = false
    gate.CanTouch = false
    WorldObjectService.Register(gate, "Portal", "lumenreach_to_brasshaven")

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "BrasshavenGatePrompt"
    prompt.ActionText = "Travel"
    prompt.ObjectText = "Brasshaven Gate · Level 10"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
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
end

local function makeVeilfall(parent)
    local origin = terrainSurfacePosition(ZONES.Veilfall + Vector3.new(-28, 0, 12), 0)
    local model = Instance.new("Model")
    model.Name = "VeilfallCascade"
    model.Parent = parent

    -- Terrain cliff shoulders frame the fall. Only the water ribbons are parts,
    -- preventing the old slab/rock-mesh failure modes from returning.
    Workspace.Terrain:FillBall(origin + Vector3.new(-23, 12, -7), 21, Enum.Material.Rock)
    Workspace.Terrain:FillBall(origin + Vector3.new(23, 12, -7), 21, Enum.Material.Rock)
    Workspace.Terrain:FillBlock(
        CFrame.new(origin + Vector3.new(0, 23, -9)),
        Vector3.new(40, 18, 28),
        Enum.Material.Rock
    )

    local ribbons = {
        { -5.2, 3.8, 28 },
        { -1.4, 4.8, 31 },
        { 3.4, 4.1, 29 },
    }
    for index, spec in ribbons do
        local bottom = makePart(
            model,
            "WaterAnchorBottom" .. index,
            Vector3.new(0.1, 0.1, 0.1),
            CFrame.new(origin + Vector3.new(spec[1], 1, 7)),
            Enum.Material.SmoothPlastic,
            Color3.new(1, 1, 1)
        )
        bottom.Transparency = 1
        bottom.CanCollide = false
        bottom.CanTouch = false
        bottom.CanQuery = false
        local top = makePart(
            model,
            "WaterAnchorTop" .. index,
            Vector3.new(0.1, 0.1, 0.1),
            CFrame.new(origin + Vector3.new(spec[1] * 0.85, spec[3], 4)),
            Enum.Material.SmoothPlastic,
            Color3.new(1, 1, 1)
        )
        top.Transparency = 1
        top.CanCollide = false
        top.CanTouch = false
        top.CanQuery = false
        local a0 = Instance.new("Attachment")
        a0.Parent = top
        local a1 = Instance.new("Attachment")
        a1.Parent = bottom
        local beam = Instance.new("Beam")
        beam.Name = "WaterRibbon" .. index
        beam.Attachment0 = a0
        beam.Attachment1 = a1
        beam.FaceCamera = true
        beam.Width0 = spec[2] * 0.75
        beam.Width1 = spec[2]
        beam.Segments = 10
        beam.Color = ColorSequence.new(Color3.fromRGB(149, 225, 230), Color3.fromRGB(208, 246, 238))
        beam.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(0.8, 0.56),
            NumberSequenceKeypoint.new(1, 0.72),
        })
        beam.LightEmission = 0.15
        beam.LightInfluence = 0.4
        beam.Parent = model
    end
end

local function makeGreenwaySetpiece(parent)
    -- Starter field is an open meadow with a ruined roadside checkpoint that
    -- teaches players that old Wayfarer infrastructure continues into the wild.
    makeRuinWall(parent, ZONES.Greenway + Vector3.new(-62, 0, 78), math.rad(22), 28, 5.5)
    makeRuinWall(parent, ZONES.Greenway + Vector3.new(58, 0, 84), math.rad(-18), 24, 4.8)
    makeBench(parent, ZONES.Greenway + Vector3.new(-82, 0, -34), math.rad(65))
    makeLumenPylon(parent, ZONES.Greenway + Vector3.new(72, 0, -48), 8)
end

local function makeCrossroadsSetpiece(parent)
    local center = ZONES.Crossroads + Vector3.new(8, 0, -18)
    makeLumenPylon(parent, center, 14)
    for _, offset in
        {
            Vector3.new(-26, 0, 18),
            Vector3.new(22, 0, 28),
            Vector3.new(26, 0, -30),
        }
    do
        makeBench(parent, ZONES.Crossroads + offset, math.atan2(-offset.X, -offset.Z))
    end
end

local function makeGlowmereSetpiece(parent)
    -- Boardwalk skirts the wetland rather than cutting across the combat pool.
    makeBoardwalk(
        parent,
        "GlowmereBoardwalkA",
        ZONES.Glowmere + Vector3.new(-76, 0, -30),
        ZONES.Glowmere + Vector3.new(-32, 0, 18),
        7.5
    )
    makeBoardwalk(
        parent,
        "GlowmereBoardwalkB",
        ZONES.Glowmere + Vector3.new(-32, 0, 18),
        ZONES.Glowmere + Vector3.new(0, 0, 63),
        7.5
    )
    makeOverlookDeck(parent, ZONES.Glowmere + Vector3.new(68, 0, -54), math.rad(-36), 15, 10)
    makeLumenPylon(parent, ZONES.Glowmere + Vector3.new(64, 0, 62), 7)
    makeLumenPylon(parent, ZONES.Glowmere + Vector3.new(-74, 0, 48), 6)
end

local function makeEastLandingSetpiece(parent)
    makeWatchtower(parent, ZONES.EastLanding + Vector3.new(-42, 0, -42), math.rad(35))
    makeMarketStall(
        parent,
        ZONES.EastLanding + Vector3.new(30, 0, -28),
        math.rad(-125),
        Color3.fromRGB(72, 111, 79)
    )
    makeHearth(parent, ZONES.EastLanding + Vector3.new(-10, 0, 38))
    makeBench(parent, ZONES.EastLanding + Vector3.new(14, 0, 48), math.rad(-150))
end

local function makeGraveboneSetpiece(parent)
    -- Watch ruins create cover and silhouette around, not inside, the main fight.
    makeRuinWall(parent, ZONES.Gravebone + Vector3.new(-74, 0, -18), math.rad(72), 44, 9)
    makeRuinWall(parent, ZONES.Gravebone + Vector3.new(-24, 0, -72), math.rad(-8), 38, 7)
    makeRuinWall(parent, ZONES.Gravebone + Vector3.new(80, 0, -58), math.rad(-58), 32, 5.5)
    makeWatchtower(parent, ZONES.Gravebone + Vector3.new(-92, 0, 58), math.rad(68))
    for _, offset in
        {
            Vector3.new(35, 0, -28),
            Vector3.new(48, 0, -6),
            Vector3.new(28, 0, 18),
            Vector3.new(-8, 0, 44),
        }
    do
        local ground = terrainSurfacePosition(ZONES.Gravebone + offset, 0)
        local marker = makePart(
            parent,
            "GraveMarker",
            Vector3.new(2.2, 4.4, 0.8),
            CFrame.new(ground + Vector3.new(0, 2.2, 0))
                * CFrame.Angles(0, math.rad((offset.X + offset.Z) % 40), math.rad(4)),
            Enum.Material.Slate,
            Color3.fromRGB(72, 78, 76)
        )
        marker.CanCollide = false
        makeCollisionProxy(
            parent,
            "GraveMarkerCollision",
            Vector3.new(2.3, 4.4, 1.0),
            marker.CFrame
        )
    end
end

local function makeMossglenSetpiece(parent)
    makeWatchtower(parent, ZONES.Mossglen + Vector3.new(-142, 0, 78), math.rad(-35))
    makeOverlookDeck(parent, ZONES.Mossglen + Vector3.new(110, 0, 82), math.rad(145), 17, 11)
    makeHearth(parent, ZONES.Mossglen + Vector3.new(-118, 0, -42))
    makeBench(parent, ZONES.Mossglen + Vector3.new(-98, 0, -52), math.rad(120))
    makeLumenPylon(parent, ZONES.Mossglen + Vector3.new(-8, 0, 128), 10)
    makeLumenPylon(parent, ZONES.Mossglen + Vector3.new(-52, 0, 105), 7)
end

local function makeSunmossSetpiece(parent)
    makeOverlookDeck(parent, ZONES.Sunmoss + Vector3.new(90, 0, 20), math.rad(-88), 20, 12)
    makeLumenPylon(parent, ZONES.Sunmoss + Vector3.new(0, 0, -72), 13)
    makeLumenPylon(parent, ZONES.Sunmoss + Vector3.new(-42, 0, 45), 9)
    makeLumenPylon(parent, ZONES.Sunmoss + Vector3.new(44, 0, 52), 9)
    makeBench(parent, ZONES.Sunmoss + Vector3.new(66, 0, -32), math.rad(-70))
end

local function makeVeilfallSetpiece(parent)
    makeOverlookDeck(parent, ZONES.Veilfall + Vector3.new(-72, 0, 54), math.rad(35), 16, 10)
    makeRuinWall(parent, ZONES.Veilfall + Vector3.new(72, 0, 34), math.rad(-42), 34, 5)
    makeLumenPylon(parent, ZONES.Veilfall + Vector3.new(-90, 0, -8), 7)
    makeLumenPylon(parent, ZONES.Veilfall + Vector3.new(86, 0, -50), 8)
end

local function makeRuinsApproach(parent)
    for index = 0, 4 do
        local z = -92 + index * 38
        local spread = 55 - index * 5
        makeLumenPylon(parent, ZONES.Ruins + Vector3.new(-spread, 0, z), 8 + index)
        makeLumenPylon(parent, ZONES.Ruins + Vector3.new(spread, 0, z), 8 + index)
    end
    makeRuinWall(parent, ZONES.Ruins + Vector3.new(-92, 0, 54), math.rad(15), 52, 8)
    makeRuinWall(parent, ZONES.Ruins + Vector3.new(108, 0, -24), math.rad(-18), 48, 7)
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
    local gui = Instance.new("BillboardGui")
    gui.Name = "LandmarkLabel"
    gui.Size = UDim2.fromOffset(176, 24)
    gui.MaxDistance = 105
    gui.AlwaysOnTop = false
    gui.Parent = anchor
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(229, 244, 232)
    label.TextStrokeColor3 = Color3.fromRGB(17, 29, 25)
    label.TextStrokeTransparency = 0.2
    label.Font = Enum.Font.GothamBold
    label.TextScaled = false
    label.TextSize = 18
    label.Parent = gui
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

local function makeExplorationTrigger(parent, landmarkId, position, radius)
    local trigger = makePart(
        parent,
        "Explore_" .. landmarkId,
        Vector3.new(2, 0.4, 2),
        CFrame.new(position + Vector3.new(0, 0.2, 0)),
        Enum.Material.SmoothPlastic,
        Color3.new(1, 1, 1)
    )
    trigger.Transparency = 1
    trigger.CanCollide = false
    trigger.CanTouch = false
    trigger.CanQuery = false
    trigger:SetAttribute("LandmarkId", landmarkId)
    trigger:SetAttribute("TriggerRadius", radius or 18)
    CollectionService:AddTag(trigger, "ExplorationTrigger")
    return trigger
end

local function makeMonsterSpawnTrigger(parent, name, position, config)
    local trigger = makePart(
        parent,
        "MonsterSpawnTrigger",
        Vector3.new(2, 0.4, 2),
        CFrame.new(position + Vector3.new(0, 0.2, 0)),
        Enum.Material.SmoothPlastic,
        Color3.new(1, 1, 1)
    )
    trigger.Transparency = 1
    trigger.CanCollide = false
    trigger.CanTouch = false
    trigger.CanQuery = false
    trigger:SetAttribute("TriggerName", name)
    trigger:SetAttribute("MonsterType", config.MonsterType)
    trigger:SetAttribute("SpawnAmount", config.SpawnAmount)
    trigger:SetAttribute("TriggerRadius", config.TriggerRadius)
    trigger:SetAttribute("SpawnRadius", config.SpawnRadius)
    trigger:SetAttribute("MaxAliveMonster", config.MaxAliveMonster)
    trigger:SetAttribute("SpawnDelay", config.SpawnDelay)
    trigger:SetAttribute("RespawnTime", config.RespawnTime)
    CollectionService:AddTag(trigger, "MonsterSpawnTrigger")
    return trigger
end

local function attachNpcPresentation(model, root, head, npcId, displayName, accent)
    local nameplate = Instance.new("BillboardGui")
    nameplate.Name = "NpcNameplate"
    nameplate.Size = UDim2.fromOffset(210, 34)
    nameplate.StudsOffsetWorldSpace = Vector3.new(0, 1.8, 0)
    nameplate.AlwaysOnTop = false
    nameplate.MaxDistance = 48
    nameplate.Parent = head
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 0.18
    label.BackgroundColor3 = Color3.fromRGB(15, 24, 22)
    label.Text = displayName
    label.TextColor3 = Color3.fromRGB(232, 245, 235)
    label.TextStrokeColor3 = Color3.fromRGB(20, 31, 27)
    label.TextStrokeTransparency = 0.3
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = nameplate
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label
    local stroke = Instance.new("UIStroke")
    stroke.Color = accent
    stroke.Transparency = 0.4
    stroke.Parent = label

    WorldObjectService.Register(model, "Npc", npcId)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "TalkPrompt"
    prompt.ActionText = "Talk"
    prompt.ObjectText = displayName
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
    prompt.Parent = root
    prompt.Triggered:Connect(function(player)
        InteractionService.Begin(player, npcId, model)
    end)
end

local NPC_CLEARANCE_OFFSETS = table.freeze({
    Vector3.zero,
    Vector3.new(5, 0, 0),
    Vector3.new(-5, 0, 0),
    Vector3.new(0, 0, 5),
    Vector3.new(0, 0, -5),
    Vector3.new(5, 0, 5),
    Vector3.new(-5, 0, 5),
    Vector3.new(5, 0, -5),
    Vector3.new(-5, 0, -5),
    Vector3.new(10, 0, 0),
    Vector3.new(-10, 0, 0),
    Vector3.new(0, 0, 10),
    Vector3.new(0, 0, -10),
    Vector3.new(10, 0, 10),
    Vector3.new(-10, 0, 10),
    Vector3.new(10, 0, -10),
    Vector3.new(-10, 0, -10),
})

local function staticNpcPositionIsClear(world, position)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { world }
    params.MaxParts = 32
    local parts = Workspace:GetPartBoundsInBox(
        CFrame.new(position + Vector3.new(0, 3.4, 0)),
        Vector3.new(5.6, 7.0, 5.6),
        params
    )
    for _, part in parts do
        if part:GetAttribute("EverLeafCollisionProxy") == true then
            return false
        end
        if part.Name == "HumanoidRootPart" then
            local model = part:FindFirstAncestorOfClass("Model")
            if model and model:FindFirstChildOfClass("Humanoid") then
                return false
            end
        end
    end
    return true
end

local function resolveStaticNpcPosition(world, requestedPosition)
    for _, offset in NPC_CLEARANCE_OFFSETS do
        local candidate = terrainSurfacePosition(requestedPosition + offset, 0)
        if staticNpcPositionIsClear(world, candidate) then
            return candidate
        end
    end
    return terrainSurfacePosition(requestedPosition, 0)
end

local NPC_STYLES = table.freeze({
    lumen_guide = table.freeze({
        Name = "Ilyra · Wayfarer Guide",
        Role = "Guide",
        HairStyle = "long",
        Position = ZONES.Camp + Vector3.new(-5, 0, 16),
        Yaw = math.rad(95),
        Cloth = Color3.fromRGB(48, 91, 80),
        Accent = Color3.fromRGB(105, 231, 194),
    }),
    camp_quartermaster = table.freeze({
        Name = "Orin · Camp Quartermaster",
        Role = "Quartermaster",
        HairStyle = "short",
        Position = ZONES.Camp + Vector3.new(-52, 0, 43),
        Yaw = math.rad(172),
        Cloth = Color3.fromRGB(111, 86, 58),
        Accent = Color3.fromRGB(168, 126, 70),
    }),
    moss_scout = table.freeze({
        Name = "Tovin · Mossglen Scout",
        Role = "Scout",
        HairStyle = "ponytail",
        Position = ZONES.EastLanding + Vector3.new(14, 0, 20),
        Yaw = math.rad(-120),
        Cloth = Color3.fromRGB(61, 91, 68),
        Accent = Color3.fromRGB(95, 146, 88),
    }),
    archive_keeper = table.freeze({
        Name = "Maela · Archive Keeper",
        Role = "Archivist",
        HairStyle = "bun",
        Position = ZONES.Camp + Vector3.new(42, 0, -40),
        Yaw = math.rad(-18),
        Cloth = Color3.fromRGB(76, 70, 103),
        Accent = Color3.fromRGB(144, 113, 169),
    }),
    path_mentor = table.freeze({
        Name = "Seren · Pathkeeper",
        Role = "Mentor",
        HairStyle = "long",
        Position = ZONES.Camp + Vector3.new(-5, 0, -76),
        Yaw = 0,
        Cloth = Color3.fromRGB(55, 81, 70),
        Accent = Color3.fromRGB(91, 164, 123),
    }),
    camp_healer = table.freeze({
        Name = "Eira · Wayfarer Healer",
        Role = "Guide",
        HairStyle = "bun",
        Position = ZONES.Camp + Vector3.new(-96, 0, -43),
        Yaw = math.rad(62),
        Cloth = Color3.fromRGB(82, 116, 93),
        Accent = Color3.fromRGB(126, 224, 171),
    }),
    glowmere_keeper = table.freeze({
        Name = "Sella · Glowmere Keeper",
        Role = "Archivist",
        HairStyle = "long",
        Position = ZONES.Glowmere + Vector3.new(-102, 0, -58),
        Yaw = math.rad(35),
        Cloth = Color3.fromRGB(66, 103, 96),
        Accent = Color3.fromRGB(105, 226, 217),
    }),
    sunmoss_researcher = table.freeze({
        Name = "Aven · Sunmoss Researcher",
        Role = "Archivist",
        HairStyle = "short",
        Position = ZONES.Sunmoss + Vector3.new(-20, 0, 72),
        Yaw = math.rad(18),
        Cloth = Color3.fromRGB(104, 108, 74),
        Accent = Color3.fromRGB(206, 224, 112),
    }),
    veilfall_warden = table.freeze({
        Name = "Neris · Veilfall Warden",
        Role = "Guard",
        HairStyle = "ponytail",
        Position = ZONES.Veilfall + Vector3.new(-84, 0, -50),
        Yaw = math.rad(50),
        Cloth = Color3.fromRGB(62, 93, 91),
        Accent = Color3.fromRGB(116, 220, 229),
    }),
})

local function makeNpc(parent, npcId)
    local style = NPC_STYLES[npcId]
    if not style then
        return nil
    end
    local position = resolveStaticNpcPosition(parent, style.Position)
    local palette = {
        Cloth = style.Cloth,
        DarkCloth = style.Cloth:Lerp(Color3.new(0, 0, 0), 0.24),
        Accent = style.Accent,
        Skin = Color3.fromRGB(211, 176, 143),
        Leather = Color3.fromRGB(84, 58, 39),
        Hair = Color3.fromRGB(78, 52, 39),
        EyeColor = Color3.fromRGB(58, 88, 68),
        Lumen = Color3.fromRGB(111, 234, 185),
        Metal = Color3.fromRGB(158, 128, 69),
    }
    local model, root, head = StylizedNpcFactory.Create(parent, {
        Name = npcId,
        NpcId = npcId,
        Position = position,
        Yaw = style.Yaw,
        Role = style.Role,
        HairStyle = style.HairStyle,
        Build = 0.96,
        HeightScale = 1.0,
        HeadScale = 0.96,
        BodyTypeScale = 0.35,
        ProportionScale = 0.35,
        Palette = palette,
    })
    if model and root and head then
        attachNpcPresentation(model, root, head, npcId, style.Name, style.Accent)
    end
    return model
end

local AMBIENT_RESIDENTS = table.freeze({
    table.freeze({
        Name = "Wayfarer Guard",
        Position = ZONES.Camp + Vector3.new(94, 0, 9),
        Yaw = math.rad(90),
        Role = "Guard",
        HairStyle = "short",
        Cloth = Color3.fromRGB(61, 91, 72),
    }),
    table.freeze({
        Name = "Wayfarer Smith",
        Position = ZONES.Camp + Vector3.new(18, 0, 72),
        Yaw = math.rad(170),
        Role = "Quartermaster",
        HairStyle = "short",
        Cloth = Color3.fromRGB(112, 76, 55),
    }),
    table.freeze({
        Name = "Wayfarer Traveler",
        Position = ZONES.Camp + Vector3.new(-18, 0, 31),
        Yaw = math.rad(-20),
        Role = "Scout",
        HairStyle = "ponytail",
        Cloth = Color3.fromRGB(83, 95, 72),
    }),
    table.freeze({
        Name = "Waystation Courier",
        Position = ZONES.Crossroads + Vector3.new(-54, 0, -44),
        Yaw = math.rad(44),
        Role = "Scout",
        HairStyle = "short",
        Cloth = Color3.fromRGB(75, 97, 77),
    }),
    table.freeze({
        Name = "Eastbridge Guard",
        Position = ZONES.EastLanding + Vector3.new(-56, 0, 8),
        Yaw = math.rad(90),
        Role = "Guard",
        HairStyle = "short",
        Cloth = Color3.fromRGB(64, 88, 69),
    }),
    table.freeze({
        Name = "Eastbridge Medic",
        Position = ZONES.EastLanding + Vector3.new(15, 0, -50),
        Yaw = math.rad(35),
        Role = "Guide",
        HairStyle = "bun",
        Cloth = Color3.fromRGB(92, 116, 96),
    }),
    table.freeze({
        Name = "Mossglen Ranger",
        Position = ZONES.Mossglen + Vector3.new(-112, 0, -76),
        Yaw = math.rad(38),
        Role = "Scout",
        HairStyle = "ponytail",
        Cloth = Color3.fromRGB(63, 98, 68),
    }),
    table.freeze({
        Name = "Sunmoss Keeper",
        Position = ZONES.Sunmoss + Vector3.new(-78, 0, -58),
        Yaw = math.rad(35),
        Role = "Archivist",
        HairStyle = "long",
        Cloth = Color3.fromRGB(104, 108, 75),
    }),
    table.freeze({
        Name = "Wayfarer Apprentice",
        Position = ZONES.Camp + Vector3.new(47, 0, -12),
        Yaw = math.rad(-70),
        Role = "Scout",
        HairStyle = "short",
        Cloth = Color3.fromRGB(70, 96, 78),
    }),
    table.freeze({
        Name = "Wayfarer Cook",
        Position = ZONES.Camp + Vector3.new(48, 0, 54),
        Yaw = math.rad(-150),
        Role = "Quartermaster",
        HairStyle = "bun",
        Cloth = Color3.fromRGB(112, 83, 58),
    }),
    table.freeze({
        Name = "Wayfarer Stablehand",
        Position = ZONES.Camp + Vector3.new(94, 0, 62),
        Yaw = math.rad(-145),
        Role = "Scout",
        HairStyle = "ponytail",
        Cloth = Color3.fromRGB(92, 82, 59),
    }),
    table.freeze({
        Name = "Wayfarer Merchant",
        Position = ZONES.Camp + Vector3.new(62, 0, 77),
        Yaw = math.rad(175),
        Role = "Quartermaster",
        HairStyle = "bun",
        Cloth = Color3.fromRGB(119, 86, 58),
    }),
    table.freeze({
        Name = "Wayfarer Artisan",
        Position = ZONES.Camp + Vector3.new(8, 0, 76),
        Yaw = math.rad(165),
        Role = "Quartermaster",
        HairStyle = "short",
        Cloth = Color3.fromRGB(101, 73, 54),
    }),
    table.freeze({
        Name = "Wayfarer Patrol",
        Position = ZONES.Camp + Vector3.new(108, 0, 8),
        Yaw = math.rad(90),
        Role = "Guard",
        HairStyle = "short",
        Cloth = Color3.fromRGB(58, 88, 69),
    }),
    table.freeze({
        Name = "Wayfarer Scholar",
        Position = ZONES.Camp + Vector3.new(31, 0, -42),
        Yaw = math.rad(180),
        Role = "Archivist",
        HairStyle = "long",
        Cloth = Color3.fromRGB(79, 86, 112),
    }),
    table.freeze({
        Name = "Wayfarer Recruit",
        Position = ZONES.Camp + Vector3.new(70, 0, -4),
        Yaw = math.rad(-90),
        Role = "Guard",
        HairStyle = "ponytail",
        Cloth = Color3.fromRGB(70, 96, 75),
    }),
    table.freeze({
        Name = "Greenway Farmer",
        Position = ZONES.Greenway + Vector3.new(-70, 0, -56),
        Yaw = math.rad(42),
        Role = "Quartermaster",
        HairStyle = "short",
        Cloth = Color3.fromRGB(92, 105, 69),
    }),
    table.freeze({
        Name = "Greenway Militia",
        Position = ZONES.Greenway + Vector3.new(80, 0, 42),
        Yaw = math.rad(-32),
        Role = "Guard",
        HairStyle = "short",
        Cloth = Color3.fromRGB(68, 91, 67),
    }),
    table.freeze({
        Name = "Crossroads Merchant",
        Position = ZONES.Crossroads + Vector3.new(48, 0, -46),
        Yaw = math.rad(-120),
        Role = "Quartermaster",
        HairStyle = "bun",
        Cloth = Color3.fromRGB(108, 82, 59),
    }),
    table.freeze({
        Name = "Crossroads Traveler",
        Position = ZONES.Crossroads + Vector3.new(-15, 0, 42),
        Yaw = math.rad(15),
        Role = "Scout",
        HairStyle = "long",
        Cloth = Color3.fromRGB(77, 96, 75),
    }),
    table.freeze({
        Name = "Glowmere Fisher",
        Position = ZONES.Glowmere + Vector3.new(92, 0, 46),
        Yaw = math.rad(-35),
        Role = "Scout",
        HairStyle = "short",
        Cloth = Color3.fromRGB(73, 103, 94),
    }),
    table.freeze({
        Name = "Eastbridge Quartermaster",
        Position = ZONES.EastLanding + Vector3.new(48, 0, 45),
        Yaw = math.rad(-130),
        Role = "Quartermaster",
        HairStyle = "short",
        Cloth = Color3.fromRGB(105, 82, 58),
    }),
    table.freeze({
        Name = "Eastbridge Patrol",
        Position = ZONES.EastLanding + Vector3.new(-18, 0, -48),
        Yaw = math.rad(180),
        Role = "Guard",
        HairStyle = "ponytail",
        Cloth = Color3.fromRGB(61, 88, 71),
    }),
    table.freeze({
        Name = "Mossglen Hunter",
        Position = ZONES.Mossglen + Vector3.new(118, 0, -88),
        Yaw = math.rad(-44),
        Role = "Scout",
        HairStyle = "short",
        Cloth = Color3.fromRGB(77, 102, 67),
    }),
    table.freeze({
        Name = "Mossglen Fletcher",
        Position = ZONES.Mossglen + Vector3.new(-126, 0, -54),
        Yaw = math.rad(38),
        Role = "Quartermaster",
        HairStyle = "bun",
        Cloth = Color3.fromRGB(92, 83, 58),
    }),
    table.freeze({
        Name = "Sunmoss Surveyor",
        Position = ZONES.Sunmoss + Vector3.new(70, 0, -32),
        Yaw = math.rad(-70),
        Role = "Scout",
        HairStyle = "short",
        Cloth = Color3.fromRGB(93, 101, 71),
    }),
    table.freeze({
        Name = "Veilfall Watcher",
        Position = ZONES.Veilfall + Vector3.new(76, 0, 20),
        Yaw = math.rad(-24),
        Role = "Guard",
        HairStyle = "short",
        Cloth = Color3.fromRGB(60, 87, 84),
    }),
    table.freeze({
        Name = "Proving Attendant",
        Position = ZONES.Proving + Vector3.new(-42, 0, 44),
        Yaw = math.rad(145),
        Role = "Mentor",
        HairStyle = "long",
        Cloth = Color3.fromRGB(71, 96, 81),
    }),
    table.freeze({
        Name = "Proving Aspirant",
        Position = ZONES.Proving + Vector3.new(42, 0, 44),
        Yaw = math.rad(-145),
        Role = "Scout",
        HairStyle = "ponytail",
        Cloth = Color3.fromRGB(85, 94, 72),
    }),
    table.freeze({
        Name = "Proving Spectator",
        Position = ZONES.Proving + Vector3.new(0, 0, 62),
        Yaw = math.rad(180),
        Role = "Guide",
        HairStyle = "short",
        Cloth = Color3.fromRGB(81, 91, 77),
    }),
})

local function makeAmbientResident(parent, spec, index)
    local position = resolveStaticNpcPosition(parent, spec.Position)
    local cloth = spec.Cloth
    local palette = {
        Cloth = cloth,
        DarkCloth = cloth:Lerp(Color3.new(0, 0, 0), 0.24),
        Accent = cloth:Lerp(Color3.fromRGB(117, 235, 192), 0.35),
        Skin = Color3.fromRGB(211, 176, 143),
        Leather = Color3.fromRGB(84, 58, 39),
        Hair = Color3.fromRGB(78, 52, 39),
        EyeColor = Color3.fromRGB(58, 88, 68),
        Lumen = Color3.fromRGB(111, 234, 185),
        Metal = Color3.fromRGB(158, 128, 69),
    }
    local model = StylizedNpcFactory.Create(parent, {
        Name = "AmbientResident" .. index,
        Position = position,
        Yaw = spec.Yaw,
        Role = spec.Role,
        HairStyle = spec.HairStyle,
        Build = 0.94 + (index % 3) * 0.03,
        HeightScale = 0.97 + (index % 2) * 0.04,
        HeadScale = 0.96,
        BodyTypeScale = 0.3,
        ProportionScale = 0.3,
        Palette = palette,
    })
    if model then
        model:SetAttribute("AmbientResident", true)
        model:SetAttribute("DisplayRole", spec.Name)
    end
    return model
end

local function makeAmbientPopulation(parent)
    for index, spec in AMBIENT_RESIDENTS do
        makeAmbientResident(parent, spec, index)
    end
end

local function registerSpawn(parent, name, spawnId, position, yaw)
    local ground = terrainSurfacePosition(position, 0)
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = name
    spawn.Size = Vector3.new(7, 0.5, 7)
    spawn.CFrame = CFrame.new(ground + Vector3.new(0, 3.25, 0)) * CFrame.Angles(0, yaw or 0, 0)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.CanCollide = false
    spawn.CanTouch = false
    spawn.CanQuery = false
    spawn.Transparency = 1
    spawn.Duration = 0
    spawn.Parent = parent
    WorldTravelService.RegisterSpawn(spawnId, spawn)
    return spawn
end

local function makeSpawns(parent)
    registerSpawn(parent, "LumenreachSpawn", "lumenreach_start", ARRIVAL_ORIGIN, math.rad(-90))
    registerSpawn(
        parent,
        "LumenreachEastGateSpawn",
        "lumenreach_east_gate",
        ZONES.Ruins + Vector3.new(-105, 0, -65),
        math.rad(-90)
    )
end

local function decorateWorld(parent)
    -- V5 density pass: tree massing now reads as continuous woodland rather than
    -- isolated rings around empty fields. Combat centers and authored roads stay open.
    placeTreeArc(parent, ZONES.Camp, 175, 145, 40, 28, 332, 1)
    placeTreeArc(parent, ZONES.Greenway, 150, 116, 37, 15, 345, 2)
    placeTreeArc(parent, ZONES.Crossroads, 124, 102, 31, 25, 335, 3)
    placeTreeArc(parent, ZONES.Glowmere, 172, 148, 42, 5, 350, 4)
    placeTreeArc(parent, ZONES.Gravebone, 142, 118, 36, 10, 350, 5)
    placeTreeArc(parent, ZONES.Mossglen, 215, 170, 50, 10, 350, 6)
    placeTreeArc(parent, ZONES.Sunmoss, 165, 134, 36, 15, 345, 7)
    placeTreeArc(parent, ZONES.Veilfall, 170, 145, 39, 30, 330, 8)
    placeTreeArc(parent, ZONES.Ruins, 185, 150, 39, 35, 325, 9)
    placeTreeArc(parent, ZONES.Proving, 132, 118, 31, 20, 340, 10)

    -- Fill the large negative-space belts between progression rooms. These are
    -- part of the generated V5 map itself, not objects layered onto an old map.
    scatterForestBand(parent, Vector3.new(-790, 0, 430), 205, 150, 42, 21, "wet")
    scatterForestBand(parent, Vector3.new(-720, 0, -410), 230, 155, 39, 22, "forest")
    scatterForestBand(parent, Vector3.new(-135, 0, 590), 235, 145, 45, 23, "wet")
    scatterForestBand(parent, Vector3.new(260, 0, 650), 250, 150, 48, 24, "forest")
    scatterForestBand(parent, Vector3.new(680, 0, 610), 235, 155, 45, 25, "forest")
    scatterForestBand(parent, Vector3.new(670, 0, -585), 245, 165, 48, 26, "dry")
    scatterForestBand(parent, Vector3.new(940, 0, -390), 190, 155, 36, 27, "dry")
    scatterForestBand(parent, Vector3.new(965, 0, 390), 180, 145, 33, 28, "forest")

    -- Fill the otherwise barren inter-zone acreage while preserving authored
    -- settlements, roads, encounters, and the Glowmere wetland.
    scatterWorldFiller(parent)

    -- Roads receive low-profile edge dressing so travel has visual rhythm every
    -- few seconds without narrowing the dodge/sprint lane.
    for index, route in ROUTES do
        dressRouteEdges(parent, route, 40 + index)
    end

    -- Zone-specific ground detail makes each biome feel inhabited and materially
    -- different while keeping the encounter floor readable.
    scatterForestBand(parent, ZONES.Greenway, 118, 92, 18, 61, "forest")
    scatterForestBand(parent, ZONES.Glowmere, 135, 112, 22, 62, "wet")
    scatterForestBand(parent, ZONES.Gravebone, 112, 94, 18, 63, "dry")
    scatterForestBand(parent, ZONES.Mossglen, 175, 132, 28, 64, "forest")
    scatterForestBand(parent, ZONES.Sunmoss, 132, 104, 18, 65, "forest")
    scatterForestBand(parent, ZONES.Veilfall, 138, 116, 20, 66, "wet")
    scatterForestBand(parent, ZONES.Ruins, 145, 118, 20, 67, "dry")

    makeWaystone(parent, ZONES.Greenway + Vector3.new(-72, 0, -46), math.rad(70), 0.78)
    makeWaystone(parent, ZONES.Crossroads + Vector3.new(42, 0, -36), math.rad(-60), 0.82)
    makeWaystone(parent, ZONES.Gravebone + Vector3.new(-70, 0, 45), math.rad(55), 0.76)
    makeWaystone(parent, ZONES.Mossglen + Vector3.new(-110, 0, -70), math.rad(45), 0.85)
    makeWaystone(parent, ZONES.Sunmoss + Vector3.new(-75, 0, 38), math.rad(35), 0.82)
    makeWaystone(parent, ZONES.Veilfall + Vector3.new(-80, 0, 55), math.rad(55), 0.78)
    makeWaystone(parent, ZONES.Ruins + Vector3.new(-105, 0, -62), math.rad(70), 0.86)

    makeSign(
        parent,
        ZONES.Crossroads + Vector3.new(-30, 0, 24),
        math.rad(-35),
        "GLOWMERE  ↑   EASTBRIDGE  →"
    )
    makeSign(
        parent,
        ZONES.EastLanding + Vector3.new(22, 0, 16),
        math.rad(-70),
        "MOSSGLEN  ↑   GRAVEBONE  ↓"
    )
    makeSign(
        parent,
        ZONES.Mossglen + Vector3.new(115, 0, -58),
        math.rad(-68),
        "SUNMOSS / SHATTERED ARCH"
    )
    makeSign(parent, ZONES.Gravebone + Vector3.new(82, 0, -20), math.rad(-80), "VEILFALL RAVINE")

    makeLantern(parent, EASTBRIDGE_WEST + Vector3.new(-12, 0, -10), math.rad(90))
    makeLantern(parent, EASTBRIDGE_EAST + Vector3.new(12, 0, 10), math.rad(-90))
    makeLantern(parent, REEDBRIDGE_WEST + Vector3.new(-10, 0, 12), math.rad(90))
    makeLantern(parent, REEDBRIDGE_EAST + Vector3.new(10, 0, -12), math.rad(-90))
end

local function makeZoneContent(parent)
    makeTown(parent)
    makeWorldSettlements(parent)
    makeWorldMMOComposition(parent)
    makeSignatureWorldContent(parent)
    makeLumenreachDistrictNetwork(parent)
    makeWorldMicroSites(parent)

    makeRoadWayhouse(
        parent,
        "EastbridgeScoutOutpost",
        ZONES.EastLanding + Vector3.new(38, 0, 38),
        math.rad(-135),
        Color3.fromRGB(76, 104, 82)
    )
    makeLantern(parent, ZONES.EastLanding + Vector3.new(-18, 0, 24), math.rad(120))
    makeLantern(parent, ZONES.EastLanding + Vector3.new(34, 0, -22), math.rad(-60))

    makeBridge(parent, "Eastbridge", EASTBRIDGE_WEST, EASTBRIDGE_EAST, 18)
    makeBridge(parent, "Reedbridge", REEDBRIDGE_WEST, REEDBRIDGE_EAST, 14)
    makeProvingCircle(parent)
    makeVeilfall(parent)
    makeRuins(parent)
    makeStoneCircle(parent, ZONES.Mossglen + Vector3.new(-10, 0, 100), 46, 16, "MosswardenArena")
    makeStoneCircle(parent, ZONES.Gravebone, 55, 14, "GraveboneWatch")

    -- Every subzone gets one authored identity setpiece. These are intentionally
    -- placed around route/combat edges instead of filling the playable center.
    makeGreenwaySetpiece(parent)
    makeCrossroadsSetpiece(parent)
    makeGlowmereSetpiece(parent)
    makeEastLandingSetpiece(parent)
    makeGraveboneSetpiece(parent)
    makeMossglenSetpiece(parent)
    makeSunmossSetpiece(parent)
    makeVeilfallSetpiece(parent)
    makeRuinsApproach(parent)
end

local function makeLabelsAndZones(parent)
    local definitions = {
        { "wayfarer_camp", "WAYFARER CAMP", ZONES.Camp, 140, 1, 10, "Town" },
        { "greenway_fields", "GREENWAY FIELDS", ZONES.Greenway, 115, 1, 3, "StarterField" },
        {
            "lumenwood_crossroads",
            "LUMENWOOD CROSSROADS",
            ZONES.Crossroads,
            95,
            2,
            4,
            "NavigationHub",
        },
        { "glowmere_wetland", "GLOWMERE WETLAND", ZONES.Glowmere, 130, 2, 5, "ExplorationLoop" },
        {
            "eastbridge_landing",
            "EASTBRIDGE LANDING",
            ZONES.EastLanding,
            72,
            3,
            7,
            "FieldOutpost",
        },
        { "gravebone_watch", "GRAVEBONE WATCH", ZONES.Gravebone, 105, 3, 7, "RuinsCombat" },
        { "mossglen_valley", "MOSSGLEN VALLEY", ZONES.Mossglen, 165, 4, 7, "PartyField" },
        { "sunmoss_ridge", "SUNMOSS RIDGE", ZONES.Sunmoss, 120, 6, 9, "HighlandLoop" },
        { "veilfall_ravine", "VEILFALL RAVINE", ZONES.Veilfall, 125, 7, 9, "DangerLoop" },
        {
            "shattered_lumen_arch",
            "SHATTERED LUMEN ARCH",
            ZONES.Ruins,
            145,
            8,
            10,
            "RegionCapstone",
        },
        {
            "wayfarer_proving_circle",
            "WAYFARER PROVING CIRCLE",
            ZONES.Proving,
            82,
            7,
            10,
            "Advancement",
        },
    }
    for _, definition in definitions do
        makeZoneMarker(
            parent,
            definition[1],
            definition[2],
            definition[3],
            definition[4],
            definition[5],
            definition[6],
            definition[7]
        )
        makeLandmarkLabel(parent, definition[3] + Vector3.new(0, 22, 0), definition[2])
    end
end

local function makeExplorationContent(parent)
    makeExplorationTrigger(parent, "lumenwood_crossroads", ZONES.Crossroads, 28)
    makeExplorationTrigger(parent, "glowmere_pool", ZONES.Glowmere + Vector3.new(20, 0, 18), 34)
    makeExplorationTrigger(
        parent,
        "eastbridge_crossing",
        (EASTBRIDGE_WEST + EASTBRIDGE_EAST) * 0.5,
        26
    )
    makeExplorationTrigger(parent, "gravebone_watch", ZONES.Gravebone, 34)
    makeExplorationTrigger(parent, "mossglen_valley", ZONES.Mossglen, 42)
    makeExplorationTrigger(parent, "wayfarer_proving_circle", ZONES.Proving, 30)
    makeExplorationTrigger(parent, "veilfall_cascade", ZONES.Veilfall + Vector3.new(-22, 0, 20), 32)
    makeExplorationTrigger(parent, "sunmoss_overlook", ZONES.Sunmoss, 36)
    makeExplorationTrigger(parent, "shattered_lumen_arch", ZONES.Ruins, 42)
    makeExplorationTrigger(parent, "greenway_crofts", Vector3.new(-785, 0, -102), 26)
    makeExplorationTrigger(parent, "glowmere_drybank", Vector3.new(-535, 0, 350), 28)
    makeExplorationTrigger(parent, "eastbridge_south_ward", Vector3.new(-80, 0, 178), 28)
    makeExplorationTrigger(parent, "mossglen_woodcamp", Vector3.new(235, 0, 242), 26)
    makeExplorationTrigger(parent, "shattered_forward_camp", Vector3.new(555, 0, 220), 28)
end

local function normalizeGeneratedCollisions(world)
    -- V11 rule: generated render geometry never owns movement collision.
    -- Every physical object is represented by an explicit, simple proxy created
    -- by its builder. This eliminates mesh/trim/roof/prop snagging and also makes
    -- missing collision auditable instead of depending on Part defaults/names.
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

local function makeEncounterContent(parent)
    EnemySpawnerService.Spawn(
        "training_dummy",
        TRAINING_ORIGIN,
        parent,
        { GroundToTerrain = true, GroundClearance = 0.1 }
    )

    makeMonsterSpawnTrigger(parent, "GreenwayMosslings", ZONES.Greenway + Vector3.new(0, 0, 72), {
        MonsterType = "LumenMossling",
        SpawnAmount = 6,
        TriggerRadius = 44,
        SpawnRadius = 22,
        MaxAliveMonster = 6,
        SpawnDelay = 0.24,
        RespawnTime = 18,
    })
    makeMonsterSpawnTrigger(parent, "GlowmereSlimes", ZONES.Glowmere + Vector3.new(-90, 0, 70), {
        MonsterType = "Slime",
        SpawnAmount = 6,
        TriggerRadius = 48,
        SpawnRadius = 24,
        MaxAliveMonster = 6,
        SpawnDelay = 0.26,
        RespawnTime = 27,
    })
    makeMonsterSpawnTrigger(parent, "RoyalGlowcapRare", ZONES.Glowmere + Vector3.new(-62, 0, 48), {
        MonsterType = "RoyalGlowcap",
        SpawnAmount = 1,
        TriggerRadius = 30,
        SpawnRadius = 8,
        MaxAliveMonster = 1,
        SpawnDelay = 0,
        RespawnTime = 85,
    })
    makeMonsterSpawnTrigger(
        parent,
        "GraveboneSkeletons",
        ZONES.Gravebone + Vector3.new(70, 0, 70),
        {
            MonsterType = "Skeleton",
            SpawnAmount = 6,
            TriggerRadius = 44,
            SpawnRadius = 24,
            MaxAliveMonster = 6,
            SpawnDelay = 0.24,
            RespawnTime = 28,
        }
    )
    makeMonsterSpawnTrigger(
        parent,
        "GraveboneCaptainRare",
        ZONES.Gravebone + Vector3.new(-60, 0, -60),
        {
            MonsterType = "GraveboneCaptain",
            SpawnAmount = 1,
            TriggerRadius = 34,
            SpawnRadius = 9,
            MaxAliveMonster = 1,
            SpawnDelay = 0,
            RespawnTime = 90,
        }
    )
    makeMonsterSpawnTrigger(
        parent,
        "MossglenRidgebeaks",
        ZONES.Mossglen + Vector3.new(-20, 0, -90),
        {
            MonsterType = "PecoPeco",
            SpawnAmount = 7,
            TriggerRadius = 50,
            SpawnRadius = 24,
            MaxAliveMonster = 7,
            SpawnDelay = 0.22,
            RespawnTime = 27,
        }
    )
    makeMonsterSpawnTrigger(parent, "BramblebackTrail", BRAMBLE_ORIGIN, {
        MonsterType = "Brambleback",
        SpawnAmount = 5,
        TriggerRadius = 46,
        SpawnRadius = 23,
        MaxAliveMonster = 5,
        SpawnDelay = 0.25,
        RespawnTime = 32,
    })
    makeMonsterSpawnTrigger(
        parent,
        "MosswardenFieldBoss",
        ZONES.Mossglen + Vector3.new(-10, 0, 100),
        {
            MonsterType = "Mosswarden",
            SpawnAmount = 1,
            TriggerRadius = 55,
            SpawnRadius = 10,
            MaxAliveMonster = 1,
            SpawnDelay = 0,
            RespawnTime = 180,
        }
    )
    makeMonsterSpawnTrigger(parent, "VeilfallWisps", ZONES.Veilfall + Vector3.new(0, 0, -80), {
        MonsterType = "LumenWisp",
        SpawnAmount = 6,
        TriggerRadius = 48,
        SpawnRadius = 23,
        MaxAliveMonster = 6,
        SpawnDelay = 0.22,
        RespawnTime = 30,
    })
    makeMonsterSpawnTrigger(
        parent,
        "ShatteredArchSkeletons",
        ZONES.Ruins + Vector3.new(88, 0, 55),
        {
            MonsterType = "Skeleton",
            SpawnAmount = 7,
            TriggerRadius = 50,
            SpawnRadius = 26,
            MaxAliveMonster = 7,
            SpawnDelay = 0.22,
            RespawnTime = 30,
        }
    )

    -- Inter-zone activity pockets prevent travel from becoming dead acreage.
    makeMonsterSpawnTrigger(parent, "OldMileMosslings", Vector3.new(-650, 0, 132), {
        MonsterType = "LumenMossling",
        SpawnAmount = 4,
        TriggerRadius = 34,
        SpawnRadius = 18,
        MaxAliveMonster = 4,
        SpawnDelay = 0.2,
        RespawnTime = 22,
    })
    makeMonsterSpawnTrigger(parent, "DrybankSlimes", Vector3.new(-500, 0, 315), {
        MonsterType = "Slime",
        SpawnAmount = 4,
        TriggerRadius = 36,
        SpawnRadius = 18,
        MaxAliveMonster = 4,
        SpawnDelay = 0.22,
        RespawnTime = 26,
    })
    makeMonsterSpawnTrigger(parent, "GraveboneRoadStragglers", Vector3.new(55, 0, -145), {
        MonsterType = "Skeleton",
        SpawnAmount = 4,
        TriggerRadius = 36,
        SpawnRadius = 18,
        MaxAliveMonster = 4,
        SpawnDelay = 0.22,
        RespawnTime = 30,
    })
    makeMonsterSpawnTrigger(parent, "MossglenTrailRidgebeaks", Vector3.new(78, 0, 260), {
        MonsterType = "PecoPeco",
        SpawnAmount = 4,
        TriggerRadius = 38,
        SpawnRadius = 19,
        MaxAliveMonster = 4,
        SpawnDelay = 0.22,
        RespawnTime = 27,
    })
    makeMonsterSpawnTrigger(parent, "SunmossAscentWisps", Vector3.new(360, 0, 385), {
        MonsterType = "LumenWisp",
        SpawnAmount = 4,
        TriggerRadius = 38,
        SpawnRadius = 18,
        MaxAliveMonster = 4,
        SpawnDelay = 0.22,
        RespawnTime = 30,
    })
    makeMonsterSpawnTrigger(parent, "ShatteredRoadSkeletons", Vector3.new(600, 0, 145), {
        MonsterType = "Skeleton",
        SpawnAmount = 5,
        TriggerRadius = 40,
        SpawnRadius = 20,
        MaxAliveMonster = 5,
        SpawnDelay = 0.22,
        RespawnTime = 30,
    })
end

function LumenreachWorldService.Init()
    clearOldGeneratedContent()
    buildTerrain()

    local world = Instance.new("Model")
    world.Name = GENERATED_NAME
    world:SetAttribute("RegionId", "lumenreach")
    world:SetAttribute("WorldDesignVersion", WORLD_DESIGN_VERSION)
    world:SetAttribute("TerrainFirstMMOLayout", true)
    world:SetAttribute("BespokeLumenreachArchitecture", true)
    world.Parent = Workspace

    makeZoneContent(world)
    decorateWorld(world)
    makeLabelsAndZones(world)
    makeExplorationContent(world)
    makeSpawns(world)
    normalizeGeneratedCollisions(world)

    for npcId in NPC_STYLES do
        makeNpc(world, npcId)
    end
    makeAmbientPopulation(world)

    makeEncounterContent(world)
end

return LumenreachWorldService
