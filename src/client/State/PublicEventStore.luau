local PublicEventStore = {}
local changed = Instance.new("BindableEvent")
local state = { Active = nil, Result = nil }

PublicEventStore.Changed = changed.Event

local function snapshot()
    return { Active = state.Active, Result = state.Result }
end

local function fire()
    changed:Fire(snapshot())
end

function PublicEventStore.Push(payload)
    if type(payload) ~= "table" then
        return
    end
    if payload.Type == "Started" or payload.Type == "Changed" then
        if type(payload.Event) ~= "table" then
            return
        end
        state.Active = table.clone(payload.Event)
        state.Active.LocalReceivedAt = os.clock()
        state.Result = nil
    elseif payload.Type == "Completed" or payload.Type == "Failed" then
        state.Active = nil
        state.Result = {
            Type = payload.Type,
            Event = payload.Event,
            Reason = payload.Reason,
            Reward = payload.Reward,
            ReceivedAt = os.clock(),
        }
    end
    fire()
end

function PublicEventStore.GetState()
    return snapshot()
end

return PublicEventStore
