local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local StatusEffectDefinitions = require(ReplicatedStorage.Shared.StatusEffectDefinitions)
local StatusEffectRules = require(ReplicatedStorage.Shared.Logic.StatusEffectRules)

local StatusEffectService = {}
local effectsByPlayer = {}
local accumulator = 0
local changedEvent = Instance.new("BindableEvent")
StatusEffectService.Changed = changedEvent.Event

local MAXIMUM_STATUS_DURATION = 3600

function StatusEffectService.Apply(player, effectId, durationSeconds, payload)
    if not player or player.Parent ~= Players then
        return false, "invalid_player"
    end
    local valid, reason = StatusEffectRules.ValidateApply(
        effectId,
        durationSeconds,
        StatusEffectDefinitions,
        MAXIMUM_STATUS_DURATION
    )
    if not valid then
        return false, reason
    end
    if payload ~= nil and type(payload) ~= "table" then
        return false, "invalid_payload"
    end

    local effects = effectsByPlayer[player]
    if not effects then
        effects = {}
        effectsByPlayer[player] = effects
    end
    local now = os.clock()
    local current = effects[effectId]
    local expiresAt =
        StatusEffectRules.ResolveExpiry(now, current and current.ExpiresAt or nil, durationSeconds)
    effects[effectId] = { ExpiresAt = expiresAt, Payload = payload or {} }
    changedEvent:Fire(player)
    return true
end

function StatusEffectService.Remove(player, effectId)
    local effects = effectsByPlayer[player]
    if effects and effects[effectId] ~= nil then
        effects[effectId] = nil
        if next(effects) == nil then
            effectsByPlayer[player] = nil
        end
        changedEvent:Fire(player)
        return true
    end
    return false
end

function StatusEffectService.Clear(player)
    if effectsByPlayer[player] ~= nil then
        effectsByPlayer[player] = nil
        changedEvent:Fire(player)
        return true
    end
    return false
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
        if accumulator < 0.25 then
            return
        end
        accumulator = 0
        local now = os.clock()
        for player, effects in effectsByPlayer do
            local changed = false
            for effectId, state in effects do
                if state.ExpiresAt <= now then
                    effects[effectId] = nil
                    changed = true
                end
            end
            if next(effects) == nil then
                effectsByPlayer[player] = nil
            end
            if changed and player.Parent == Players then
                changedEvent:Fire(player)
            end
        end
    end)
end

return StatusEffectService
