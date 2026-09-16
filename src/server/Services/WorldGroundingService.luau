local Workspace = game:GetService("Workspace")

local WorldGroundingService = {}

local function lowestVisibleWorldY(model)
    local lowest = math.huge
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            if descendant.Name ~= "HumanoidRootPart" or descendant.Transparency < 1 then
                local half = descendant.Size * 0.5
                for _, x in { -1, 1 } do
                    for _, y in { -1, 1 } do
                        for _, z in { -1, 1 } do
                            local corner = descendant.CFrame:PointToWorldSpace(
                                Vector3.new(half.X * x, half.Y * y, half.Z * z)
                            )
                            lowest = math.min(lowest, corner.Y)
                        end
                    end
                end
            end
        end
    end
    if lowest == math.huge then
        return nil
    end
    return lowest
end

function WorldGroundingService.GroundModel(model, requestedPosition, options)
    options = options or {}
    if not model or not model:IsA("Model") then
        return false, "invalid_model"
    end

    local pivot = model:GetPivot()
    local rotation = pivot - pivot.Position
    local stagingHeight = tonumber(options.StagingHeight) or 40
    model:PivotTo(CFrame.new(requestedPosition + Vector3.new(0, stagingHeight, 0)) * rotation)

    local includeInstances = {}
    if type(options.IncludeInstances) == "table" then
        for _, instance in options.IncludeInstances do
            if typeof(instance) == "Instance" and instance.Parent then
                table.insert(includeInstances, instance)
            end
        end
    end

    local groundSource = "world_surface"
    if #includeInstances == 0 then
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if not terrain then
            return false, "terrain_missing"
        end
        table.insert(includeInstances, terrain)
        groundSource = "terrain"
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = includeInstances
    -- World grounding treats water as traversable volume, never as a floor.
    -- Callers that need aquatic placement should provide their own water-specific resolver.
    params.IgnoreWater = true

    local rayOrigin =
        Vector3.new(requestedPosition.X, requestedPosition.Y + 120, requestedPosition.Z)
    local hit = Workspace:Raycast(rayOrigin, Vector3.new(0, -260, 0), params)
    if not hit then
        return false, "ground_not_found"
    end

    local lowest = lowestVisibleWorldY(model)
    if not lowest then
        return false, "no_visible_parts"
    end

    local clearance = tonumber(options.Clearance) or 0.08
    local shiftY = hit.Position.Y + clearance - lowest
    model:PivotTo(CFrame.new(0, shiftY, 0) * model:GetPivot())

    model:SetAttribute("EverLeafGroundY", hit.Position.Y)
    model:SetAttribute("EverLeafGroundSource", groundSource)
    model:SetAttribute("EverLeafGroundClearance", clearance)
    model:SetAttribute("EverLeafGroundShiftY", shiftY)
    return true
end

return WorldGroundingService
