local PartyStore = {}
local changed = Instance.new("BindableEvent")
local latestEvent = nil

PartyStore.Changed = changed.Event

function PartyStore.Push(eventData)
    latestEvent = eventData
    changed:Fire(eventData)
end

function PartyStore.GetLatestEvent()
    return latestEvent
end

return PartyStore
