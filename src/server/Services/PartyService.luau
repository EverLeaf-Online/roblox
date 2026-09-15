local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartyRules = require(ReplicatedStorage.Shared.Logic.PartyRules)

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

local function snapshotParty(party)
    if not party or not party.Leader then
        return nil
    end
    local members = {}
    for _, member in party.Members do
        if member.Parent == Players then
            table.insert(members, { UserId = member.UserId, Name = member.Name })
        end
    end
    return {
        Id = party.Id,
        LeaderUserId = party.Leader.UserId,
        Members = members,
        MaxMembers = party.MaxMembers,
    }
end

local function fireChanged(party)
    local snapshot = snapshotParty(party)
    if not snapshot then
        return
    end
    for _, member in party.Members do
        if member.Parent == Players then
            event:Fire(member, { Type = "Changed", Party = snapshot })
        end
    end
end

local function clearInvitesFromLeader(leader)
    for target, invite in invitations do
        if invite.Leader == leader then
            invitations[target] = nil
            if target.Parent == Players then
                event:Fire(target, { Type = "InviteCleared" })
            end
        end
    end
end

function PartyService.Create(player)
    if partyByPlayer[player] then
        return false, "already_in_party"
    end
    invitations[player] = nil
    local party = makeParty(player)
    partyByPlayer[player] = party
    fireChanged(party)
    return true, party
end

function PartyService.Get(player)
    return partyByPlayer[player]
end

function PartyService.Invite(leader, targetUserId)
    local party = partyByPlayer[leader]
    local target = findPlayer(targetUserId)
    local allowed, reason = PartyRules.CanInvite(
        party ~= nil and party.Leader == leader,
        party and #party.Members or 0,
        party and party.MaxMembers or 6,
        target ~= nil,
        target == leader,
        target ~= nil and partyByPlayer[target] ~= nil
    )
    if not allowed then
        return false, reason
    end

    invitations[target] = { Leader = leader, ExpiresAt = os.clock() + 30 }
    event:Fire(target, {
        Type = "Invite",
        FromUserId = leader.UserId,
        FromName = leader.Name,
        Duration = 30,
    })
    return true
end

function PartyService.Accept(player)
    local invite = invitations[player]
    local party = invite and partyByPlayer[invite.Leader] or nil
    local allowed, reason = PartyRules.CanAccept(
        partyByPlayer[player] ~= nil,
        invite ~= nil,
        invite ~= nil and invite.ExpiresAt <= os.clock(),
        party ~= nil and party.Leader == invite.Leader,
        party ~= nil and #party.Members >= party.MaxMembers
    )
    if not allowed then
        invitations[player] = nil
        event:Fire(player, { Type = "InviteCleared" })
        return false, reason
    end

    invitations[player] = nil
    table.insert(party.Members, player)
    partyByPlayer[player] = party
    fireChanged(party)
    return true, snapshotParty(party)
end

function PartyService.Decline(player)
    invitations[player] = nil
    event:Fire(player, { Type = "InviteCleared" })
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
    event:Fire(target, { Type = "Kicked", Party = nil })
    fireChanged(party)
    return true, snapshotParty(party)
end

function PartyService.Leave(player)
    local party = partyByPlayer[player]
    if not party then
        return false, "not_in_party"
    end
    local wasLeader = party.Leader == player
    for index = #party.Members, 1, -1 do
        if party.Members[index] == player then
            table.remove(party.Members, index)
            break
        end
    end
    partyByPlayer[player] = nil
    event:Fire(player, { Type = "Left", Party = nil })

    if wasLeader then
        clearInvitesFromLeader(player)
    end
    if #party.Members > 0 then
        if wasLeader then
            party.Leader = party.Members[1]
        end
        fireChanged(party)
    end
    return true
end

function PartyService.GetSnapshot(player)
    return snapshotParty(partyByPlayer[player])
end

function PartyService.Init()
    Players.PlayerRemoving:Connect(function(player)
        invitations[player] = nil
        if partyByPlayer[player] then
            PartyService.Leave(player)
        end
    end)
end

return PartyService
