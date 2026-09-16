local TradeRules = require("../src/shared/Logic/TradeRules")

local ok, reason = TradeRules.CanRequest(false, false, true, 12)
assert(ok and reason == nil, "nearby same-region players can trade")
local farOk, farReason = TradeRules.CanRequest(false, false, true, 30)
assert(not farOk and farReason == "too_far", "distant trade requests rejected")
local regionOk, regionReason = TradeRules.CanRequest(false, false, false, 5)
assert(not regionOk and regionReason == "different_region", "cross-region trade rejected")
assert(
    TradeRules.ValidQuantity(1) and TradeRules.ValidQuantity(999999),
    "valid quantities accepted"
)
assert(
    not TradeRules.ValidQuantity(0) and not TradeRules.ValidQuantity(1.5),
    "invalid quantities rejected"
)
assert(TradeRules.ValidShardAmount(50, 100), "affordable shard offer accepted")
assert(not TradeRules.ValidShardAmount(101, 100), "overspending shards rejected")
local addOk = TradeRules.CanAddItem(10, 3, 7, 2, false)
assert(addOk, "remaining inventory quantity can be offered")
local addBad, addReason = TradeRules.CanAddItem(10, 3, 8, 2, false)
assert(not addBad and addReason == "insufficient_quantity", "over-offering item quantity rejected")
local fullOk, fullReason = TradeRules.CanAddItem(10, 0, 1, TradeRules.MaxOfferTypes, true)
assert(not fullOk and fullReason == "offer_full", "distinct trade offer cap enforced")
print("trade rules tests passed")
