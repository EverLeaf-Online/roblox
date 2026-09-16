-- Canonical Lumenreach world coordinates and topology.
-- Keep gameplay, events, travel, and environment generation on this shared spatial contract
-- so new map passes cannot silently drift their interaction/event coordinates away from art.
local zones = table.freeze({
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

local eastbridgeWest = Vector3.new(-292, 4, 92)
local eastbridgeEast = Vector3.new(-205, 6, 92)
local reedbridgeWest = Vector3.new(-315, 0, 350)
local reedbridgeEast = Vector3.new(-228, 6, 350)
local arrivalOrigin = zones.Camp + Vector3.new(-65, 0, 12)
local trainingOrigin = zones.Camp + Vector3.new(68, 0, -18)
local brambleOrigin = zones.Mossglen + Vector3.new(150, 0, -30)

local routes = table.freeze({
    table.freeze({
        Id = "greenway",
        Width = 22,
        Points = table.freeze({
            zones.Camp + Vector3.new(88, 0, 12),
            Vector3.new(-835, 2, 20),
            zones.Greenway,
            Vector3.new(-610, 3, 52),
            zones.Crossroads,
        }),
    }),
    table.freeze({
        Id = "proving_road",
        Width = 15,
        Points = table.freeze({
            zones.Camp + Vector3.new(5, 0, -82),
            Vector3.new(-945, 3, -190),
            Vector3.new(-940, 4, -270),
            zones.Proving,
        }),
    }),
    table.freeze({
        Id = "glowmere_road",
        Width = 16,
        Points = table.freeze({
            zones.Crossroads,
            Vector3.new(-490, 3, 175),
            Vector3.new(-470, 0, 300),
            zones.Glowmere,
        }),
    }),
    table.freeze({
        Id = "eastbridge_west",
        Width = 20,
        Points = table.freeze({
            zones.Crossroads,
            Vector3.new(-395, 4, 75),
            Vector3.new(-335, 4, 88),
            eastbridgeWest,
        }),
    }),
    table.freeze({
        Id = "eastbridge_east",
        Width = 20,
        Points = table.freeze({
            eastbridgeEast,
            zones.EastLanding,
        }),
    }),
    table.freeze({
        Id = "reedbridge_west",
        Width = 15,
        Points = table.freeze({
            zones.Glowmere,
            Vector3.new(-360, -1, 390),
            reedbridgeWest,
        }),
    }),
    table.freeze({
        Id = "reedbridge_east",
        Width = 15,
        Points = table.freeze({
            reedbridgeEast,
            Vector3.new(-110, 6, 345),
            zones.Mossglen,
        }),
    }),
    table.freeze({
        Id = "gravebone_road",
        Width = 16,
        Points = table.freeze({
            zones.EastLanding,
            Vector3.new(-20, 6, 20),
            Vector3.new(58, 6, -90),
            zones.Gravebone,
        }),
    }),
    table.freeze({
        Id = "mossglen_road",
        Width = 19,
        Points = table.freeze({
            zones.EastLanding,
            Vector3.new(-30, 6, 185),
            Vector3.new(40, 6, 255),
            zones.Mossglen,
        }),
    }),
    table.freeze({
        Id = "sunmoss_road",
        Width = 16,
        Points = table.freeze({
            zones.Mossglen,
            Vector3.new(260, 14, 350),
            Vector3.new(385, 26, 395),
            zones.Sunmoss,
        }),
    }),
    table.freeze({
        Id = "bramble_road",
        Width = 14,
        Points = table.freeze({
            zones.Mossglen + Vector3.new(75, 0, -12),
            brambleOrigin,
        }),
    }),
    table.freeze({
        Id = "veilfall_road",
        Width = 16,
        Points = table.freeze({
            zones.Gravebone,
            Vector3.new(225, 1, -270),
            Vector3.new(320, -8, -330),
            zones.Veilfall,
        }),
    }),
    table.freeze({
        Id = "ruins_main",
        Width = 20,
        Points = table.freeze({
            zones.Mossglen + Vector3.new(70, 0, -75),
            Vector3.new(350, 7, 200),
            Vector3.new(540, 8, 150),
            Vector3.new(720, 9, 100),
            zones.Ruins,
        }),
    }),
    table.freeze({
        Id = "sunmoss_return",
        Width = 15,
        Points = table.freeze({
            zones.Sunmoss,
            Vector3.new(620, 27, 360),
            Vector3.new(735, 18, 235),
            zones.Ruins + Vector3.new(-45, 0, 38),
        }),
    }),
    table.freeze({
        Id = "veilfall_return",
        Width = 16,
        Points = table.freeze({
            zones.Veilfall,
            Vector3.new(570, -10, -290),
            Vector3.new(700, 1, -170),
            Vector3.new(810, 8, -40),
            zones.Ruins + Vector3.new(-35, 0, -38),
        }),
    }),
})

local gorgePoints = table.freeze({
    Vector3.new(-370, -6, 560),
    Vector3.new(-325, -7, 410),
    Vector3.new(-265, -8, 265),
    Vector3.new(-250, -9, 95),
    Vector3.new(-155, -10, -20),
    Vector3.new(-30, -11, -135),
    Vector3.new(150, -13, -245),
    Vector3.new(335, -16, -330),
    zones.Veilfall + Vector3.new(-20, 0, -5),
})

local dressingExclusions = table.freeze({
    table.freeze({ Center = arrivalOrigin, Radius = 54 }),
    table.freeze({ Center = trainingOrigin, Radius = 34 }),
    table.freeze({ Center = zones.Camp, Radius = 136 }),
    table.freeze({ Center = zones.Crossroads, Radius = 82 }),
    table.freeze({ Center = zones.EastLanding, Radius = 88 }),
    table.freeze({ Center = zones.Proving, Radius = 50 }),
    table.freeze({ Center = zones.Greenway + Vector3.new(0, 0, 72), Radius = 48 }),
    table.freeze({ Center = zones.Glowmere + Vector3.new(-90, 0, 70), Radius = 50 }),
    table.freeze({ Center = zones.Glowmere + Vector3.new(-62, 0, 48), Radius = 24 }),
    table.freeze({ Center = zones.Gravebone + Vector3.new(70, 0, 70), Radius = 48 }),
    table.freeze({ Center = zones.Gravebone + Vector3.new(-60, 0, -60), Radius = 28 }),
    table.freeze({ Center = zones.Mossglen + Vector3.new(-20, 0, -90), Radius = 54 }),
    table.freeze({ Center = brambleOrigin, Radius = 48 }),
    table.freeze({ Center = zones.Mossglen + Vector3.new(-10, 0, 100), Radius = 58 }),
    table.freeze({ Center = zones.Veilfall + Vector3.new(0, 0, -80), Radius = 52 }),
    table.freeze({ Center = zones.Ruins + Vector3.new(88, 0, 55), Radius = 56 }),
})

return table.freeze({
    WorldWidth = 2200,
    WorldDepth = 1250,
    DesignVersion = 28,
    Zones = zones,
    EastbridgeWest = eastbridgeWest,
    EastbridgeEast = eastbridgeEast,
    ReedbridgeWest = reedbridgeWest,
    ReedbridgeEast = reedbridgeEast,
    ArrivalOrigin = arrivalOrigin,
    TrainingOrigin = trainingOrigin,
    BrambleOrigin = brambleOrigin,
    Routes = routes,
    GorgePoints = gorgePoints,
    DressingExclusions = dressingExclusions,
})
