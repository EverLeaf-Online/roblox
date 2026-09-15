local NpcGroundingRules = {}

function NpcGroundingRules.ComputeRootY(groundY, footBottomLocalY, clearance)
    groundY = tonumber(groundY) or 0
    footBottomLocalY = tonumber(footBottomLocalY) or -3
    clearance = tonumber(clearance) or 0
    return groundY - footBottomLocalY + clearance
end

return NpcGroundingRules
