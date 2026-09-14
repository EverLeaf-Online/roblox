local GameConfig = {}

GameConfig.LevelCap = 200
GameConfig.VerticalSliceMaxLevel = 30

GameConfig.CoreStats = {
    "Might",
    "Finesse",
    "Insight",
    "Fortune",
}

GameConfig.Progression = {
    APPerLevel = 5,
    SPPerLevelAfterFirstAdvancement = 3,
    FirstAdvancementLevels = { 8, 10 },
    LaterAdvancementLevels = { 30, 70, 120 },
}

GameConfig.Currencies = {
    "Shards",
    "Marks",
}

GameConfig.Regions = {
    "Lumenreach",
    "Brasshaven",
}

GameConfig.Bosses = {
    "Belforge Colossus",
}

GameConfig.Monetization = {
    RobuxPowerPurchasesAllowed = false,
    CosmeticOnly = true,
}

return table.freeze(GameConfig)
