local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ProfileSchema = require(script.Parent.Parent.Data.ProfileSchema)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ProfileSaveRules = require(ReplicatedStorage.Shared.Logic.ProfileSaveRules)

local PlayerDataService = {}
local store = DataStoreService:GetDataStore(GameConfig.DataStore.Name)
local profiles = {}
local persistent = {}
local saveStates = {}
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
            local callbackNow = os.time()
            local lock = data.Meta.ActiveSession
            if
                not ProfileSaveRules.CanClaim(
                    lock,
                    sessionId,
                    callbackNow,
                    GameConfig.DataStore.SessionLockSeconds
                )
            then
                blocked = true
                return nil
            end
            data.Meta.ActiveSession = { Id = sessionId, TouchedAt = callbackNow }
            data.Meta.LastSeenAt = callbackNow
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
        saveStates[player] = { Revision = 0, SavedRevision = 0, Saving = false }
        return true, profile
    end
    local ok, profileOrReason = claimPersistentProfile(player)
    if not ok then
        return false, profileOrReason
    end
    profiles[player] = profileOrReason
    persistent[player] = true
    saveStates[player] = { Revision = 0, SavedRevision = 0, Saving = false }
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
    if type(mutator) ~= "function" then
        return false, "invalid_mutator"
    end
    local ok, reason = pcall(mutator, profile)
    if not ok then
        return false, tostring(reason)
    end
    PlayerDataService.NotifyChanged(player)
    return true
end
function PlayerDataService.NotifyChanged(player)
    if profiles[player] then
        local state = saveStates[player]
        if state then
            state.Revision += 1
        end
        changedEvent:Fire(player)
    end
end

function PlayerDataService.Save(player, releaseSession)
    local profile = profiles[player]
    if not profile or not persistent[player] then
        return true
    end

    local state = saveStates[player]
    if not state then
        return false, "save_state_missing"
    end

    -- Serialize saves per player. This prevents an older autosave snapshot from
    -- completing after a newer leave/shutdown save and overwriting it.
    while state.Saving do
        task.wait()
        if profiles[player] ~= profile then
            return false, "profile_unloaded"
        end
        state = saveStates[player]
        if not state then
            return false, "save_state_missing"
        end
    end
    state.Saving = true

    local capturedRevision = state.Revision
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
            -- Saving is stricter than claiming: once another session owns the
            -- key (or our lock disappeared), this server must never reacquire it
            -- implicitly during a save.
            if not ProfileSaveRules.OwnsLock(oldLock, sessionId) then
                lostLock = true
                return nil
            end
            return snapshot
        end)
    end)

    state.Saving = false
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
                "[PlayerDataService] Refused save for %s because session lock was lost",
                player.Name
            )
        )
        return false, "session_lock_lost"
    end

    local savedRevision = ProfileSaveRules.SavedRevisionAfterSuccess(
        capturedRevision,
        state.Revision,
        state.SavedRevision
    )
    state.SavedRevision = savedRevision
    return true
end

function PlayerDataService.Unload(player)
    local saved, reason = PlayerDataService.Save(player, true)
    if not saved then
        warn(
            string.format(
                "[PlayerDataService] Final save failed for %s: %s",
                player.Name,
                tostring(reason)
            )
        )
    end
    profiles[player] = nil
    persistent[player] = nil
    saveStates[player] = nil
end
function PlayerDataService.IsPersistent(player)
    return persistent[player] == true
end
function PlayerDataService.GetSaveState(player)
    local state = saveStates[player]
    if not state then
        return nil
    end
    return {
        Revision = state.Revision,
        SavedRevision = state.SavedRevision,
        Saving = state.Saving,
        Dirty = state.Revision > state.SavedRevision,
    }
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
        local remaining = 0
        for player in profiles do
            remaining += 1
            task.spawn(function()
                PlayerDataService.Save(player, true)
                remaining -= 1
            end)
        end

        local deadline = os.clock() + (GameConfig.DataStore.ShutdownSaveSeconds or 24)
        while remaining > 0 and os.clock() < deadline do
            task.wait(0.05)
        end
        if remaining > 0 then
            warn(
                string.format(
                    "[PlayerDataService] Shutdown save window expired with %d profile(s) still pending",
                    remaining
                )
            )
        end
    end)
end

return PlayerDataService
