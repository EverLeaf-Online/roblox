local DerivedStatsService = require(script.Parent.DerivedStatsService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local ResourceService = require(script.Parent.ResourceService)

local CharacterStatsService = {}

function CharacterStatsService.Apply(player, resetResources)
    local profile = PlayerDataService.Get(player)
    local character = player.Character
    if not profile or not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local derived = DerivedStatsService.Compute(profile)
    local oldMax = math.max(1, humanoid.MaxHealth)
    local oldHealth = humanoid.Health
    local wasDead = oldHealth <= 0
    local ratio = math.clamp(oldHealth / oldMax, 0, 1)

    humanoid.MaxHealth = derived.MaxHP
    if resetResources then
        humanoid.Health = derived.MaxHP
    elseif not wasDead then
        humanoid.Health = math.max(1, derived.MaxHP * ratio)
    end

    if resetResources then
        ResourceService.Reset(player, profile)
    else
        ResourceService.Reconcile(player, profile)
    end
end

return CharacterStatsService
