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
})

Net.Functions = table.freeze({
    AllocateStat = "AllocateStat",
    RequestProfile = "RequestProfile",
    BasicAttack = "BasicAttack",
    GameAction = "GameAction",
    RequestCatalog = "RequestCatalog",
})

return table.freeze(Net)
