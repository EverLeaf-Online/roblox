local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local StatusEffectService = {}
local effectsByPlayer = {}
local accumulator = 0

function StatusEffectService.Apply(player, effectId, durationSeconds, payload)
    if type(effectId) ~= "string" or effectId == "" then
        return false, "invalid_effect"
    end
    if type(durationSeconds) ~= "number" or durationSeconds <= 0 then
        return false, "invalid_duration"
    end
    local effects = effectsByPlayer[player]
    if not effects then
        effects = {}
        effectsByPlayer[player] = effects
    end
    effects[effectId] = { ExpiresAt = os.clock() + durationSeconds, Payload = payload or {} }
    return true
end

function StatusEffectService.Remove(player, effectId)
    local effects = effectsByPlayer[player]
    if effects then
        effects[effectId] = nil
    end
end

function StatusEffectService.GetSnapshot(player)
    local result = {}
    local effects = effectsByPlayer[player] or {}
    local now = os.clock()
    for effectId, state in effects do
        if state.ExpiresAt > now then
            result[effectId] = math.max(0, state.ExpiresAt - now)
        end
    end
    return result
end

function StatusEffectService.Init()
    Players.PlayerRemoving:Connect(function(player)
        effectsByPlayer[player] = nil
    end)
    RunService.Heartbeat:Connect(function(deltaTime)
        accumulator += deltaTime
        if accumulator < 0.5 then
            return
        end
        accumulator = 0
        local now = os.clock()
        for _, effects in effectsByPlayer do
            for effectId, state in effects do
                if state.ExpiresAt <= now then
                    effects[effectId] = nil
                end
            end
        end
    end)
end

return StatusEffectService
