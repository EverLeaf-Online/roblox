local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local AdvancementRules = require(ReplicatedStorage.Shared.Logic.AdvancementRules)
local HotbarRules = require(ReplicatedStorage.Shared.Logic.HotbarRules)
local ClassFamilyDefinitions = require(script.Parent.Parent.Content.ClassFamilyDefinitions)
local InventoryService = require(script.Parent.InventoryService)

local AdvancementService = {}
local FIRST_TRIAL_QUEST_ID = "first_advancement_trial"
local SECOND_PREREQUISITE_QUEST_ID = "belforge_gate_sentinel"
local SECOND_ADVANCEMENT_LEVEL = GameConfig.Progression.LaterAdvancementLevels[1] or 30
local STARTING_SP = GameConfig.Progression.SPPerLevelAfterFirstAdvancement
local SECOND_ADVANCEMENT_SP = GameConfig.Progression.SPPerLevelAfterFirstAdvancement

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

function AdvancementService.CanSecondAdvance(profile)
    if type(profile) ~= "table" then
        return false, "invalid_state"
    end
    local familyId = profile.FamilyId
    local family = type(familyId) == "string" and ClassFamilyDefinitions[familyId] or nil
    if not family then
        return false, "unknown_family"
    end
    return AdvancementRules.CanSecondAdvance(
        profile,
        family,
        SECOND_ADVANCEMENT_LEVEL,
        SECOND_PREREQUISITE_QUEST_ID
    )
end

local function assignStarterSkill(profile, starterSkillId)
    if type(starterSkillId) ~= "string" or starterSkillId == "" then
        return nil
    end
    profile.Skills.Learned[starterSkillId] =
        math.max(1, profile.Skills.Learned[starterSkillId] or 0)
    local existingSlot = HotbarRules.FindSkill(profile.Skills.Hotbar, starterSkillId)
    if existingSlot then
        return existingSlot
    end
    for index = 2, 8 do
        local key = tostring(index)
        if profile.Skills.Hotbar[key] == nil or profile.Skills.Hotbar[key] == "" then
            HotbarRules.Assign(profile.Skills.Hotbar, index, starterSkillId)
            return index
        end
    end
    return nil
end

local function canGrantStarterItem(profile, starterItemId)
    if type(starterItemId) ~= "string" or starterItemId == "" then
        return true
    end
    local weapon = profile.Equipment and profile.Equipment.Weapon or ""
    if weapon == nil or weapon == "" then
        return true
    end
    return InventoryService.CanAdd(profile, starterItemId, 1)
end

local function grantStarterItem(profile, starterItemId)
    if type(starterItemId) ~= "string" or starterItemId == "" then
        return nil, false
    end
    profile.Equipment = profile.Equipment or {}
    if profile.Equipment.Weapon == nil or profile.Equipment.Weapon == "" then
        profile.Equipment.Weapon = starterItemId
        return starterItemId, true
    end
    local added = InventoryService.Add(profile, starterItemId, 1)
    if added then
        return starterItemId, false
    end
    return nil, false
end

function AdvancementService.FirstAdvance(profile, familyId)
    local ok, reason = AdvancementService.CanFirstAdvance(profile, familyId)
    if not ok then
        return false, reason
    end

    local family = ClassFamilyDefinitions[familyId]
    if not canGrantStarterItem(profile, family.StarterItemId) then
        return false, "inventory_full"
    end

    profile.FamilyId = familyId
    profile.AdvancementTier = 1
    profile.SP += STARTING_SP
    local hotbarSlot = assignStarterSkill(profile, family.StarterSkillId)
    local starterItemId, starterItemEquipped = grantStarterItem(profile, family.StarterItemId)

    return true,
        {
            Tier = 1,
            FamilyId = familyId,
            FamilyDisplayName = family.DisplayName,
            StarterSkillId = family.StarterSkillId,
            StarterSkillHotbarSlot = hotbarSlot,
            StarterItemId = starterItemId,
            StarterItemEquipped = starterItemEquipped,
            GrantedSP = STARTING_SP,
        }
end

function AdvancementService.SecondAdvance(profile)
    local ok, reason = AdvancementService.CanSecondAdvance(profile)
    if not ok then
        return false, reason
    end

    local family = ClassFamilyDefinitions[profile.FamilyId]
    local advancement = family.SecondAdvancement
    profile.AdvancementTier = 2
    profile.SP += SECOND_ADVANCEMENT_SP
    local hotbarSlot = assignStarterSkill(profile, advancement.StarterSkillId)

    return true,
        {
            Tier = 2,
            FamilyId = profile.FamilyId,
            FamilyDisplayName = family.DisplayName,
            AdvancementDisplayName = advancement.DisplayName,
            StarterSkillId = advancement.StarterSkillId,
            StarterSkillHotbarSlot = hotbarSlot,
            GrantedSP = SECOND_ADVANCEMENT_SP,
        }
end

return AdvancementService
