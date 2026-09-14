local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local AdvancementService = {}

local validFirstLevels = {}
for _, level in GameConfig.Progression.FirstAdvancementLevels do
    validFirstLevels[level] = true
end

function AdvancementService.RequiredLevel(targetTier, firstAdvancementLevel)
    if targetTier == 1 then
        if not validFirstLevels[firstAdvancementLevel] then
            return nil
        end
        return firstAdvancementLevel
    end

    local laterIndex = targetTier - 1
    return GameConfig.Progression.LaterAdvancementLevels[laterIndex]
end

function AdvancementService.CanAdvance(profile, targetTier, firstAdvancementLevel)
    if type(targetTier) ~= "number" or targetTier % 1 ~= 0 then
        return false, "invalid_tier"
    end
    if targetTier ~= profile.AdvancementTier + 1 then
        return false, "wrong_tier"
    end

    local requiredLevel = AdvancementService.RequiredLevel(targetTier, firstAdvancementLevel)
    if not requiredLevel then
        return false, "invalid_requirement"
    end
    if profile.Level < requiredLevel then
        return false, "level_too_low"
    end
    return true
end

function AdvancementService.Advance(profile, familyId, firstAdvancementLevel)
    local targetTier = profile.AdvancementTier + 1
    local ok, reason = AdvancementService.CanAdvance(profile, targetTier, firstAdvancementLevel)
    if not ok then
        return false, reason
    end

    if targetTier == 1 then
        if type(familyId) ~= "string" or familyId == "" then
            return false, "invalid_family"
        end
        profile.FamilyId = familyId
    elseif not profile.FamilyId then
        return false, "missing_family"
    end

    profile.AdvancementTier = targetTier
    return true, targetTier
end

return AdvancementService
