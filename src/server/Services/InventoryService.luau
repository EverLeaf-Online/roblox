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
    local total = 0
    for _, slot in ensure(profile).Slots do
        if slot.ItemId == itemId then
            total += slot.Quantity
        end
    end
    return total
end

function InventoryService.CanAdd(profile, itemId, quantity)
    local definition = ItemDefinitions[itemId]
    if not definition or not InventoryRules.IsValidQuantity(quantity) then
        return false
    end
    local inventory = ensure(profile)
    local stackLimit = definition.StackLimit or 1
    return InventoryRules.CanAdd(inventory.Slots, inventory.Capacity, itemId, quantity, stackLimit)
end

function InventoryService.Add(profile, itemId, quantity)
    local definition = ItemDefinitions[itemId]
    if not definition then
        return false, "unknown_item"
    end
    if not InventoryRules.IsValidQuantity(quantity) then
        return false, "invalid_quantity"
    end
    if not InventoryService.CanAdd(profile, itemId, quantity) then
        return false, "inventory_full"
    end

    local inventory = ensure(profile)
    local stackLimit = definition.StackLimit or 1
    local remaining = quantity
    for _, slot in inventory.Slots do
        if slot.ItemId == itemId and slot.Quantity < stackLimit then
            local moved = math.min(remaining, stackLimit - slot.Quantity)
            slot.Quantity += moved
            remaining -= moved
            if remaining <= 0 then
                return true
            end
        end
    end
    while remaining > 0 do
        local moved = math.min(remaining, stackLimit)
        table.insert(inventory.Slots, { ItemId = itemId, Quantity = moved })
        remaining -= moved
    end
    return true
end

function InventoryService.RemoveAt(profile, slotIndex, quantity)
    if type(slotIndex) ~= "number" or slotIndex % 1 ~= 0 then
        return false, "invalid_slot"
    end
    if not InventoryRules.IsValidQuantity(quantity) then
        return false, "invalid_quantity"
    end
    local slots = ensure(profile).Slots
    local slot = slots[slotIndex]
    if not slot then
        return false, "empty_slot"
    end
    if slot.Quantity < quantity then
        return false, "insufficient_quantity"
    end
    slot.Quantity -= quantity
    local itemId = slot.ItemId
    if slot.Quantity == 0 then
        table.remove(slots, slotIndex)
    end
    return true, itemId
end

function InventoryService.Remove(profile, itemId, quantity)
    if not InventoryRules.IsValidQuantity(quantity) then
        return false, "invalid_quantity"
    end
    if InventoryService.Count(profile, itemId) < quantity then
        return false, "insufficient_quantity"
    end
    local slots = ensure(profile).Slots
    local remaining = quantity
    for index = #slots, 1, -1 do
        local slot = slots[index]
        if slot.ItemId == itemId then
            local moved = math.min(remaining, slot.Quantity)
            slot.Quantity -= moved
            remaining -= moved
            if slot.Quantity == 0 then
                table.remove(slots, index)
            end
            if remaining == 0 then
                break
            end
        end
    end
    return true
end

return InventoryService
