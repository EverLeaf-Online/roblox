return table.freeze({
    lumen_first_steps = table.freeze({
        DisplayName = "First Steps in Lumenreach",
        MinimumLevel = 1,
        StartNpcId = "lumen_guide",
        Objectives = table.freeze({
            table.freeze({ Type = "Defeat", Target = "lumen_mossling", Required = 2 }),
        }),
        Reward = table.freeze({ Exp = 25, Currencies = table.freeze({ Shards = 3 }) }),
    }),
})
