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
local WORLD_WIDTH = 2350
local WORLD_DEPTH = 1800
local WORLD_DESIGN_VERSION = 7

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
    wedge.Parent = parent
    return wedge
end

local function makeCollisionProxy(parent, name, size, cframe)
    local part =
        makePart(parent, name, size, cframe, Enum.Material.SmoothPlastic, Color3.new(0, 0, 0))
    part.Transparency = 1
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part:SetAttribute("EverLeafCollisionProxy", true)
    return part
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
    for index = 1, #points - 1 do
        local a = points[index]
        local b = points[index + 1]
        local flatDelta = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
        if flatDelta.Magnitude > 1 then
            local midpoint = Vector3.new((a.X + b.X) * 0.5, 0, (a.Z + b.Z) * 0.5)
            local frame = CFrame.lookAt(midpoint, midpoint + flatDelta.Unit)
            local length = flatDelta.Magnitude + width * 0.7
            local variation = 0.9 + ((index * 31) % 5) * 0.035
            local ridgeHeight = height * variation

            terrain:FillBlock(
                frame + Vector3.new(0, ridgeHeight * 0.30, 0),
                Vector3.new(width, ridgeHeight * 0.60, length),
                material
            )
            terrain:FillBlock(
                frame + Vector3.new(0, ridgeHeight * 0.59, 0),
                Vector3.new(width * 0.72, ridgeHeight * 0.38, length * 0.91),
                if index % 3 == 0 then Enum.Material.Rock else material
            )
            terrain:FillBlock(
                frame + Vector3.new(0, ridgeHeight * 0.82, 0),
                Vector3.new(width * 0.42, ridgeHeight * 0.25, length * 0.76),
                Enum.Material.Rock
            )

            -- Small shoulder fills soften the stepped ridge without returning
            -- to the giant spherical blobs that read as stacked green balls.
            for shoulder = -1, 1, 2 do
                local shoulderPosition = midpoint
                    + frame.RightVector * shoulder * width * 0.27
                    + Vector3.new(0, ridgeHeight * 0.32, 0)
                terrain:FillBall(shoulderPosition, width * 0.22, material)
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
    for x = -1140, 1080, 120 do
        table.insert(north, Vector3.new(x, 25, 835 + ((x / 120) % 3) * 18))
        table.insert(south, Vector3.new(x, 20, -795 - ((x / 120) % 4) * 13))
    end
    local west = {}
    for z = -680, 720, 120 do
        table.insert(west, Vector3.new(-1160, 18, z))
    end
    local east = {}
    for z = -680, 720, 115 do
        table.insert(east, Vector3.new(1085, 28, z))
    end
    fillMountainRidge(north, 92, 102, Enum.Material.Grass)
    fillMountainRidge(south, 96, 106, Enum.Material.Grass)
    fillMountainRidge(west, 98, 108, Enum.Material.Grass)
    fillMountainRidge(east, 100, 116, Enum.Material.Rock)

    -- Internal terrain ridges divide rooms without arbitrary invisible walls.
    fillMountainRidge({
        Vector3.new(-830, 18, 270),
        Vector3.new(-760, 22, 350),
        Vector3.new(-680, 26, 430),
        Vector3.new(-600, 25, 520),
    }, 68, 72, Enum.Material.Grass)
    fillMountainRidge({
        Vector3.new(245, 8, -105),
        Vector3.new(330, 5, -135),
        Vector3.new(430, 8, -135),
        Vector3.new(540, 13, -110),
        Vector3.new(650, 18, -75),
    }, 62, 68, Enum.Material.Rock)

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
    makeCollisionProxy(
        placed,
        "TreeTrunkCollision",
        Vector3.new(3.2, math.clamp(targetHeight * 0.38, 7, 13), 3.2),
        CFrame.new(ground + Vector3.new(0, math.clamp(targetHeight * 0.19, 3.5, 6.5), 0))
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
    end
    return placed
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
            local samples = math.max(1, math.floor(length / 58))
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
        "SignCollision",
        Vector3.new(0.8, 6.3, 0.8),
        base * CFrame.new(0, 3.15, 0)
    )
    return model
end

