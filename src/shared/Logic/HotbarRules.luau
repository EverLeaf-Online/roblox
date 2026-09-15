local HotbarRules = {}

local SLOT_COUNT = 8

function HotbarRules.IsValidSlot(index)
    return type(index) == "number" and index % 1 == 0 and index >= 1 and index <= SLOT_COUNT
end

function HotbarRules.CanAssign(index, skillId, skillExists, skillKind, learnedRank)
    if not HotbarRules.IsValidSlot(index) then
        return false, "invalid_hotbar_slot"
    end
    if type(skillId) ~= "string" then
        return false, "invalid_skill_id"
    end
    if skillId == "" then
        return true
    end
    if not skillExists then
        return false, "unknown_skill"
    end
    if skillKind ~= "Active" then
        return false, "skill_not_active"
    end
    if (tonumber(learnedRank) or 0) <= 0 then
        return false, "skill_not_learned"
    end
    return true
end

function HotbarRules.Assign(hotbar, index, skillId)
    if
        type(hotbar) ~= "table"
        or not HotbarRules.IsValidSlot(index)
        or type(skillId) ~= "string"
    then
        return false
    end
    if skillId ~= "" then
        for slotIndex = 1, SLOT_COUNT do
            local key = tostring(slotIndex)
            if hotbar[key] == skillId then
                hotbar[key] = ""
            end
        end
    end
    hotbar[tostring(index)] = skillId
    return true
end

function HotbarRules.FindSkill(hotbar, skillId)
    if type(hotbar) ~= "table" or type(skillId) ~= "string" or skillId == "" then
        return nil
    end
    for slotIndex = 1, SLOT_COUNT do
        if hotbar[tostring(slotIndex)] == skillId then
            return slotIndex
        end
    end
    return nil
end

return table.freeze(HotbarRules)
