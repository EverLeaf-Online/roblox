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
            Exp = 400,
            Currencies = table.freeze({ Shards = 30, Marks = 1 }),
        }),
    }),
    first_advancement_trial = table.freeze({
        DisplayName = "The Five Paths",
        MinimumLevel = 8,
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
    brasshaven_passage = table.freeze({
        DisplayName = "The Road Beyond Lumenreach",
        MinimumLevel = 20,
        StartNpcId = "lumen_guide",
        PrerequisiteQuests = table.freeze({ "old_grove_stirs" }),
        Objectives = table.freeze({
            table.freeze({ Type = "Explore", Target = "shattered_lumen_arch", Required = 1 }),
        }),
        Reward = table.freeze({
            Exp = 220,
            Currencies = table.freeze({ Shards = 20 }),
            UnlockRegions = table.freeze({ "brasshaven" }),
        }),
    }),
})
