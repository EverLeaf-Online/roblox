local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SkillDefinitions = require(script.Parent.Parent.Content.SkillDefinitions)
local ResourceService = require(script.Parent.ResourceService)
local SkillUseRules = require(ReplicatedStorage.Shared.Logic.SkillUseRules)
local HotbarRules = require(ReplicatedStorage.Shared.Logic.HotbarRules)
local AdvancementRules = require(ReplicatedStorage.Shared.Logic.AdvancementRules)
local SkillEffectService = require(script.Parent.SkillEffectService)

local SkillService = {}
local cooldowns = {}

function SkillService.Learn(profile, skillId)
    local definition = SkillDefinitions[skillId]
    if not definition then
        return false, "unknown_skill"
    end
    local familyAllowed, familyReason = AdvancementRules.CanUseFamilySkill(profile, definition)
    if not familyAllowed then
        return false, familyReason
    end
    if profile.Level < (definition.RequiredLevel or 1) then
        return false, "level_too_low"
    end
    if profile.AdvancementTier < (definition.RequiredTier or 0) then
        return false, "tier_too_low"
    end
    local currentRank = profile.Skills.Learned[skillId] or 0
    if currentRank >= definition.MaxRank then
        return false, "max_rank"
    end
    local cost = definition.SPCostPerRank or 1
    if profile.SP < cost then
        return false, "insufficient_sp"
    end
    profile.SP -= cost
    profile.Skills.Learned[skillId] = currentRank + 1
    return true, currentRank + 1
end

function SkillService.AssignHotbar(profile, hotbarIndex, skillId)
    local definition = type(skillId) == "string" and skillId ~= "" and SkillDefinitions[skillId]
        or nil
    local allowed, reason = HotbarRules.CanAssign(
        hotbarIndex,
        skillId,
        skillId == "" or definition ~= nil,
        definition and definition.Kind or nil,
        skillId == "" and 1 or profile.Skills.Learned[skillId]
    )
    if not allowed then
        return false, reason
    end
    HotbarRules.Assign(profile.Skills.Hotbar, hotbarIndex, skillId)
    return true, { Index = hotbarIndex, SkillId = skillId }
end

function SkillService.TryBeginUse(player, profile, skillId)
    local definition = SkillDefinitions[skillId]
    if not definition or definition.Kind ~= "Active" then
        return false, "invalid_skill"
    end
    if not profile.Skills.Learned[skillId] then
        return false, "skill_not_learned"
    end
    local familyAllowed, familyReason = AdvancementRules.CanUseFamilySkill(profile, definition)
    if not familyAllowed then
        return false, familyReason
    end
    local state = cooldowns[player]
    if not state then
        state = {}
        cooldowns[player] = state
    end
    local now = os.clock()
    local previousCooldown = state[skillId] or 0
    local mpCost = definition.MPCost or 0
    local resourceSnapshot = ResourceService.GetSnapshot(player, profile)
    local allowed, reason =
        SkillUseRules.CanBegin(now, previousCooldown, resourceSnapshot.CurrentMP, mpCost)
    if not allowed then
        return false, reason
    end
    if mpCost > 0 then
        local spent, spendReason = ResourceService.SpendMP(player, profile, mpCost)
        if not spent then
            return false, spendReason
        end
    end
    state[skillId] = now + (definition.Cooldown or 0)
    return true, definition, { PreviousCooldown = previousCooldown, MPCost = mpCost }
end

function SkillService.Use(player, profile, skillId)
    local ok, definitionOrReason, transaction = SkillService.TryBeginUse(player, profile, skillId)
    if not ok then
        return false, definitionOrReason
    end

    local effectOk, result = SkillEffectService.Execute(player, profile, definitionOrReason)
    if effectOk then
        return true, result
    end

    local state = cooldowns[player]
    if state then
        state[skillId] = transaction.PreviousCooldown
    end
    if transaction.MPCost > 0 then
        ResourceService.RestoreMP(player, profile, transaction.MPCost)
    end
    return false, result
end

Players.PlayerRemoving:Connect(function(player)
    cooldowns[player] = nil
end)

return SkillService
