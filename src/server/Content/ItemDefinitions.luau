return table.freeze({
    training_blade = table.freeze({
        DisplayName = "Training Blade",
        Type = "Equipment",
        EquipmentSlot = "Weapon",
        StackLimit = 1,
        Stats = table.freeze({ AttackPower = 2 }),
        SellPrice = table.freeze({ Currency = "Shards", Amount = 1 }),
    }),
    small_tonic = table.freeze({
        DisplayName = "Small Tonic",
        Type = "Consumable",
        StackLimit = 99,
        Effects = table.freeze({ RestoreHP = 35, RestoreMP = 20 }),
        SellPrice = table.freeze({ Currency = "Shards", Amount = 1 }),
    }),
    lumen_fragment = table.freeze({
        DisplayName = "Lumen Fragment",
        Type = "Material",
        StackLimit = 999,
        SellPrice = table.freeze({ Currency = "Shards", Amount = 1 }),
    }),
})
