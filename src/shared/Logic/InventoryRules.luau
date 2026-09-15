local InventoryRules = {}

local VALID_EQUIPMENT_SLOTS = {
    Weapon = true,
    Head = true,
    Body = true,
    Legs = true,
    Accessory = true,
    Ring1 = true,
    Ring2 = true,
}

local function validSlots(slots)
    if type(slots) ~= "table" then
        return false
    end
    for _, slot in slots do
        if
            type(slot) ~= "table"
            or type(slot.ItemId) ~= "string"
            or slot.ItemId == ""
            or not InventoryRules.IsValidQuantity(slot.Quantity)
        then
            return false
        end
    end
    return true
end

function InventoryRules.IsValidQuantity(quantity)
    return type(quantity) == "number" and quantity % 1 == 0 and quantity > 0
end

function InventoryRules.Count(slots, itemId)
    if type(slots) ~= "table" then
        return 0
    end
    local total = 0
    for _, slot in slots do
        if
            type(slot) == "table"
            and slot.ItemId == itemId
            and InventoryRules.IsValidQuantity(slot.Quantity)
        then
            total += slot.Quantity
        end
    end
    return total
end

function InventoryRules.CanAdd(slots, capacity, itemId, quantity, stackLimit)
    if not validSlots(slots) or not InventoryRules.IsValidQuantity(quantity) then
        return false
    end
    capacity = math.max(0, math.floor(tonumber(capacity) or 0))
    stackLimit = math.max(1, math.floor(tonumber(stackLimit) or 1))
    local remaining = quantity
    for _, slot in slots do
        if slot.ItemId == itemId and slot.Quantity < stackLimit then
            remaining -= math.min(remaining, stackLimit - slot.Quantity)
            if remaining <= 0 then
                return true
            end
        end
    end
    return #slots + math.ceil(remaining / stackLimit) <= capacity
end

function InventoryRules.Add(slots, capacity, itemId, quantity, stackLimit)
    if not validSlots(slots) or type(itemId) ~= "string" or itemId == "" then
        return false, "invalid_inventory"
    end
    if not InventoryRules.IsValidQuantity(quantity) then
        return false, "invalid_quantity"
    end
    stackLimit = math.max(1, math.floor(tonumber(stackLimit) or 1))
    if not InventoryRules.CanAdd(slots, capacity, itemId, quantity, stackLimit) then
        return false, "inventory_full"
    end

    local remaining = quantity
    for _, slot in slots do
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
        table.insert(slots, { ItemId = itemId, Quantity = moved })
        remaining -= moved
    end
    return true
end

function InventoryRules.RemoveAt(slots, slotIndex, quantity)
    if not validSlots(slots) then
        return false, "invalid_inventory"
    end
    if type(slotIndex) ~= "number" or slotIndex % 1 ~= 0 then
        return false, "invalid_slot"
    end
    if not InventoryRules.IsValidQuantity(quantity) then
        return false, "invalid_quantity"
    end
    local slot = slots[slotIndex]
    if not slot then
        return false, "empty_slot"
    end
    if (tonumber(slot.Quantity) or 0) < quantity then
        return false, "insufficient_quantity"
    end

    slot.Quantity -= quantity
    local itemId = slot.ItemId
    if slot.Quantity == 0 then
        table.remove(slots, slotIndex)
    end
    return true, itemId
end

function InventoryRules.Remove(slots, itemId, quantity)
    if not validSlots(slots) then
        return false, "invalid_inventory"
    end
    if type(itemId) ~= "string" or itemId == "" then
        return false, "invalid_item"
    end
    if not InventoryRules.IsValidQuantity(quantity) then
        return false, "invalid_quantity"
    end
    if InventoryRules.Count(slots, itemId) < quantity then
        return false, "insufficient_quantity"
    end

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

function InventoryRules.IsValidEquipmentSlot(slotName)
    return VALID_EQUIPMENT_SLOTS[slotName] == true
end

return table.freeze(InventoryRules)
