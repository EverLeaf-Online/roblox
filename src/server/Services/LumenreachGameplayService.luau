local Workspace = game:GetService("Workspace")

local LumenreachActivityService = require(script.Parent.LumenreachActivityService)

local LumenreachGameplayService = {}

local GENERATED_NAME = "EverLeafGeneratedWorld"
local initialized = false

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

local COLORS = table.freeze({
    Timber = Color3.fromRGB(72, 53, 36),
    TimberLight = Color3.fromRGB(107, 79, 51),
    Slate = Color3.fromRGB(71, 83, 79),
    SlateDark = Color3.fromRGB(51, 62, 59),
    Lumen = Color3.fromRGB(102, 237, 194),
    Leaf = Color3.fromRGB(88, 154, 101),
    Reed = Color3.fromRGB(76, 143, 120),
    Glowmere = Color3.fromRGB(104, 225, 219),
    Sunmoss = Color3.fromRGB(205, 224, 112),
    Veil = Color3.fromRGB(118, 218, 231),
})

local function terrainSurface(position, offset)
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return position
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { terrain }
    params.IgnoreWater = true
    local hit = Workspace:Raycast(
        Vector3.new(position.X, position.Y + 160, position.Z),
        Vector3.new(0, -340, 0),
        params
    )
    if not hit then
        return position + Vector3.new(0, offset or 0, 0)
    end
    return hit.Position + Vector3.new(0, offset or 0, 0)
end

