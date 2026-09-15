return table.freeze({
    small_tonic = table.freeze({
        DisplayName = "Small Tonic",
        Inputs = table.freeze({ lumenleaf = 2 }),
        Output = table.freeze({ ItemId = "small_tonic", Quantity = 1 }),
    }),
    field_tonic = table.freeze({
        DisplayName = "Field Tonic",
        Inputs = table.freeze({ lumenleaf = 2, glowreed = 1 }),
        Output = table.freeze({ ItemId = "field_tonic", Quantity = 1 }),
    }),
})
