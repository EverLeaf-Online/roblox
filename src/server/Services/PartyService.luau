local Players = game:GetService("Players")
local PartyService = {}
local partyByPlayer = {}
local invitations = {}
local nextId = 0
local event = Instance.new("BindableEvent")
PartyService.Event = event.Event

local function makeParty(leader)
    nextId += 1
    return { Id = nextId, Leader = leader, Members = { leader }, MaxMembers = 6 }
end

local function findPlayer(userId)
    if type(userId) ~= "number" then
        return nil
    end
    return Players:GetPlayerByUserId(userId)
end

function PartyService.Create(player)
    if partyByPlayer[player] then
        return false, "already_in_party"
    end
    local party = makeParty(player)
    partyByPlayer[player] = party
    return true, party
end

function PartyService.Get(player)
    return partyByPlayer[player]
end

function PartyService.Invite(leader, targetUserId)
    local party = partyByPlayer[leader]
    if not party or party.Leader ~= leader then
        return false, "not_party_leader"
    end
    local target = findPlayer(targetUserId)
    if not target or target == leader then
        return false, "invalid_target"
    end
    if partyByPlayer[target] then
        return false, "target_in_party"
    end
    invitations[target] = { Leader = leader, ExpiresAt = os.clock() + 30 }
    event:Fire(target, { Type = "Invite", FromUserId = leader.UserId, FromName = leader.Name })
    return true
end

function PartyService.Accept(player)
    local invite = invitations[player]
    if not invite or invite.ExpiresAt <= os.clock() then
        invitations[player] = nil
        return false, "no_invitation"
    end
    invitations[player] = nil
    local party = partyByPlayer[invite.Leader]
    if not party or party.Leader ~= invite.Leader then
        return false, "party_unavailable"
    end
    if #party.Members >= party.MaxMembers then
        return false, "party_full"
    end
    table.insert(party.Members, player)
    partyByPlayer[player] = party
    for _, member in party.Members do
        event:Fire(member, { Type = "Changed" })
    end
    return true
end

function PartyService.Decline(player)
    invitations[player] = nil
    return true
end

function PartyService.Kick(leader, targetUserId)
    local party = partyByPlayer[leader]
    if not party or party.Leader ~= leader then
        return false, "not_party_leader"
    end
    local target = findPlayer(targetUserId)
    if not target or target == leader or partyByPlayer[target] ~= party then
        return false, "invalid_target"
    end
    for index = #party.Members, 1, -1 do
        if party.Members[index] == target then
            table.remove(party.Members, index)
            break
        end
    end
    partyByPlayer[target] = nil
    event:Fire(target, { Type = "Kicked" })
    for _, member in party.Members do
        event:Fire(member, { Type = "Changed" })
    end
    return true
end

function PartyService.Leave(player)
    local party = partyByPlayer[player]
    if not party then
        return false, "not_in_party"
    end
    for index = #party.Members, 1, -1 do
        if party.Members[index] == player then
            table.remove(party.Members, index)
            break
        end
    end
    partyByPlayer[player] = nil
    if #party.Members > 0 and party.Leader == player then
        party.Leader = party.Members[1]
    end
    for _, member in party.Members do
        event:Fire(member, { Type = "Changed" })
    end
    return true
end

function PartyService.GetSnapshot(player)
    local party = partyByPlayer[player]
    if not party then
        return nil
    end
    local members = {}
    for _, member in party.Members do
        table.insert(members, { UserId = member.UserId, Name = member.Name })
    end
    return {
        Id = party.Id,
        LeaderUserId = party.Leader.UserId,
        Members = members,
        MaxMembers = party.MaxMembers,
    }
end

function PartyService.Init()
    Players.PlayerRemoving:Connect(function(player)
        invitations[player] = nil
        PartyService.Leave(player)
    end)
end

return PartyService
