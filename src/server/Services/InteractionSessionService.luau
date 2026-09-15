local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InteractionSessionRules = require(ReplicatedStorage.Shared.Logic.InteractionSessionRules)
local WorldObjectService = require(script.Parent.WorldObjectService)

local InteractionSessionService = {}
local sessions = {}
local SESSION_SECONDS = 60
local INTERACTION_DISTANCE = 12

local function refresh(session)
    session.ExpiresAt = os.clock() + SESSION_SECONDS
end

local function validate(player, expectedId, idField)
    local session = sessions[player]
    if not session then
        return false
    end
    local worldObject = session.WorldObject
    local registered = worldObject and WorldObjectService.Get(worldObject)
    local worldObjectMatches = registered ~= nil
        and registered.Kind == "Npc"
        and registered.Id == session.NpcId
    local allowed = InteractionSessionRules.CanValidate(
        session.ExpiresAt <= os.clock(),
        session[idField] == expectedId,
        worldObjectMatches,
        WorldObjectService.CanInteract(player, worldObject, INTERACTION_DISTANCE)
    )
    if not allowed then
        sessions[player] = nil
        return false
    end
    refresh(session)
    return true
end

function InteractionSessionService.Begin(player, npcId, shopId, worldObject)
    local registered = worldObject and WorldObjectService.Get(worldObject)
    if not registered or registered.Kind ~= "Npc" or registered.Id ~= npcId then
        return false, "invalid_world_object"
    end
    if not WorldObjectService.CanInteract(player, worldObject, INTERACTION_DISTANCE) then
        return false, "too_far"
    end
    sessions[player] = {
        NpcId = npcId,
        ShopId = shopId,
        WorldObject = worldObject,
        ExpiresAt = os.clock() + SESSION_SECONDS,
    }
    return true
end

function InteractionSessionService.ValidateShop(player, shopId)
    return validate(player, shopId, "ShopId")
end

function InteractionSessionService.ValidateNpc(player, npcId)
    return validate(player, npcId, "NpcId")
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
