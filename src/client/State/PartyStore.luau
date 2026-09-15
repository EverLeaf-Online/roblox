local PartyStore = {}
local changed = Instance.new("BindableEvent")
local state = { Party = nil, Invite = nil }
local inviteGeneration = 0

PartyStore.Changed = changed.Event

local function snapshot()
    return { Party = state.Party, Invite = state.Invite }
end

function PartyStore.Seed(party)
    state.Party = party
    changed:Fire(snapshot())
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
                changed:Fire(snapshot())
            end
        end)
    elseif eventData.Type == "InviteCleared" then
        inviteGeneration += 1
        state.Invite = nil
    elseif eventData.Type == "Kicked" or eventData.Type == "Left" then
        inviteGeneration += 1
        state.Party = nil
        state.Invite = nil
    end
    changed:Fire(snapshot())
end

function PartyStore.GetState()
    if state.Invite and state.Invite.ExpiresAt <= os.clock() then
        state.Invite = nil
    end
    return snapshot()
end

return PartyStore
