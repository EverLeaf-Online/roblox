local EquipmentEligibilityRules = {}

function EquipmentEligibilityRules.CanEquip(profile, definition)
    if type(profile) ~= "table" or type(definition) ~= "table" then
        return false, "invalid_state"
    end
    local familyId = definition.FamilyId
    if familyId ~= nil and familyId ~= "" and profile.FamilyId ~= familyId then
        return false, "wrong_family"
    end
    local requiredTier = tonumber(definition.RequiredAdvancementTier) or 0
    if (tonumber(profile.AdvancementTier) or 0) < requiredTier then
        return false, "tier_too_low"
    end
    local requiredLevel = tonumber(definition.RequiredLevel) or 1
    if (tonumber(profile.Level) or 1) < requiredLevel then
        return false, "level_too_low"
    end
    return true
end

return EquipmentEligibilityRules
