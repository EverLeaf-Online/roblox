local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ProfileSchema = require(script.Parent.Parent.Data.ProfileSchema)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local PlayerDataService = {}
local store = DataStoreService:GetDataStore(GameConfig.DataStore.Name)
local profiles = {}
local persistent = {}
local closing = false
local changedEvent = Instance.new("BindableEvent")
local sessionId = if game.JobId ~= "" then game.JobId else HttpService:GenerateGUID(false)

local function keyFor(player)
    return string.format("player:%d", player.UserId)
end

local function retry(operation)
    local lastError = nil
    for attempt = 1, GameConfig.DataStore.MaxAttempts do
        local ok, result = pcall(operation)
        if ok then
            return true, result
        end
        lastError = result
        if attempt < GameConfig.DataStore.MaxAttempts then
            task.wait(GameConfig.DataStore.RetryBaseSeconds * (2 ^ (attempt - 1)))
        end
    end
    return false, lastError
end

local function persistenceEnabled()
    return not RunService:IsStudio() or GameConfig.DataStore.EnableInStudio
end

local function claimPersistentProfile(player)
    local blocked = false
    local migrationError = nil
    local claimed = nil
    local now = os.time()

    local ok, result = retry(function()
        blocked = false
        migrationError = nil
        return store:UpdateAsync(keyFor(player), function(raw)
            local migrated, dataOrReason = ProfileSchema.Migrate(raw)
            if not migrated then
                migrationError = dataOrReason
                return nil
            end
            local data = dataOrReason
            local lock = data.Meta.ActiveSession
            if lock and lock.Id ~= sessionId then
                local touchedAt = tonumber(lock.TouchedAt) or 0
                if now - touchedAt < GameConfig.DataStore.SessionLockSeconds then
                    blocked = true
                    return nil
                end
            end
            data.Meta.ActiveSession = { Id = sessionId, TouchedAt = now }
            data.Meta.LastSeenAt = now
            claimed = ProfileSchema.DeepCopy(data)
            return data
        end)
    end)

    if not ok then
        return false, tostring(result)
    end
    if migrationError then
        return false, migrationError
    end
    if blocked then
        return false, "profile_in_use"
    end

    local profile = claimed or result
    if type(profile) ~= "table" then
        return false, "invalid_profile"
    end
    local migrated, migratedProfile = ProfileSchema.Migrate(profile)
    if not migrated then
        return false, migratedProfile
    end
    return true, migratedProfile
end

function PlayerDataService.Load(player)
    assert(player:IsA("Player"), "Load expects Player")
    if profiles[player] then
        return true, profiles[player]
    end
    if not persistenceEnabled() then
        local profile = ProfileSchema.New()
        profiles[player] = profile
        persistent[player] = false
        return true, profile
    end
    local ok, profileOrReason = claimPersistentProfile(player)
    if not ok then
        return false, profileOrReason
    end
    profiles[player] = profileOrReason
    persistent[player] = true
    return true, profileOrReason
end

PlayerDataService.Changed = changedEvent.Event
function PlayerDataService.Get(player)
    return profiles[player]
end
function PlayerDataService.GetSnapshot(player)
    local profile = profiles[player]
    return profile and ProfileSchema.PublicSnapshot(profile) or nil
end
function PlayerDataService.Mutate(player, mutator)
    local profile = profiles[player]
    if not profile then
        return false, "profile_not_loaded"
    end
    mutator(profile)
    return true
end
function PlayerDataService.NotifyChanged(player)
    if profiles[player] then
        changedEvent:Fire(player)
    end
end

function PlayerDataService.Save(player, releaseSession)
    local profile = profiles[player]
    if not profile or not persistent[player] then
        return true
    end
    local snapshot = ProfileSchema.DeepCopy(profile)
    snapshot.Meta.SchemaVersion = GameConfig.DataStore.SchemaVersion
    snapshot.Meta.LastSeenAt = os.time()
    snapshot.Meta.ActiveSession = if releaseSession
        then nil
        else { Id = sessionId, TouchedAt = os.time() }

    local lostLock = false
    local ok, result = retry(function()
        lostLock = false
        return store:UpdateAsync(keyFor(player), function(raw)
            local old = if type(raw) == "table" then raw else nil
            local oldLock = old and old.Meta and old.Meta.ActiveSession
            if oldLock and oldLock.Id ~= sessionId then
                local touchedAt = tonumber(oldLock.TouchedAt) or 0
                if os.time() - touchedAt < GameConfig.DataStore.SessionLockSeconds then
                    lostLock = true
                    return nil
                end
            end
            return snapshot
        end)
    end)
    if not ok then
        warn(
            string.format(
                "[PlayerDataService] Save failed for %s: %s",
                player.Name,
                tostring(result)
            )
        )
        return false, tostring(result)
    end
    if lostLock then
        warn(
            string.format(
                "[PlayerDataService] Refused save for %s because session lock moved",
                player.Name
            )
        )
        return false, "session_lock_lost"
    end
    return true
end

function PlayerDataService.Unload(player)
    PlayerDataService.Save(player, true)
    profiles[player] = nil
    persistent[player] = nil
end
function PlayerDataService.IsPersistent(player)
    return persistent[player] == true
end

function PlayerDataService.Init()
    Players.PlayerRemoving:Connect(function(player)
        PlayerDataService.Unload(player)
    end)
    task.spawn(function()
        while not closing do
            task.wait(GameConfig.DataStore.AutosaveSeconds)
            if closing then
                break
            end
            for player in profiles do
                task.spawn(PlayerDataService.Save, player, false)
            end
        end
    end)
    game:BindToClose(function()
        closing = true
        for player in profiles do
            PlayerDataService.Save(player, true)
        end
    end)
end

return PlayerDataService
