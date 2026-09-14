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
})
