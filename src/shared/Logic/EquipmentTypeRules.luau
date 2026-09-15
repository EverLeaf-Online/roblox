local EquipmentTypeRules = {}

local ARMOR_TYPES = table.freeze({
    LightArmor = true,
    HeavyArmor = true,
})

local ACCESSORY_TYPES = table.freeze({
    Charm = true,
    Ring = true,
})

local ARMOR_SLOTS = table.freeze({
    Head = true,
    Body = true,
    Legs = true,
})

function EquipmentTypeRules.IsArmorType(value)
    return type(value) == "string" and ARMOR_TYPES[value] == true
end

function EquipmentTypeRules.IsAccessoryType(value)
    return type(value) == "string" and ACCESSORY_TYPES[value] == true
end

function EquipmentTypeRules.Validate(definition)
    if type(definition) ~= "table" or definition.Type ~= "Equipment" then
        return false, "not_equipment"
    end

    local slot = definition.EquipmentSlot
    if slot == "Weapon" then
        if type(definition.WeaponType) ~= "string" or definition.WeaponType == "" then
            return false, "weapon_type_required"
        end
        if definition.ArmorType ~= nil or definition.AccessoryType ~= nil then
            return false, "invalid_weapon_category"
        end
        return true
    end

    if ARMOR_SLOTS[slot] then
        if not EquipmentTypeRules.IsArmorType(definition.ArmorType) then
            return false, "armor_type_required"
        end
        if definition.WeaponType ~= nil or definition.AccessoryType ~= nil then
            return false, "invalid_armor_category"
        end
        return true
    end

    if slot == "Accessory" then
        if not EquipmentTypeRules.IsAccessoryType(definition.AccessoryType) then
            return false, "accessory_type_required"
        end
        if definition.AccessoryType == "Ring" then
            return false, "ring_slot_required"
        end
        if definition.WeaponType ~= nil or definition.ArmorType ~= nil then
            return false, "invalid_accessory_category"
        end
        return true
    end

    if slot == "Ring1" or slot == "Ring2" then
        if definition.AccessoryType ~= "Ring" then
            return false, "ring_type_required"
        end
        if definition.WeaponType ~= nil or definition.ArmorType ~= nil then
            return false, "invalid_ring_category"
        end
        return true
    end

    return false, "unsupported_equipment_slot"
end

return table.freeze(EquipmentTypeRules)
