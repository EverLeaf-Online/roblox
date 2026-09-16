local Workspace = game:GetService("Workspace")

local LumenreachTerrainBuilder = {}

function LumenreachTerrainBuilder.FlattenTerrain(center, size, topY, material)
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

function LumenreachTerrainBuilder.FillTerrainRoute(points, width, material)
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
    local samplesBySegment = {}

    -- Carve and line the gorge first. Water used to be written inside this same
    -- loop, so the next overlapping rock sample overwrote most of the previous
    -- water sphere. From above that produced a dry boulder trench.
    for index = 1, #points - 1 do
        local a = points[index]
        local b = points[index + 1]
        local length = (b - a).Magnitude
        local samples = math.max(2, math.ceil(length / 18))
        samplesBySegment[index] = samples
        for step = 0, samples do
            local alpha = step / samples
            local point = a:Lerp(b, alpha)
            terrain:FillBall(point + Vector3.new(0, 9, 0), 43, Enum.Material.Air)
            terrain:FillBall(point + Vector3.new(0, -18, 0), 28, Enum.Material.Rock)
        end
    end

    -- Cut one continuous inner channel after every rock operation has finished,
    -- then fill water as the final material pass so nothing can overwrite it.
    for index = 1, #points - 1 do
        local a = points[index]
        local b = points[index + 1]
        local samples = samplesBySegment[index]
        for step = 0, samples do
            local alpha = step / samples
            local point = a:Lerp(b, alpha)
            terrain:FillBall(point + Vector3.new(0, -4, 0), 19, Enum.Material.Air)
            terrain:FillBall(point + Vector3.new(0, -8, 0), 16, Enum.Material.Water)
        end
    end
end

function LumenreachTerrainBuilder.Build(spec)
    local terrain = Workspace.Terrain
    local zones = spec.Zones
    local brambleOrigin = spec.BrambleOrigin
    terrain:Clear()

    terrain:FillBlock(
        CFrame.new(-50, -20, 20),
        Vector3.new(spec.WorldWidth, 40, spec.WorldDepth),
        Enum.Material.Grass
    )
    terrain:FillBlock(
        CFrame.new(-50, -44, 20),
        Vector3.new(spec.WorldWidth, 18, spec.WorldDepth),
        Enum.Material.Rock
    )

    LumenreachTerrainBuilder.FlattenTerrain(
        zones.Camp,
        Vector3.new(285, 0, 220),
        2,
        Enum.Material.Ground
    )
    LumenreachTerrainBuilder.FlattenTerrain(
        zones.Greenway,
        Vector3.new(250, 0, 220),
        1,
        Enum.Material.Grass
    )
    LumenreachTerrainBuilder.FlattenTerrain(
        zones.Crossroads,
        Vector3.new(185, 0, 165),
        4,
        Enum.Material.Ground
    )
    LumenreachTerrainBuilder.FlattenTerrain(
        zones.Glowmere,
        Vector3.new(240, 0, 205),
        -4,
        Enum.Material.Grass
    )
    LumenreachTerrainBuilder.FlattenTerrain(
        zones.EastLanding,
        Vector3.new(135, 0, 130),
        6,
        Enum.Material.Ground
    )
    LumenreachTerrainBuilder.FlattenTerrain(
        zones.Gravebone,
        Vector3.new(210, 0, 185),
        6,
        Enum.Material.Ground
    )
    LumenreachTerrainBuilder.FlattenTerrain(
        zones.Mossglen,
        Vector3.new(330, 0, 265),
        6,
        Enum.Material.Grass
    )
    LumenreachTerrainBuilder.FlattenTerrain(
        brambleOrigin,
        Vector3.new(150, 0, 120),
        6,
        Enum.Material.Grass
    )
    LumenreachTerrainBuilder.FlattenTerrain(
        zones.Sunmoss,
        Vector3.new(235, 0, 185),
        34,
        Enum.Material.Grass
    )
    LumenreachTerrainBuilder.FlattenTerrain(
        zones.Veilfall,
        Vector3.new(255, 0, 220),
        -18,
        Enum.Material.Ground
    )
    LumenreachTerrainBuilder.FlattenTerrain(
        zones.Ruins,
        Vector3.new(290, 0, 235),
        10,
        Enum.Material.Ground
    )
    LumenreachTerrainBuilder.FlattenTerrain(
        zones.Proving,
        Vector3.new(175, 0, 175),
        4,
        Enum.Material.Ground
    )

    terrain:FillBlock(
        CFrame.new(zones.Sunmoss.X, 12, zones.Sunmoss.Z),
        Vector3.new(310, 44, 260),
        Enum.Material.Rock
    )
    terrain:FillBlock(
        CFrame.new(zones.Sunmoss.X, 31, zones.Sunmoss.Z),
        Vector3.new(250, 8, 200),
        Enum.Material.Grass
    )

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

    for _, route in spec.Routes do
        LumenreachTerrainBuilder.FillTerrainRoute(
            route.Points,
            route.Width + 7,
            Enum.Material.Ground
        )
        LumenreachTerrainBuilder.FillTerrainRoute(route.Points, route.Width, Enum.Material.Ground)
    end

    carveGorge(spec.GorgePoints)

    -- Glowmere's wetland is a shallow basin connected visually to the gorge.
    terrain:FillBall(zones.Glowmere + Vector3.new(20, -8, 18), 72, Enum.Material.Air)
    terrain:FillBall(zones.Glowmere + Vector3.new(20, -18, 18), 64, Enum.Material.Mud)
    terrain:FillBall(zones.Glowmere + Vector3.new(20, -8, 18), 52, Enum.Material.Water)

    LumenreachTerrainBuilder.FlattenTerrain(
        zones.Camp,
        Vector3.new(270, 0, 205),
        2,
        Enum.Material.Ground
    )
    LumenreachTerrainBuilder.FlattenTerrain(
        zones.Crossroads,
        Vector3.new(170, 0, 150),
        4,
        Enum.Material.Ground
    )
    LumenreachTerrainBuilder.FlattenTerrain(
        zones.Gravebone,
        Vector3.new(195, 0, 170),
        6,
        Enum.Material.Ground
    )
    LumenreachTerrainBuilder.FlattenTerrain(
        zones.Mossglen,
        Vector3.new(300, 0, 235),
        6,
        Enum.Material.Grass
    )
    LumenreachTerrainBuilder.FlattenTerrain(
        brambleOrigin,
        Vector3.new(138, 0, 108),
        6,
        Enum.Material.Grass
    )
    LumenreachTerrainBuilder.FlattenTerrain(
        zones.Ruins,
        Vector3.new(270, 0, 215),
        10,
        Enum.Material.Ground
    )
    LumenreachTerrainBuilder.FlattenTerrain(
        zones.Proving,
        Vector3.new(160, 0, 160),
        4,
        Enum.Material.Ground
    )

    LumenreachTerrainBuilder.FillTerrainRoute(
        { zones.Crossroads, Vector3.new(-335, 4, 88), spec.EastbridgeWest },
        20,
        Enum.Material.Ground
    )
    LumenreachTerrainBuilder.FillTerrainRoute(
        { spec.EastbridgeEast, zones.EastLanding },
        20,
        Enum.Material.Ground
    )
    LumenreachTerrainBuilder.FillTerrainRoute(
        { zones.Glowmere + Vector3.new(45, 0, -35), spec.ReedbridgeWest },
        15,
        Enum.Material.Ground
    )
    LumenreachTerrainBuilder.FillTerrainRoute(
        { spec.ReedbridgeEast, zones.Mossglen },
        15,
        Enum.Material.Ground
    )
end

return LumenreachTerrainBuilder