local function makeBuilding(parent, name, center, width, depth, height, yaw, accent)
    local ground = terrainSurfacePosition(center, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    local timber = Color3.fromRGB(76, 55, 38)
    local wallColor = accent or Color3.fromRGB(116, 121, 101)
    local roofColor = Color3.fromRGB(45, 66, 58)

    makePart(
        model,
        "StoneFoundation",
        Vector3.new(width + 1.6, 0.8, depth + 1.6),
        base * CFrame.new(0, 0.4, 0),
        Enum.Material.Slate,
        Color3.fromRGB(74, 82, 78)
    )
    makePart(
        model,
        "Floor",
        Vector3.new(width, 0.8, depth),
        base * CFrame.new(0, 0.8, 0),
        Enum.Material.WoodPlanks,
        timber
    )

    local doorWidth = math.min(7, width * 0.28)
    local sideWidth = (width - doorWidth) * 0.5
    local wallSpecs = {
        { Vector3.new(width, height, 1), Vector3.new(0, height * 0.5 + 0.8, depth * 0.5) },
        { Vector3.new(1, height, depth), Vector3.new(-width * 0.5, height * 0.5 + 0.8, 0) },
        { Vector3.new(1, height, depth), Vector3.new(width * 0.5, height * 0.5 + 0.8, 0) },
        {
            Vector3.new(sideWidth, height, 1),
            Vector3.new(-(doorWidth + sideWidth) * 0.5, height * 0.5 + 0.8, -depth * 0.5),
        },
        {
            Vector3.new(sideWidth, height, 1),
            Vector3.new((doorWidth + sideWidth) * 0.5, height * 0.5 + 0.8, -depth * 0.5),
        },
    }
    for index, spec in wallSpecs do
        makePart(
            model,
            "Wall" .. index,
            spec[1],
            base * CFrame.new(spec[2]),
            Enum.Material.WoodPlanks,
            wallColor
        )
    end

    for _, x in { -1, 1 } do
        for _, z in { -1, 1 } do
            makePart(
                model,
                "CornerPost",
                Vector3.new(1.05, height + 1.2, 1.05),
                base * CFrame.new(x * width * 0.5, height * 0.5 + 0.8, z * depth * 0.5),
                Enum.Material.Wood,
                timber
            )
        end
    end

    for _, side in { -1, 1 } do
        local window = makePart(
            model,
            "Window",
            Vector3.new(4.5, 3.5, 0.25),
            base * CFrame.new(side * width * 0.27, height * 0.56 + 0.8, -depth * 0.505),
            Enum.Material.Glass,
            Color3.fromRGB(129, 207, 183)
        )
        window.Transparency = 0.28
        window.CanCollide = false
        window.CanTouch = false
        window.CanQuery = false
    end

    -- Derive the roof from the actual span so both panels meet at one ridge.
    local pitch = math.rad(18)
    local halfRun = width * 0.5 + 1.4
    local slopeLength = halfRun / math.cos(pitch)
    local rise = halfRun * math.tan(pitch)
    local eaveY = height + 1.0
    for _, side in { -1, 1 } do
        local roof = makePart(
            model,
            "Roof",
            Vector3.new(slopeLength + 0.15, 0.72, depth + 2.4),
            base
                * CFrame.new(side * halfRun * 0.5, eaveY + rise * 0.5, 0)
                * CFrame.Angles(0, 0, -side * pitch),
            Enum.Material.WoodPlanks,
            roofColor
        )
        roof.CanCollide = false
        roof.CanTouch = false
        roof.CanQuery = false
    end

    local ridge = makePart(
        model,
        "RoofRidge",
        Vector3.new(0.9, 0.9, depth + 2.6),
        base * CFrame.new(0, eaveY + rise, 0),
        Enum.Material.Wood,
        timber
    )
    ridge.CanCollide = false
    ridge.CanTouch = false
    ridge.CanQuery = false

    local lintel = makePart(
        model,
        "DoorLintel",
        Vector3.new(doorWidth, 0.7, 1.2),
        base * CFrame.new(0, height + 0.25, -depth * 0.5 - 0.05),
        Enum.Material.Wood,
        timber
    )
    lintel.CanCollide = false
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
    counter.CanCollide = true
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
    makeBench(model, position + Vector3.new(0, 0, 1), yaw or 0)
    return model
end

local function makeStoneShrine(parent, name, position, yaw, accent)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    local stone = Color3.fromRGB(78, 88, 83)
    makePart(
        model,
        "ShrineBase",
        Vector3.new(14, 1.2, 10),
        base * CFrame.new(0, 0.6, 0),
        Enum.Material.Slate,
        stone
    )
    for _, x in { -4.8, 4.8 } do
        makePart(
            model,
            "ShrinePillar",
            Vector3.new(2.2, 9.5, 2.2),
            base * CFrame.new(x, 5.4, 0),
            Enum.Material.Slate,
            stone
        )
    end
    local crown = makePart(
        model,
        "ShrineCrown",
        Vector3.new(13, 2.0, 3.0),
        base * CFrame.new(0, 10.2, 0),
        Enum.Material.Slate,
        Color3.fromRGB(65, 76, 72)
    )
    crown.CanCollide = false
    local lumen = makePart(
        model,
        "ShrineLumen",
        Vector3.new(2.4, 5.6, 0.6),
        base * CFrame.new(0, 5.2, -1.8),
        Enum.Material.Neon,
        accent or Color3.fromRGB(104, 231, 188)
    )
    lumen.CanCollide = false
    lumen.CanTouch = false
    lumen.CanQuery = false
    local light = Instance.new("PointLight")
    light.Color = lumen.Color
    light.Brightness = 1.1
    light.Range = 18
    light.Parent = lumen
    return model
end

local function makeRuinedHall(parent, name, center, width, depth, yaw)
    local ground = terrainSurfacePosition(center, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    local stone = Color3.fromRGB(72, 80, 78)
    makePart(
        model,
        "RuinFloor",
        Vector3.new(width, 0.8, depth),
        base * CFrame.new(0, 0.4, 0),
        Enum.Material.Slate,
        stone
    )
    makeRuinWall(model, center + (base.RightVector * (-width * 0.44)), yaw + math.rad(90), depth, 8)
    makeRuinWall(
        model,
        center + (base.RightVector * (width * 0.44)),
        yaw + math.rad(90),
        depth * 0.72,
        7
    )
    makeRuinWall(model, center + (base.LookVector * (depth * 0.44)), yaw, width * 0.8, 9)
    for _, offset in
        { Vector3.new(-width * 0.28, 0, -depth * 0.2), Vector3.new(width * 0.23, 0, depth * 0.14) }
    do
        local pillarGround = terrainSurfacePosition(center + base:VectorToWorldSpace(offset), 0)
        makePart(
            model,
            "BrokenPillar",
            Vector3.new(3, 8, 3),
            CFrame.new(pillarGround + Vector3.new(0, 4, 0)),
            Enum.Material.Slate,
            stone
        )
    end
    return model
end

local function makeGatehouse(parent, name, position, yaw, width)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    width = width or 28
    local stone = Color3.fromRGB(73, 82, 79)
    for _, side in { -1, 1 } do
        makePart(
            model,
            "GateTower",
            Vector3.new(8, 17, 10),
            base * CFrame.new(side * width * 0.5, 8.5, 0),
            Enum.Material.Slate,
            stone
        )
    end
    local beam = makePart(
        model,
        "GateLintel",
        Vector3.new(width - 8, 4, 8),
        base * CFrame.new(0, 15, 0),
        Enum.Material.Slate,
        Color3.fromRGB(62, 72, 69)
    )
    beam.CanCollide = false
    return model
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
    return model
end

local function makeForgeYard(parent, name, position, yaw)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    local pad = makePart(
        model,
        "ForgePad",
        Vector3.new(22, 0.8, 17),
        base * CFrame.new(0, 0.4, 0),
        Enum.Material.Slate,
        SIGNATURE.SlateDark
    )
    pad.CanCollide = false
    local forge = makePart(
        model,
        "ForgeBody",
        Vector3.new(7, 5, 6),
        base * CFrame.new(-4.5, 2.8, 1.2),
        Enum.Material.Brick,
        Color3.fromRGB(74, 68, 61)
    )
    forge.CanCollide = false
    local mouth = makePart(
        model,
        "ForgeMouth",
        Vector3.new(3.4, 2.2, 0.5),
        base * CFrame.new(-4.5, 2.6, -1.9),
        Enum.Material.Neon,
        Color3.fromRGB(255, 147, 66)
    )
    mouth.CanCollide = false
    mouth.CanTouch = false
    mouth.CanQuery = false
    local chimney = makePart(
        model,
        "ForgeChimney",
        Vector3.new(2.8, 10, 2.8),
        base * CFrame.new(-4.5, 8.0, 1.2),
        Enum.Material.Brick,
        Color3.fromRGB(65, 62, 58)
    )
    chimney.CanCollide = false
    local anvil = makePart(
        model,
        "ForgeAnvil",
        Vector3.new(4.2, 1.2, 2.0),
        base * CFrame.new(4.8, 3.0, -1.0),
        Enum.Material.Metal,
        Color3.fromRGB(84, 91, 91)
    )
    anvil.CanCollide = false
    local stand = makePart(
        model,
        "AnvilStand",
        Vector3.new(1.8, 2.4, 1.8),
        base * CFrame.new(4.8, 1.2, -1.0),
        Enum.Material.Wood,
        SIGNATURE.Timber
    )
    stand.CanCollide = false
    for _, x in { -8.5, 8.5 } do
        local post = makePart(
            model,
            "ForgeAwningPost",
            Vector3.new(0.6, 7.2, 0.6),
            base * CFrame.new(x, 3.6, 6.1),
            Enum.Material.Wood,
            SIGNATURE.Timber
        )
        post.CanCollide = false
    end
    local awning = makePart(
        model,
        "ForgeAwning",
        Vector3.new(19, 0.5, 6.5),
        base * CFrame.new(0, 7.0, 5.7) * CFrame.Angles(math.rad(-7), 0, 0),
        Enum.Material.Fabric,
        Color3.fromRGB(124, 83, 57)
    )
    awning.CanCollide = false
    awning.CanTouch = false
    awning.CanQuery = false
    return model
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

local function makeGlowmereStiltHouse(parent, name, position, yaw, accent)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    local floorY = 5.6
    for _, x in { -6.5, 6.5 } do
        for _, z in { -5.0, 5.0 } do
            local stilt = makePart(
                model,
                "Stilt",
                Vector3.new(0.9, 8.0, 0.9),
                base * CFrame.new(x, 4.0, z),
                Enum.Material.Wood,
                SIGNATURE.Timber
            )
            stilt.CanCollide = false
        end
    end
    makePart(
        model,
        "StiltFloor",
        Vector3.new(15.5, 0.8, 12.5),
        base * CFrame.new(0, floorY, 0),
        Enum.Material.WoodPlanks,
        SIGNATURE.TimberLight
    )
    makePart(
        model,
        "StiltBackWall",
        Vector3.new(15.5, 7.0, 0.8),
        base * CFrame.new(0, floorY + 3.5, 5.8),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(86, 112, 92)
    )
    for _, x in { -7.0, 7.0 } do
        makePart(
            model,
            "StiltSideWall",
            Vector3.new(0.8, 7.0, 12.0),
            base * CFrame.new(x, floorY + 3.5, 0),
            Enum.Material.WoodPlanks,
            Color3.fromRGB(86, 112, 92)
        )
    end
    for _, side in { -1, 1 } do
        local roof = makePart(
            model,
            "StiltRoof",
            Vector3.new(9.0, 0.65, 14.5),
            base
                * CFrame.new(side * 3.9, floorY + 8.7, 0)
                * CFrame.Angles(0, 0, math.rad(-side * 20)),
            Enum.Material.WoodPlanks,
            Color3.fromRGB(44, 67, 59)
        )
        roof.CanCollide = false
    end
    local porch = makePart(
        model,
        "StiltPorch",
        Vector3.new(10, 0.7, 5.5),
        base * CFrame.new(0, floorY, -8.3),
        Enum.Material.WoodPlanks,
        SIGNATURE.TimberLight
    )
    porch.CanCollide = false
    makeSignatureCrystal(
        model,
        "WetlandLantern",
        base * CFrame.new(0, floorY + 0.4, -10.1),
        2.2,
        accent or Color3.fromRGB(112, 226, 211)
    )
    return model
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
    local skiff = makePart(
        model,
        "WayfarerSkiff",
        Vector3.new(5.2, 1.2, 13.0),
        base * CFrame.new(8.2, 0.7, -length * 0.55) * CFrame.Angles(math.rad(4), 0, 0),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(92, 68, 45)
    )
    skiff.CanCollide = false
    return model
end

local function makeGraveboneMausoleum(parent, name, position, yaw)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    makePart(
        model,
        "MausoleumBase",
        Vector3.new(18, 1.4, 16),
        base * CFrame.new(0, 0.7, 0),
        Enum.Material.Slate,
        SIGNATURE.SlateDark
    )
    for _, x in { -7, 7 } do
        makePart(
            model,
            "MausoleumPillar",
            Vector3.new(3.2, 11, 3.2),
            base * CFrame.new(x, 6.1, -5.5),
            Enum.Material.Slate,
            SIGNATURE.Slate
        )
    end
    makePart(
        model,
        "MausoleumBack",
        Vector3.new(17, 11, 2.2),
        base * CFrame.new(0, 6.1, 6.2),
        Enum.Material.Slate,
        SIGNATURE.Slate
    )
    local cap = makeWedge(
        model,
        "MausoleumCrown",
        Vector3.new(20, 5.0, 17.5),
        base * CFrame.new(0, 13.2, 0) * CFrame.Angles(0, math.rad(90), 0),
        Enum.Material.Slate,
        Color3.fromRGB(58, 67, 65)
    )
    cap.CanCollide = false
    makeSignatureCrystal(
        model,
        "MemorialLumen",
        base * CFrame.new(0, 2.2, -6.6),
        4.6,
        Color3.fromRGB(128, 196, 170)
    )
    return model
end

local function makeMossglenRangerHall(parent, name, position, yaw)
    local ground = terrainSurfacePosition(position, 0)
    local model = makeBuilding(parent, name, position, 40, 28, 10, yaw, Color3.fromRGB(73, 108, 78))
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    local porch = makePart(
        model,
        "RangerPorch",
        Vector3.new(28, 0.7, 8),
        base * CFrame.new(0, 0.8, -18),
        Enum.Material.WoodPlanks,
        SIGNATURE.TimberLight
    )
    porch.CanCollide = false
    for _, x in { -10, 0, 10 } do
        local rack = makePart(
            model,
            "RangerRack",
            Vector3.new(0.6, 6.0, 0.6),
            base * CFrame.new(x, 3.0, -21),
            Enum.Material.Wood,
            SIGNATURE.Timber
        )
        rack.CanCollide = false
        local bow = makePart(
            model,
            "RangerBow",
            Vector3.new(0.28, 4.8, 0.28),
            base * CFrame.new(x + 0.6, 3.3, -21.4) * CFrame.Angles(0, 0, math.rad(18)),
            Enum.Material.Wood,
            Color3.fromRGB(117, 82, 48)
        )
        bow.CanCollide = false
    end
    return model
end

local function makeSunmossObservatory(parent, name, position, yaw)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    makePart(
        model,
        "ObservatoryBase",
        Vector3.new(24, 1.2, 24),
        base * CFrame.new(0, 0.6, 0),
        Enum.Material.Slate,
        SIGNATURE.SlateDark
    )
    for _, x in { -8, 8 } do
        for _, z in { -8, 8 } do
            makePart(
                model,
                "ObservatoryPillar",
                Vector3.new(2.0, 15, 2.0),
                base * CFrame.new(x, 7.5, z),
                Enum.Material.Slate,
                SIGNATURE.Slate
            )
        end
    end
    makePart(
        model,
        "ObservatoryDeck",
        Vector3.new(26, 1.0, 26),
        base * CFrame.new(0, 15.2, 0),
        Enum.Material.WoodPlanks,
        SIGNATURE.TimberLight
    )
    local axis = makePart(
        model,
        "LumenScopeAxis",
        Vector3.new(2.0, 9.0, 2.0),
        base * CFrame.new(0, 20.1, 0) * CFrame.Angles(math.rad(58), 0, 0),
        Enum.Material.Metal,
        SIGNATURE.Bronze
    )
    axis.CanCollide = false
    local scope = makePart(
        model,
        "LumenScope",
        Vector3.new(5.0, 5.0, 14.0),
        base * CFrame.new(0, 24.0, -2.8) * CFrame.Angles(math.rad(-32), 0, 0),
        Enum.Material.Metal,
        Color3.fromRGB(95, 105, 103)
    )
    scope.Shape = Enum.PartType.Cylinder
    scope.CanCollide = false
    makeSignatureCrystal(
        model,
        "ScopeLens",
        base * CFrame.new(0, 27.4, -8.2),
        3.4,
        Color3.fromRGB(207, 225, 112)
    )
    return model
end

local function makeVeilfallSanctuary(parent, name, position, yaw)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    makePart(
        model,
        "SanctuaryFloor",
        Vector3.new(32, 1.0, 26),
        base * CFrame.new(0, 0.5, 0),
        Enum.Material.Slate,
        Color3.fromRGB(67, 80, 78)
    )
    for _, x in { -12, 0, 12 } do
        for _, z in { -9, 9 } do
            local pillar = makePart(
                model,
                "SanctuaryPillar",
                Vector3.new(2.2, 13, 2.2),
                base * CFrame.new(x, 6.5, z),
                Enum.Material.Slate,
                SIGNATURE.Slate
            )
            pillar.CanCollide = false
        end
    end
    makePart(
        model,
        "SanctuaryBridgeBeam",
        Vector3.new(31, 2.0, 3.0),
        base * CFrame.new(0, 12.0, 9),
        Enum.Material.Slate,
        SIGNATURE.SlateDark
    ).CanCollide =
        false
    for _, x in { -8, 0, 8 } do
        makeSignatureCrystal(
            model,
            "SanctuaryLumen",
            base * CFrame.new(x, 1.0, 0),
            7.5 - math.abs(x) * 0.2,
            Color3.fromRGB(115, 226, 225)
        )
    end
    return model
end

local function makeShatteredFortressTower(parent, name, position, yaw, brokenSide)
    local ground = terrainSurfacePosition(position, 0)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local base = CFrame.new(ground) * CFrame.Angles(0, yaw or 0, 0)
    makePart(
        model,
        "FortressTowerCore",
        Vector3.new(18, 28, 18),
        base * CFrame.new(0, 14, 0),
        Enum.Material.Slate,
        Color3.fromRGB(68, 77, 75)
    )
    makePart(
        model,
        "FortressTowerBand",
        Vector3.new(20, 2.0, 20),
        base * CFrame.new(0, 20, 0),
        Enum.Material.Slate,
        Color3.fromRGB(54, 63, 61)
    )
    for _, x in { -7, 0, 7 } do
        for _, z in { -8.5, 8.5 } do
            if not (brokenSide and x == 7 and z > 0) then
                makePart(
                    model,
                    "FortressMerlon",
                    Vector3.new(4.0, 5.0, 2.5),
                    base * CFrame.new(x, 30.5, z),
                    Enum.Material.Slate,
                    SIGNATURE.SlateDark
                )
            end
        end
    end
    for _, z in { -7, 0, 7 } do
        for _, x in { -8.5, 8.5 } do
            if not (brokenSide and z == -7 and x < 0) then
                makePart(
                    model,
                    "FortressMerlon",
                    Vector3.new(2.5, 5.0, 4.0),
                    base * CFrame.new(x, 30.5, z),
                    Enum.Material.Slate,
                    SIGNATURE.SlateDark
                )
            end
        end
    end
    return model
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

local function makeTownExpansion(parent)
    local camp = ZONES.Camp
    makeBuilding(
        parent,
        "WayfarerHealerLodge",
        camp + Vector3.new(-105, 0, -54),
        28,
        22,
        9,
        math.rad(62),
        Color3.fromRGB(96, 124, 101)
    )
    makeBuilding(
        parent,
        "WayfarerCraftHall",
        camp + Vector3.new(8, 0, 86),
        36,
        25,
        10,
        math.rad(178),
        Color3.fromRGB(123, 91, 64)
    )
    makeBuilding(
        parent,
        "WayfarerStorehouse",
        camp + Vector3.new(-112, 0, 62),
        25,
        20,
        8,
        math.rad(108),
        Color3.fromRGB(115, 94, 66)
    )
    makeBuilding(
        parent,
        "WayfarerStable",
        camp + Vector3.new(102, 0, 72),
        34,
        24,
        9,
        math.rad(-150),
        Color3.fromRGB(103, 86, 62)
    )
    makeBuilding(
        parent,
        "PathkeeperLodge",
        camp + Vector3.new(15, 0, -104),
        30,
        22,
        9,
        math.rad(6),
        Color3.fromRGB(77, 105, 88)
    )
    makeWatchtower(parent, camp + Vector3.new(-125, 0, -86), math.rad(25))
    makeWatchtower(parent, camp + Vector3.new(124, 0, -82), math.rad(-25))
    makeFenceLine(
        parent,
        "CampNorthPalisade",
        camp + Vector3.new(-120, 0, 100),
        camp + Vector3.new(112, 0, 100),
        8,
        5.5
    )
    makeFenceLine(
        parent,
        "CampSouthPalisadeWest",
        camp + Vector3.new(-120, 0, -112),
        camp + Vector3.new(-20, 0, -112),
        8,
        5.5
    )
    makeFenceLine(
        parent,
        "CampSouthPalisadeEast",
        camp + Vector3.new(42, 0, -112),
        camp + Vector3.new(112, 0, -112),
        8,
        5.5
    )
    makeFenceLine(
        parent,
        "CampWestPalisade",
        camp + Vector3.new(-132, 0, -96),
        camp + Vector3.new(-132, 0, 92),
        8,
        5.5
    )
    makeSupplyStack(parent, camp + Vector3.new(-84, 0, 43), math.rad(16), 1.0)
    makeSupplyStack(parent, camp + Vector3.new(82, 0, 43), math.rad(-12), 1.0)
    makeSupplyStack(parent, camp + Vector3.new(80, 0, -52), math.rad(32), 0.9)
end

local function makeWorldSettlements(parent)
    -- Greenway settlement edge: visible habitation immediately outside town.
    makeBuilding(
        parent,
        "GreenwayWayhouse",
        ZONES.Greenway + Vector3.new(-92, 0, -62),
        28,
        21,
        8,
        math.rad(48),
        Color3.fromRGB(97, 112, 80)
    )
    makeBuilding(
        parent,
        "GreenwayStoreShed",
        ZONES.Greenway + Vector3.new(92, 0, -54),
        22,
        18,
        7,
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
    makeBuilding(
        parent,
        "CrossroadsWaystation",
        ZONES.Crossroads + Vector3.new(-70, 0, -58),
        30,
        22,
        9,
        math.rad(38),
        Color3.fromRGB(84, 108, 87)
    )
    makeBuilding(
        parent,
        "CrossroadsCourierHouse",
        ZONES.Crossroads + Vector3.new(70, 0, 55),
        24,
        19,
        8,
        math.rad(-142),
        Color3.fromRGB(111, 91, 66)
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
    makeBuilding(
        parent,
        "GlowmereKeeperHut",
        ZONES.Glowmere + Vector3.new(-112, 0, -74),
        26,
        20,
        8,
        math.rad(32),
        Color3.fromRGB(73, 107, 91)
    )
    makeBuilding(
        parent,
        "GlowmereReedHouse",
        ZONES.Glowmere + Vector3.new(102, 0, -80),
        24,
        19,
        8,
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
    makeBuilding(
        parent,
        "EastbridgeBarracks",
        ZONES.EastLanding + Vector3.new(-58, 0, 48),
        30,
        22,
        9,
        math.rad(136),
        Color3.fromRGB(83, 102, 78)
    )
    makeBuilding(
        parent,
        "EastbridgeStorehouse",
        ZONES.EastLanding + Vector3.new(62, 0, -52),
        27,
        21,
        8,
        math.rad(-46),
        Color3.fromRGB(118, 91, 60)
    )
    makeBuilding(
        parent,
        "EastbridgeMedicLodge",
        ZONES.EastLanding + Vector3.new(-52, 0, -55),
        24,
        19,
        8,
        math.rad(44),
        Color3.fromRGB(92, 119, 97)
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
    makeBuilding(
        parent,
        "MossglenRangerLodge",
        ZONES.Mossglen + Vector3.new(-128, 0, -92),
        32,
        24,
        9,
        math.rad(42),
        Color3.fromRGB(74, 109, 78)
    )
    makeBuilding(
        parent,
        "MossglenHunterCabin",
        ZONES.Mossglen + Vector3.new(128, 0, -105),
        26,
        20,
        8,
        math.rad(-38),
        Color3.fromRGB(100, 91, 61)
    )
    makeBuilding(
        parent,
        "MossglenSupplyHouse",
        ZONES.Mossglen + Vector3.new(-150, 0, 12),
        24,
        19,
        8,
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
    makeBuilding(
        parent,
        "SunmossObservatoryLodge",
        ZONES.Sunmoss + Vector3.new(-92, 0, -72),
        30,
        23,
        9,
        math.rad(35),
        Color3.fromRGB(105, 111, 77)
    )
    makeBuilding(
        parent,
        "SunmossKeeperHouse",
        ZONES.Sunmoss + Vector3.new(88, 0, 72),
        24,
        19,
        8,
        math.rad(-145),
        Color3.fromRGB(84, 104, 79)
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
    makeBuilding(
        parent,
        "VeilfallRefuge",
        ZONES.Veilfall + Vector3.new(-104, 0, -68),
        27,
        21,
        8,
        math.rad(45),
        Color3.fromRGB(69, 98, 92)
    )
    makeBuilding(
        parent,
        "VeilfallSurveyHut",
        ZONES.Veilfall + Vector3.new(108, 0, 68),
        23,
        18,
        8,
        math.rad(-132),
        Color3.fromRGB(86, 105, 90)
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
    makeBuilding(
        parent,
        "ProvingMentorLodge",
        ZONES.Proving + Vector3.new(-72, 0, 58),
        30,
        22,
        9,
        math.rad(48),
        Color3.fromRGB(81, 106, 88)
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

    -- Four permanent service buildings define a readable town square. The
    -- arrival lane remains open on the west side and the Greenway departure
    -- gate stays visible from the spawn point.
    makeBuilding(
        parent,
        "WayfarerHall",
        camp + Vector3.new(-42, 0, -60),
        44,
        30,
        11,
        math.rad(8),
        Color3.fromRGB(112, 124, 103)
    )
    makeBuilding(
        parent,
        "QuartermasterHouse",
        camp + Vector3.new(-62, 0, 66),
        30,
        23,
        9,
        math.rad(168),
        Color3.fromRGB(132, 106, 69)
    )
    makeBuilding(
        parent,
        "ArchiveLodge",
        camp + Vector3.new(48, 0, -72),
        32,
        24,
        10,
        math.rad(-12),
        Color3.fromRGB(103, 95, 126)
    )
    makeBuilding(
        parent,
        "WayfarerInn",
        camp + Vector3.new(66, 0, 62),
        31,
        24,
        10,
        math.rad(-165),
        Color3.fromRGB(82, 112, 88)
    )

    -- Plaza, service court, and training yard are authored as separate town
    -- rooms so new players immediately understand where to socialize, shop,
    -- train, and leave for the field.
    Workspace.Terrain:FillBlock(
        CFrame.new(camp.X - 12, 1.25, camp.Z + 2),
        Vector3.new(142, 1.5, 112),
        Enum.Material.Slate
    )
    Workspace.Terrain:FillBlock(
        CFrame.new(camp.X + 63, 1.25, camp.Z + 3),
        Vector3.new(48, 1.5, 126),
        Enum.Material.Ground
    )
    Workspace.Terrain:FillBlock(
        CFrame.new(camp.X - 70, 1.25, camp.Z + 8),
        Vector3.new(42, 1.5, 58),
        Enum.Material.Ground
    )

    makeHearth(parent, camp + Vector3.new(-3, 0, 4))
    makeBench(parent, camp + Vector3.new(-22, 0, 18), math.rad(24))
    makeBench(parent, camp + Vector3.new(20, 0, 18), math.rad(-24))
    makeBench(parent, camp + Vector3.new(-20, 0, -17), math.rad(155))
    makeMarketStall(
        parent,
        camp + Vector3.new(-67, 0, 29),
        math.rad(92),
        Color3.fromRGB(128, 101, 62)
    )
    makeMarketStall(
        parent,
        camp + Vector3.new(53, 0, -34),
        math.rad(-88),
        Color3.fromRGB(94, 81, 128)
    )

    -- Training yard: deliberately clear enough for dodge/combat practice.
    for _, offset in
        {
            Vector3.new(45, 0, -45),
            Vector3.new(82, 0, -45),
            Vector3.new(45, 0, 22),
            Vector3.new(82, 0, 22),
        }
    do
        makeLumenPylon(parent, camp + offset, 7)
    end
    makeSign(parent, camp + Vector3.new(62, 0, -31), math.rad(-90), "TRAINING YARD")

    makeLantern(parent, camp + Vector3.new(-58, 0, 18), math.rad(90))
    makeLantern(parent, camp + Vector3.new(-28, 0, 45), math.rad(180))
    makeLantern(parent, camp + Vector3.new(25, 0, 45), math.rad(180))
    makeLantern(parent, camp + Vector3.new(55, 0, 18), math.rad(-90))
    makeLantern(parent, camp + Vector3.new(-30, 0, -40), 0)
    makeLantern(parent, camp + Vector3.new(34, 0, -40), 0)
    makeLantern(parent, camp + Vector3.new(-82, 0, 48), math.rad(120))

    makeSign(parent, camp + Vector3.new(88, 0, 32), math.rad(-76), "GREENWAY  →")
    makeSign(parent, camp + Vector3.new(8, 0, -104), math.rad(180), "PROVING CIRCLE")
    makeSign(parent, camp + Vector3.new(-88, 0, 12), math.rad(88), "ARRIVAL / WAYFARER HALL")
    makeLumenPylon(parent, camp + Vector3.new(-102, 0, -18), 7)
    makeLumenPylon(parent, camp + Vector3.new(-102, 0, 44), 7)

    -- Eastern departure gate is a landmark, not a wall. The opening is wide
    -- enough for parties to sprint/dodge through without snagging.
    local gateBase = CFrame.new(terrainSurfacePosition(camp + Vector3.new(116, 0, 12), 0))
        * CFrame.Angles(0, math.rad(90), 0)
    for _, side in { -1, 1 } do
        makePart(
            parent,
            "TownGatePost",
            Vector3.new(2.0, 11, 2.0),
            gateBase * CFrame.new(side * 13.5, 5.5, 0),
            Enum.Material.Wood,
            Color3.fromRGB(70, 50, 34)
        )
    end
    local top = makePart(
        parent,
        "TownGateBeam",
        Vector3.new(30.5, 1.4, 2.2),
        gateBase * CFrame.new(0, 10.0, 0),
        Enum.Material.Wood,
        Color3.fromRGB(70, 50, 34)
    )
    top.CanCollide = false
    top.CanTouch = false
    top.CanQuery = false
    makeLumenPylon(parent, camp + Vector3.new(116, 0, -19), 9)
    makeLumenPylon(parent, camp + Vector3.new(116, 0, 43), 9)
    makeTownExpansion(parent)
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
        makePart(
            model,
            "ArchPillar",
            Vector3.new(8, 25, 8),
            CFrame.new(origin + Vector3.new(x, 12.5, 0)),
            Enum.Material.Slate,
            stone
        )
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
    local position = terrainSurfacePosition(style.Position, 0)
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
        Name = "Wayfarer Healer",
        Position = ZONES.Camp + Vector3.new(-96, 0, -40),
        Yaw = math.rad(55),
        Role = "Guide",
        HairStyle = "bun",
        Cloth = Color3.fromRGB(87, 118, 97),
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
        Name = "Glowmere Keeper",
        Position = ZONES.Glowmere + Vector3.new(-103, 0, -50),
        Yaw = math.rad(35),
        Role = "Archivist",
        HairStyle = "long",
        Cloth = Color3.fromRGB(67, 101, 93),
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
        Name = "Sunmoss Researcher",
        Position = ZONES.Sunmoss + Vector3.new(-15, 0, 72),
        Yaw = math.rad(16),
        Role = "Archivist",
        HairStyle = "bun",
        Cloth = Color3.fromRGB(106, 108, 73),
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
        Name = "Veilfall Refugee",
        Position = ZONES.Veilfall + Vector3.new(-84, 0, -56),
        Yaw = math.rad(48),
        Role = "Guide",
        HairStyle = "long",
        Cloth = Color3.fromRGB(70, 99, 94),
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
    local position = terrainSurfacePosition(spec.Position, 0)
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
    registerSpawn(parent, "LumenreachSpawn", "lumenreach_start", ARRIVAL_ORIGIN, math.rad(90))
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
    placeTreeArc(parent, ZONES.Camp, 175, 145, 28, 28, 332, 1)
    placeTreeArc(parent, ZONES.Greenway, 150, 116, 26, 15, 345, 2)
    placeTreeArc(parent, ZONES.Crossroads, 124, 102, 22, 25, 335, 3)
    placeTreeArc(parent, ZONES.Glowmere, 172, 148, 30, 5, 350, 4)
    placeTreeArc(parent, ZONES.Gravebone, 142, 118, 26, 10, 350, 5)
    placeTreeArc(parent, ZONES.Mossglen, 215, 170, 36, 10, 350, 6)
    placeTreeArc(parent, ZONES.Sunmoss, 165, 134, 26, 15, 345, 7)
    placeTreeArc(parent, ZONES.Veilfall, 170, 145, 28, 30, 330, 8)
    placeTreeArc(parent, ZONES.Ruins, 185, 150, 28, 35, 325, 9)
    placeTreeArc(parent, ZONES.Proving, 132, 118, 22, 20, 340, 10)

    -- Fill the large negative-space belts between progression rooms. These are
    -- part of the generated V5 map itself, not objects layered onto an old map.
    scatterForestBand(parent, Vector3.new(-790, 0, 430), 205, 150, 28, 21, "wet")
    scatterForestBand(parent, Vector3.new(-720, 0, -410), 230, 155, 26, 22, "forest")
    scatterForestBand(parent, Vector3.new(-135, 0, 590), 235, 145, 30, 23, "wet")
    scatterForestBand(parent, Vector3.new(260, 0, 650), 250, 150, 32, 24, "forest")
    scatterForestBand(parent, Vector3.new(680, 0, 610), 235, 155, 30, 25, "forest")
    scatterForestBand(parent, Vector3.new(670, 0, -585), 245, 165, 32, 26, "dry")
    scatterForestBand(parent, Vector3.new(940, 0, -390), 190, 155, 24, 27, "dry")
    scatterForestBand(parent, Vector3.new(965, 0, 390), 180, 145, 22, 28, "forest")

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
    makeSignatureWorldContent(parent)

    makeBuilding(
        parent,
        "EastbridgeScoutOutpost",
        ZONES.EastLanding + Vector3.new(38, 0, 38),
        24,
        18,
        8,
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

    for npcId in NPC_STYLES do
        makeNpc(world, npcId)
    end
    makeAmbientPopulation(world)

    makeEncounterContent(world)
end

return LumenreachWorldService
