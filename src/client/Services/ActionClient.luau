local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Net)

local ActionClient = {}
local remote = nil

local function getRemote()
    if remote and remote.Parent then
        return remote
    end
    local folder = ReplicatedStorage:WaitForChild(Net.RemoteFolderName)
    remote = folder:WaitForChild(Net.Functions.GameAction)
    return remote
end

function ActionClient.Invoke(actionName, payload)
    local ok, success, result = pcall(function()
        return getRemote():InvokeServer(actionName, payload or {})
    end)
    if not ok then
        return false, "request_failed"
    end
    return success, result
end

return ActionClient
