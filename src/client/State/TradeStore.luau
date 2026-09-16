local TradeStore = {}
local changed = Instance.new("BindableEvent")
local state = { Request = nil, Sent = nil, Trade = nil, Result = nil }
local requestGeneration = 0

TradeStore.Changed = changed.Event

local function snapshot()
    return {
        Request = state.Request,
        Sent = state.Sent,
        Trade = state.Trade,
        Result = state.Result,
    }
end

local function fire()
    changed:Fire(snapshot())
end

function TradeStore.Push(payload)
    if type(payload) ~= "table" then
        return
    end
    if payload.Type == "Request" then
        requestGeneration += 1
        local generation = requestGeneration
        state.Request = {
            FromUserId = payload.FromUserId,
            FromName = payload.FromName,
            FromDisplayName = payload.FromDisplayName,
            ExpiresAt = os.clock() + math.max(1, tonumber(payload.Duration) or 30),
        }
        state.Sent = nil
        state.Result = nil
        task.delay(math.max(1, tonumber(payload.Duration) or 30), function()
            if requestGeneration == generation and state.Request then
                state.Request = nil
                fire()
            end
        end)
    elseif payload.Type == "RequestSent" then
        state.Sent = { TargetUserId = payload.TargetUserId, TargetName = payload.TargetName }
        state.Result = nil
    elseif payload.Type == "RequestCleared" then
        requestGeneration += 1
        state.Request = nil
        state.Sent = nil
    elseif payload.Type == "Changed" then
        requestGeneration += 1
        state.Request = nil
        state.Sent = nil
        state.Trade = payload.Trade
        state.Result = nil
    elseif payload.Type == "Completed" then
        requestGeneration += 1
        state.Request = nil
        state.Sent = nil
        state.Trade = nil
        state.Result = { Type = "Completed", Reason = payload.Reason }
    elseif payload.Type == "Cancelled" then
        requestGeneration += 1
        state.Request = nil
        state.Sent = nil
        state.Trade = nil
        state.Result = { Type = "Cancelled", Reason = payload.Reason }
    end
    fire()
end

function TradeStore.GetState()
    if state.Request and state.Request.ExpiresAt <= os.clock() then
        requestGeneration += 1
        state.Request = nil
    end
    return snapshot()
end

return TradeStore
