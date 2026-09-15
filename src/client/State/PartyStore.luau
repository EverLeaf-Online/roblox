local PartyStore = {}
local changed = Instance.new("BindableEvent")
local state = { Party = nil, Invite = nil, ReadyCheck = nil, ReadyResult = nil }
local inviteGeneration = 0
local readyGeneration = 0

PartyStore.Changed = changed.Event

local function snapshot()
    return {
        Party = state.Party,
        Invite = state.Invite,
        ReadyCheck = state.ReadyCheck,
        ReadyResult = state.ReadyResult,
    }
end

local function fire()
    changed:Fire(snapshot())
end

function PartyStore.Seed(party)
    state.Party = party
    fire()
end

function PartyStore.Push(eventData)
    if type(eventData) ~= "table" then
        return
    end
    if eventData.Type == "Changed" then
        inviteGeneration += 1
        state.Party = eventData.Party
        state.Invite = nil
    elseif eventData.Type == "Invite" then
        inviteGeneration += 1
        local generation = inviteGeneration
        local duration = math.max(1, tonumber(eventData.Duration) or 30)
        state.Invite = {
            FromUserId = eventData.FromUserId,
            FromName = eventData.FromName,
            ExpiresAt = os.clock() + duration,
        }
        task.delay(duration, function()
            if inviteGeneration == generation and state.Invite then
                state.Invite = nil
                fire()
            end
        end)
    elseif eventData.Type == "InviteCleared" then
        inviteGeneration += 1
        state.Invite = nil
    elseif eventData.Type == "ReadyCheck" and type(eventData.ReadyCheck) == "table" then
        readyGeneration += 1
        local generation = readyGeneration
        local duration = math.max(1, tonumber(eventData.ReadyCheck.Duration) or 20)
        state.ReadyCheck = table.clone(eventData.ReadyCheck)
        state.ReadyCheck.ExpiresAt = os.clock() + duration
        state.ReadyResult = nil
        task.delay(duration, function()
            if readyGeneration == generation and state.ReadyCheck then
                state.ReadyCheck = nil
                state.ReadyResult =
                    { Type = "Cleared", Reason = "expired", Generation = generation }
                fire()
            end
        end)
    elseif eventData.Type == "ReadyCheckComplete" then
        readyGeneration += 1
        state.ReadyCheck = nil
        state.ReadyResult = {
            Type = "Complete",
            Reason = eventData.Reason,
            Generation = readyGeneration,
        }
    elseif eventData.Type == "ReadyCheckCleared" then
        readyGeneration += 1
        state.ReadyCheck = nil
        state.ReadyResult = {
            Type = "Cleared",
            Reason = eventData.Reason,
            Generation = readyGeneration,
        }
    elseif eventData.Type == "Kicked" or eventData.Type == "Left" then
        inviteGeneration += 1
        readyGeneration += 1
        state.Party = nil
        state.Invite = nil
        state.ReadyCheck = nil
        state.ReadyResult = nil
    end
    fire()
end

function PartyStore.GetState()
    if state.Invite and state.Invite.ExpiresAt <= os.clock() then
        state.Invite = nil
    end
    if state.ReadyCheck and state.ReadyCheck.ExpiresAt <= os.clock() then
        readyGeneration += 1
        state.ReadyCheck = nil
        state.ReadyResult = { Type = "Cleared", Reason = "expired", Generation = readyGeneration }
    end
    return snapshot()
end

return PartyStore
