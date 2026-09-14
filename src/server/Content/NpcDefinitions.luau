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
        QuestOffers = table.freeze({ "lumen_echoes" }),
        ShopId = "archive_exchange",
    }),
})
