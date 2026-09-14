local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ActionService = require(script.Parent.Services.ActionService)
local CatalogService = require(script.Parent.Services.CatalogService)
local CharacterStatsService = require(script.Parent.Services.CharacterStatsService)
local CombatService = require(script.Parent.Services.CombatService)
local DeathService = require(script.Parent.Services.DeathService)
local EnemyAIService = require(script.Parent.Services.EnemyAIService)
local EnemySpawnerService = require(script.Parent.Services.EnemySpawnerService)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local InteractionService = require(script.Parent.Services.InteractionService)
local InteractionSessionService = require(script.Parent.Services.InteractionSessionService)
local LumenreachWorldService = require(script.Parent.Services.LumenreachWorldService)
local MovementSanityService = require(script.Parent.Services.MovementSanityService)
local PartyService = require(script.Parent.Services.PartyService)
local PBRMaterialService = require(script.Parent.Services.PBRMaterialService)
local Net = require(ReplicatedStorage.Shared.Net)
local PlayerDataService = require(script.Parent.Services.PlayerDataService)
local RateLimiterService = require(script.Parent.Services.RateLimiterService)
local SnapshotService = require(script.Parent.Services.SnapshotService)
local StatusEffectService = require(script.Parent.Services.StatusEffectService)
local StudioEnvironmentAssetService = require(script.Parent.Services.StudioEnvironmentAssetService)
local WorldVisualService = require(script.Parent.Services.WorldVisualService)
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
local partyEvent = ensureRemote("RemoteEvent", Net.Events.PartyEvent)
local interactionEvent = ensureRemote("RemoteEvent", Net.Events.InteractionEvent)
local requestProfile = ensureRemote("RemoteFunction", Net.Functions.RequestProfile)
local allocateStat = ensureRemote("RemoteFunction", Net.Functions.AllocateStat)
local basicAttack = ensureRemote("RemoteFunction", Net.Functions.BasicAttack)
local gameAction = ensureRemote("RemoteFunction", Net.Functions.GameAction)
local requestCatalog = ensureRemote("RemoteFunction", Net.Functions.RequestCatalog)

PlayerDataService.Init()
MovementSanityService.Init()
EnemySpawnerService.Init()
PBRMaterialService.Init()
StudioEnvironmentAssetService.Init()
LumenreachWorldService.Init()
EnemyAIService.Init()
PartyService.Init()
InteractionSessionService.Init()
StatusEffectService.Init()
WorldVisualService.Init()
Players.RespawnTime = 3

local function assignSafeRespawn(player)
    local world = Workspace:FindFirstChild("EverLeafGeneratedWorld")
    local spawn = world and world:FindFirstChild("LumenreachSpawn")
    if spawn and spawn:IsA("SpawnLocation") then
        player.RespawnLocation = spawn
    end
end

local function replicateProfile(player)
    CharacterStatsService.Apply(player, false)
    local snapshot = SnapshotService.Build(player)
    if snapshot then
        profileChanged:FireClient(player, snapshot)
    end
end

PlayerDataService.Changed:Connect(replicateProfile)
PartyService.Event:Connect(function(player, eventData)
    if player.Parent == Players then
        partyEvent:FireClient(player, eventData)
    end
end)

InteractionService.Opened:Connect(function(player, description)
    if player.Parent == Players then
        interactionEvent:FireClient(player, "open", description)
    end
end)

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

    assignSafeRespawn(player)
    DeathService.InitPlayer(player)

    player.CharacterAdded:Connect(function()
        task.defer(function()
            CharacterStatsService.Apply(player, true)
            PlayerDataService.NotifyChanged(player)
        end)
    end)
    if player.Character then
        task.defer(function()
            CharacterStatsService.Apply(player, true)
            PlayerDataService.NotifyChanged(player)
        end)
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
    local limit = GameConfig.Security.ProfileRequest
    if
        not RateLimiterService.Allow(
            player,
            "RequestProfile",
            limit.Capacity,
            limit.RefillPerSecond,
            1
        )
    then
        return nil
    end
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

basicAttack.OnServerInvoke = function(player)
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

    return CombatService.BasicAttack(player, profile)
end

requestCatalog.OnServerInvoke = function(player)
    local limit = GameConfig.Security.CatalogRequest
    if
        not RateLimiterService.Allow(
            player,
            "RequestCatalog",
            limit.Capacity,
            limit.RefillPerSecond,
            1
        )
    then
        return nil
    end
    return CatalogService.Build()
end

gameAction.OnServerInvoke = function(player, actionName, payload)
    local limit = GameConfig.Security.GameplayAction
    if
        not RateLimiterService.Allow(player, "GameAction", limit.Capacity, limit.RefillPerSecond, 1)
    then
        return false, "rate_limited"
    end
    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "profile_not_loaded"
    end
    local ok, result = ActionService.Handle(player, profile, actionName, payload)
    if ok then
        PlayerDataService.NotifyChanged(player)
    end
    return ok, result
end
