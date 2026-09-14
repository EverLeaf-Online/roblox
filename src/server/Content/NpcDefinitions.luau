return table.freeze({
    lumen_guide = table.freeze({
        DisplayName = "Ilyra · Wayfarer Guide",
        RegionId = "lumenreach",
        Dialogue = table.freeze({
            "Lumenreach rewards curiosity, but the old paths have teeth. Learn the camp, read the land, and never ignore a trail that suddenly goes quiet.",
            "The Crossroads, Glowmere, Veilfall, and the Shattered Arch form the old wayfarer circuit. Walk it once and the region starts making sense.",
            "When the old grove finally stirs, come back to me. The road beyond Lumenreach does not open for untested travelers.",
        }),
        QuestOffers = table.freeze({
            "lumen_first_steps",
            "lumen_trail_watch",
            "brasshaven_passage",
        }),
    }),
    camp_quartermaster = table.freeze({
        DisplayName = "Orin · Camp Quartermaster",
        RegionId = "lumenreach",
        Dialogue = table.freeze({
            "If it keeps you standing, I probably stock it. If it glows, Maela probably wants to study it first.",
            "Bring back Lumen fragments from the wilds. They are useful for lamps, salves, and convincing nervous scouts to leave camp.",
        }),
        QuestOffers = table.freeze({ "lumen_supply_run" }),
        ShopId = "lumen_supply",
    }),
    moss_scout = table.freeze({
        DisplayName = "Tovin · Mossglen Scout",
        RegionId = "lumenreach",
        Dialogue = table.freeze({
            "The wildlife is moving in patterns it should not. Skeletons at the Arch, ridgebeaks crowding Mossglen, and something heavy moving under the roots.",
            "If you hear the grove go silent, do not assume you are alone. That is usually when the Mosswarden is closest.",
        }),
        QuestOffers = table.freeze({
            "gravebone_problem",
            "mossglen_hunt",
            "old_grove_stirs",
            "quiet_hunts",
        }),
        ShopId = "scout_outfitter",
    }),
    archive_keeper = table.freeze({
        DisplayName = "Maela · Archive Keeper",
        RegionId = "lumenreach",
        Dialogue = table.freeze({
            "The first wayfarers marked their route with Lumen stone, not ink. Their stories are still out there if you know where to look.",
            "There is a hollow behind Veilfall that does not appear on any camp map. Find it, and you may understand why the old road was abandoned.",
        }),
        QuestOffers = table.freeze({ "lumen_echoes", "lumen_attunement" }),
        ShopId = "archive_exchange",
    }),
    path_mentor = table.freeze({
        DisplayName = "Seren · Pathkeeper",
        RegionId = "lumenreach",
        AdvancementMentor = true,
        AdvancementQuestId = "first_advancement_trial",
        Dialogue = table.freeze({
            "Surviving the grove proves instinct. Choosing a path proves intent. The old Wayfarers kept five disciplines, and none of them forgive hesitation.",
            "Walk the proving circle, then bring down the Gravebone Captain at the Shattered Arch. Return when you know what kind of fighter you intend to become.",
            "The trial is behind you. The choice ahead is permanent. Read each path carefully before you bind yourself to it.",
        }),
        QuestOffers = table.freeze({ "first_advancement_trial" }),
    }),
    belforge_foreman = table.freeze({
        DisplayName = "Vale · Belforge Foreman",
        RegionId = "brasshaven",
        Dialogue = table.freeze({
            "Welcome to Brasshaven. If you want work, start by clearing the Rivet Scuttlers out of the scrap lanes before they chew through another pressure line.",
            "Good. The scrap lanes can breathe again, but the hotworks are spitting Slagmites through cracked vents. Bring me springs and clear the worst of them.",
            "Those cores are holding heat far longer than they should. Bring me a clean sample before we decide what is waking below the eastworks.",
            "The Belforge is still sealed. Brasshaven has work enough to harden you before Level 30, and the Colossus can wait until you are ready.",
        }),
        QuestOffers = table.freeze({
            "brasshaven_first_shift",
            "brasshaven_hot_lines",
            "brasshaven_core_sample",
        }),
    }),
})
