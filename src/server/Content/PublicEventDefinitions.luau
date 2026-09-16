local BrasshavenWorldConfig = require(script.Parent.BrasshavenWorldConfig)
local LumenreachWorldConfig = require(script.Parent.LumenreachWorldConfig)
local ZONES = LumenreachWorldConfig.Zones
local BRASS = BrasshavenWorldConfig.EncounterCenters

return table.freeze({
    greenway_breach = table.freeze({
        DisplayName = "Greenway Breach",
        RegionId = "lumenreach",
        MinimumLevel = 1,
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
        MinimumLevel = 4,
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
        MinimumLevel = 6,
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
    foundry_scrap_surge = table.freeze({
        DisplayName = "Foundry Scrap Surge",
        RegionId = "brasshaven",
        MinimumLevel = 10,
        WorldModelName = BrasshavenWorldConfig.GeneratedWorldName,
        GroundSurfaceName = BrasshavenWorldConfig.GroundSurfaceName,
        Center = BRASS.ScrapLanes,
        Radius = 82,
        SpawnRadius = 26,
        SpawnInnerRadius = 10,
        DurationSeconds = 195,
        StartText = "The scrap lanes are spilling machines into the foundry threshold. Rally nearby Wayfarers and stop the surge.",
        SuccessText = "The scrap lanes are under control. Participating Wayfarers received an event reward.",
        FailureText = "The foundry line was overrun. Crews are sealing the scrap lanes until another response can form.",
        Reward = table.freeze({ Exp = 360, Currencies = table.freeze({ Shards = 24 }) }),
        Waves = table.freeze({
            table.freeze({
                table.freeze({ MonsterId = "rivet_scuttler", Count = 5 }),
                table.freeze({ MonsterId = "slagmite", Count = 2 }),
            }),
            table.freeze({
                table.freeze({ MonsterId = "gearjaw_hound", Count = 3 }),
                table.freeze({ MonsterId = "cindercoil", Count = 3 }),
            }),
            table.freeze({
                table.freeze({ MonsterId = "rivet_scuttler", Count = 3 }),
                table.freeze({ MonsterId = "pressure_bastion", Count = 1 }),
            }),
        }),
    }),
    eastworks_grid_break = table.freeze({
        DisplayName = "Eastworks Grid Break",
        RegionId = "brasshaven",
        MinimumLevel = 20,
        WorldModelName = BrasshavenWorldConfig.GeneratedWorldName,
        GroundSurfaceName = BrasshavenWorldConfig.GroundSurfaceName,
        Center = BRASS.BlueglassAnnex,
        Radius = 112,
        SpawnRadius = 30,
        SpawnInnerRadius = 10,
        DurationSeconds = 215,
        StartText = "The Eastworks grid has cross-fed into the Blueglass line. Break the automation wave before the annex overloads.",
        SuccessText = "The Eastworks grid has stabilized. Participating Wayfarers received an event reward.",
        FailureText = "The Blueglass line overloaded. Eastworks crews are isolating the annex before another push.",
        Reward = table.freeze({ Exp = 720, Currencies = table.freeze({ Shards = 38, Marks = 1 }) }),
        Waves = table.freeze({
            table.freeze({
                table.freeze({ MonsterId = "blueflame_sentry", Count = 4 }),
                table.freeze({ MonsterId = "arc_siphon", Count = 2 }),
            }),
            table.freeze({
                table.freeze({ MonsterId = "foundry_reaver", Count = 4 }),
                table.freeze({ MonsterId = "blueflame_sentry", Count = 2 }),
            }),
            table.freeze({
                table.freeze({ MonsterId = "foundry_reaver", Count = 3 }),
                table.freeze({ MonsterId = "smelter_golem", Count = 1 }),
            }),
        }),
    }),
    upper_foundry_lockdown = table.freeze({
        DisplayName = "Upper Foundry Lockdown",
        RegionId = "brasshaven",
        MinimumLevel = 26,
        WorldModelName = BrasshavenWorldConfig.GeneratedWorldName,
        GroundSurfaceName = BrasshavenWorldConfig.GroundSurfaceName,
        Center = BRASS.AuthorityHall,
        Radius = 118,
        SpawnRadius = 31,
        SpawnInnerRadius = 10,
        DurationSeconds = 225,
        StartText = "Old authority protocols have locked the upper foundry. Clear the hostile machines before the district seals completely.",
        SuccessText = "The upper-foundry lockdown is broken. Participating Wayfarers received an event reward.",
        FailureText = "Authority control held the district. The marshal will reopen the line after the mechanisms cool.",
        Reward = table.freeze({ Exp = 980, Currencies = table.freeze({ Shards = 52, Marks = 1 }) }),
        Waves = table.freeze({
            table.freeze({
                table.freeze({ MonsterId = "forge_specter", Count = 4 }),
                table.freeze({ MonsterId = "ironclad_enforcer", Count = 2 }),
            }),
            table.freeze({
                table.freeze({ MonsterId = "molten_drake", Count = 4 }),
                table.freeze({ MonsterId = "ironclad_enforcer", Count = 3 }),
            }),
            table.freeze({
                table.freeze({ MonsterId = "forge_specter", Count = 3 }),
                table.freeze({ MonsterId = "bellows_titan", Count = 1 }),
            }),
        }),
    }),
})