local function part(parent, name, size, cf, material, color, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Anchored = true
    p.Material = material or Enum.Material.SmoothPlastic
    p.Color = color or Color3.new(1, 1, 1)
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = true
    if shape == "Ball" then
        p.Shape = Enum.PartType.Ball
    elseif shape == "Cylinder" then
        p.Shape = Enum.PartType.Cylinder
    end
    p.Parent = parent
    return p
end

local function prompt(parent, actionText, objectText, holdDuration)
    local p = Instance.new("ProximityPrompt")
    p.ActionText = actionText
    p.ObjectText = objectText
    p.KeyboardKeyCode = Enum.KeyCode.E
    p.GamepadKeyCode = Enum.KeyCode.ButtonX
    p.HoldDuration = holdDuration or 0.35
    p.MaxActivationDistance = 10
    p.RequiresLineOfSight = false
    p.Parent = parent
    return p
end

local function makeLumenleaf(parent, id, position)
    local ground = terrainSurface(position, 0)
    local model = Instance.new("Model")
    model.Name = "Lumenleaf_" .. id
    model.Parent = parent
    local base = part(
        model,
        "RootCluster",
        Vector3.new(3.4, 0.8, 3.4),
        CFrame.new(ground + Vector3.new(0, 0.4, 0)),
        Enum.Material.Ground,
        Color3.fromRGB(64, 88, 66),
        "Ball"
    )
    for index = 1, 5 do
        local angle = (index - 1) * math.pi * 2 / 5
        local leaf = part(
            model,
            "LumenleafBlade",
            Vector3.new(0.45, 3.2, 1.15),
            CFrame.new(ground + Vector3.new(math.cos(angle) * 0.9, 1.6, math.sin(angle) * 0.9))
                * CFrame.Angles(math.rad(-20), -angle, math.rad(18)),
            Enum.Material.Grass,
            COLORS.Leaf
        )
        leaf.CanQuery = false
    end
    local heart = part(
        model,
        "LumenleafHeart",
        Vector3.new(0.65, 2.0, 0.65),
        CFrame.new(ground + Vector3.new(0, 1.4, 0)) * CFrame.Angles(0, math.rad(45), math.rad(8)),
        Enum.Material.Neon,
        COLORS.Lumen
    )
    heart.CanQuery = false
    local pr = prompt(base, "Gather", "Lumenleaf", 0.55)
    LumenreachActivityService.Bind(pr, {
        Type = "Gather",
        Id = "lumenleaf_" .. id,
        ItemId = "lumenleaf",
        Quantity = 1,
        Cooldown = 22,
        Title = "Lumenleaf",
        SuccessText = "Gathered fresh Lumenleaf.",
    })
end

local function makeGlowreed(parent, id, position)
    local ground = terrainSurface(position, 0)
    local model = Instance.new("Model")
    model.Name = "Glowreed_" .. id
    model.Parent = parent
    local root = part(
        model,
        "ReedRoot",
        Vector3.new(2.8, 0.6, 2.8),
        CFrame.new(ground + Vector3.new(0, 0.3, 0)),
        Enum.Material.Mud,
        Color3.fromRGB(65, 82, 69),
        "Ball"
    )
    for index = 1, 6 do
        local x = ((index * 17) % 7 - 3) * 0.34
        local z = ((index * 11) % 5 - 2) * 0.4
        local height = 3.4 + (index % 3) * 0.75
        local reed = part(
            model,
            "GlowreedStem",
            Vector3.new(0.28, height, 0.28),
            CFrame.new(ground + Vector3.new(x, height * 0.5, z)),
            Enum.Material.Grass,
            COLORS.Reed,
            "Cylinder"
        )
        reed.CanQuery = false
        local tip = part(
            model,
            "GlowreedTip",
            Vector3.new(0.6, 1.1, 0.6),
            CFrame.new(ground + Vector3.new(x, height + 0.35, z)),
            Enum.Material.Neon,
            COLORS.Glowmere,
            "Ball"
        )
        tip.CanQuery = false
    end
    local pr = prompt(root, "Cut reeds", "Glowreed", 0.65)
    LumenreachActivityService.Bind(pr, {
        Type = "Gather",
        Id = "glowreed_" .. id,
        ItemId = "glowreed",
        Quantity = 1,
        Cooldown = 28,
        Title = "Glowreed",
        SuccessText = "Cut a bundle of Glowreed.",
    })
end

local function makeSunmossBloom(parent, id, position)
    local ground = terrainSurface(position, 0)
    local model = Instance.new("Model")
    model.Name = "SunmossBloom_" .. id
    model.Parent = parent
    local root = part(
        model,
        "SunmossStone",
        Vector3.new(4.2, 1.1, 3.6),
        CFrame.new(ground + Vector3.new(0, 0.55, 0)) * CFrame.Angles(0, math.rad(id * 31 % 180), 0),
        Enum.Material.Slate,
        Color3.fromRGB(78, 88, 72)
    )
    for index = 1, 6 do
        local angle = (index - 1) * math.pi * 2 / 6
        local petal = part(
            model,
            "SunmossPetal",
            Vector3.new(1.4, 0.35, 0.7),
            CFrame.new(ground + Vector3.new(math.cos(angle) * 1.0, 1.25, math.sin(angle) * 1.0))
                * CFrame.Angles(0, -angle, math.rad(10)),
            Enum.Material.Neon,
            COLORS.Sunmoss
        )
        petal.CanQuery = false
    end
    local pr = prompt(root, "Harvest", "Sunmoss Bloom", 0.7)
    LumenreachActivityService.Bind(pr, {
        Type = "Gather",
        Id = "sunmoss_bloom_" .. id,
        ItemId = "sunmoss_bloom",
        Quantity = 1,
        Cooldown = 35,
        Title = "Sunmoss Bloom",
        SuccessText = "Harvested a Sunmoss Bloom.",
    })
end

local function makeVeilCrystal(parent, id, position)
    local ground = terrainSurface(position, 0)
    local model = Instance.new("Model")
    model.Name = "VeilwaterCrystal_" .. id
    model.Parent = parent
    local root = part(
        model,
        "CrystalBase",
        Vector3.new(3.8, 1.2, 3.5),
        CFrame.new(ground + Vector3.new(0, 0.6, 0)),
        Enum.Material.Slate,
        Color3.fromRGB(60, 72, 74)
    )
    for index = 1, 4 do
        local angle = (index - 1) * math.pi * 2 / 4
        local height = 2.8 + index * 0.6
        local shard = part(
            model,
            "VeilCrystalShard",
            Vector3.new(0.9, height, 0.9),
            CFrame.new(
                ground
                    + Vector3.new(math.cos(angle) * 0.8, 1.0 + height * 0.5, math.sin(angle) * 0.8)
            )
                * CFrame.Angles(math.rad((index % 2 == 0) and 10 or -8), -angle, math.rad(8)),
            Enum.Material.Neon,
            COLORS.Veil
        )
        shard.Transparency = 0.08
        shard.CanQuery = false
    end
    local pr = prompt(root, "Extract", "Veilwater Crystal", 0.85)
    LumenreachActivityService.Bind(pr, {
        Type = "Gather",
        Id = "veilwater_crystal_" .. id,
        ItemId = "veilwater_crystal",
        Quantity = 1,
        Cooldown = 40,
        Title = "Veilwater Crystal",
        SuccessText = "Extracted a Veilwater Crystal shard.",
    })
end

local function makeRestShrine(parent, id, position, title)
    local ground = terrainSurface(position, 0)
    local model = Instance.new("Model")
    model.Name = "RestShrine_" .. id
    model.Parent = parent
    local root = part(
        model,
        "ShrineDais",
        Vector3.new(10, 1.1, 8),
        CFrame.new(ground + Vector3.new(0, 0.55, 0)),
        Enum.Material.Slate,
        COLORS.SlateDark
    )
    for _, x in { -3.5, 3.5 } do
        part(
            model,
            "ShrinePost",
            Vector3.new(1.2, 7.5, 1.2),
            CFrame.new(ground + Vector3.new(x, 4.1, 1.2)),
            Enum.Material.Slate,
            COLORS.Slate
        )
    end
    local crystal = part(
        model,
        "ShrineHeart",
        Vector3.new(1.3, 5.5, 1.3),
        CFrame.new(ground + Vector3.new(0, 3.1, 0)) * CFrame.Angles(0, math.rad(45), math.rad(7)),
        Enum.Material.Neon,
        COLORS.Lumen
    )
    crystal.CanQuery = false
    local pr = prompt(root, "Rest", title or "Wayfarer Rest", 1.0)
    LumenreachActivityService.Bind(pr, {
        Type = "Rest",
        Id = "rest_" .. id,
        Cooldown = 30,
        Title = title or "Wayfarer Rest",
        SuccessText = "Your HP and MP are fully restored.",
    })
end

local function makeApothecaryBench(parent, position)
    local ground = terrainSurface(position, 0)
    local model = Instance.new("Model")
    model.Name = "WayfarerApothecaryBench"
    model.Parent = parent
    local base = CFrame.new(ground)

    local top = part(
        model,
        "BenchTop",
        Vector3.new(9.2, 0.48, 3.6),
        base * CFrame.new(0, 2.55, 0),
        Enum.Material.WoodPlanks,
        COLORS.TimberLight
    )
    top.CanCollide = false
    for _, x in { -3.7, 3.7 } do
        for _, z in { -1.25, 1.25 } do
            local leg = part(
                model,
                "BenchLeg",
                Vector3.new(0.55, 2.25, 0.55),
                base * CFrame.new(x, 1.125, z),
                Enum.Material.Wood,
                COLORS.Timber
            )
            leg.CanCollide = false
        end
    end
    local shelf = part(
        model,
        "BenchShelf",
        Vector3.new(8.2, 0.35, 2.7),
        base * CFrame.new(0, 0.8, 0.25),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(86, 63, 42)
    )
    shelf.CanCollide = false
    local backboard = part(
        model,
        "BenchBackboard",
        Vector3.new(8.8, 2.8, 0.35),
        base * CFrame.new(0, 4.05, 1.55),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(82, 62, 43)
    )
    backboard.CanCollide = false

    local smallStation = part(
        model,
        "SmallTonicMortar",
        Vector3.new(1.65, 1.15, 1.65),
        base * CFrame.new(-2.45, 3.35, -0.2),
        Enum.Material.Slate,
        Color3.fromRGB(69, 78, 75),
        "Cylinder"
    )
    local fieldStation = part(
        model,
        "FieldTonicKettle",
        Vector3.new(1.9, 1.55, 1.9),
        base * CFrame.new(2.45, 3.52, -0.15),
        Enum.Material.Metal,
        Color3.fromRGB(78, 88, 86),
        "Ball"
    )
    local glow = part(
        model,
        "BenchLumenLamp",
        Vector3.new(0.45, 2.0, 0.45),
        base * CFrame.new(0, 3.65, 1.25) * CFrame.Angles(0, math.rad(45), math.rad(8)),
        Enum.Material.Neon,
        COLORS.Lumen
    )
    glow.CanQuery = false

    -- Solid invisible workstation volume prevents avatar/camera clipping through the bench.
    local blocker = part(
        model,
        "BenchCollision",
        Vector3.new(9.0, 4.3, 3.5),
        base * CFrame.new(0, 2.15, 0),
        Enum.Material.SmoothPlastic,
        Color3.new(0, 0, 0)
    )
    blocker.Transparency = 1
    blocker.CanCollide = true
    blocker.CanQuery = true
    blocker.CastShadow = false
    blocker:SetAttribute("EverLeafCollisionProxy", true)

    local smallPrompt = prompt(smallStation, "Brew", "Small Tonic · 2 Lumenleaf", 0.8)
    LumenreachActivityService.Bind(smallPrompt, {
        Type = "Craft",
        Id = "craft_small_tonic",
        RecipeId = "small_tonic",
        Cooldown = 0.75,
        Title = "Wayfarer Apothecary",
        MissingText = "Small Tonic requires 2 Lumenleaf.",
    })
    local fieldPrompt = prompt(fieldStation, "Brew", "Field Tonic · Lumenleaf + Glowreed", 1.0)
    LumenreachActivityService.Bind(fieldPrompt, {
        Type = "Craft",
        Id = "craft_field_tonic",
        RecipeId = "field_tonic",
        Cooldown = 0.75,
        Title = "Wayfarer Apothecary",
        MissingText = "Field Tonic requires 2 Lumenleaf and 1 Glowreed.",
    })
end

local function makeWayfarerCache(parent, id, position, reward, title)
    local ground = terrainSurface(position, 0)
    local model = Instance.new("Model")
    model.Name = "WayfarerCache_" .. id
    model.Parent = parent
    local chest = part(
        model,
        "CacheChest",
        Vector3.new(6.2, 3.2, 4.4),
        CFrame.new(ground + Vector3.new(0, 1.6, 0)),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(91, 65, 43)
    )
    part(
        model,
        "CacheBand",
        Vector3.new(6.5, 0.65, 4.7),
        CFrame.new(ground + Vector3.new(0, 2.1, 0)),
        Enum.Material.Metal,
        Color3.fromRGB(113, 96, 69)
    )
    local rune = part(
        model,
        "CacheRune",
        Vector3.new(1.0, 1.6, 0.18),
        CFrame.new(ground + Vector3.new(0, 1.8, -2.3)) * CFrame.Angles(0, 0, math.rad(20)),
        Enum.Material.Neon,
        COLORS.Lumen
    )
    rune.CanQuery = false
    local pr = prompt(chest, "Open", title or "Wayfarer Cache", 0.75)
    LumenreachActivityService.Bind(pr, {
        Type = "Cache",
        Id = "cache_" .. id,
        SecretId = "lumenreach_cache_" .. id,
        Reward = reward,
        Cooldown = 0.5,
        Title = title or "Wayfarer Cache",
        SuccessText = "You recovered supplies left by an earlier Wayfarer.",
    })
end

local function buildGathering(parent)
    local lumenleafPositions = {
        ZONES.Greenway + Vector3.new(-82, 0, 78),
        ZONES.Greenway + Vector3.new(-28, 0, 102),
        ZONES.Greenway + Vector3.new(48, 0, 92),
        ZONES.Greenway + Vector3.new(90, 0, 38),
        ZONES.Crossroads + Vector3.new(-68, 0, 62),
        ZONES.Crossroads + Vector3.new(58, 0, -62),
    }
    for index, position in lumenleafPositions do
        makeLumenleaf(parent, index, position)
    end

    local glowreedPositions = {
        ZONES.Glowmere + Vector3.new(-104, 0, 58),
        ZONES.Glowmere + Vector3.new(-62, 0, 92),
        ZONES.Glowmere + Vector3.new(8, 0, 106),
        ZONES.Glowmere + Vector3.new(74, 0, 82),
        ZONES.Glowmere + Vector3.new(112, 0, 35),
    }
    for index, position in glowreedPositions do
        makeGlowreed(parent, index, position)
    end

    local sunmossPositions = {
        ZONES.Sunmoss + Vector3.new(-72, 0, 14),
        ZONES.Sunmoss + Vector3.new(-32, 0, 78),
        ZONES.Sunmoss + Vector3.new(42, 0, 96),
        ZONES.Sunmoss + Vector3.new(86, 0, 26),
    }
    for index, position in sunmossPositions do
        makeSunmossBloom(parent, index, position)
    end

    local veilPositions = {
        ZONES.Veilfall + Vector3.new(-76, 0, -24),
        ZONES.Veilfall + Vector3.new(-28, 0, -96),
        ZONES.Veilfall + Vector3.new(46, 0, -82),
        ZONES.Veilfall + Vector3.new(92, 0, -28),
    }
    for index, position in veilPositions do
        makeVeilCrystal(parent, index, position)
    end
end

local function buildServices(parent)
    makeApothecaryBench(parent, ZONES.Camp + Vector3.new(-92, 0, -28))
    makeRestShrine(parent, "camp", ZONES.Camp + Vector3.new(-78, 0, -18), "Wayfarer Camp Rest")
    makeRestShrine(
        parent,
        "eastbridge",
        ZONES.EastLanding + Vector3.new(12, 0, 48),
        "Eastbridge Rest"
    )
    makeRestShrine(parent, "mossglen", ZONES.Mossglen + Vector3.new(-102, 0, -48), "Ranger Rest")
    makeRestShrine(parent, "proving", ZONES.Proving + Vector3.new(-70, 0, 46), "Aspirant Rest")
end

local function buildCaches(parent)
    makeWayfarerCache(
        parent,
        "greenway_old_mile",
        ZONES.Greenway + Vector3.new(-122, 0, 96),
        { Currencies = { Shards = 6 }, Items = { small_tonic = 1 }, Exp = 20 },
        "Old Mile Cache"
    )
    makeWayfarerCache(
        parent,
        "glowmere_fisher",
        ZONES.Glowmere + Vector3.new(118, 0, 92),
        { Currencies = { Shards = 8 }, Items = { glowreed = 2 }, Exp = 30 },
        "Glowmere Fisher Cache"
    )
    makeWayfarerCache(
        parent,
        "gravebone_reliquary",
        ZONES.Gravebone + Vector3.new(-116, 0, 72),
        { Currencies = { Shards = 10 }, Items = { field_tonic = 1 }, Exp = 45 },
        "Gravebone Reliquary"
    )
    makeWayfarerCache(
        parent,
        "sunmoss_survey",
        ZONES.Sunmoss + Vector3.new(108, 0, 88),
        { Currencies = { Shards = 12 }, Items = { lumen_fragment = 3 }, Exp = 55 },
        "Sunmoss Survey Cache"
    )
    makeWayfarerCache(
        parent,
        "veilfall_refuge",
        ZONES.Veilfall + Vector3.new(-118, 0, 82),
        { Currencies = { Shards = 15 }, Items = { field_tonic = 1 }, Exp = 65 },
        "Veilfall Refuge Cache"
    )
end

function LumenreachGameplayService.Init()
    if initialized then
        return
    end
    initialized = true
    LumenreachActivityService.Init()

    local world = Workspace:FindFirstChild(GENERATED_NAME)
    if not world or not world:IsA("Model") then
        warn("[LumenreachGameplayService] Generated Lumenreach world not found")
        return
    end

    local activities = Instance.new("Model")
    activities.Name = "GameplayActivities"
    activities:SetAttribute("Purpose", "Interactive MMORPG world activities")
    activities.Parent = world

    buildGathering(activities)
    buildServices(activities)
    buildCaches(activities)
end

return LumenreachGameplayService
