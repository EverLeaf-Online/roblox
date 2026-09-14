local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterStatsService = require(script.Parent.Services.CharacterStatsService)
local CombatService = require(script.Parent.Services.CombatService)
local EnemySpawnerService = require(script.Parent.Services.EnemySpawnerService)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MovementSanityService = require(script.Parent.Services.MovementSanityService)
local Net = require(ReplicatedStorage.Shared.Net)
local PlayerDataService = require(script.Parent.Services.PlayerDataService)
local RateLimiterService = require(script.Parent.Services.RateLimiterService)
local SnapshotService = require(script.Parent.Services.SnapshotService)
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
local basicAttack = ensureRemote("RemoteFunction", Net.Functions.BasicAttack)

PlayerDataService.Init()
MovementSanityService.Init()
EnemySpawnerService.Init()

local function replicateProfile(player)
    CharacterStatsService.Apply(player, false)
    local snapshot = SnapshotService.Build(player)
    if snapshot then
        profileChanged:FireClient(player, snapshot)
    end
end

PlayerDataService.Changed:Connect(replicateProfile)

local function onPlayerAdded(player)
    local ok, profileOrReason = PlayerDataService.Load(player)
    if not ok then
        warn(
            string.format(
                "[Bootstrap] Failed to load %s: %s",
                player.Name,
                tostring(profileOrReason)
            )
        )
        player:Kick("Your EverLeaf data could not be loaded safely. Please rejoin.")
        return
    end

    player:SetAttribute("MovementPlaneZ", GameConfig.Movement.DefaultPlaneZ)

    player.CharacterAdded:Connect(function()
        task.defer(CharacterStatsService.Apply, player, true)
    end)
    if player.Character then
        task.defer(CharacterStatsService.Apply, player, true)
    end

    if player.Parent == Players then
        profileReady:FireClient(player, SnapshotService.Build(player))
    end
end

Players.PlayerAdded:Connect(function(player)
    task.spawn(onPlayerAdded, player)
end)
for _, player in Players:GetPlayers() do
    task.spawn(onPlayerAdded, player)
end

requestProfile.OnServerInvoke = function(player)
    return SnapshotService.Build(player)
end

allocateStat.OnServerInvoke = function(player, statName, amount)
    local limit = GameConfig.Security.AllocateStat
    if
        not RateLimiterService.Allow(
            player,
            "AllocateStat",
            limit.Capacity,
            limit.RefillPerSecond,
            1
        )
    then
        return false, "rate_limited"
    end

    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "profile_not_loaded"
    end

    local ok, reason = StatService.Allocate(profile, statName, amount)
    if ok then
        PlayerDataService.NotifyChanged(player)
    end
    return ok, reason
end

basicAttack.OnServerInvoke = function(player, target)
    local limit = GameConfig.Security.BasicAttack
    if
        not RateLimiterService.Allow(
            player,
            "BasicAttack",
            limit.Capacity,
            limit.RefillPerSecond,
            1
        )
    then
        return false, "rate_limited"
    end

    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "profile_not_loaded"
    end

    return CombatService.BasicAttack(player, profile, target)
end
