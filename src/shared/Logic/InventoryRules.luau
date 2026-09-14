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

function InventoryRules.IsValidQuantity(quantity)
    return type(quantity) == "number" and quantity % 1 == 0 and quantity > 0
end

function InventoryRules.CanAdd(slots, capacity, itemId, quantity, stackLimit)
    if not InventoryRules.IsValidQuantity(quantity) then
        return false
    end
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

function InventoryRules.IsValidEquipmentSlot(slotName)
    return VALID_EQUIPMENT_SLOTS[slotName] == true
end

return InventoryRules
