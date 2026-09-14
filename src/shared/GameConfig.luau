local GameConfig = {}

GameConfig.Environment = "development"

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

GameConfig.DataStore = {
    Name = "EverLeafPlayerData_v1",
    SchemaVersion = 2,
    AutosaveSeconds = 60,
    SessionLockSeconds = 180,
    MaxAttempts = 4,
    RetryBaseSeconds = 1,
    EnableInStudio = false,
}

GameConfig.Security = {
    AllocateStat = {
        Capacity = 8,
        RefillPerSecond = 4,
    },
    BasicAttack = {
        Capacity = 6,
        RefillPerSecond = 5,
    },
    GameplayAction = {
        Capacity = 12,
        RefillPerSecond = 8,
    },
    ProfileRequest = {
        Capacity = 4,
        RefillPerSecond = 1,
    },
    CatalogRequest = {
        Capacity = 2,
        RefillPerSecond = 0.2,
    },
}

GameConfig.Movement = {
    DefaultPlaneZ = 0,
    DepthTolerance = 1.5,
    HardCorrectionDepth = 5,
    ServerCheckInterval = 0.1,
    CameraDistance = 32,
    CameraHeight = 5,
    CameraLookHeight = 2.5,
    CameraResponsiveness = 10,
}

GameConfig.DerivedStats = {
    BaseHP = 100,
    HPPerLevel = 12,
    HPPerMight = 5,
    BaseMP = 50,
    MPPerLevel = 4,
    MPPerInsight = 6,
}

GameConfig.Combat = {
    DefaultMastery = 0.25,
    MinimumMastery = 0.1,
    MaximumMastery = 1,
    BeginnerAttackPower = 5,
    BeginnerStatScale = 1.5,
    BasicAttackCooldown = 0.55,
    BasicAttackRange = 10,
    BasicAttackVerticalRange = 8,
    BasicAttackDepthRange = 3,
}

GameConfig.Development = {
    SpawnTrainingDummyInStudio = true,
}

GameConfig.Places = {
    World = 0,
    Instance = 0,
}

GameConfig.AdminUserIds = {}

GameConfig.Features = {
    Crafting = true,
    Enhancement = false,
    Storage = false,
    Trading = false,
}

GameConfig.Monetization = {
    RobuxPowerPurchasesAllowed = false,
    CosmeticOnly = true,
}

return table.freeze(GameConfig)
