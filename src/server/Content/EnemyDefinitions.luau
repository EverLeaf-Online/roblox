return table.freeze({
    training_dummy = table.freeze({
        DisplayName = "Training Dummy",
        MaxHealth = 100,
        Reward = table.freeze({
            Exp = 10,
            Currencies = table.freeze({
                Shards = 1,
            }),
        }),
        RespawnSeconds = 3,
    }),
    lumen_mossling = table.freeze({
        DisplayName = "Lumen Mossling",
        MaxHealth = 42,
        Reward = table.freeze({
            Exp = 18,
            Currencies = table.freeze({
                Shards = 2,
            }),
        }),
        RespawnSeconds = 7,
        AI = table.freeze({
            AggroRange = 24,
            AttackRange = 4.5,
            AttackCooldown = 1.6,
            MoveSpeed = 9,
            Damage = 6,
        }),
    }),
})
