local Players = game:GetService("Players")
local InteractionSessionService = {}
local sessions = {}

function InteractionSessionService.Begin(player, npcId, shopId)
    sessions[player] = {
        NpcId = npcId,
        ShopId = shopId,
        ExpiresAt = os.clock() + 15,
    }
end

function InteractionSessionService.ValidateShop(player, shopId)
    local session = sessions[player]
    return session ~= nil and session.ExpiresAt > os.clock() and session.ShopId == shopId
end

function InteractionSessionService.ValidateNpc(player, npcId)
    local session = sessions[player]
    return session ~= nil and session.ExpiresAt > os.clock() and session.NpcId == npcId
end

function InteractionSessionService.Clear(player)
    sessions[player] = nil
end

function InteractionSessionService.Init()
    Players.PlayerRemoving:Connect(function(player)
        sessions[player] = nil
    end)
end

return InteractionSessionService
