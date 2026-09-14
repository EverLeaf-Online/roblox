return table.freeze({
    lumen_first_steps = table.freeze({
        DisplayName = "First Steps in Lumenreach",
        MinimumLevel = 1,
        StartNpcId = "lumen_guide",
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "lumen_mossling", Required = 2 }),
        }),
        Reward = table.freeze({ Exp = 35, Currencies = table.freeze({ Shards = 4 }) }),
    }),
    lumen_supply_run = table.freeze({
        DisplayName = "Fragments for the Road",
        MinimumLevel = 1,
        StartNpcId = "camp_quartermaster",
        PrerequisiteQuests = table.freeze({ "lumen_first_steps" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Collect", Target = "lumen_fragment", Required = 3 }),
        }),
        Reward = table.freeze({
            Exp = 45,
            Currencies = table.freeze({ Shards = 6 }),
            Items = table.freeze({ field_tonic = 2 }),
        }),
    }),
    lumen_trail_watch = table.freeze({
        DisplayName = "Waymarks of Lumenreach",
        MinimumLevel = 2,
        StartNpcId = "lumen_guide",
        PrerequisiteQuests = table.freeze({ "lumen_first_steps" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Explore", Target = "lumenwood_crossroads", Required = 1 }),
            table.freeze({ Type = "Explore", Target = "glowmere_pool", Required = 1 }),
        }),
        Reward = table.freeze({ Exp = 70, Currencies = table.freeze({ Shards = 8 }) }),
    }),
    gravebone_problem = table.freeze({
        DisplayName = "Bones Beneath the Arch",
        MinimumLevel = 3,
        StartNpcId = "moss_scout",
        PrerequisiteQuests = table.freeze({ "lumen_trail_watch" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "skeleton", Required = 4 }),
            table.freeze({ Type = "Collect", Target = "gravebone_shard", Required = 2 }),
        }),
        Reward = table.freeze({ Exp = 105, Currencies = table.freeze({ Shards = 12 }) }),
    }),
    mossglen_hunt = table.freeze({
        DisplayName = "Trouble in Mossglen",
        MinimumLevel = 4,
        StartNpcId = "moss_scout",
        PrerequisiteQuests = table.freeze({ "gravebone_problem" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "peco_peco", Required = 4 }),
            table.freeze({ Type = "Defeat", Target = "brambleback", Required = 3 }),
        }),
        Reward = table.freeze({
            Exp = 145,
            Currencies = table.freeze({ Shards = 15 }),
            Items = table.freeze({ scout_blade = 1 }),
        }),
    }),
    lumen_echoes = table.freeze({
        DisplayName = "Echoes of the Old Wayfarers",
        MinimumLevel = 4,
        StartNpcId = "archive_keeper",
        PrerequisiteQuests = table.freeze({ "lumen_trail_watch" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Explore", Target = "shattered_lumen_arch", Required = 1 }),
            table.freeze({ Type = "Explore", Target = "veilfall_cascade", Required = 1 }),
            table.freeze({ Type = "Explore", Target = "sunmoss_overlook", Required = 1 }),
            table.freeze({ Type = "Explore", Target = "whisperroot_hollow", Required = 1 }),
        }),
        Reward = table.freeze({
            Exp = 165,
            Currencies = table.freeze({ Shards = 18 }),
            Items = table.freeze({ mossguard_charm = 1 }),
        }),
    }),
    old_grove_stirs = table.freeze({
        DisplayName = "Root of the Old Grove",
        MinimumLevel = 6,
        StartNpcId = "moss_scout",
        PrerequisiteQuests = table.freeze({ "mossglen_hunt", "lumen_echoes" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "mosswarden", Required = 1 }),
            table.freeze({ Type = "Collect", Target = "mosswarden_core", Required = 1 }),
        }),
        Reward = table.freeze({
            Exp = 525,
            Currencies = table.freeze({ Shards = 30, Marks = 1 }),
        }),
    }),
    first_advancement_trial = table.freeze({
        DisplayName = "The Five Paths",
        MinimumLevel = 7,
        StartNpcId = "path_mentor",
        PrerequisiteQuests = table.freeze({ "old_grove_stirs" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Explore", Target = "wayfarer_proving_circle", Required = 1 }),
            table.freeze({ Type = "Defeat", Target = "gravebone_captain", Required = 1 }),
        }),
        Reward = table.freeze({
            Exp = 250,
            Currencies = table.freeze({ Shards = 20, Marks = 1 }),
        }),
    }),
    quiet_hunts = table.freeze({
        DisplayName = "The Quiet Hunts",
        MinimumLevel = 8,
        StartNpcId = "moss_scout",
        PrerequisiteQuests = table.freeze({ "first_advancement_trial" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "royal_glowcap", Required = 1 }),
            table.freeze({ Type = "Defeat", Target = "lumen_wisp", Required = 3 }),
        }),
        Reward = table.freeze({
            Exp = 600,
            Currencies = table.freeze({ Shards = 18 }),
        }),
    }),
    lumen_attunement = table.freeze({
        DisplayName = "Attunement of the Five",
        MinimumLevel = 8,
        StartNpcId = "archive_keeper",
        PrerequisiteQuests = table.freeze({ "first_advancement_trial" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Collect", Target = "wisp_essence", Required = 4 }),
            table.freeze({ Type = "Collect", Target = "glowcap_gel", Required = 4 }),
        }),
        Reward = table.freeze({
            Exp = 650,
            Currencies = table.freeze({ Shards = 18 }),
        }),
    }),
    brasshaven_passage = table.freeze({
        DisplayName = "The Road Beyond Lumenreach",
        MinimumLevel = 10,
        MinimumAdvancementTier = 1,
        StartNpcId = "lumen_guide",
        PrerequisiteQuests = table.freeze({ "first_advancement_trial" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Explore", Target = "shattered_lumen_arch", Required = 1 }),
        }),
        Reward = table.freeze({
            Exp = 220,
            Currencies = table.freeze({ Shards = 20 }),
            UnlockRegions = table.freeze({ "brasshaven" }),
        }),
    }),
    brasshaven_first_shift = table.freeze({
        DisplayName = "First Shift at the Foundry",
        MinimumLevel = 10,
        MinimumAdvancementTier = 1,
        StartNpcId = "belforge_foreman",
        PrerequisiteQuests = table.freeze({ "brasshaven_passage" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "rivet_scuttler", Required = 5 }),
        }),
        Reward = table.freeze({
            Exp = 550,
            Currencies = table.freeze({ Shards = 25 }),
        }),
    }),
    brasshaven_hot_lines = table.freeze({
        DisplayName = "Heat in the Lines",
        MinimumLevel = 11,
        MinimumAdvancementTier = 1,
        StartNpcId = "belforge_foreman",
        PrerequisiteQuests = table.freeze({ "brasshaven_first_shift" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Collect", Target = "rivet_spring", Required = 5 }),
            table.freeze({ Type = "Defeat", Target = "slagmite", Required = 3 }),
        }),
        Reward = table.freeze({
            Exp = 700,
            Currencies = table.freeze({ Shards = 30 }),
        }),
    }),
    brasshaven_core_sample = table.freeze({
        DisplayName = "A Core Worth Studying",
        MinimumLevel = 12,
        MinimumAdvancementTier = 1,
        StartNpcId = "belforge_foreman",
        PrerequisiteQuests = table.freeze({ "brasshaven_hot_lines" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Collect", Target = "slag_core", Required = 4 }),
        }),
        Reward = table.freeze({
            Exp = 1100,
            Currencies = table.freeze({ Shards = 35 }),
            Items = table.freeze({ field_tonic = 2 }),
        }),
    }),
    brasshaven_teeth_in_gears = table.freeze({
        DisplayName = "Teeth in the Gears",
        MinimumLevel = 13,
        MinimumAdvancementTier = 1,
        StartNpcId = "belforge_foreman",
        PrerequisiteQuests = table.freeze({ "brasshaven_core_sample" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "gearjaw_hound", Required = 5 }),
            table.freeze({ Type = "Collect", Target = "gearjaw_tooth", Required = 4 }),
        }),
        Reward = table.freeze({
            Exp = 1200,
            Currencies = table.freeze({ Shards = 42 }),
        }),
    }),
    brasshaven_cinder_signal = table.freeze({
        DisplayName = "Cinders in the Ducts",
        MinimumLevel = 14,
        MinimumAdvancementTier = 1,
        StartNpcId = "belforge_foreman",
        PrerequisiteQuests = table.freeze({ "brasshaven_teeth_in_gears" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "cindercoil", Required = 4 }),
            table.freeze({ Type = "Collect", Target = "cinder_coil", Required = 4 }),
        }),
        Reward = table.freeze({
            Exp = 1400,
            Currencies = table.freeze({ Shards = 48 }),
        }),
    }),
    brasshaven_pressure_bastion = table.freeze({
        DisplayName = "The Pressure Bastion",
        MinimumLevel = 15,
        MinimumAdvancementTier = 1,
        StartNpcId = "belforge_foreman",
        PrerequisiteQuests = table.freeze({ "brasshaven_cinder_signal" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "pressure_bastion", Required = 1 }),
            table.freeze({ Type = "Collect", Target = "pressure_seal", Required = 1 }),
        }),
        Reward = table.freeze({
            Exp = 1800,
            Currencies = table.freeze({ Shards = 60, Marks = 1 }),
        }),
    }),
    brasshaven_dead_shift = table.freeze({
        DisplayName = "The Dead Shift",
        MinimumLevel = 16,
        MinimumAdvancementTier = 1,
        StartNpcId = "belforge_foreman",
        PrerequisiteQuests = table.freeze({ "brasshaven_pressure_bastion" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "furnace_husk", Required = 5 }),
            table.freeze({ Type = "Collect", Target = "furnace_plate", Required = 4 }),
        }),
        Reward = table.freeze({
            Exp = 1500,
            Currencies = table.freeze({ Shards = 55 }),
        }),
    }),
    brasshaven_arc_fault = table.freeze({
        DisplayName = "Arc Fault",
        MinimumLevel = 17,
        MinimumAdvancementTier = 1,
        StartNpcId = "belforge_foreman",
        PrerequisiteQuests = table.freeze({ "brasshaven_dead_shift" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "arc_siphon", Required = 4 }),
            table.freeze({ Type = "Collect", Target = "arc_cell", Required = 4 }),
        }),
        Reward = table.freeze({
            Exp = 1900,
            Currencies = table.freeze({ Shards = 62 }),
        }),
    }),
    brasshaven_crossfeed = table.freeze({
        DisplayName = "Crossfeed Pressure",
        MinimumLevel = 18,
        MinimumAdvancementTier = 1,
        StartNpcId = "belforge_foreman",
        PrerequisiteQuests = table.freeze({ "brasshaven_arc_fault" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "furnace_husk", Required = 4 }),
            table.freeze({ Type = "Defeat", Target = "cindercoil", Required = 4 }),
        }),
        Reward = table.freeze({
            Exp = 1800,
            Currencies = table.freeze({ Shards = 68 }),
            Items = table.freeze({ field_tonic = 2 }),
        }),
    }),
    brasshaven_railbreaker = table.freeze({
        DisplayName = "Break the Railbreaker",
        MinimumLevel = 19,
        MinimumAdvancementTier = 1,
        StartNpcId = "belforge_foreman",
        PrerequisiteQuests = table.freeze({ "brasshaven_crossfeed" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "railbreaker", Required = 1 }),
            table.freeze({ Type = "Collect", Target = "railbreaker_pin", Required = 1 }),
        }),
        Reward = table.freeze({
            Exp = 2500,
            Currencies = table.freeze({ Shards = 75, Marks = 1 }),
        }),
    }),
})
