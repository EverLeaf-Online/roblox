local Players = game:GetService("Players")

local DerivedStatsService = require(script.Parent.DerivedStatsService)

local ResourceService = {}
local runtime = {}

local function getOrCreate(player, profile)
    local state = runtime[player]
    if state then
        return state
    end

    local derived = DerivedStatsService.Compute(profile)
    state = {
        CurrentMP = derived.MaxMP,
    }
    runtime[player] = state
    return state
end

function ResourceService.Reset(player, profile)
    local derived = DerivedStatsService.Compute(profile)
    runtime[player] = {
        CurrentMP = derived.MaxMP,
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
    return true, state.CurrentMP
end

Players.PlayerRemoving:Connect(function(player)
    runtime[player] = nil
end)

return ResourceService
