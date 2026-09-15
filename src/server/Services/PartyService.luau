local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartyReadyRules = require(ReplicatedStorage.Shared.Logic.PartyReadyRules)
local PartyRules = require(ReplicatedStorage.Shared.Logic.PartyRules)

local PartyService = {}
local partyByPlayer = {}
local invitations = {}
local readyChecks = {}
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

local function recognitionFor(player)
    if player:GetAttribute("EverLeafFounder") == true then
        return "FOUNDER"
    elseif player:GetAttribute("EverLeafMember") == true then
        return "MEMBER"
    end
    return nil
end

local function snapshotParty(party)
    if not party or not party.Leader then
        return nil
    end
    local members = {}
    for _, member in party.Members do
        if member.Parent == Players then
            table.insert(members, {
                UserId = member.UserId,
                Name = member.Name,
                DisplayName = member.DisplayName,
                Recognition = recognitionFor(member),
            })
        end
    end
    return {
        Id = party.Id,
        LeaderUserId = party.Leader.UserId,
        Members = members,
        MaxMembers = party.MaxMembers,
    }
end

local function readySnapshot(party, check)
    local members = {}
    for _, member in party.Members do
        if member.Parent == Players then
            table.insert(members, {
                UserId = member.UserId,
                Name = member.Name,
                DisplayName = member.DisplayName,
                Recognition = recognitionFor(member),
                Ready = check.Responses[member.UserId] == true,
            })
        end
    end
    return {
        Purpose = check.Purpose,
        LeaderUserId = party.Leader.UserId,
        LeaderName = party.Leader.Name,
        Members = members,
        Duration = math.max(0, check.ExpiresAt - os.clock()),
    }
end

local function fireReadyCheck(party, check)
    local snapshot = readySnapshot(party, check)
    for _, member in party.Members do
        if member.Parent == Players then
            event:Fire(member, { Type = "ReadyCheck", ReadyCheck = snapshot })
        end
    end
end

local function notifyReadyOutcome(party, eventType, reason)
    for _, member in party.Members do
        if member.Parent == Players then
            event:Fire(member, { Type = eventType, Reason = reason })
        end
    end
end

local function clearReadyCheck(party, reason)
    local check = readyChecks[party]
    if not check then
        return false
    end
    readyChecks[party] = nil
    notifyReadyOutcome(party, "ReadyCheckCleared", reason)
    return true
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
    clearReadyCheck(party, "party_changed")
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
    clearReadyCheck(party, "party_changed")
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
    clearReadyCheck(party, "party_changed")
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

function PartyService.StartReadyCheck(leader, purpose, duration)
    local party = partyByPlayer[leader]
    local allowed, reason = PartyReadyRules.CanStart(
        party ~= nil and party.Leader == leader,
        party and #party.Members or 0,
        party and party.MaxMembers or 6,
        party ~= nil and readyChecks[party] ~= nil
    )
    if not allowed then
        return false, reason
    end

    duration = math.clamp(tonumber(duration) or 20, 5, 60)
    local check = {
        Purpose = tostring(purpose or "party"),
        ExpiresAt = os.clock() + duration,
        Responses = { [leader.UserId] = true },
    }
    readyChecks[party] = check
    fireReadyCheck(party, check)

    task.delay(duration, function()
        if readyChecks[party] == check then
            readyChecks[party] = nil
            notifyReadyOutcome(party, "ReadyCheckCleared", "expired")
        end
    end)
    return true, readySnapshot(party, check)
end

function PartyService.RespondReadyCheck(player, accepted)
    local party = partyByPlayer[player]
    local check = party and readyChecks[party] or nil
    local allowed, reason = PartyReadyRules.CanRespond(
        party ~= nil,
        check ~= nil,
        check ~= nil and check.ExpiresAt <= os.clock()
    )
    if not allowed then
        if party and check and check.ExpiresAt <= os.clock() then
            readyChecks[party] = nil
            notifyReadyOutcome(party, "ReadyCheckCleared", "expired")
        end
        return false, reason
    end
    if type(accepted) ~= "boolean" then
        return false, "invalid_response"
    end
    if not accepted then
        readyChecks[party] = nil
        notifyReadyOutcome(party, "ReadyCheckCleared", "declined")
        return true, { Complete = false, Declined = true, Purpose = check.Purpose }
    end

    check.Responses[player.UserId] = true
    local memberIds = {}
    for _, member in party.Members do
        table.insert(memberIds, member.UserId)
    end
    if PartyReadyRules.AllReady(memberIds, check.Responses) then
        readyChecks[party] = nil
        local members = table.clone(party.Members)
        return true, { Complete = true, Purpose = check.Purpose, Party = party, Members = members }
    end

    fireReadyCheck(party, check)
    return true, { Complete = false, Purpose = check.Purpose }
end

function PartyService.NotifyReadyCheckOutcome(party, completed, reason)
    if not party then
        return false
    end
    notifyReadyOutcome(party, completed and "ReadyCheckComplete" or "ReadyCheckCleared", reason)
    return true
end

function PartyService.GetReadyCheck(player)
    local party = partyByPlayer[player]
    local check = party and readyChecks[party] or nil
    return check and readySnapshot(party, check) or nil
end

function PartyService.GetSnapshot(player)
    return snapshotParty(partyByPlayer[player])
end

function PartyService.RefreshPresentation(player)
    local party = partyByPlayer[player]
    if not party then
        return false
    end
    fireChanged(party)
    local check = readyChecks[party]
    if check then
        fireReadyCheck(party, check)
    end
    return true
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
