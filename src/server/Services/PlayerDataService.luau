local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local PlayerDataService = {}

local profiles = {}

local function makeDefaultProfile()
    return {
        Level = 1,
        Exp = 0,
        AP = 0,
        SP = 0,
        AdvancementTier = 0,
        FamilyId = nil,
        Stats = {
            Might = 4,
            Finesse = 4,
            Insight = 4,
            Fortune = 4,
        },
        Currencies = {
            Shards = 0,
            Marks = 0,
        },
    }
end

local function cloneProfile(profile)
    return {
        Level = profile.Level,
        Exp = profile.Exp,
        AP = profile.AP,
        SP = profile.SP,
        AdvancementTier = profile.AdvancementTier,
        FamilyId = profile.FamilyId,
        Stats = table.clone(profile.Stats),
        Currencies = table.clone(profile.Currencies),
    }
end

function PlayerDataService.Load(player)
    assert(player:IsA("Player"), "Load expects Player")
    if profiles[player] then
        return profiles[player]
    end

    local profile = makeDefaultProfile()
    profiles[player] = profile
    return profile
end

function PlayerDataService.Get(player)
    return profiles[player]
end

function PlayerDataService.GetSnapshot(player)
    local profile = profiles[player]
    if not profile then
        return nil
    end
    return cloneProfile(profile)
end

function PlayerDataService.Mutate(player, mutator)
    local profile = profiles[player]
    if not profile then
        return false, "profile_not_loaded"
    end

    mutator(profile)
    return true
end

function PlayerDataService.Unload(player)
    -- Persistence will replace this in the next milestone. Keeping state
    -- server-owned now prevents client-authoritative progression from entering
    -- the architecture while the game is still new.
    profiles[player] = nil
end

function PlayerDataService.Init()
    Players.PlayerRemoving:Connect(PlayerDataService.Unload)
end

return PlayerDataService
