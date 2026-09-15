local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryRules = require(ReplicatedStorage.Shared.Logic.InventoryRules)
local ItemDefinitions = require(script.Parent.Parent.Content.ItemDefinitions)

local InventoryService = {}

local function ensure(profile)
    profile.Inventory = profile.Inventory or { Capacity = 48, Slots = {} }
    profile.Inventory.Slots = profile.Inventory.Slots or {}
    return profile.Inventory
end

function InventoryService.GetDefinition(itemId)
    return ItemDefinitions[itemId]
end

function InventoryService.Count(profile, itemId)
    return InventoryRules.Count(ensure(profile).Slots, itemId)
end

function InventoryService.CanAdd(profile, itemId, quantity)
    local definition = ItemDefinitions[itemId]
    if not definition or not InventoryRules.IsValidQuantity(quantity) then
        return false
    end
    local inventory = ensure(profile)
    return InventoryRules.CanAdd(
        inventory.Slots,
        inventory.Capacity,
        itemId,
        quantity,
        definition.StackLimit or 1
    )
end

function InventoryService.Add(profile, itemId, quantity)
    local definition = ItemDefinitions[itemId]
    if not definition then
        return false, "unknown_item"
    end
    local inventory = ensure(profile)
    return InventoryRules.Add(
        inventory.Slots,
        inventory.Capacity,
        itemId,
        quantity,
        definition.StackLimit or 1
    )
end

function InventoryService.RemoveAt(profile, slotIndex, quantity)
    return InventoryRules.RemoveAt(ensure(profile).Slots, slotIndex, quantity)
end

function InventoryService.Remove(profile, itemId, quantity)
    return InventoryRules.Remove(ensure(profile).Slots, itemId, quantity)
end

return InventoryService
