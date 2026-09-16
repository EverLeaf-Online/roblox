local fs = require("@lune/fs")
local source = fs.readFile("src/server/Services/TradeService.luau")
local payloads = fs.readFile("src/shared/Validation/ActionPayloadRules.luau")
local bootstrap = fs.readFile("src/server/bootstrap.server.luau")
local net = fs.readFile("src/shared/Net.luau")
local ui = fs.readFile("src/client/UI/Components/TradeOverlay.luau")

for _, token in
    {
        "validateOffer",
        "ProfileSchema.DeepCopy(profileA)",
        "ProfileSchema.DeepCopy(profileB)",
        "InventoryService.Remove(workA",
        "InventoryService.Add(workB",
        "PlayerDataService.NotifyChanged(session.A)",
        "PlayerDataService.NotifyChanged(session.B)",
        "both_offers_must_be_locked",
        "recipient_inventory_full",
        "Tradeable == false",
        "distanceBetween(player, target)",
    }
do
    assert(string.find(source, token, 1, true), "missing secure trade invariant: " .. token)
end
for _, action in
    {
        "trade.request",
        "trade.accept",
        "trade.decline",
        "trade.add_item",
        "trade.remove_item",
        "trade.set_shards",
        "trade.lock",
        "trade.unlock",
        "trade.confirm",
        "trade.cancel",
    }
do
    assert(
        string.find(payloads, '["' .. action .. '"]', 1, true),
        "missing trade payload schema: " .. action
    )
end
assert(
    string.find(net, 'TradeEvent = "TradeEvent"', 1, true),
    "trade event missing from network contract"
)
assert(string.find(bootstrap, "TradeService.Init()", 1, true), "trade service must initialize")
assert(
    string.find(bootstrap, "tradeEvent:FireClient", 1, true),
    "trade event must be bridged to client"
)
assert(
    string.find(ui, "both sides lock and confirm", 1, true),
    "trade UI must explain confirmation model"
)
print("trade service rules tests passed")
