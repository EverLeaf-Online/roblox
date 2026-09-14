local MovementSanityMath = {}

function MovementSanityMath.IsDisplacementAllowed(
    dx,
    dy,
    dz,
    elapsed,
    maxHorizontalSpeed,
    slack,
    maxVerticalSpeed
)
    elapsed = math.max(0.001, elapsed)
    local horizontal = math.sqrt(dx * dx + dz * dz)
    local horizontalLimit = maxHorizontalSpeed * elapsed + slack
    local verticalLimit = maxVerticalSpeed * elapsed + slack
    return horizontal <= horizontalLimit and math.abs(dy) <= verticalLimit, horizontal, math.abs(dy)
end

return MovementSanityMath
