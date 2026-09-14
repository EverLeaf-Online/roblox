local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DerivedStatsService = require(script.Parent.DerivedStatsService)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerDamageService = require(script.Parent.PlayerDamageService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local ResourceRegenMath = require(ReplicatedStorage.Shared.Math.ResourceRegenMath)

local ResourceService = {}
local runtime = {}
local initialized = false

local function getOrCreate(player, profile)
    local state = runtime[player]
    if state then
        return state
    end

    local derived = DerivedStatsService.Compute(profile)
    state = {
        CurrentMP = derived.MaxMP,
        LastCombatAt = -math.huge,
    }
    runtime[player] = state
    return state
end

function ResourceService.Reset(player, profile)
    local derived = DerivedStatsService.Compute(profile)
    runtime[player] = {
        CurrentMP = derived.MaxMP,
        LastCombatAt = -math.huge,
    }
end

function ResourceService.Reconcile(player, profile)
    local state = getOrCreate(player, profile)
    local derived = DerivedStatsService.Compute(profile)
    state.CurrentMP = math.clamp(state.CurrentMP, 0, derived.MaxMP)
end

function ResourceService.GetSnapshot(player, profile)
    local state = getOrCreate(player, profile)
    local derived = DerivedStatsService.Compute(profile)
    return {
        CurrentMP = math.clamp(state.CurrentMP, 0, derived.MaxMP),
    }
end

function ResourceService.MarkCombat(player, profile)
    local state = getOrCreate(player, profile)
    state.LastCombatAt = os.clock()
end

function ResourceService.CanSpendMP(player, profile, amount)
    if type(amount) ~= "number" or amount <= 0 or amount ~= amount or amount == math.huge then
        return false
    end
    local state = getOrCreate(player, profile)
    return state.CurrentMP >= amount
end

function ResourceService.SpendMP(player, profile, amount)
    if not ResourceService.CanSpendMP(player, profile, amount) then
        return false, "insufficient_mp"
    end
    local state = getOrCreate(player, profile)
    state.CurrentMP -= amount
    state.LastCombatAt = os.clock()
    return true, state.CurrentMP
end

function ResourceService.RestoreMP(player, profile, amount)
    if type(amount) ~= "number" or amount <= 0 then
        return false, "invalid_amount"
    end
    local state = getOrCreate(player, profile)
    local derived = DerivedStatsService.Compute(profile)
    state.CurrentMP = math.min(derived.MaxMP, state.CurrentMP + amount)
    return true, state.CurrentMP
end

local function regeneratePlayer(player, now)
    local profile = PlayerDataService.Get(player)
    if not profile then
        return
    end
    local state = getOrCreate(player, profile)
    local derived = DerivedStatsService.Compute(profile)
    local lastCombatAt = math.max(PlayerDamageService.GetLastDamageAt(player), state.LastCombatAt)
    local changedMP = false

    if
        now - lastCombatAt >= GameConfig.Resources.MPRegenDelay
        and state.CurrentMP < derived.MaxMP
    then
        local amount = ResourceRegenMath.MPPerTick(profile.Stats.Insight, GameConfig.Resources)
        local nextMP = math.min(derived.MaxMP, state.CurrentMP + amount)
        changedMP = math.abs(nextMP - state.CurrentMP) > 0.001
        state.CurrentMP = nextMP
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if
        humanoid
        and humanoid.Health > 0
        and humanoid.Health < humanoid.MaxHealth
        and now - lastCombatAt >= GameConfig.Resources.HPRegenDelay
    then
        local amount = ResourceRegenMath.HPPerTick(humanoid.MaxHealth, GameConfig.Resources)
        humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + amount)
    end

    if changedMP then
        PlayerDataService.NotifyChanged(player)
    end
end

function ResourceService.Init()
    if initialized then
        return
    end
    initialized = true
    task.spawn(function()
        while true do
            task.wait(GameConfig.Resources.RegenTickSeconds)
            local now = os.clock()
            for _, player in Players:GetPlayers() do
                regeneratePlayer(player, now)
            end
        end
    end)
end

Players.PlayerRemoving:Connect(function(player)
    runtime[player] = nil
end)

return ResourceService
