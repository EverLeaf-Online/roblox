local NpcGroundingRules = {}

function NpcGroundingRules.ComputeVerticalShift(groundY, footBottomWorldY, clearance)
    groundY = tonumber(groundY) or 0
    footBottomWorldY = tonumber(footBottomWorldY) or 0
    clearance = tonumber(clearance) or 0
    return groundY + clearance - footBottomWorldY
end

return NpcGroundingRules
