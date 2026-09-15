local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CombatHitboxMath = require(ReplicatedStorage.Shared.Math.CombatHitboxMath)
local EnemyService = require(script.Parent.EnemyService)
local TargetingService = require(script.Parent.TargetingService)

local CombatHitboxService = {}

local function resolveEnemyModel(part)
    local current = part
    while current and current ~= Workspace do
        if current:IsA("Model") and EnemyService.IsValidTarget(current) then
            return current
        end
        current = current.Parent
    end
    return nil
end

local function queryCandidates(player, spec)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not root or not root:IsA("BasePart") then
        return {}, nil
    end

    local range = math.max(1, tonumber(spec.Range) or 8)
    local width = math.max(1, tonumber(spec.HitboxWidth) or 6)
    local verticalRange = math.max(1, tonumber(spec.VerticalRange) or 6)
    local center = root.CFrame * CFrame.new(0, 0, -(range * 0.5))
    local sizeX, sizeY, sizeZ = CombatHitboxMath.BoxSize(range, width, verticalRange)

    local activeEnemies = EnemyService.GetActiveEnemies()
    if #activeEnemies == 0 then
        return {}, root
    end

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = activeEnemies
    params.MaxParts = 192

    local candidates = {}
    local seen = {}
    for _, part in Workspace:GetPartBoundsInBox(center, Vector3.new(sizeX, sizeY, sizeZ), params) do
        local enemy = resolveEnemyModel(part)
        if enemy and not seen[enemy] then
            seen[enemy] = true
            table.insert(candidates, enemy)
        end
    end
    return candidates, root
end

function CombatHitboxService.FindMeleeTargets(player, spec)
    local candidates = queryCandidates(player, spec)
    if #candidates == 0 then
        return {}
    end
    return TargetingService.FindEnemiesFromCandidates(player, candidates, {
        Range = math.max(1, tonumber(spec.Range) or 8),
        VerticalRange = math.max(1, tonumber(spec.VerticalRange) or 6),
        ArcDegrees = spec.ArcDegrees,
        RequireLineOfSight = spec.RequireLineOfSight == true,
        MaxTargets = spec.MaxTargets or 1,
    })
end

function CombatHitboxService.FindMeleeTarget(player, spec)
    local targets = CombatHitboxService.FindMeleeTargets(player, {
        Range = spec.Range,
        HitboxWidth = spec.HitboxWidth,
        VerticalRange = spec.VerticalRange,
        ArcDegrees = spec.ArcDegrees,
        RequireLineOfSight = spec.RequireLineOfSight,
        MaxTargets = 1,
    })
    return targets[1]
end

return CombatHitboxService
