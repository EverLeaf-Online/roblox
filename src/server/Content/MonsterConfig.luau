local MonsterConfig = {}

local definitions = {
    training_dummy = table.freeze({
        Id = "training_dummy",
        TemplateName = "TrainingDummy",
        DisplayName = "Training Dummy",
        MaxHealth = 100,
        GroundOffset = 2.4,
        Damage = 0,
        WalkSpeed = 0,
        DetectionRange = 0,
        AttackRange = 0,
        AttackCooldown = 999,
        AttackWindup = 0,
        DodgeChance = 0,
        DodgeCooldown = 999,
        DodgeDistance = 0,
        DodgePause = 0,
        RespawnTime = 3,
        LeashRange = 0,
        HitStun = 0.2,
        Reward = table.freeze({
            Exp = 10,
            Currencies = table.freeze({ Shards = 1 }),
        }),
    }),
    lumen_mossling = table.freeze({
        Id = "lumen_mossling",
        TemplateName = "LumenMossling",
        DisplayName = "Lumen Mossling",
        MaxHealth = 42,
        GroundOffset = 1.5,
        Damage = 6,
        WalkSpeed = 9,
        DetectionRange = 24,
        AttackRange = 4.5,
        AttackCooldown = 1.6,
        AttackWindup = 0.42,
        DodgeChance = 0.05,
        DodgeCooldown = 4.5,
        DodgeDistance = 5,
        DodgePause = 0.35,
        RespawnTime = 7,
        LeashRange = 42,
        HitStun = 0.22,
        Reward = table.freeze({
            Exp = 18,
            Currencies = table.freeze({ Shards = 2 }),
        }),
    }),
    skeleton = table.freeze({
        Id = "skeleton",
        TemplateName = "Skeleton",
        DisplayName = "Gravebone Skeleton",
        MaxHealth = 78,
        GroundOffset = 3.9,
        Damage = 10,
        WalkSpeed = 11,
        DetectionRange = 46,
        AttackRange = 5.5,
        AttackCooldown = 1.45,
        AttackWindup = 0.38,
        DodgeChance = 0.28,
        DodgeCooldown = 3.4,
        DodgeDistance = 7,
        DodgePause = 0.42,
        RespawnTime = 28,
        LeashRange = 72,
        HitStun = 0.24,
        Reward = table.freeze({
            Exp = 28,
            Currencies = table.freeze({ Shards = 3 }),
        }),
    }),
    slime = table.freeze({
        Id = "slime",
        TemplateName = "Slime",
        DisplayName = "Glowcap Slime",
        MaxHealth = 118,
        GroundOffset = 1.65,
        Damage = 9,
        WalkSpeed = 7,
        DetectionRange = 34,
        AttackRange = 4.8,
        AttackCooldown = 1.8,
        AttackWindup = 0.55,
        DodgeChance = 0.08,
        DodgeCooldown = 5.5,
        DodgeDistance = 5,
        DodgePause = 0.5,
        RespawnTime = 32,
        LeashRange = 58,
        HitStun = 0.3,
        Reward = table.freeze({
            Exp = 34,
            Currencies = table.freeze({ Shards = 4 }),
        }),
    }),
    peco_peco = table.freeze({
        Id = "peco_peco",
        TemplateName = "PecoPeco",
        -- Keep the requested template/API name for compatibility while using an original in-world name.
        DisplayName = "Suncrest Ridgebeak",
        MaxHealth = 86,
        GroundOffset = 4.15,
        Damage = 11,
        WalkSpeed = 15,
        DetectionRange = 40,
        AttackRange = 5.2,
        AttackCooldown = 1.35,
        AttackWindup = 0.32,
        DodgeChance = 0.18,
        DodgeCooldown = 3.8,
        DodgeDistance = 6.5,
        DodgePause = 0.36,
        RespawnTime = 30,
        LeashRange = 68,
        HitStun = 0.2,
        Reward = table.freeze({
            Exp = 38,
            Currencies = table.freeze({ Shards = 4 }),
        }),
    }),
}

local aliases = table.freeze({
    TrainingDummy = "training_dummy",
    LumenMossling = "lumen_mossling",
    Skeleton = "skeleton",
    Slime = "slime",
    PecoPeco = "peco_peco",
})

function MonsterConfig.Get(idOrTemplateName)
    if type(idOrTemplateName) ~= "string" then
        return nil
    end
    return definitions[idOrTemplateName] or definitions[aliases[idOrTemplateName]]
end

function MonsterConfig.GetId(idOrTemplateName)
    local definition = MonsterConfig.Get(idOrTemplateName)
    return definition and definition.Id or nil
end

function MonsterConfig.All()
    return definitions
end

return table.freeze(MonsterConfig)
