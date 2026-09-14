local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local ThirdPersonController = {}

local player = Players.LocalPlayer
local humanoid = nil
local root = nil
local thumbstick = Vector2.zero
local sprintHeld = false
local lastDodgeAt = -math.huge
local dodgeUntil = 0
local dodgeDirection = Vector3.zero

local function attachCharacter(character)
    humanoid = character:WaitForChild("Humanoid")
    root = character:WaitForChild("HumanoidRootPart")
    humanoid.AutoRotate = true
    humanoid.UseJumpPower = true
    humanoid.JumpPower = GameConfig.Movement.JumpPower
    humanoid.WalkSpeed = GameConfig.Movement.WalkSpeed
    dodgeUntil = 0
    dodgeDirection = Vector3.zero
end

local function inputBlocked()
    return GuiService.MenuIsOpen
        or UserInputService:GetFocusedTextBox() ~= nil
        or player:GetAttribute("EverLeafUiCapture") == true
end

local function getMoveInput()
    local x = 0
    local z = 0

    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        x -= 1
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        x += 1
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        z += 1
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        z -= 1
    end

    local keyboard = Vector2.new(x, z)
    if keyboard.Magnitude > 1 then
        keyboard = keyboard.Unit
    end

    if thumbstick.Magnitude >= GameConfig.Movement.GamepadDeadzone then
        return Vector2.new(thumbstick.X, -thumbstick.Y)
    end
    return keyboard
end

local function getWorldMoveDirection()
    local input = getMoveInput()
    if input.Magnitude <= 0 then
        return Vector3.zero
    end

    local camera = Workspace.CurrentCamera
    if not camera then
        return Vector3.zero
    end

    local forward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
    local right = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z)
    if forward.Magnitude <= 0.001 or right.Magnitude <= 0.001 then
        return Vector3.zero
    end

    forward = forward.Unit
    right = right.Unit
    local direction = right * input.X + forward * input.Y
    return if direction.Magnitude > 1 then direction.Unit else direction
end

local function tryJump()
    if not humanoid or humanoid.Health <= 0 then
        return
    end
    if humanoid.FloorMaterial == Enum.Material.Air then
        return
    end
    humanoid.Jump = true
end

local function tryDodge()
    if not humanoid or not root or humanoid.Health <= 0 then
        return
    end
    if humanoid.FloorMaterial == Enum.Material.Air then
        return
    end

    local now = os.clock()
    if now - lastDodgeAt < GameConfig.Movement.DodgeCooldown then
        return
    end
    lastDodgeAt = now

    local direction = getWorldMoveDirection()
    if direction.Magnitude <= 0.01 then
        local look = root.CFrame.LookVector
        direction = Vector3.new(look.X, 0, look.Z)
        if direction.Magnitude <= 0.01 then
            return
        end
        direction = direction.Unit
    end

    dodgeDirection = direction
    dodgeUntil = now + GameConfig.Movement.DodgeDuration
    humanoid.AutoRotate = false
    humanoid.WalkSpeed = 0
    humanoid:Move(Vector3.zero, false)
    root.CFrame = CFrame.lookAt(root.Position, root.Position + dodgeDirection)

    local velocity = root.AssemblyLinearVelocity
    root.AssemblyLinearVelocity = Vector3.new(
        dodgeDirection.X * GameConfig.Movement.DodgeSpeed,
        velocity.Y,
        dodgeDirection.Z * GameConfig.Movement.DodgeSpeed
    )
    player:SetAttribute("LastLocalDodgeAt", now)
end

function ThirdPersonController.Start()
    player.CharacterAdded:Connect(attachCharacter)
    if player.Character then
        task.spawn(attachCharacter, player.Character)
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or inputBlocked() then
            return
        end

        if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
            tryJump()
        elseif
            input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL3
        then
            sprintHeld = true
        elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonB then
            tryDodge()
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL3 then
            sprintHeld = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Thumbstick1 then
            thumbstick = Vector2.new(input.Position.X, input.Position.Y)
        end
    end)

    RunService:BindToRenderStep(
        "EverLeaf3DMovement",
        Enum.RenderPriority.Input.Value + 1,
        function()
            if not humanoid or humanoid.Health <= 0 then
                return
            end

            local now = os.clock()
            if dodgeUntil > 0 then
                if now < dodgeUntil and root and root.Parent then
                    humanoid.WalkSpeed = 0
                    humanoid:Move(Vector3.zero, false)
                    local velocity = root.AssemblyLinearVelocity
                    root.AssemblyLinearVelocity = Vector3.new(
                        dodgeDirection.X * GameConfig.Movement.DodgeSpeed,
                        velocity.Y,
                        dodgeDirection.Z * GameConfig.Movement.DodgeSpeed
                    )
                    return
                end

                dodgeUntil = 0
                dodgeDirection = Vector3.zero
                humanoid.AutoRotate = true
            end

            if inputBlocked() then
                humanoid:Move(Vector3.zero, false)
                return
            end

            humanoid.WalkSpeed = if sprintHeld
                then GameConfig.Movement.SprintSpeed
                else GameConfig.Movement.WalkSpeed
            humanoid:Move(getWorldMoveDirection(), false)
        end
    )
end

return ThirdPersonController
