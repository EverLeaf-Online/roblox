local InventoryService = require(script.Parent.InventoryService)
local ResourceService = require(script.Parent.ResourceService)

local ConsumableService = {}

function ConsumableService.Use(player, profile, itemId)
    local definition = InventoryService.GetDefinition(itemId)
    if not definition or definition.Type ~= "Consumable" then
        return false, "not_consumable"
    end
    if InventoryService.Count(profile, itemId) < 1 then
        return false, "item_missing"
    end
    local effects = definition.Effects or {}
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if effects.RestoreHP and humanoid and humanoid.Health > 0 then
        humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + effects.RestoreHP)
    end
    if effects.RestoreMP then
        ResourceService.RestoreMP(player, profile, effects.RestoreMP)
    end
    return InventoryService.Remove(profile, itemId, 1)
end

return ConsumableService
