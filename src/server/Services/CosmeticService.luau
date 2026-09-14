local CosmeticService = {}

function CosmeticService.Grant(profile, cosmeticId)
    if type(cosmeticId) ~= "string" or cosmeticId == "" then
        return false, "invalid_cosmetic"
    end
    profile.Cosmetics.Owned[cosmeticId] = true
    return true
end

function CosmeticService.Equip(profile, slotName, cosmeticId)
    if type(slotName) ~= "string" or slotName == "" then
        return false, "invalid_slot"
    end
    if cosmeticId ~= "" and not profile.Cosmetics.Owned[cosmeticId] then
        return false, "not_owned"
    end
    profile.Cosmetics.Equipped[slotName] = cosmeticId
    return true
end

return CosmeticService
