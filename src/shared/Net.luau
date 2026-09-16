local Net = {}

Net.RemoteFolderName = "EverLeafRemotes"

Net.Events = table.freeze({
    ProfileReady = "ProfileReady",
    ProfileChanged = "ProfileChanged",
    PartyEvent = "PartyEvent",
    InteractionEvent = "InteractionEvent",
    WorldNotice = "WorldNotice",
    PlayerDamageEvent = "PlayerDamageEvent",
    MovementIntent = "MovementIntent",
    TradeEvent = "TradeEvent",
})

Net.Functions = table.freeze({
    RequestProfile = "RequestProfile",
    BasicAttack = "BasicAttack",
    GameAction = "GameAction",
    RequestCatalog = "RequestCatalog",
    RefreshEntitlements = "RefreshEntitlements",
})

return table.freeze(Net)
