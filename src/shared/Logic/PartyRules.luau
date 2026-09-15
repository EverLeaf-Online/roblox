local PartyRules = {}

function PartyRules.CanAccept(alreadyInParty, hasInvite, inviteExpired, partyAvailable, partyFull)
    if alreadyInParty then
        return false, "already_in_party"
    end
    if not hasInvite or inviteExpired then
        return false, "no_invitation"
    end
    if not partyAvailable then
        return false, "party_unavailable"
    end
    if partyFull then
        return false, "party_full"
    end
    return true
end

function PartyRules.CanInvite(
    isLeader,
    memberCount,
    maxMembers,
    targetExists,
    targetIsSelf,
    targetInParty
)
    if not isLeader then
        return false, "not_party_leader"
    end
    if not targetExists or targetIsSelf then
        return false, "invalid_target"
    end
    if targetInParty then
        return false, "target_in_party"
    end
    memberCount = math.max(0, tonumber(memberCount) or 0)
    maxMembers = math.max(1, tonumber(maxMembers) or 1)
    if memberCount >= maxMembers then
        return false, "party_full"
    end
    return true
end

return table.freeze(PartyRules)
