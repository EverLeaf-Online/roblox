local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ActionPayloadRules = require(ReplicatedStorage.Shared.Validation.ActionPayloadRules)
local ActionService = require(script.Parent.Services.ActionService)
local AchievementService = require(script.Parent.Services.AchievementService)
local BelforgeColossusService = require(script.Parent.Services.BelforgeColossusService)
local BrasshavenWorldService = require(script.Parent.Services.BrasshavenWorldService)
local CatalogService = require(script.Parent.Services.CatalogService)
local CharacterStatsService = require(script.Parent.Services.CharacterStatsService)
local CombatService = require(script.Parent.Services.CombatService)
local DeathService = require(script.Parent.Services.DeathService)
local EnemyAIService = require(script.Parent.Services.EnemyAIService)
local EnemySpawnerService = require(script.Parent.Services.EnemySpawnerService)
local EquipmentVisualService = require(script.Parent.Services.EquipmentVisualService)
local ExplorationService = require(script.Parent.Services.ExplorationService)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MonsterAnimationService = require(script.Parent.Services.MonsterAnimationService)
local MonsterSpawnService = require(script.Parent.Services.MonsterSpawnService)
local InteractionService = require(script.Parent.Services.InteractionService)
local InteractionSessionService = require(script.Parent.Services.InteractionSessionService)
local LumenreachWorldService = require(script.Parent.Services.LumenreachWorldService)
local MovementSanityService = require(script.Parent.Services.MovementSanityService)
local MonetizationService = require(script.Parent.Services.MonetizationService)
local PartyService = require(script.Parent.Services.PartyService)
local PBRMaterialService = require(script.Parent.Services.PBRMaterialService)
local Net = require(ReplicatedStorage.Shared.Net)
local PlayerDataService = require(script.Parent.Services.PlayerDataService)
local PlayerDamageService = require(script.Parent.Services.PlayerDamageService)
local PlayerDodgeService = require(script.Parent.Services.PlayerDodgeService)
local PlayerPresentationService = require(script.Parent.Services.PlayerPresentationService)
local RateLimiterService = require(script.Parent.Services.RateLimiterService)
local ResourceService = require(script.Parent.Services.ResourceService)
local SnapshotService = require(script.Parent.Services.SnapshotService)
local StatusEffectService = require(script.Parent.Services.StatusEffectService)
local StudioEnvironmentAssetService = require(script.Parent.Services.StudioEnvironmentAssetService)
local WorldTravelService = require(script.Parent.Services.WorldTravelService)
local WorldVisualService = require(script.Parent.Services.WorldVisualService)

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
local playerDamageEvent = ensureRemote("RemoteEvent", Net.Events.PlayerDamageEvent)
local movementIntent = ensureRemote("RemoteEvent", Net.Events.MovementIntent)
ensureRemote("RemoteEvent", Net.Events.WorldNotice)
local requestProfile = ensureRemote("RemoteFunction", Net.Functions.RequestProfile)
local basicAttack = ensureRemote("RemoteFunction", Net.Functions.BasicAttack)
local gameAction = ensureRemote("RemoteFunction", Net.Functions.GameAction)
local requestCatalog = ensureRemote("RemoteFunction", Net.Functions.RequestCatalog)
local refreshEntitlements = ensureRemote("RemoteFunction", Net.Functions.RefreshEntitlements)

PlayerDataService.Init()
MonetizationService.Init()
PlayerPresentationService.Init()
MovementSanityService.Init()
PlayerDodgeService.Init()
ResourceService.Init()
EnemySpawnerService.Init()
PBRMaterialService.Init()
StudioEnvironmentAssetService.Init()
LumenreachWorldService.Init()
BrasshavenWorldService.Init()
MonsterAnimationService.Init()
EnemyAIService.Init()
MonsterSpawnService.Init()
BelforgeColossusService.Init()
ExplorationService.Init()
PartyService.Init()
InteractionSessionService.Init()
StatusEffectService.Init()
WorldVisualService.Init()
Players.RespawnTime = 3

local function syncPlayerWorld(player, profile, moveCharacter)
    local ok, reason = WorldTravelService.SyncPlayer(player, profile, moveCharacter)
    if not ok then
        warn(
            string.format(
                "[Bootstrap] Could not sync %s to %s: %s",
                player.Name,
                tostring(profile.World.SpawnId),
                tostring(reason)
            )
        )
        profile.World.RegionId = "lumenreach"
        profile.World.SpawnId = "lumenreach_start"
        WorldTravelService.SyncPlayer(player, profile, moveCharacter)
    end
end

