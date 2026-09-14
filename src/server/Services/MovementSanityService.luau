local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local MovementSanityService = {}
local accumulator = 0

local function correctPlayer(player)
    local character = player.Character
    if not character then
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then
        return
    end

    local planeZ = player:GetAttribute("MovementPlaneZ")
    if type(planeZ) ~= "number" then
        planeZ = GameConfig.Movement.DefaultPlaneZ
    end

    local offset = root.Position.Z - planeZ
    if math.abs(offset) > GameConfig.Movement.HardCorrectionDepth then
        local position = root.Position
        local rotation = root.CFrame.Rotation
        root.CFrame = CFrame.new(position.X, position.Y, planeZ) * rotation
    end

    if math.abs(offset) > GameConfig.Movement.DepthTolerance then
        local velocity = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(velocity.X, velocity.Y, 0)
    end
end

function MovementSanityService.Init()
    RunService.Heartbeat:Connect(function(deltaTime)
        accumulator += deltaTime
        if accumulator < GameConfig.Movement.ServerCheckInterval then
            return
        end
        accumulator = 0

        for _, player in Players:GetPlayers() do
            correctPlayer(player)
        end
    end)
end

return MovementSanityService
