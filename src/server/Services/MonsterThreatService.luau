local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ThreatRules = require(ReplicatedStorage.Shared.Logic.ThreatRules)

local MonsterThreatService = {}
local states = {}

local function validPlayerTarget(player, origin, range)
    if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
        return nil
    end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root then
        return nil
    end
    local distance = (root.Position - origin).Magnitude
    if distance > range then
        return nil
    end
    return distance
end

local function getState(monster)
    local state = states[monster]
    if not state then
        state = {}
        states[monster] = state
    end
    return state
end

function MonsterThreatService.Add(monster, player, amount)
    if typeof(monster) ~= "Instance" or not monster:IsA("Model") or not monster.Parent then
        return false
    end
    if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
        return false
    end
    local state = getState(monster)
    state[player] = ThreatRules.Add(state[player], amount)
    return true
end

function MonsterThreatService.Clear(monster)
    states[monster] = nil
end

function MonsterThreatService.Get(monster, player)
    local state = states[monster]
    return state and (tonumber(state[player]) or 0) or 0
end

function MonsterThreatService.SelectTarget(monster, currentTarget, origin, range)
    if typeof(origin) ~= "Vector3" then
        return nil
    end
    range = math.max(0, tonumber(range) or 0)
    if range <= 0 then
        return nil
    end

    local state = states[monster]
    local currentDistance = currentTarget and validPlayerTarget(currentTarget, origin, range) or nil
    local currentThreat = currentTarget and MonsterThreatService.Get(monster, currentTarget) or 0
    local bestPlayer = nil
    local bestThreat = 0
    local bestDistance = math.huge

    if state then
        for player, threat in state do
            if player.Parent ~= Players then
                state[player] = nil
                continue
            end
            local distance = validPlayerTarget(player, origin, range)
            if distance then
                threat = math.max(0, tonumber(threat) or 0)
                if threat > bestThreat or threat == bestThreat and distance < bestDistance then
                    bestPlayer = player
                    bestThreat = threat
                    bestDistance = distance
                end
            end
        end
        if next(state) == nil then
            states[monster] = nil
        end
    end

    if currentDistance then
        if
            bestPlayer
            and bestPlayer ~= currentTarget
            and ThreatRules.ShouldSwitch(
                currentThreat,
                bestThreat,
                GameConfig.Combat.ThreatSwitchRatio
            )
        then
            return bestPlayer, bestDistance
        end
        return currentTarget, currentDistance
    end

    if bestPlayer then
        return bestPlayer, bestDistance
    end
    return nil
end

Players.PlayerRemoving:Connect(function(player)
    for monster, state in states do
        state[player] = nil
        if next(state) == nil then
            states[monster] = nil
        end
    end
end)

return MonsterThreatService
