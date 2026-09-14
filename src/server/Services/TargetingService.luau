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

function TargetingService.FindBestEnemy(player, spec)
    local character = player.Character
    local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not playerRoot then
        return nil
    end

    local range = tonumber(spec.Range) or 10
    local verticalRange = tonumber(spec.VerticalRange) or range
    local arcDegrees = tonumber(spec.ArcDegrees) or 360
    local requireLineOfSight = spec.RequireLineOfSight == true
    local minimumDot = math.cos(math.rad(math.clamp(arcDegrees, 1, 360) * 0.5))

    local forward = Vector3.new(playerRoot.CFrame.LookVector.X, 0, playerRoot.CFrame.LookVector.Z)
    if forward.Magnitude > 0.001 then
        forward = forward.Unit
    end

    local nearest = nil
    local nearestDistance = math.huge
    for _, candidate in EnemyService.GetActiveEnemies() do
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
                and distance < nearestDistance
            then
                nearest = candidate
                nearestDistance = distance
            end
        end
    end

    return nearest
end

function TargetingService.FindNearestEnemy(player, spec)
    local copied = table.clone(spec)
    copied.ArcDegrees = copied.ArcDegrees or 360
    return TargetingService.FindBestEnemy(player, copied)
end

return TargetingService
