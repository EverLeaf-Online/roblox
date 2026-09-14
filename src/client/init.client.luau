local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local remotes = ReplicatedStorage:WaitForChild(Net.RemoteFolderName)
local profileReady = remotes:WaitForChild(Net.Events.ProfileReady)
local profileChanged = remotes:WaitForChild(Net.Events.ProfileChanged)
local requestProfile = remotes:WaitForChild(Net.Functions.RequestProfile)

local currentProfile = nil

local function setProfile(snapshot)
    currentProfile = snapshot
end

profileReady.OnClientEvent:Connect(setProfile)
profileChanged.OnClientEvent:Connect(setProfile)

local ok, snapshot = pcall(function()
    return requestProfile:InvokeServer()
end)
if ok and snapshot then
    setProfile(snapshot)
end

return currentProfile
