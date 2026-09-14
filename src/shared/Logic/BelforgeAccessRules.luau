local BelforgeAccessRules = {}

local REQUIRED_LEVEL = 30
local REQUIRED_QUEST = "belforge_gate_sentinel"

function BelforgeAccessRules.CanEnter(profile)
    if type(profile) ~= "table" then
        return false, "invalid_profile"
    end
    if (tonumber(profile.Level) or 1) < REQUIRED_LEVEL then
        return false, "level_too_low"
    end
    local quests = profile.Quests
    local completed = type(quests) == "table" and quests.Completed
    if type(completed) ~= "table" or completed[REQUIRED_QUEST] ~= true then
        return false, "sentinel_incomplete"
    end
    return true
end

return BelforgeAccessRules
