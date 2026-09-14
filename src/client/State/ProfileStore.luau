local ProfileStore = {}

local current = nil
local changed = Instance.new("BindableEvent")

function ProfileStore.Set(snapshot)
    current = snapshot
    changed:Fire(snapshot)
end

function ProfileStore.Get()
    return current
end

function ProfileStore.Subscribe(callback)
    assert(type(callback) == "function", "Subscribe expects function")
    local connection = changed.Event:Connect(callback)
    if current then
        task.defer(callback, current)
    end
    return connection
end

return ProfileStore
