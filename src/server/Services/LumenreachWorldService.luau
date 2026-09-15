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
        "Floor",
        Vector3.new(width, 0.8, depth),
        base * CFrame.new(0, 0.4, 0),
        Enum.Material.WoodPlanks,
        timber
    )

    local doorWidth = math.min(7, width * 0.28)
    local sideWidth = (width - doorWidth) * 0.5
    local wallSpecs = {
        { Vector3.new(width, height, 1), Vector3.new(0, height * 0.5, depth * 0.5) },
        { Vector3.new(1, height, depth), Vector3.new(-width * 0.5, height * 0.5, 0) },
        { Vector3.new(1, height, depth), Vector3.new(width * 0.5, height * 0.5, 0) },
        {
            Vector3.new(sideWidth, height, 1),
            Vector3.new(-(doorWidth + sideWidth) * 0.5, height * 0.5, -depth * 0.5),
        },
        {
            Vector3.new(sideWidth, height, 1),
            Vector3.new((doorWidth + sideWidth) * 0.5, height * 0.5, -depth * 0.5),
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

    -- Clean, restrained gable: two correctly oriented roof panels, deliberately
    -- kept above head height with modest overhang.
    for _, side in { -1, 1 } do
        local roof = makePart(
            model,
            "Roof",
            Vector3.new(width * 0.56 + 1.4, 0.7, depth + 2.2),
            base
                * CFrame.new(side * width * 0.25, height + 2.25, 0)
                * CFrame.Angles(0, 0, math.rad(-side * 18)),
            Enum.Material.WoodPlanks,
            roofColor
        )
        roof.CanCollide = false
        roof.CanTouch = false
        roof.CanQuery = false
    end

    local lintel = makePart(
        model,
        "DoorLintel",
        Vector3.new(doorWidth, 0.7, 1.2),
        base * CFrame.new(0, height - 0.5, -depth * 0.5 - 0.05),
        Enum.Material.Wood,
        timber
    )
    lintel.CanCollide = false
    return model
end

local function makeTown(parent)
    local camp = ZONES.Camp
    makeBuilding(
        parent,
        "WayfarerHall",
        camp + Vector3.new(-40, 0, -58),
        42,
        28,
        11,
        math.rad(8),
        Color3.fromRGB(116, 121, 101)
    )
    makeBuilding(
        parent,
        "QuartermasterHouse",
        camp + Vector3.new(-55, 0, 68),
        28,
        22,
        9,
        math.rad(168),
        Color3.fromRGB(128, 107, 70)
    )
    makeBuilding(
        parent,
        "ArchiveLodge",
        camp + Vector3.new(48, 0, -70),
        30,
        23,
        10,
        math.rad(-12),
        Color3.fromRGB(102, 97, 122)
    )
    makeBuilding(
        parent,
        "WayfarerInn",
        camp + Vector3.new(62, 0, 60),
        29,
        22,
        9,
        math.rad(-165),
        Color3.fromRGB(83, 110, 86)
    )

    -- Open plaza: no tents or structures occupy the arrival footprint.
    Workspace.Terrain:FillBlock(
        CFrame.new(camp.X - 15, 1.25, camp.Z + 2),
        Vector3.new(130, 1.5, 105),
        Enum.Material.Slate
    )
    Workspace.Terrain:FillBlock(
        CFrame.new(camp.X + 58, 1.25, camp.Z + 8),
        Vector3.new(45, 1.5, 115),
        Enum.Material.Ground
    )

    makeLantern(parent, camp + Vector3.new(-55, 0, 18), math.rad(90))
    makeLantern(parent, camp + Vector3.new(-25, 0, 43), math.rad(180))
    makeLantern(parent, camp + Vector3.new(22, 0, 43), math.rad(180))
    makeLantern(parent, camp + Vector3.new(52, 0, 16), math.rad(-90))
    makeLantern(parent, camp + Vector3.new(-28, 0, -38), 0)
    makeLantern(parent, camp + Vector3.new(32, 0, -38), 0)

    makeSign(parent, camp + Vector3.new(82, 0, 34), math.rad(-76), "GREENWAY  →")
    makeSign(parent, camp + Vector3.new(8, 0, -102), math.rad(180), "PROVING CIRCLE")

    -- A proper eastern gate frames departure without blocking the road.
    local gateBase = CFrame.new(terrainSurfacePosition(camp + Vector3.new(112, 0, 12), 0))
        * CFrame.Angles(0, math.rad(90), 0)
    for _, side in { -1, 1 } do
        makePart(
            parent,
            "TownGatePost",
            Vector3.new(1.8, 10, 1.8),
            gateBase * CFrame.new(side * 12.5, 5, 0),
            Enum.Material.Wood,
            Color3.fromRGB(70, 50, 34)
        )
    end
    local top = makePart(
        parent,
        "TownGateBeam",
        Vector3.new(28.5, 1.25, 2.0),
        gateBase * CFrame.new(0, 9.35, 0),
        Enum.Material.Wood,
        Color3.fromRGB(70, 50, 34)
    )
    top.CanCollide = false
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
    for index = 1, 5 do
        local angle = math.rad(-90 + (index - 1) * 72)
        local pos = ZONES.Proving + Vector3.new(math.cos(angle) * 20, 0, math.sin(angle) * 20)
        makeWaystone(parent, pos, -angle + math.rad(90), 0.7)
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
    -- Tree massing frames zone edges; roads and encounter centers stay open.
    placeTreeArc(parent, ZONES.Camp, 175, 145, 18, 28, 332, 1)
    placeTreeArc(parent, ZONES.Greenway, 145, 110, 16, 15, 345, 2)
    placeTreeArc(parent, ZONES.Crossroads, 118, 95, 14, 25, 335, 3)
    placeTreeArc(parent, ZONES.Glowmere, 165, 140, 18, 5, 350, 4)
    placeTreeArc(parent, ZONES.Gravebone, 135, 110, 15, 10, 350, 5)
    placeTreeArc(parent, ZONES.Mossglen, 205, 160, 22, 10, 350, 6)
    placeTreeArc(parent, ZONES.Sunmoss, 155, 125, 16, 15, 345, 7)
    placeTreeArc(parent, ZONES.Veilfall, 160, 135, 18, 30, 330, 8)
    placeTreeArc(parent, ZONES.Ruins, 175, 140, 18, 35, 325, 9)
    placeTreeArc(parent, ZONES.Proving, 125, 112, 14, 20, 340, 10)

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
    -- Eastbridge Landing is a small mid-zone field outpost. Moving the Scout
    -- here turns the eastern half into a genuine second quest hub instead of
    -- forcing every Level 3-8 hunt to bounce all the way back to starter town.
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
    world:SetAttribute("WorldDesignVersion", 3)
    world:SetAttribute("TerrainFirstMMOLayout", true)
    world.Parent = Workspace

    makeZoneContent(world)
    decorateWorld(world)
    makeLabelsAndZones(world)
    makeExplorationContent(world)
    makeSpawns(world)

    for npcId in NPC_STYLES do
        makeNpc(world, npcId)
    end

    makeEncounterContent(world)
end

return LumenreachWorldService
