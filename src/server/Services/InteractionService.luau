local NpcDefinitions = require(script.Parent.Parent.Content.NpcDefinitions)
local InteractionSessionService = require(script.Parent.InteractionSessionService)
local QuestService = require(script.Parent.QuestService)
local WorldObjectService = require(script.Parent.WorldObjectService)

local InteractionService = {}
local openedEvent = Instance.new("BindableEvent")

InteractionService.Opened = openedEvent.Event

function InteractionService.Describe(npcId)
    local definition = NpcDefinitions[npcId]
    if not definition then
        return false, "unknown_npc"
    end
    return true,
        {
            NpcId = npcId,
            DisplayName = definition.DisplayName,
            QuestOffers = definition.QuestOffers,
            ShopId = definition.ShopId,
        }
end

function InteractionService.Begin(player, npcId, worldObject)
    local definition = NpcDefinitions[npcId]
    if not definition then
        return false, "unknown_npc"
    end

    local registered = WorldObjectService.Get(worldObject)
    if not registered or registered.Kind ~= "Npc" or registered.Id ~= npcId then
        return false, "invalid_world_object"
    end
    if not WorldObjectService.CanInteract(player, worldObject, 12) then
        return false, "too_far"
    end

    InteractionSessionService.Begin(player, npcId, definition.ShopId)
    local ok, description = InteractionService.Describe(npcId)
    if ok then
        openedEvent:Fire(player, description)
    end
    return ok, description
end

function InteractionService.StartOfferedQuest(profile, npcId, questId)
    local definition = NpcDefinitions[npcId]
    if not definition then
        return false, "unknown_npc"
    end
    local offered = false
    for _, offeredQuestId in definition.QuestOffers or {} do
        if offeredQuestId == questId then
            offered = true
            break
        end
    end
    if not offered then
        return false, "quest_not_offered"
    end
    return QuestService.Start(profile, questId)
end

return InteractionService
