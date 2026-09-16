local QuestService = require(script.Parent.QuestService)

local QuestObjectiveService = {}

local VALID_TYPES = table.freeze({
    Defeat = true,
    Collect = true,
    Explore = true,
    Interact = true,
    Craft = true,
    Use = true,
    Reach = true,
    Escort = true,
    Survive = true,
    PublicEvent = true,
})

function QuestObjectiveService.Record(profile, objectiveType, targetId, amount)
    if type(profile) ~= "table" then
        return false, {}
    end
    if type(objectiveType) ~= "string" or not VALID_TYPES[objectiveType] then
        return false, {}
    end
    if type(targetId) ~= "string" or targetId == "" then
        return false, {}
    end
    amount = amount or 1
    if type(amount) ~= "number" or amount <= 0 or amount ~= amount or amount == math.huge then
        return false, {}
    end
    return QuestService.Record(profile, objectiveType, targetId, amount)
end

function QuestObjectiveService.Supports(objectiveType)
    return VALID_TYPES[objectiveType] == true
end

return QuestObjectiveService
