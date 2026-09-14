local EnemyService = require(script.Parent.EnemyService)
local TargetingService = {}

function TargetingService.FindNearestEnemy(player, spec)
    local character = player.Character
    local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not playerRoot then
        return nil
    end
    local nearest = nil
    local nearestDistance = math.huge
    for _, candidate in EnemyService.GetActiveEnemies() do
        local root = candidate:FindFirstChild("HumanoidRootPart") or candidate.PrimaryPart
        if root then
            local delta = root.Position - playerRoot.Position
            local horizontal = math.abs(delta.X)
            if
                horizontal <= spec.Range
                and math.abs(delta.Y) <= spec.VerticalRange
                and math.abs(delta.Z) <= spec.DepthRange
                and horizontal < nearestDistance
            then
                nearest = candidate
                nearestDistance = horizontal
            end
        end
    end
    return nearest
end

return TargetingService
