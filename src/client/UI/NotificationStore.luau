local NotificationStore = {}

local changed = Instance.new("BindableEvent")
local nextId = 0

function NotificationStore.Push(kind, title, body, duration)
    nextId += 1
    local notification = {
        Id = nextId,
        Kind = kind or "info",
        Title = title or "EverLeaf",
        Body = body or "",
        Duration = math.clamp(tonumber(duration) or 3.5, 1.5, 8),
    }
    changed:Fire(notification)
    return notification.Id
end

function NotificationStore.Subscribe(callback)
    assert(type(callback) == "function", "Subscribe expects function")
    return changed.Event:Connect(callback)
end

return NotificationStore
