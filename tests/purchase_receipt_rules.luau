local Rules = require("../src/shared/Logic/PurchaseReceiptRules")

local receipt = {
    PurchaseId = "purchase-abc-123",
    ProductId = 3712998285,
    PlayerId = 12345,
    CurrencySpent = 25,
}

local ok, purchaseId = Rules.ValidateIncoming(receipt, 3712998285)
assert(ok and purchaseId == receipt.PurchaseId, "valid support receipt accepted")

local duplicate = {
    PurchaseId = receipt.PurchaseId,
    ProductId = receipt.ProductId,
    PlayerId = receipt.PlayerId,
}
assert(Rules.MatchesStored(receipt, duplicate), "same purchase/product/player is idempotent")

local wrongPlayer = table.clone(duplicate)
wrongPlayer.PlayerId = 99999
assert(
    not Rules.MatchesStored(receipt, wrongPlayer),
    "purchase id collision with another player rejected"
)

local wrongProduct = table.clone(duplicate)
wrongProduct.ProductId = 1
assert(
    not Rules.MatchesStored(receipt, wrongProduct),
    "purchase id collision with another product rejected"
)

local badOk, badReason = Rules.ValidateIncoming({
    PurchaseId = "purchase-x",
    ProductId = 1,
    PlayerId = 12345,
}, 3712998285)
assert(not badOk and badReason == "unexpected_product", "unexpected product fails closed")

badOk, badReason = Rules.ValidateIncoming({
    PurchaseId = "",
    ProductId = 3712998285,
    PlayerId = 12345,
}, 3712998285)
assert(not badOk and badReason == "invalid_purchase_id", "missing purchase id rejected")

badOk, badReason = Rules.ValidateIncoming({
    PurchaseId = "purchase-y",
    ProductId = 3712998285,
    PlayerId = -2,
}, 3712998285)
assert(not badOk and badReason == "invalid_player_id", "invalid player id rejected")

print("purchase receipt rules tests passed")
