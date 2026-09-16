local LumenreachWorldConfig = require(script.Parent.LumenreachWorldConfig)
local ZONES = LumenreachWorldConfig.Zones

return table.freeze({
    greenway_breach = table.freeze({
        DisplayName = "Greenway Breach",
        RegionId = "lumenreach",
        Center = ZONES.Greenway + Vector3.new(0, 1, 0),
        Radius = 115,
        DurationSeconds = 180,
        StartText = "Hostile creatures are breaking across the Greenway. Join the defense before the trail is overrun.",
        SuccessText = "The Greenway is secure. Participating Wayfarers received an event reward.",
        FailureText = "The breach did not close in time. The patrol will regroup before the next defense.",
        Reward = table.freeze({ Exp = 120, Currencies = table.freeze({ Shards = 10 }) }),
        Waves = table.freeze({
            table.freeze({
                table.freeze({ MonsterId = "lumen_mossling", Count = 4 }),
                table.freeze({ MonsterId = "slime", Count = 2 }),
            }),
            table.freeze({
                table.freeze({ MonsterId = "peco_peco", Count = 3 }),
                table.freeze({ MonsterId = "brambleback", Count = 2 }),
            }),
            table.freeze({
                table.freeze({ MonsterId = "slime", Count = 3 }),
                table.freeze({ MonsterId = "royal_glowcap", Count = 1 }),
            }),
        }),
    }),
    glowmere_surge = table.freeze({
        DisplayName = "Glowmere Surge",
        RegionId = "lumenreach",
        Center = ZONES.Glowmere + Vector3.new(0, 4, 0),
        Radius = 108,
        DurationSeconds = 195,
        StartText = "The Glowmere is surging with unstable Lumen. Clear the creatures gathering around the wetland channels.",
        SuccessText = "The Glowmere current has settled. Participating Wayfarers received an event reward.",
        FailureText = "The surge overwhelmed the marsh patrol. The channels will remain dangerous until the next response.",
        Reward = table.freeze({ Exp = 155, Currencies = table.freeze({ Shards = 12 }) }),
        Waves = table.freeze({
            table.freeze({
                table.freeze({ MonsterId = "slime", Count = 4 }),
                table.freeze({ MonsterId = "lumen_wisp", Count = 2 }),
            }),
            table.freeze({
                table.freeze({ MonsterId = "lumen_wisp", Count = 4 }),
                table.freeze({ MonsterId = "peco_peco", Count = 2 }),
            }),
            table.freeze({
                table.freeze({ MonsterId = "slime", Count = 2 }),
                table.freeze({ MonsterId = "royal_glowcap", Count = 1 }),
                table.freeze({ MonsterId = "lumen_wisp", Count = 2 }),
            }),
        }),
    }),
    eastbridge_assault = table.freeze({
        DisplayName = "Eastbridge Assault",
        RegionId = "lumenreach",
        Center = ZONES.EastLanding + Vector3.new(0, 2, 0),
        Radius = 122,
        DurationSeconds = 210,
        StartText = "Gravebone forces are pushing toward Eastbridge. Hold the landing and break their advance.",
        SuccessText = "Eastbridge held. Participating Wayfarers received an event reward.",
        FailureText = "The Eastbridge line broke. The defenders will regroup before another counterattack.",
        Reward = table.freeze({ Exp = 190, Currencies = table.freeze({ Shards = 15 }) }),
        Waves = table.freeze({
            table.freeze({
                table.freeze({ MonsterId = "skeleton", Count = 5 }),
            }),
            table.freeze({
                table.freeze({ MonsterId = "skeleton", Count = 4 }),
                table.freeze({ MonsterId = "brambleback", Count = 2 }),
            }),
            table.freeze({
                table.freeze({ MonsterId = "skeleton", Count = 4 }),
                table.freeze({ MonsterId = "gravebone_captain", Count = 1 }),
            }),
        }),
    }),
})
