local CurrencyRules = require("../src/shared/Logic/CurrencyRules")
local InventoryRules = require("../src/shared/Logic/InventoryRules")
local ProfileTransaction = require("../src/shared/Logic/ProfileTransaction")
local ItemDefinitions = require("../src/server/Content/ItemDefinitions")
local ShopDefinitions = require("../src/server/Content/ShopDefinitions")

local MAX_BALANCE = 2_000_000_000

assert(CurrencyRules.IsValidAmount(1), "positive integer currency amount accepted")
assert(not CurrencyRules.IsValidAmount(0), "zero currency mutation rejected")
assert(not CurrencyRules.IsValidAmount(-1), "negative currency mutation rejected")
assert(not CurrencyRules.IsValidAmount(1.5), "fractional currency mutation rejected")
assert(not CurrencyRules.IsValidAmount(0 / 0), "NaN currency mutation rejected")
assert(not CurrencyRules.IsValidAmount(math.huge), "infinite currency mutation rejected")

local ok, value = CurrencyRules.Add(MAX_BALANCE - 5, 5, MAX_BALANCE)
assert(ok and value == MAX_BALANCE, "balance can reach configured cap exactly")
ok, value = CurrencyRules.Add(MAX_BALANCE - 5, 6, MAX_BALANCE)
assert(not ok and value == "balance_cap", "currency overflow is rejected")
ok, value = CurrencyRules.Add("100", 1, MAX_BALANCE)
assert(not ok and value == "invalid_balance", "corrupted stored balance fails closed")
ok, value = CurrencyRules.Spend(5, 6, MAX_BALANCE)
assert(not ok and value == "insufficient_funds", "overspend rejected")
ok, value = CurrencyRules.Spend(5, 5, MAX_BALANCE)
assert(ok and value == 0, "exact balance spend is valid")

-- Same-currency shop loops must always destroy currency, never mint it.
for shopId, shop in ShopDefinitions do
    for itemId, buyPrice in shop.Items do
        local definition = ItemDefinitions[itemId]
        assert(definition, string.format("shop %s item exists: %s", shopId, itemId))
        local sellPrice = definition.SellPrice
        if sellPrice and sellPrice.Currency == shop.Currency then
            assert(
                sellPrice.Amount < buyPrice,
                string.format("shop %s cannot buy/sell %s for same-currency profit", shopId, itemId)
            )
        end
    end
end

-- Simulate the production buy/sell mutation ordering for a known same-currency item.
do
    local itemId = "small_tonic"
    local shop = ShopDefinitions.lumen_supply
    local definition = ItemDefinitions[itemId]
    local profile = {
        Currencies = { Shards = 100, Marks = 0 },
        Inventory = { Capacity = 48, Slots = {} },
    }
    local startingShards = profile.Currencies.Shards
    local quantity = 10
    local buyTotal = shop.Items[itemId] * quantity
    local sellTotal = definition.SellPrice.Amount * quantity

    local bought = ProfileTransaction.Run(profile, function(working)
        local spent, nextBalance =
            CurrencyRules.Spend(working.Currencies.Shards, buyTotal, MAX_BALANCE)
        if not spent then
            return false, nextBalance
        end
        working.Currencies.Shards = nextBalance
        local added, addReason = InventoryRules.Add(
            working.Inventory.Slots,
            working.Inventory.Capacity,
            itemId,
            quantity,
            definition.StackLimit
        )
        if not added then
            return false, addReason
        end
        return true
    end)
    assert(bought, "modeled shop buy succeeds")

    local sold = ProfileTransaction.Run(profile, function(working)
        local removed, removeReason =
            InventoryRules.Remove(working.Inventory.Slots, itemId, quantity)
        if not removed then
            return false, removeReason
        end
        local added, nextBalance =
            CurrencyRules.Add(working.Currencies.Shards, sellTotal, MAX_BALANCE)
        if not added then
            return false, nextBalance
        end
        working.Currencies.Shards = nextBalance
        return true
    end)
    assert(sold, "modeled shop sell succeeds")
    assert(InventoryRules.Count(profile.Inventory.Slots, itemId) == 0, "round trip consumes items")
    assert(
        profile.Currencies.Shards == startingShards - buyTotal + sellTotal,
        "round trip balance matches model"
    )
    assert(profile.Currencies.Shards < startingShards, "same-currency round trip cannot mint money")
end

-- Repeated round trips also remain a sink.
do
    local itemId = "field_tonic"
    local shop = ShopDefinitions.lumen_supply
    local definition = ItemDefinitions[itemId]
    local balance = 10_000
    local start = balance
    for _ = 1, 100 do
        local spent, nextBalance = CurrencyRules.Spend(balance, shop.Items[itemId], MAX_BALANCE)
        assert(spent, "repeated buy remains affordable")
        balance = nextBalance
        local added, soldBalance =
            CurrencyRules.Add(balance, definition.SellPrice.Amount, MAX_BALANCE)
        assert(added, "repeated sell remains valid")
        balance = soldBalance
    end
    assert(balance < start, "100 buy/sell cycles cannot create currency")
end

print("currency/economy abuse tests passed")
