local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local AdvancementRules = require(ReplicatedStorage.Shared.Logic.AdvancementRules)
local ClassFamilyDefinitions = require(script.Parent.Parent.Content.ClassFamilyDefinitions)

local AdvancementService = {}
local FIRST_TRIAL_QUEST_ID = "first_advancement_trial"
local STARTING_SP = GameConfig.Progression.SPPerLevelAfterFirstAdvancement

function AdvancementService.GetFamily(familyId)
    return ClassFamilyDefinitions[familyId]
end

function AdvancementService.RequiredLevel(targetTier, familyId)
    if targetTier == 1 then
        local family = ClassFamilyDefinitions[familyId]
        return family and family.FirstAdvancementLevel or nil
    end
    local laterIndex = targetTier - 1
    return GameConfig.Progression.LaterAdvancementLevels[laterIndex]
end

function AdvancementService.CanFirstAdvance(profile, familyId)
    if type(familyId) ~= "string" or familyId == "" then
        return false, "invalid_family"
    end
    local family = ClassFamilyDefinitions[familyId]
    if not family then
        return false, "unknown_family"
    end
    return AdvancementRules.CanFirstAdvance(profile, family, FIRST_TRIAL_QUEST_ID)
end

local function assignStarterSkill(profile, starterSkillId)
    if type(starterSkillId) ~= "string" or starterSkillId == "" then
        return nil
    end
    profile.Skills.Learned[starterSkillId] =
        math.max(1, profile.Skills.Learned[starterSkillId] or 0)
    for index = 2, 8 do
        local key = tostring(index)
        if profile.Skills.Hotbar[key] == nil or profile.Skills.Hotbar[key] == "" then
            profile.Skills.Hotbar[key] = starterSkillId
            return index
        end
    end
    return nil
end

function AdvancementService.FirstAdvance(profile, familyId)
    local ok, reason = AdvancementService.CanFirstAdvance(profile, familyId)
    if not ok then
        return false, reason
    end

    local family = ClassFamilyDefinitions[familyId]
    profile.FamilyId = familyId
    profile.AdvancementTier = 1
    profile.SP += STARTING_SP
    local hotbarSlot = assignStarterSkill(profile, family.StarterSkillId)

    return true,
        {
            Tier = 1,
            FamilyId = familyId,
            FamilyDisplayName = family.DisplayName,
            StarterSkillId = family.StarterSkillId,
            StarterSkillHotbarSlot = hotbarSlot,
            GrantedSP = STARTING_SP,
        }
end

return AdvancementService
