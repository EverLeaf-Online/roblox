local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryRules = require(ReplicatedStorage.Shared.Logic.InventoryRules)
local EquipmentEligibilityRules = require(ReplicatedStorage.Shared.Logic.EquipmentEligibilityRules)
local InventoryService = require(script.Parent.InventoryService)

local EquipmentService = {}
function EquipmentService.Equip(profile, inventoryIndex)
    local inventory = profile.Inventory
    local slot = inventory and inventory.Slots and inventory.Slots[inventoryIndex]
    if not slot then
        return false, "empty_slot"
    end
    local definition = InventoryService.GetDefinition(slot.ItemId)
    if not definition or definition.Type ~= "Equipment" then
        return false, "not_equipment"
    end
    local equipmentSlot = definition.EquipmentSlot
    if not InventoryRules.IsValidEquipmentSlot(equipmentSlot) then
        return false, "invalid_equipment_slot"
    end
    local eligible, eligibilityReason = EquipmentEligibilityRules.CanEquip(profile, definition)
    if not eligible then
        return false, eligibilityReason
    end

    local newItemId = slot.ItemId
    local oldItemId = profile.Equipment[equipmentSlot]
    local removed, reason = InventoryService.RemoveAt(profile, inventoryIndex, 1)
    if not removed then
        return false, reason
    end
    if oldItemId ~= "" then
        local returned, returnReason = InventoryService.Add(profile, oldItemId, 1)
        if not returned then
            InventoryService.Add(profile, newItemId, 1)
            return false, returnReason
        end
    end
    profile.Equipment[equipmentSlot] = newItemId
    return true, equipmentSlot
end

function EquipmentService.Unequip(profile, equipmentSlot)
    if not InventoryRules.IsValidEquipmentSlot(equipmentSlot) then
        return false, "invalid_equipment_slot"
    end
    local itemId = profile.Equipment[equipmentSlot]
    if not itemId or itemId == "" then
        return false, "slot_empty"
    end
    local ok, reason = InventoryService.Add(profile, itemId, 1)
    if not ok then
        return false, reason
    end
    profile.Equipment[equipmentSlot] = ""
    return true
end

function EquipmentService.GetStatBonus(profile, statName)
    local total = 0
    for _, itemId in profile.Equipment do
        if itemId ~= "" then
            local definition = InventoryService.GetDefinition(itemId)
            local stats = definition and definition.Stats
            if stats and type(stats[statName]) == "number" then
                total += stats[statName]
            end
        end
    end
    return total
end

return EquipmentService
