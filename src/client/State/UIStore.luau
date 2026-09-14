local UIStore = {}
local changedEvent = Instance.new("BindableEvent")
local openScreens = {}

UIStore.Changed = changedEvent.Event

function UIStore.Open(screenId, payload)
    openScreens[screenId] = payload or true
    changedEvent:Fire(screenId, true, payload)
end

function UIStore.Close(screenId)
    if openScreens[screenId] == nil then
        return
    end
    openScreens[screenId] = nil
    changedEvent:Fire(screenId, false)
end

function UIStore.IsOpen(screenId)
    return openScreens[screenId] ~= nil
end

function UIStore.GetPayload(screenId)
    return openScreens[screenId]
end

return UIStore