local function replicateSnapshot(player)
    local snapshot = SnapshotService.Build(player)
    if snapshot and player.Parent == Players then
        profileChanged:FireClient(player, snapshot)
    end
end

local function replicateProfile(player)
    CharacterStatsService.Apply(player, false)
    local profile = PlayerDataService.Get(player)
    if profile then
        EquipmentVisualService.Apply(player, profile)
    end
    replicateSnapshot(player)
end

PlayerDataService.Changed:Connect(replicateProfile)
MonetizationService.Changed:Connect(function(player)
    replicateSnapshot(player)
    PartyService.RefreshPresentation(player)
end)
StatusEffectService.Changed:Connect(replicateSnapshot)
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

PlayerDamageService.Event:Connect(function(player, payload)
    if player.Parent == Players then
        playerDamageEvent:FireClient(player, payload)
    end
end)

local function onPlayerAdded(player)
    player:SetAttribute("EverLeafCrouching", false)
    player:SetAttribute("EverLeafDodging", false)
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

    local achievementChanged = AchievementService.SyncJoin(player, profileOrReason)
    if achievementChanged then
        PlayerDataService.NotifyChanged(player)
    end
    MonetizationService.OnProfileLoaded(player)

    syncPlayerWorld(player, profileOrReason, player.Character ~= nil)
    DeathService.InitPlayer(player)

    player.CharacterAdded:Connect(function(character)
        player:SetAttribute("EverLeafCrouching", false)
        player:SetAttribute("EverLeafDodging", false)
        StatusEffectService.Clear(player)
        task.defer(function()
            local humanoid = character:WaitForChild("Humanoid", 5)
            local root = character:WaitForChild("HumanoidRootPart", 5)
            local profile = PlayerDataService.Get(player)
            if profile and humanoid and root and player.Character == character then
                -- RespawnLocation handles the engine spawn, then this authoritative
                -- settle pass resolves the actual floor and avatar clearance. This
                -- prevents terrain/build timing from leaving the character underground.
                WorldTravelService.Teleport(player, profile.World.SpawnId, {
                    SkipStreamingPrefetch = true,
                })
            elseif profile then
                WorldTravelService.SetRespawn(player, profile.World.SpawnId)
            end
            CharacterStatsService.Apply(player, true)
            if profile then
                EquipmentVisualService.Apply(player, profile)
            end
            PlayerDataService.NotifyChanged(player)
        end)
    end)
    if player.Character then
        task.defer(function()
            CharacterStatsService.Apply(player, true)
            local profile = PlayerDataService.Get(player)
            if profile then
                EquipmentVisualService.Apply(player, profile)
            end
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

requestProfile.OnServerInvoke = function(player, ...)
    if select("#", ...) > 0 then
        return nil
    end
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

movementIntent.OnServerEvent:Connect(function(player, payload)
    local limit = GameConfig.Security.MovementIntent
    if
        not RateLimiterService.Allow(
            player,
            "MovementIntent",
            limit.Capacity,
            limit.RefillPerSecond,
            1
        )
    then
        return
    end
    if not ActionPayloadRules.ValidateMovementIntent(payload) then
        return
    end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        player:SetAttribute("EverLeafCrouching", false)
        return
    end

    if payload.Dodge == true then
        PlayerDodgeService.TryStart(player, payload.DirectionX, payload.DirectionZ)
        return
    end

    if payload.Crouching then
        if
            player:GetAttribute("EverLeafStaggered") == true
            or player:GetAttribute("EverLeafDodging") == true
            or humanoid.FloorMaterial == Enum.Material.Air
        then
            return
        end
    end
    player:SetAttribute("EverLeafCrouching", payload.Crouching)
end)

basicAttack.OnServerInvoke = function(player, ...)
    if select("#", ...) > 0 then
        return false, "invalid_payload"
    end
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

requestCatalog.OnServerInvoke = function(player, ...)
    if select("#", ...) > 0 then
        return nil
    end
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

refreshEntitlements.OnServerInvoke = function(player, ...)
    if select("#", ...) > 0 then
        return false, "invalid_payload"
    end
    local limit = GameConfig.Security.EntitlementRefresh
    if
        not RateLimiterService.Allow(
            player,
            "RefreshEntitlements",
            limit.Capacity,
            limit.RefillPerSecond,
            1
        )
    then
        return false, "rate_limited"
    end
    return MonetizationService.RefreshEntitlementsNow(player)
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
    local ok, result, profileMutated = ActionService.Handle(player, profile, actionName, payload)
    if ok and profileMutated then
        AchievementService.SyncProgression(player, profile)
        PlayerDataService.NotifyChanged(player)
    end
    return ok, result
end
