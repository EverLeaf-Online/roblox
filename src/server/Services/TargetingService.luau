local Workspace = game:GetService("Workspace")
local EnemyService = require(script.Parent.EnemyService)

local TargetingService = {}

local function hasLineOfSight(character, target, origin, targetPosition)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { character }
    params.IgnoreWater = false

    local result = Workspace:Raycast(origin, targetPosition - origin, params)
    return not result or result.Instance:IsDescendantOf(target)
end

local function eligibleEntries(player, candidates, spec)
    local character = player.Character
    local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not playerRoot then
        return {}
    end

    local range = math.max(0, tonumber(spec.Range) or 10)
    local verticalRange = math.max(0, tonumber(spec.VerticalRange) or range)
    local arcDegrees = math.clamp(tonumber(spec.ArcDegrees) or 360, 1, 360)
    local requireLineOfSight = spec.RequireLineOfSight == true
    local minimumDot = math.cos(math.rad(arcDegrees * 0.5))

    local forward = Vector3.new(playerRoot.CFrame.LookVector.X, 0, playerRoot.CFrame.LookVector.Z)
    if forward.Magnitude > 0.001 then
        forward = forward.Unit
    end

    local entries = {}
    for _, candidate in candidates do
        local root = candidate:FindFirstChild("HumanoidRootPart") or candidate.PrimaryPart
        if root and EnemyService.IsValidTarget(candidate) then
            local delta = root.Position - playerRoot.Position
            local distance = delta.Magnitude
            local flatDelta = Vector3.new(delta.X, 0, delta.Z)
            local facing = 1
            if flatDelta.Magnitude > 0.001 and forward.Magnitude > 0.001 then
                facing = forward:Dot(flatDelta.Unit)
            end

            local visible = true
            if requireLineOfSight then
                visible = hasLineOfSight(character, candidate, playerRoot.Position, root.Position)
            end

            if
                distance <= range
                and math.abs(delta.Y) <= verticalRange
                and facing >= minimumDot
                and visible
            then
                table.insert(entries, { Model = candidate, Distance = distance })
            end
        end
    end

    table.sort(entries, function(a, b)
        if a.Distance ~= b.Distance then
            return a.Distance < b.Distance
        end
        return a.Model.Name < b.Model.Name
    end)
    return entries
end

local function modelsFromEntries(entries, maxTargets)
    maxTargets = math.clamp(math.floor(tonumber(maxTargets) or 1), 1, 8)
    local result = {}
    for index = 1, math.min(maxTargets, #entries) do
        result[index] = entries[index].Model
    end
    return result
end

function TargetingService.FindEnemiesFromCandidates(player, candidates, spec)
    if type(candidates) ~= "table" or type(spec) ~= "table" then
        return {}
    end
    return modelsFromEntries(eligibleEntries(player, candidates, spec), spec.MaxTargets)
end

function TargetingService.FindBestEnemyFromCandidates(player, candidates, spec)
    local targets = TargetingService.FindEnemiesFromCandidates(player, candidates, {
        Range = spec.Range,
        VerticalRange = spec.VerticalRange,
        ArcDegrees = spec.ArcDegrees,
        RequireLineOfSight = spec.RequireLineOfSight,
        MaxTargets = 1,
    })
    return targets[1]
end

function TargetingService.FindEnemies(player, spec)
    return TargetingService.FindEnemiesFromCandidates(player, EnemyService.GetActiveEnemies(), spec)
end

function TargetingService.FindBestEnemy(player, spec)
    local targets = TargetingService.FindEnemies(player, {
        Range = spec.Range,
        VerticalRange = spec.VerticalRange,
        ArcDegrees = spec.ArcDegrees,
        RequireLineOfSight = spec.RequireLineOfSight,
        MaxTargets = 1,
    })
    return targets[1]
end

function TargetingService.FindNearestEnemy(player, spec)
    local copied = table.clone(spec)
    copied.ArcDegrees = copied.ArcDegrees or 360
    return TargetingService.FindBestEnemy(player, copied)
end

return TargetingService
