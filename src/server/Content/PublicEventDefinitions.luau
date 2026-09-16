return table.freeze({
    greenway_breach = table.freeze({
        DisplayName = "Greenway Breach",
        RegionId = "lumenreach",
        Center = Vector3.new(-720, 2, 40),
        Radius = 115,
        DurationSeconds = 180,
        Reward = table.freeze({ Exp = 120, Currencies = table.freeze({ Shards = 10 }) }),
        Waves = table.freeze({
            table.freeze({
                table.freeze({ MonsterId = "lumen_mossling", Count = 4 }),
                table.freeze({ MonsterId = "slime", Count = 2 }),
            }),
            table.freeze({
                table.freeze({ MonsterId = "peco_peco", Count = 3 }),
                table.freeze({ MonsterId = "brambleback", Count = 2 }),
            }),
            table.freeze({
                table.freeze({ MonsterId = "slime", Count = 3 }),
                table.freeze({ MonsterId = "royal_glowcap", Count = 1 }),
            }),
        }),
    }),
})
