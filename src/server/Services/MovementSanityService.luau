local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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

    humanoid.UseJumpPower = true
    humanoid.JumpPower = GameConfig.Movement.JumpPower
    humanoid.WalkSpeed = math.clamp(humanoid.WalkSpeed, 0, GameConfig.Movement.SprintSpeed)

    local velocity = root.AssemblyLinearVelocity
    local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
    if horizontal.Magnitude > GameConfig.Movement.MaxHorizontalSpeed then
        horizontal = horizontal.Unit * GameConfig.Movement.MaxHorizontalSpeed
        root.AssemblyLinearVelocity = Vector3.new(horizontal.X, velocity.Y, horizontal.Z)
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
