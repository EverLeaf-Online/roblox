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
GameConfig.CurrencyMaximumBalance = 2_000_000_000

GameConfig.Regions = {
    "Lumenreach",
    "Brasshaven",
}

GameConfig.Bosses = {
    "Belforge Colossus",
}

GameConfig.Streaming = {
    PrefetchTimeoutSeconds = 3,
}

GameConfig.DataStore = {
    Name = "EverLeafPlayerData_v1",
    SchemaVersion = 3,
    AutosaveSeconds = 60,
    SessionLockSeconds = 180,
    MaxAttempts = 4,
    RetryBaseSeconds = 1,
    ShutdownSaveSeconds = 24,
    EnableInStudio = false,
}

GameConfig.Security = {
    BasicAttack = {
        Capacity = 6,
        RefillPerSecond = 5,
    },
    GameplayAction = {
        Capacity = 12,
        RefillPerSecond = 8,
    },
    MovementIntent = {
        Capacity = 8,
        RefillPerSecond = 6,
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
    WalkSpeed = 16,
    SprintSpeed = 24,
    CrouchSpeed = 9,
    JumpPower = 50,
    DodgeSpeed = 42,
    DodgeDuration = 0.22,
    DodgeCooldown = 0.8,
    MaxHorizontalSpeed = 58,
    MaxVerticalSpeed = 180,
    DisplacementSlack = 7,
    TeleportGraceSeconds = 0.75,
    GamepadDeadzone = 0.15,
    CrouchCameraOffset = Vector3.new(0, -1.15, 0),
    ServerCheckInterval = 0.1,
}

GameConfig.Camera = {
    Distance = 10,
    FocusHeight = 2.5,
    ShoulderOffset = 1.25,
    FieldOfView = 70,
    Responsiveness = 16,
    MouseSensitivity = 0.0032,
    GamepadSensitivity = 2.2,
    MinPitchDegrees = -65,
    MaxPitchDegrees = 55,
    CollisionPadding = 0.35,
    MinimumCollisionDistance = 1.75,
    CollisionRecoveryResponsiveness = 7,
}

GameConfig.DerivedStats = {
    BaseHP = 100,
    HPPerLevel = 12,
    HPPerMight = 5,
    BaseMP = 50,
    MPPerLevel = 4,
    MPPerInsight = 6,
    BaseDefense = 2,
    DefensePerLevel = 0.4,
    DefensePerMight = 0.6,
    BaseCritChance = 0.04,
    CritChancePerFortune = 0.0035,
    CritChancePerFinesse = 0.0015,
    MaximumCritChance = 0.35,
    BaseCritMultiplier = 1.45,
    CritMultiplierPerFinesse = 0.0025,
    CritMultiplierPerFortune = 0.0015,
    MaximumCritMultiplier = 2.25,
}

GameConfig.Resources = {
    RegenTickSeconds = 1,
    MPRegenDelay = 3.5,
    HPRegenDelay = 6,
    BaseMPPerSecond = 2,
    MPPerInsightPerSecond = 0.12,
    MinimumHPPerSecond = 2,
    HPPercentPerSecond = 0.015,
}

GameConfig.Combat = {
    DefaultMastery = 0.25,
    MinimumMastery = 0.1,
    MaximumMastery = 1,
    BeginnerAttackPower = 5,
    BeginnerStatScale = 1.5,
    BasicAttackCooldown = 0.55,
    BasicAttackRange = 9,
    BasicAttackVerticalRange = 6,
    BasicAttackArcDegrees = 120,
    BasicAttackHitboxWidth = 7,
    BasicProjectileSpeed = 76,
    BasicProjectileRadius = 0.4,
    ProjectileStepCap = 60,
    RequireLineOfSight = true,
    MonsterAttackHitboxWidthMultiplier = 1.15,
    MonsterAttackHitboxMinWidth = 4,
    MonsterAttackHitboxMaxWidth = 10,
    MonsterAttackVerticalRange = 5.5,
    MonsterAttackDepthSlack = 1,
    MonsterAttackRequireLineOfSight = true,
    ThreatSwitchRatio = 1.15,
    PlayerDamageIFrames = 0.15,
    DefenseConstant = 100,
}

GameConfig.Graphics = {
    Brightness = 1.75,
    ClockTime = 15.1,
    ExposureCompensation = -0.12,
    EnvironmentDiffuseScale = 0.38,
    EnvironmentSpecularScale = 0.72,
    ShadowSoftness = 0.35,
    AtmosphereDensity = 0.2,
    AtmosphereHaze = 1.15,
    AtmosphereGlare = 0.04,
}

GameConfig.Development = {
    SpawnTrainingDummyInStudio = true,
    TrainingDummyPosition = Vector3.new(8, 4, 0),
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
