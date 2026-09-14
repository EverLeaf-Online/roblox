local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local InstanceTeleportService = {}

function InstanceTeleportService.Teleport(players, instanceState)
    local placeId = GameConfig.Places.Instance
    if type(placeId) ~= "number" or placeId <= 0 then
        return false, "instance_place_not_configured"
    end
    if type(players) ~= "table" or #players == 0 then
        return false, "no_players"
    end
    local options = Instance.new("TeleportOptions")
    options.ShouldReserveServer = true
    options:SetTeleportData({ InstanceId = instanceState.Id, Kind = instanceState.Kind })
    local ok, result = pcall(function()
        return TeleportService:TeleportAsync(placeId, players, options)
    end)
    if not ok then
        return false, tostring(result)
    end
    return true, result
end

return InstanceTeleportService
