local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ProjectileMath = require(ReplicatedStorage.Shared.Math.ProjectileMath)
local EnemyService = require(script.Parent.EnemyService)

local ProjectileService = {}

local function enemyFromPart(part)
    local current = part
    while current and current ~= Workspace do
        if current:IsA("Model") and EnemyService.IsValidTarget(current) then
            return current
        end
        current = current.Parent
    end
    return nil
end

local function raycastParams(attackerCharacter)
    local excluded = { attackerCharacter }
    for _, player in Players:GetPlayers() do
        local character = player.Character
        if character and character ~= attackerCharacter then
            table.insert(excluded, character)
        end
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = excluded
    params.IgnoreWater = false
    return params
end

function ProjectileService.TraceToTarget(player, target, spec)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local targetRoot = target and (target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart)
    if not character or not root or not root:IsA("BasePart") or not targetRoot then
        return nil, "projectile_unavailable"
    end

    local range = math.max(1, tonumber(spec.Range) or 1)
    local speed =
        math.max(1, tonumber(spec.ProjectileSpeed) or GameConfig.Combat.BasicProjectileSpeed)
    local radius =
        math.max(0, tonumber(spec.ProjectileRadius) or GameConfig.Combat.BasicProjectileRadius)
    local origin = root.Position + Vector3.new(0, 1.35, 0) + root.CFrame.LookVector * 1.2
    local aimPosition = targetRoot.Position + Vector3.new(0, 0.8, 0)
    local initialDelta = aimPosition - origin
    if initialDelta.Magnitude <= 0.01 then
        return target, nil, aimPosition
    end

    local direction = initialDelta.Unit
    local traveled = 0
    local position = origin
    local params = raycastParams(character)
    local maxLifetime = ProjectileMath.TravelTime(range, speed) + 0.3
    local startedAt = os.clock()
    local steps = 0

    while traveled < range and os.clock() - startedAt <= maxLifetime do
        if not character.Parent or not root.Parent then
            return nil, "projectile_cancelled", position
        end
        if not target.Parent or not EnemyService.IsValidTarget(target) then
            return nil, "projectile_target_lost", position
        end

        local deltaTime = RunService.Heartbeat:Wait()
        local remaining = range - traveled
        local stepLength = ProjectileMath.StepLength(speed, deltaTime, remaining)
        if stepLength <= 0 then
            continue
        end
        steps += 1
        if steps > (GameConfig.Combat.ProjectileStepCap or 60) then
            return nil, "projectile_timeout", position
        end

        local castVector = direction * stepLength
        local hit = if radius > 0 and Workspace.Spherecast
            then Workspace:Spherecast(position, radius, castVector, params)
            else Workspace:Raycast(position, castVector, params)

        if hit then
            local enemy = enemyFromPart(hit.Instance)
            if enemy then
                return enemy, nil, hit.Position
            end
            return nil, "projectile_blocked", hit.Position
        end

        position += castVector
        traveled += stepLength
    end

    return nil, "projectile_missed", position
end

return ProjectileService
