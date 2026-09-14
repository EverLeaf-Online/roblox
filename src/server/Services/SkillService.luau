local Players = game:GetService("Players")
local SkillDefinitions = require(script.Parent.Parent.Content.SkillDefinitions)
local ResourceService = require(script.Parent.ResourceService)
local SkillEffectService = require(script.Parent.SkillEffectService)

local SkillService = {}
local cooldowns = {}

function SkillService.Learn(profile, skillId)
    local definition = SkillDefinitions[skillId]
    if not definition then
        return false, "unknown_skill"
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
    if
        type(hotbarIndex) ~= "number"
        or hotbarIndex % 1 ~= 0
        or hotbarIndex < 1
        or hotbarIndex > 8
    then
        return false, "invalid_hotbar_slot"
    end
    if skillId ~= "" and not profile.Skills.Learned[skillId] then
        return false, "skill_not_learned"
    end
    profile.Skills.Hotbar[tostring(hotbarIndex)] = skillId
    return true
end

function SkillService.TryBeginUse(player, profile, skillId)
    local definition = SkillDefinitions[skillId]
    if not definition or definition.Kind ~= "Active" then
        return false, "invalid_skill"
    end
    if not profile.Skills.Learned[skillId] then
        return false, "skill_not_learned"
    end
    local state = cooldowns[player]
    if not state then
        state = {}
        cooldowns[player] = state
    end
    local now = os.clock()
    if (state[skillId] or 0) > now then
        return false, "cooldown"
    end
    local mpCost = definition.MPCost or 0
    if mpCost > 0 then
        local spent, reason = ResourceService.SpendMP(player, profile, mpCost)
        if not spent then
            return false, reason
        end
    end
    state[skillId] = now + (definition.Cooldown or 0)
    return true, definition
end

function SkillService.Use(player, profile, skillId)
    local ok, definitionOrReason = SkillService.TryBeginUse(player, profile, skillId)
    if not ok then
        return false, definitionOrReason
    end
    return SkillEffectService.Execute(player, profile, definitionOrReason)
end

Players.PlayerRemoving:Connect(function(player)
    cooldowns[player] = nil
end)

return SkillService
