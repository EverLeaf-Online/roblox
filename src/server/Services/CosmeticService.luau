local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ActionPayloadRules = require(ReplicatedStorage.Shared.Validation.ActionPayloadRules)

local CosmeticService = {}

function CosmeticService.Grant(profile, cosmeticId)
    if type(cosmeticId) ~= "string" or cosmeticId == "" or #cosmeticId > 64 then
        return false, "invalid_cosmetic"
    end
    profile.Cosmetics.Owned[cosmeticId] = true
    return true
end

function CosmeticService.Equip(profile, slotName, cosmeticId)
    if not ActionPayloadRules.IsCosmeticSlot(slotName) then
        return false, "invalid_slot"
    end
    if type(cosmeticId) ~= "string" or #cosmeticId > 64 then
        return false, "invalid_cosmetic"
    end
    if cosmeticId ~= "" and not profile.Cosmetics.Owned[cosmeticId] then
        return false, "not_owned"
    end
    profile.Cosmetics.Equipped[slotName] = cosmeticId
    return true
end

return CosmeticService
