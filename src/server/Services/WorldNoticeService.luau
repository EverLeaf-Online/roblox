local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Net)
local WorldNoticeRules = require(ReplicatedStorage.Shared.Logic.WorldNoticeRules)

local WorldNoticeService = {}

local function remote()
    local folder = ReplicatedStorage:FindFirstChild(Net.RemoteFolderName)
    return folder and folder:FindFirstChild(Net.Events.WorldNotice)
end

function WorldNoticeService.Send(player, payload)
    local event = remote()
    if not event or not event:IsA("RemoteEvent") then
        return false, "remote_unavailable"
    end
    event:FireClient(player, payload)
    return true
end

function WorldNoticeService.SendReason(player, reason)
    return WorldNoticeService.Send(player, WorldNoticeRules.ForReason(reason))
end

return WorldNoticeService
