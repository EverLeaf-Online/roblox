return table.freeze({
    lumen_first_steps = table.freeze({
        DisplayName = "First Steps in Lumenreach",
        MinimumLevel = 1,
        StartNpcId = "lumen_guide",
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "lumen_mossling", Required = 2 }),
            table.freeze({ Type = "Interact", Target = "camp_quartermaster", Required = 1 }),
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
            table.freeze({ Type = "Reach", Target = "lumenwood_crossroads", Required = 1 }),
            table.freeze({ Type = "Explore", Target = "glowmere_pool", Required = 1 }),
        }),
        Reward = table.freeze({ Exp = 70, Currencies = table.freeze({ Shards = 8 }) }),
    }),
    gravebone_problem = table.freeze({
        DisplayName = "Bones at Gravebone Watch",
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
            table.freeze({ Type = "Explore", Target = "gravebone_watch", Required = 1 }),
            table.freeze({ Type = "Explore", Target = "eastbridge_crossing", Required = 1 }),
            table.freeze({ Type = "Explore", Target = "mossglen_valley", Required = 1 }),
            table.freeze({ Type = "Explore", Target = "glowmere_pool", Required = 1 }),
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
    lumen_fieldcraft = table.freeze({
        DisplayName = "Fieldcraft: Lumenleaf",
        MinimumLevel = 1,
        StartNpcId = "camp_healer",
        PrerequisiteQuests = table.freeze({ "lumen_first_steps" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Collect", Target = "lumenleaf", Required = 4 }),
            table.freeze({ Type = "Craft", Target = "small_tonic", Required = 1 }),
            table.freeze({ Type = "Use", Target = "small_tonic", Required = 1 }),
        }),
        Reward = table.freeze({
            Exp = 55,
            Currencies = table.freeze({ Shards = 5 }),
            Items = table.freeze({ small_tonic = 2 }),
        }),
    }),
    glowmere_reedwork = table.freeze({
        DisplayName = "Reeds of Glowmere",
        MinimumLevel = 2,
        StartNpcId = "glowmere_keeper",
        PrerequisiteQuests = table.freeze({ "lumen_trail_watch" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Collect", Target = "glowreed", Required = 4 }),
            table.freeze({ Type = "Explore", Target = "glowmere_pool", Required = 1 }),
            table.freeze({ Type = "Interact", Target = "camp_healer", Required = 1 }),
        }),
        Reward = table.freeze({
            Exp = 95,
            Currencies = table.freeze({ Shards = 8 }),
            Items = table.freeze({ field_tonic = 1 }),
        }),
    }),
    sunmoss_observations = table.freeze({
        DisplayName = "Light Above the Ridge",
        MinimumLevel = 7,
        StartNpcId = "sunmoss_researcher",
        PrerequisiteQuests = table.freeze({ "old_grove_stirs" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Collect", Target = "sunmoss_bloom", Required = 3 }),
            table.freeze({ Type = "Explore", Target = "sunmoss_overlook", Required = 1 }),
        }),
        Reward = table.freeze({
            Exp = 220,
            Currencies = table.freeze({ Shards = 14 }),
        }),
    }),
    veilfall_resonance = table.freeze({
        DisplayName = "Resonance Below Veilfall",
        MinimumLevel = 8,
        StartNpcId = "veilfall_warden",
        PrerequisiteQuests = table.freeze({ "first_advancement_trial" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Collect", Target = "veilwater_crystal", Required = 3 }),
            table.freeze({ Type = "Explore", Target = "veilfall_cascade", Required = 1 }),
        }),
        Reward = table.freeze({
            Exp = 280,
            Currencies = table.freeze({ Shards = 16 }),
            Items = table.freeze({ field_tonic = 1 }),
        }),
    }),
    greenway_breach_watch = table.freeze({
        DisplayName = "Hold the Greenway",
        MinimumLevel = 3,
        StartNpcId = "lumen_guide",
        PrerequisiteQuests = table.freeze({ "lumen_trail_watch" }),
        Objectives = table.freeze({
            table.freeze({ Type = "PublicEvent", Target = "greenway_breach", Required = 1 }),
        }),
        Reward = table.freeze({
            Exp = 140,
            Currencies = table.freeze({ Shards = 12 }),
            Items = table.freeze({ field_tonic = 1 }),
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
    eastworks_blueflame = table.freeze({
        DisplayName = "Blueglass Burn",
        MinimumLevel = 20,
        MinimumAdvancementTier = 1,
        StartNpcId = "eastworks_engineer",
        PrerequisiteQuests = table.freeze({ "brasshaven_railbreaker" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "blueflame_sentry", Required = 5 }),
            table.freeze({ Type = "Collect", Target = "flux_lens", Required = 4 }),
        }),
        Reward = table.freeze({
            Exp = 2400,
            Currencies = table.freeze({ Shards = 80 }),
        }),
    }),
    eastworks_reaver_line = table.freeze({
        DisplayName = "Reavers on the Line",
        MinimumLevel = 21,
        MinimumAdvancementTier = 1,
        StartNpcId = "eastworks_engineer",
        PrerequisiteQuests = table.freeze({ "eastworks_blueflame" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "foundry_reaver", Required = 5 }),
            table.freeze({ Type = "Collect", Target = "reaver_actuator", Required = 4 }),
        }),
        Reward = table.freeze({
            Exp = 2600,
            Currencies = table.freeze({ Shards = 88 }),
        }),
    }),
    eastworks_grid_purge = table.freeze({
        DisplayName = "Purge the Eastworks Grid",
        MinimumLevel = 22,
        MinimumAdvancementTier = 1,
        StartNpcId = "eastworks_engineer",
        PrerequisiteQuests = table.freeze({ "eastworks_reaver_line" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "blueflame_sentry", Required = 4 }),
            table.freeze({ Type = "Defeat", Target = "foundry_reaver", Required = 4 }),
        }),
        Reward = table.freeze({
            Exp = 2500,
            Currencies = table.freeze({ Shards = 96 }),
            Items = table.freeze({ field_tonic = 2 }),
        }),
    }),
    eastworks_smelter_golem = table.freeze({
        DisplayName = "Heart of the Smelter",
        MinimumLevel = 23,
        MinimumAdvancementTier = 1,
        StartNpcId = "eastworks_engineer",
        PrerequisiteQuests = table.freeze({ "eastworks_grid_purge" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "smelter_golem", Required = 1 }),
            table.freeze({ Type = "Collect", Target = "smelter_core", Required = 1 }),
        }),
        Reward = table.freeze({
            Exp = 3400,
            Currencies = table.freeze({ Shards = 110, Marks = 1 }),
        }),
    }),
    belforge_flux_ghosts = table.freeze({
        DisplayName = "Ghosts in the Flux",
        MinimumLevel = 24,
        MinimumAdvancementTier = 1,
        StartNpcId = "belforge_marshal",
        PrerequisiteQuests = table.freeze({ "eastworks_smelter_golem" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "forge_specter", Required = 5 }),
            table.freeze({ Type = "Collect", Target = "specter_residue", Required = 4 }),
        }),
        Reward = table.freeze({
            Exp = 3300,
            Currencies = table.freeze({ Shards = 120 }),
        }),
    }),
    belforge_enforcer_protocol = table.freeze({
        DisplayName = "Enforcer Protocol",
        MinimumLevel = 25,
        MinimumAdvancementTier = 1,
        StartNpcId = "belforge_marshal",
        PrerequisiteQuests = table.freeze({ "belforge_flux_ghosts" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "ironclad_enforcer", Required = 5 }),
            table.freeze({ Type = "Collect", Target = "enforcer_badge", Required = 4 }),
        }),
        Reward = table.freeze({
            Exp = 3500,
            Currencies = table.freeze({ Shards = 132 }),
        }),
    }),
    belforge_molten_runoff = table.freeze({
        DisplayName = "Molten Runoff",
        MinimumLevel = 26,
        MinimumAdvancementTier = 1,
        StartNpcId = "belforge_marshal",
        PrerequisiteQuests = table.freeze({ "belforge_enforcer_protocol" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "molten_drake", Required = 5 }),
            table.freeze({ Type = "Collect", Target = "drake_scale", Required = 4 }),
        }),
        Reward = table.freeze({
            Exp = 3700,
            Currencies = table.freeze({ Shards = 145 }),
        }),
    }),
    belforge_triple_lock = table.freeze({
        DisplayName = "Three Locks, One Furnace",
        MinimumLevel = 27,
        MinimumAdvancementTier = 1,
        StartNpcId = "belforge_marshal",
        PrerequisiteQuests = table.freeze({ "belforge_molten_runoff" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "forge_specter", Required = 3 }),
            table.freeze({ Type = "Defeat", Target = "ironclad_enforcer", Required = 3 }),
            table.freeze({ Type = "Defeat", Target = "molten_drake", Required = 3 }),
        }),
        Reward = table.freeze({
            Exp = 3300,
            Currencies = table.freeze({ Shards = 160 }),
            Items = table.freeze({ field_tonic = 3 }),
        }),
    }),
    belforge_bellows_titan = table.freeze({
        DisplayName = "The Bellows Titan",
        MinimumLevel = 28,
        MinimumAdvancementTier = 1,
        StartNpcId = "belforge_marshal",
        PrerequisiteQuests = table.freeze({ "belforge_triple_lock" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "bellows_titan", Required = 1 }),
            table.freeze({ Type = "Collect", Target = "bellows_core", Required = 1 }),
        }),
        Reward = table.freeze({
            Exp = 4800,
            Currencies = table.freeze({ Shards = 180, Marks = 1 }),
        }),
    }),
    belforge_gate_sentinel = table.freeze({
        DisplayName = "Sentinel at the Belforge",
        MinimumLevel = 29,
        MinimumAdvancementTier = 1,
        StartNpcId = "belforge_marshal",
        PrerequisiteQuests = table.freeze({ "belforge_bellows_titan" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "belforge_sentinel", Required = 1 }),
            table.freeze({ Type = "Collect", Target = "belforge_gate_key", Required = 1 }),
        }),
        Reward = table.freeze({
            Exp = 5050,
            Currencies = table.freeze({ Shards = 200, Marks = 2 }),
        }),
    }),
    belforge_colossus_trial = table.freeze({
        DisplayName = "The Belforge Colossus",
        MinimumLevel = 30,
        MinimumAdvancementTier = 2,
        StartNpcId = "belforge_oathkeeper",
        PrerequisiteQuests = table.freeze({ "belforge_gate_sentinel" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "belforge_colossus", Required = 1 }),
            table.freeze({ Type = "Collect", Target = "belforge_colossus_core", Required = 1 }),
        }),
        Reward = table.freeze({
            Exp = 2500,
            Currencies = table.freeze({ Shards = 250, Marks = 3 }),
            Items = table.freeze({ colossus_emblem = 1 }),
        }),
    }),
})
