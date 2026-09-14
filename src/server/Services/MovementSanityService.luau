local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MovementSanityMath = require(ReplicatedStorage.Shared.Math.MovementSanityMath)

local MovementSanityService = {}
local accumulator = 0
local states = {}

local function resetState(player, root)
    states[player] = {
        Root = root,
        CFrame = root.CFrame,
        CheckedAt = os.clock(),
        GraceUntil = os.clock() + GameConfig.Movement.TeleportGraceSeconds,
    }
end

function MovementSanityService.AllowTeleport(player, graceSeconds)
    local state = states[player]
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not state or not root or state.Root ~= root then
        if root then
            resetState(player, root)
        end
        return
    end
    state.CFrame = root.CFrame
    state.CheckedAt = os.clock()
    state.GraceUntil = os.clock() + (graceSeconds or GameConfig.Movement.TeleportGraceSeconds)
end

local function correctPlayer(player)
    local character = player.Character
    if not character then
        states[player] = nil
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

    local now = os.clock()
    local state = states[player]
    if not state or state.Root ~= root then
        resetState(player, root)
        return
    end

    if now <= state.GraceUntil then
        state.CFrame = root.CFrame
        state.CheckedAt = now
        return
    end

    local delta = root.Position - state.CFrame.Position
    local elapsed = now - state.CheckedAt
    local allowed = MovementSanityMath.IsDisplacementAllowed(
        delta.X,
        delta.Y,
        delta.Z,
        elapsed,
        GameConfig.Movement.MaxHorizontalSpeed,
        GameConfig.Movement.DisplacementSlack,
        GameConfig.Movement.MaxVerticalSpeed
    )

    if not allowed then
        root.CFrame = state.CFrame
        root.AssemblyLinearVelocity = Vector3.new(0, math.min(velocity.Y, 0), 0)
        state.CheckedAt = now
        return
    end

    state.CFrame = root.CFrame
    state.CheckedAt = now
end

function MovementSanityService.Init()
    Players.PlayerRemoving:Connect(function(player)
        states[player] = nil
    end)

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
