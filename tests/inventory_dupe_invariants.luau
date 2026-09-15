local InventoryRules = require("../src/shared/Logic/InventoryRules")
local ProfileTransaction = require("../src/shared/Logic/ProfileTransaction")

local function snapshot(slots)
    local result = {}
    for index, slot in slots do
        result[index] = { ItemId = slot.ItemId, Quantity = slot.Quantity }
    end
    return result
end

local function equalSlots(a, b)
    if #a ~= #b then
        return false
    end
    for index, slot in a do
        local other = b[index]
        if not other or slot.ItemId ~= other.ItemId or slot.Quantity ~= other.Quantity then
            return false
        end
    end
    return true
end

local function assertValid(slots, capacity, stackLimits)
    assert(#slots <= capacity, "inventory never exceeds capacity")
    for _, slot in slots do
        assert(type(slot.ItemId) == "string" and slot.ItemId ~= "", "slot item id remains valid")
        assert(
            type(slot.Quantity) == "number" and slot.Quantity >= 1,
            "slot quantity stays positive"
        )
        assert(slot.Quantity % 1 == 0, "slot quantity stays integral")
        assert(slot.Quantity <= (stackLimits[slot.ItemId] or 1), "stack limit is never exceeded")
    end
end

-- Corrupted persisted slot state fails closed instead of entering arithmetic.
do
    local malformed = { { ItemId = "tonic", Quantity = "10" } }
    local before = snapshot(malformed)
    local addOk, addReason = InventoryRules.Add(malformed, 4, "tonic", 1, 10)
    assert(not addOk and addReason == "invalid_inventory", "malformed slot blocks add")
    local removeOk, removeReason = InventoryRules.Remove(malformed, "tonic", 1)
    assert(not removeOk and removeReason == "invalid_inventory", "malformed slot blocks remove")
    assert(equalSlots(malformed, before), "malformed inventory is never mutated")
end

-- Failed capacity additions must be mutation-free.
do
    local slots = { { ItemId = "blade", Quantity = 1 }, { ItemId = "tonic", Quantity = 10 } }
    local before = snapshot(slots)
    local ok, reason = InventoryRules.Add(slots, 2, "tonic", 1, 10)
    assert(not ok and reason == "inventory_full", "full inventory rejects extra stack")
    assert(equalSlots(slots, before), "failed add leaves inventory unchanged")
end

-- Failed removals must be mutation-free.
do
    local slots = { { ItemId = "tonic", Quantity = 4 } }
    local before = snapshot(slots)
    local ok, reason = InventoryRules.Remove(slots, "tonic", 5)
    assert(not ok and reason == "insufficient_quantity", "over-remove is rejected")
    assert(equalSlots(slots, before), "failed remove leaves inventory unchanged")
end

-- Equipment swap conserves both the equipped and inventory copies exactly once.
do
    local profile = {
        Inventory = { Capacity = 2, Slots = { { ItemId = "new_blade", Quantity = 1 } } },
        Equipment = { Weapon = "old_blade" },
    }
    local ok = ProfileTransaction.Run(profile, function(working)
        local removed, itemId = InventoryRules.RemoveAt(working.Inventory.Slots, 1, 1)
        assert(removed and itemId == "new_blade", "candidate equipment removed once")
        local returned = InventoryRules.Add(working.Inventory.Slots, 2, "old_blade", 1, 1)
        assert(returned, "old equipment returned once")
        working.Equipment.Weapon = "new_blade"
        return true
    end)
    assert(ok, "equipment swap commits")
    assert(profile.Equipment.Weapon == "new_blade", "new item equipped")
    assert(
        InventoryRules.Count(profile.Inventory.Slots, "new_blade") == 0,
        "new item not duplicated"
    )
    assert(
        InventoryRules.Count(profile.Inventory.Slots, "old_blade") == 1,
        "old item returned exactly once"
    )
end

-- Full-inventory unequip failure rolls back equipment and inventory atomically.
do
    local profile = {
        Inventory = {
            Capacity = 1,
            Slots = { { ItemId = "tonic", Quantity = 10 } },
        },
        Equipment = { Weapon = "blade" },
    }
    local beforeSlots = snapshot(profile.Inventory.Slots)
    local ok, reason = ProfileTransaction.Run(profile, function(working)
        local added, addReason = InventoryRules.Add(working.Inventory.Slots, 1, "blade", 1, 1)
        if not added then
            return false, addReason
        end
        working.Equipment.Weapon = ""
        return true
    end)
    assert(not ok and reason == "inventory_full", "full inventory blocks unequip")
    assert(profile.Equipment.Weapon == "blade", "failed unequip preserves equipped item")
    assert(equalSlots(profile.Inventory.Slots, beforeSlots), "failed unequip preserves inventory")
end

-- Unexpected mutator errors also fail closed without partial state.
do
    local profile = { Currencies = { Shards = 50 } }
    local ok, reason = ProfileTransaction.Run(profile, function(working)
        working.Currencies.Shards = 0
        error("forced mutation failure")
    end)
    assert(not ok and reason == "transaction_error", "thrown mutation fails transaction")
    assert(profile.Currencies.Shards == 50, "thrown mutation cannot partially commit")
end

-- Deterministic fuzz: hundreds of add/remove attempts must conserve the modeled count.
do
    local stackLimits = { tonic = 10, ore = 7, blade = 1 }
    local itemIds = { "tonic", "ore", "blade" }
    local capacity = 8
    local slots = {}
    local expected = { tonic = 0, ore = 0, blade = 0 }
    local seed = 90317
    local function nextUnit()
        seed = (seed * 48271) % 2147483647
        return seed / 2147483647
    end
    local function nextInteger(minimum, maximum)
        return minimum + math.floor(nextUnit() * (maximum - minimum + 1))
    end

    for _ = 1, 600 do
        local itemId = itemIds[nextInteger(1, #itemIds)]
        local quantity = nextInteger(1, 4)
        if nextUnit() < 0.57 then
            local before = InventoryRules.Count(slots, itemId)
            local ok = InventoryRules.Add(slots, capacity, itemId, quantity, stackLimits[itemId])
            if ok then
                expected[itemId] += quantity
            else
                assert(
                    InventoryRules.Count(slots, itemId) == before,
                    "failed fuzz add is mutation-free"
                )
            end
        else
            local before = InventoryRules.Count(slots, itemId)
            local ok = InventoryRules.Remove(slots, itemId, quantity)
            if ok then
                expected[itemId] -= quantity
            else
                assert(
                    InventoryRules.Count(slots, itemId) == before,
                    "failed fuzz remove is mutation-free"
                )
            end
        end

        assertValid(slots, capacity, stackLimits)
        for _, trackedId in itemIds do
            assert(
                InventoryRules.Count(slots, trackedId) == expected[trackedId],
                "fuzz item count matches modeled conservation"
            )
        end
    end
end

print("inventory/equipment dupe invariant tests passed")
