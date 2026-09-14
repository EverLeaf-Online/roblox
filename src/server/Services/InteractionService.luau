local ItemDefinitions = require(script.Parent.Parent.Content.ItemDefinitions)
local NpcDefinitions = require(script.Parent.Parent.Content.NpcDefinitions)
local QuestDefinitions = require(script.Parent.Parent.Content.QuestDefinitions)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestAccessRules = require(ReplicatedStorage.Shared.Logic.QuestAccessRules)
local ShopDefinitions = require(script.Parent.Parent.Content.ShopDefinitions)
local InteractionSessionService = require(script.Parent.InteractionSessionService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local QuestService = require(script.Parent.QuestService)
local WorldObjectService = require(script.Parent.WorldObjectService)

local InteractionService = {}
local openedEvent = Instance.new("BindableEvent")

InteractionService.Opened = openedEvent.Event

local function prerequisitesMet(profile, definition)
    if not profile then
        return true
    end
    return QuestAccessRules.CanStart(profile, definition)
end

local function visibleQuestOffers(definition, profile)
    local result = {}
    for _, questId in definition.QuestOffers or {} do
        local quest = QuestDefinitions[questId]
        if quest then
            local active = profile and profile.Quests.Active[questId] ~= nil
            local completed = profile and profile.Quests.Completed[questId] == true
            if active or (not completed and prerequisitesMet(profile, quest)) then
                table.insert(result, questId)
            end
        end
    end
    return result
end

local function chooseDialogue(definition, profile)
    local dialogue = definition.Dialogue or {}
    if #dialogue == 0 then
        return "The trails are open. Stay alert out there."
    end
    if not profile then
        return dialogue[1]
    end

    if definition.AdvancementMentor and type(definition.AdvancementQuestId) == "string" then
        local questId = definition.AdvancementQuestId
        if profile.Quests.Completed[questId] == true then
            return dialogue[#dialogue]
        end
        if profile.Quests.Active[questId] ~= nil and #dialogue >= 2 then
            return dialogue[2]
        end
    end

    local completedCount = 0
    for _, questId in definition.QuestOffers or {} do
        if profile.Quests.Completed[questId] == true then
            completedCount += 1
        end
    end
    local index = math.clamp(completedCount + 1, 1, #dialogue)
    return dialogue[index]
end

function InteractionService.Describe(npcId, profile)
    local definition = NpcDefinitions[npcId]
    if not definition then
        return false, "unknown_npc"
    end

    local description = {
        NpcId = npcId,
        DisplayName = definition.DisplayName,
        DialogueText = chooseDialogue(definition, profile),
        QuestOffers = visibleQuestOffers(definition, profile),
        ShopId = definition.ShopId,
        AdvancementMentor = definition.AdvancementMentor == true,
    }

    local shop = definition.ShopId and ShopDefinitions[definition.ShopId]
    if shop then
        description.ShopDisplayName = shop.DisplayName
        description.ShopCurrency = shop.Currency
        description.ShopItems = {}
        for itemId, price in shop.Items do
            local item = ItemDefinitions[itemId]
            table.insert(description.ShopItems, {
                ItemId = itemId,
                DisplayName = item and item.DisplayName or itemId,
                Price = price,
            })
        end
        table.sort(description.ShopItems, function(a, b)
            return a.DisplayName < b.DisplayName
        end)
    end

    return true, description
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
    local ok, description = InteractionService.Describe(npcId, PlayerDataService.Get(player))
    if ok then
        openedEvent:Fire(player, description)
    end
    return ok, description
end

local function npcOffersQuest(npcId, questId)
    local definition = NpcDefinitions[npcId]
    if not definition then
        return false
    end
    for _, offeredQuestId in definition.QuestOffers or {} do
        if offeredQuestId == questId then
            return true
        end
    end
    return false
end

function InteractionService.IsAdvancementMentor(npcId)
    local definition = NpcDefinitions[npcId]
    return definition ~= nil and definition.AdvancementMentor == true
end

function InteractionService.StartOfferedQuest(profile, npcId, questId)
    local definition = NpcDefinitions[npcId]
    if not definition then
        return false, "unknown_npc"
    end
    if not npcOffersQuest(npcId, questId) then
        return false, "quest_not_offered"
    end
    return QuestService.Start(profile, questId)
end

function InteractionService.TurnInOfferedQuest(profile, npcId, questId)
    if not npcOffersQuest(npcId, questId) then
        return false, "quest_not_offered"
    end
    return QuestService.TurnIn(profile, questId)
end

return InteractionService
