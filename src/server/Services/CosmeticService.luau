local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ActionPayloadRules = require(ReplicatedStorage.Shared.Validation.ActionPayloadRules)
local CosmeticDefinitions = require(ReplicatedStorage.Shared.CosmeticDefinitions)

local CosmeticService = {}

function CosmeticService.Grant(profile, cosmeticId)
    if type(cosmeticId) ~= "string" or cosmeticId == "" or #cosmeticId > 64 then
        return false, "invalid_cosmetic"
    end
    if not CosmeticDefinitions[cosmeticId] then
        return false, "unknown_cosmetic"
    end
    if profile.Cosmetics.Owned[cosmeticId] then
        return false, "already_owned"
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
    if cosmeticId == "" then
        profile.Cosmetics.Equipped[slotName] = ""
        return true
    end

    local definition = CosmeticDefinitions[cosmeticId]
    if not definition then
        return false, "unknown_cosmetic"
    end
    if definition.Slot ~= slotName then
        return false, "wrong_slot"
    end
    if not profile.Cosmetics.Owned[cosmeticId] then
        return false, "not_owned"
    end
    profile.Cosmetics.Equipped[slotName] = cosmeticId
    return true
end

return CosmeticService
