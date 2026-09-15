local CameraImpulse = {}

local amplitude = 0
local fovKick = 0
local phase = 0

function CameraImpulse.Punch(strength)
    strength = math.clamp(tonumber(strength) or 0, 0, 1.5)
    if strength <= 0 then
        return
    end
    amplitude = math.min(1.5, amplitude + strength)
    fovKick = math.max(fovKick, strength * 1.8)
end

function CameraImpulse.Step(deltaTime)
    deltaTime = math.max(0, tonumber(deltaTime) or 0)
    phase += deltaTime * 46

    local current = amplitude
    local currentFov = fovKick
    amplitude *= math.exp(-18 * deltaTime)
    fovKick *= math.exp(-14 * deltaTime)

    if amplitude < 0.001 then
        amplitude = 0
    end
    if fovKick < 0.001 then
        fovKick = 0
    end

    if current <= 0.001 and currentFov <= 0.001 then
        return Vector3.zero, Vector3.zero, 0
    end

    local position = Vector3.new(
        math.sin(phase * 1.7) * 0.055 * current,
        math.cos(phase * 2.3) * 0.04 * current,
        0
    )
    local rotation = Vector3.new(
        math.sin(phase * 2.1) * 0.42 * current,
        math.cos(phase * 1.4) * 0.32 * current,
        math.sin(phase * 1.9) * 0.18 * current
    )
    return position, rotation, currentFov
end

function CameraImpulse.Reset()
    amplitude = 0
    fovKick = 0
    phase = 0
end

return CameraImpulse
