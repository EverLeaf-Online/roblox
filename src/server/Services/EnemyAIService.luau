local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PlayerDamageService = require(script.Parent.PlayerDamageService)

local EnemyAIService = {}
local controllers = {}
local accumulator = 0

local function nearestPlayer(root, range)
    local winner = nil
    local best = range
    for _, player in Players:GetPlayers() do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
        if humanoid and humanoid.Health > 0 and playerRoot then
            local distance = (playerRoot.Position - root.Position).Magnitude
            if distance <= best then
                winner = player
                best = distance
            end
        end
    end
    return winner, best
end

function EnemyAIService.Attach(enemy, aiDefinition)
    if typeof(enemy) ~= "Instance" or not enemy:IsA("Model") or type(aiDefinition) ~= "table" then
        return false, "invalid_ai"
    end
    controllers[enemy] =
        { Definition = aiDefinition, Target = nil, State = "Idle", NextAttackAt = 0 }
    enemy.Destroying:Once(function()
        controllers[enemy] = nil
    end)
    return true
end

function EnemyAIService.Detach(enemy)
    controllers[enemy] = nil
end

function EnemyAIService.GetState(enemy)
    local state = controllers[enemy]
    return state and state.State or nil
end

function EnemyAIService.Init()
    RunService.Heartbeat:Connect(function(deltaTime)
        accumulator += deltaTime
        if accumulator < 0.1 then
            return
        end
        accumulator = 0
        for enemy, state in controllers do
            local root = enemy:FindFirstChild("HumanoidRootPart")
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            if not root or not humanoid or humanoid.Health <= 0 then
                controllers[enemy] = nil
                continue
            end
            local def = state.Definition
            local target, distance = nearestPlayer(root, def.AggroRange or 20)
            state.Target = target
            if not target then
                state.State = "Idle"
                continue
            end
            local targetRoot = target.Character
                and target.Character:FindFirstChild("HumanoidRootPart")
            if distance <= (def.AttackRange or 4) then
                state.State = "Attack"
                if os.clock() >= state.NextAttackAt then
                    state.NextAttackAt = os.clock() + (def.AttackCooldown or 1.5)
                    PlayerDamageService.Apply(
                        target,
                        def.Damage or 5,
                        enemy:GetAttribute("EnemyId")
                    )
                end
            elseif targetRoot then
                state.State = "Pursue"
                humanoid:MoveTo(
                    Vector3.new(targetRoot.Position.X, root.Position.Y, root.Position.Z)
                )
            end
        end
    end)
end

return EnemyAIService
