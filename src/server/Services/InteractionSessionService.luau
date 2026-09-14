local Players = game:GetService("Players")
local InteractionSessionService = {}
local sessions = {}
local SESSION_SECONDS = 60

local function refresh(session)
    session.ExpiresAt = os.clock() + SESSION_SECONDS
end

function InteractionSessionService.Begin(player, npcId, shopId)
    sessions[player] = {
        NpcId = npcId,
        ShopId = shopId,
        ExpiresAt = os.clock() + SESSION_SECONDS,
    }
end

function InteractionSessionService.ValidateShop(player, shopId)
    local session = sessions[player]
    local valid = session ~= nil and session.ExpiresAt > os.clock() and session.ShopId == shopId
    if valid then
        refresh(session)
    end
    return valid
end

function InteractionSessionService.ValidateNpc(player, npcId)
    local session = sessions[player]
    local valid = session ~= nil and session.ExpiresAt > os.clock() and session.NpcId == npcId
    if valid then
        refresh(session)
    end
    return valid
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
