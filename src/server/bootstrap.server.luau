local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local PlayerDataService = require(script.Parent.Services.PlayerDataService)
local StatService = require(script.Parent.Services.StatService)

local remotes = ReplicatedStorage:FindFirstChild(Net.RemoteFolderName)
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = Net.RemoteFolderName
    remotes.Parent = ReplicatedStorage
end

local function ensureRemote(className, name)
    local existing = remotes:FindFirstChild(name)
    if existing then
        return existing
    end
    local remote = Instance.new(className)
    remote.Name = name
    remote.Parent = remotes
    return remote
end

local profileReady = ensureRemote("RemoteEvent", Net.Events.ProfileReady)
local profileChanged = ensureRemote("RemoteEvent", Net.Events.ProfileChanged)
local requestProfile = ensureRemote("RemoteFunction", Net.Functions.RequestProfile)
local allocateStat = ensureRemote("RemoteFunction", Net.Functions.AllocateStat)

PlayerDataService.Init()

local function replicateProfile(player)
    local snapshot = PlayerDataService.GetSnapshot(player)
    if snapshot then
        profileChanged:FireClient(player, snapshot)
    end
end

local function onPlayerAdded(player)
    PlayerDataService.Load(player)
    profileReady:FireClient(player, PlayerDataService.GetSnapshot(player))
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
    task.spawn(onPlayerAdded, player)
end

requestProfile.OnServerInvoke = function(player)
    return PlayerDataService.GetSnapshot(player)
end

allocateStat.OnServerInvoke = function(player, statName, amount)
    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "profile_not_loaded"
    end

    local ok, reason = StatService.Allocate(profile, statName, amount)
    if ok then
        replicateProfile(player)
    end
    return ok, reason
end
