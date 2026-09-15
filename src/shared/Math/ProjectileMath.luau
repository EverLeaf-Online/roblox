local ProjectileMath = {}

function ProjectileMath.TravelTime(distance, speed)
    distance = math.max(0, tonumber(distance) or 0)
    speed = math.max(1, tonumber(speed) or 1)
    return distance / speed
end

function ProjectileMath.StepLength(speed, deltaTime, remainingDistance)
    speed = math.max(1, tonumber(speed) or 1)
    deltaTime = math.clamp(tonumber(deltaTime) or 0, 0, 0.1)
    remainingDistance = math.max(0, tonumber(remainingDistance) or 0)
    return math.min(speed * deltaTime, remainingDistance)
end

return ProjectileMath
