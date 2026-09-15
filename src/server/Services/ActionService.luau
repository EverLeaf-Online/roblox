local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ActionPayloadRules = require(ReplicatedStorage.Shared.Validation.ActionPayloadRules)

local AdvancementService = require(script.Parent.AdvancementService)
local BelforgeColossusService = require(script.Parent.BelforgeColossusService)
local ConsumableService = require(script.Parent.ConsumableService)
local CosmeticService = require(script.Parent.CosmeticService)
local EquipmentService = require(script.Parent.EquipmentService)
local InteractionService = require(script.Parent.InteractionService)
local InteractionSessionService = require(script.Parent.InteractionSessionService)
local PartyService = require(script.Parent.PartyService)
local PayloadValidationService = require(script.Parent.PayloadValidationService)
local ShopService = require(script.Parent.ShopService)
local SocialProfileService = require(script.Parent.SocialProfileService)
local SkillService = require(script.Parent.SkillService)
local StatService = require(script.Parent.StatService)

local ActionService = {}
local handlers = {}

handlers["stat.allocate"] = function(_, profile, payload)
    return StatService.Allocate(profile, payload.StatName, payload.Amount or 1)
end
handlers["inventory.use"] = function(player, profile, payload)
    return ConsumableService.Use(player, profile, payload.ItemId)
end
handlers["equipment.equip"] = function(_, profile, payload)
    return EquipmentService.Equip(profile, payload.InventoryIndex)
end
handlers["equipment.unequip"] = function(_, profile, payload)
    return EquipmentService.Unequip(profile, payload.Slot)
end
handlers["skill.learn"] = function(_, profile, payload)
    return SkillService.Learn(profile, payload.SkillId)
end
handlers["skill.hotbar"] = function(_, profile, payload)
    return SkillService.AssignHotbar(profile, payload.Index, payload.SkillId)
end
handlers["skill.use"] = function(player, profile, payload)
    return SkillService.Use(player, profile, payload.SkillId)
end
handlers["quest.start"] = function(player, profile, payload)
    if not InteractionSessionService.ValidateNpc(player, payload.NpcId) then
        return false, "interaction_session_required"
    end
    return InteractionService.StartOfferedQuest(profile, payload.NpcId, payload.QuestId)
end
handlers["quest.turnin"] = function(player, profile, payload)
    if not InteractionSessionService.ValidateNpc(player, payload.NpcId) then
        return false, "interaction_session_required"
    end
    return InteractionService.TurnInOfferedQuest(profile, payload.NpcId, payload.QuestId)
end
handlers["shop.buy"] = function(player, profile, payload)
    return ShopService.Buy(player, profile, payload.ShopId, payload.ItemId, payload.Quantity)
end
handlers["shop.sell"] = function(player, profile, payload)
    return ShopService.Sell(player, profile, payload.ShopId, payload.ItemId, payload.Quantity)
end
handlers["advancement.first"] = function(player, profile, payload)
    if not InteractionSessionService.ValidateNpc(player, payload.NpcId) then
        return false, "interaction_session_required"
    end
    if not InteractionService.IsAdvancementMentor(payload.NpcId, 1) then
        return false, "invalid_mentor"
    end
    return AdvancementService.FirstAdvance(profile, payload.FamilyId)
end
handlers["advancement.second"] = function(player, profile, payload)
    if not InteractionSessionService.ValidateNpc(player, payload.NpcId) then
        return false, "interaction_session_required"
    end
    if not InteractionService.IsAdvancementMentor(payload.NpcId, 2) then
        return false, "invalid_mentor"
    end
    return AdvancementService.SecondAdvance(profile)
end
handlers["party.create"] = function(player)
    local ok, reason = PartyService.Create(player)
    if not ok then
        return false, reason
    end
    return true, PartyService.GetSnapshot(player)
end
handlers["party.invite"] = function(player, _, payload)
    return PartyService.Invite(player, payload.TargetUserId)
end
handlers["party.accept"] = function(player)
    local ok, result = PartyService.Accept(player)
    if not ok then
        return false, result
    end
    return true, PartyService.GetSnapshot(player)
end
handlers["party.decline"] = function(player)
    return PartyService.Decline(player)
end
handlers["party.kick"] = function(player, _, payload)
    local ok, result = PartyService.Kick(player, payload.TargetUserId)
    if not ok then
        return false, result
    end
    return true, PartyService.GetSnapshot(player)
end
handlers["party.leave"] = function(player)
    return PartyService.Leave(player)
end
handlers["party.ready.respond"] = function(player, _, payload)
    if type(payload.Accepted) ~= "boolean" then
        return false, "invalid_response"
    end
    return BelforgeColossusService.RespondPartyReadyCheck(player, payload.Accepted)
end
handlers["social.inspect"] = function(_, _, payload)
    return SocialProfileService.Inspect(payload.TargetUserId)
end
handlers["cosmetic.equip"] = function(_, profile, payload)
    return CosmeticService.Equip(profile, payload.Slot, payload.CosmeticId)
end
handlers["settings.update"] = function(_, profile, payload)
    local key = payload.Key
    local value = payload.Value
    if key == "MusicVolume" or key == "SfxVolume" then
        if type(value) ~= "number" then
            return false, "invalid_value"
        end
        profile.Settings[key] = math.clamp(value, 0, 1)
        return true
    end
    if key == "ShowDamageNumbers" then
        if type(value) ~= "boolean" then
            return false, "invalid_value"
        end
        profile.Settings[key] = value
        return true
    end
    return false, "invalid_setting"
end

function ActionService.Handle(player, profile, actionName, payload)
    if type(actionName) ~= "string" then
        return false, "invalid_action"
    end
    if payload == nil then
        payload = {}
    end
    if type(payload) ~= "table" or not PayloadValidationService.IsBounded(payload) then
        return false, "invalid_payload"
    end
    local validPayload, payloadReason = ActionPayloadRules.Validate(actionName, payload)
    if not validPayload then
        return false, payloadReason
    end
    local handler = handlers[actionName]
    if not handler then
        return false, "unknown_action"
    end
    local ok, result = handler(player, profile, payload)
    return ok, result, ActionPayloadRules.MutatesProfile(actionName)
end

return ActionService
