local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CombatFacing = {}
local player = Players.LocalPlayer
local lockedUntil = 0
local lockedDirection = Vector3.zero
local ownsAutoRotate = false

local function cameraPlanarDirection()
    local camera = Workspace.CurrentCamera
    if not camera then
        return nil
    end
    local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
    if look.Magnitude <= 0.001 then
        return nil
    end
    return look.Unit
end

local function applyDirection(root, direction)
    if not root or not root.Parent or direction.Magnitude <= 0.001 then
        return false
    end
    root.CFrame = CFrame.lookAt(root.Position, root.Position + direction)
    return true
end

function CombatFacing.LockToCamera(duration)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root then
        return false
    end

    local direction = cameraPlanarDirection()
    if not direction then
        return false
    end

    duration = math.clamp(tonumber(duration) or 0.2, 0.05, 2)
    lockedUntil = os.clock() + duration
    lockedDirection = direction
    ownsAutoRotate = true
    humanoid.AutoRotate = false
    applyDirection(root, direction)
    return true
end

function CombatFacing.Apply(root, humanoid, now)
    now = tonumber(now) or os.clock()
    if lockedUntil > now and lockedDirection.Magnitude > 0.001 then
        if humanoid then
            humanoid.AutoRotate = false
        end
        applyDirection(root, lockedDirection)
        return true
    end

    if ownsAutoRotate and humanoid then
        humanoid.AutoRotate = true
    end
    lockedUntil = 0
    lockedDirection = Vector3.zero
    ownsAutoRotate = false
    return false
end

function CombatFacing.Reset()
    lockedUntil = 0
    lockedDirection = Vector3.zero
    ownsAutoRotate = false
end

function CombatFacing.IsLocked(now)
    return lockedUntil > (tonumber(now) or os.clock())
end

return CombatFacing
