local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraController = require(script.Parent.Controllers.CameraController)
local CombatController = require(script.Parent.Controllers.CombatController)
local SideScrollerController = require(script.Parent.Controllers.SideScrollerController)
local Net = require(ReplicatedStorage.Shared.Net)
local ProfileStore = require(script.Parent.State.ProfileStore)

local remotes = ReplicatedStorage:WaitForChild(Net.RemoteFolderName)
local profileReady = remotes:WaitForChild(Net.Events.ProfileReady)
local profileChanged = remotes:WaitForChild(Net.Events.ProfileChanged)
local requestProfile = remotes:WaitForChild(Net.Functions.RequestProfile)

profileReady.OnClientEvent:Connect(ProfileStore.Set)
profileChanged.OnClientEvent:Connect(ProfileStore.Set)

local ok, snapshot = pcall(function()
    return requestProfile:InvokeServer()
end)
if ok and snapshot then
    ProfileStore.Set(snapshot)
end

SideScrollerController.Start()
CameraController.Start()
CombatController.Start()
