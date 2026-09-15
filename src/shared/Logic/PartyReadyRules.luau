local PartyReadyRules = {}

function PartyReadyRules.CanStart(isLeader, memberCount, maxMembers, hasActiveCheck)
    if not isLeader then
        return false, "not_party_leader"
    end
    memberCount = math.max(0, tonumber(memberCount) or 0)
    maxMembers = math.max(1, tonumber(maxMembers) or 1)
    if memberCount < 2 then
        return false, "party_too_small"
    end
    if memberCount > maxMembers then
        return false, "party_full"
    end
    if hasActiveCheck then
        return false, "ready_check_active"
    end
    return true
end

function PartyReadyRules.CanRespond(isMember, hasCheck, expired)
    if not isMember then
        return false, "not_in_party"
    end
    if not hasCheck or expired then
        return false, "no_ready_check"
    end
    return true
end

function PartyReadyRules.AllReady(memberIds, responses)
    if type(memberIds) ~= "table" or #memberIds == 0 then
        return false
    end
    for _, memberId in memberIds do
        if responses[memberId] ~= true then
            return false
        end
    end
    return true
end

return table.freeze(PartyReadyRules)
