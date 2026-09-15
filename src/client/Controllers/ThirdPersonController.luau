local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)
local CombatFacing = require(script.Parent.Parent.Presentation.CombatFacing)

local ThirdPersonController = {}

local player = Players.LocalPlayer
local humanoid = nil
local root = nil
local thumbstick = Vector2.zero
local sprintHeld = false
local crouching = false
local movementIntentRemote = nil
local lastDodgeAt = -math.huge
local dodgeUntil = 0
local dodgeDirection = Vector3.zero
local dodgeStartedAt = -math.huge
local dodgeAttachment = nil
local dodgeVelocity = nil
local rollMotor = nil
local rollMotorBaseTransform = nil
local rollPoseMotors = {}

local function restoreRollPose()
    if rollMotor and rollMotor.Parent and rollMotorBaseTransform then
        rollMotor.Transform = rollMotorBaseTransform
    end
    rollMotor = nil
    rollMotorBaseTransform = nil

    for motor, baseTransform in rollPoseMotors do
        if motor and motor.Parent then
            motor.Transform = baseTransform
        end
    end
    table.clear(rollPoseMotors)
end

local function clearDodgeMover()
    restoreRollPose()
    if dodgeVelocity then
        dodgeVelocity:Destroy()
        dodgeVelocity = nil
    end
    if dodgeAttachment then
        dodgeAttachment:Destroy()
        dodgeAttachment = nil
    end
end

local function attachCharacter(character)
    clearDodgeMover()
    humanoid = character:WaitForChild("Humanoid")
    root = character:WaitForChild("HumanoidRootPart")
    CombatFacing.Reset()
    humanoid.AutoRotate = true
    humanoid.UseJumpPower = true
    humanoid.JumpPower = GameConfig.Movement.JumpPower
    humanoid.WalkSpeed = GameConfig.Movement.WalkSpeed
    dodgeUntil = 0
    dodgeStartedAt = -math.huge
    dodgeDirection = Vector3.zero
    crouching = false
    humanoid.CameraOffset = Vector3.zero
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

local function findCharacterMotor(names)
    local character = player.Character
    if not character then
        return nil
    end
    for _, name in names do
        local motor = character:FindFirstChild(name, true)
        if motor and motor:IsA("Motor6D") then
            return motor
        end
    end
    return nil
end

local function rememberPoseMotor(motor)
    if motor and rollPoseMotors[motor] == nil then
        rollPoseMotors[motor] = motor.Transform
    end
    return motor
end

local function beginRollPose()
    restoreRollPose()
    rollMotor = findCharacterMotor({ "Root", "RootJoint" })
    if rollMotor then
        rollMotorBaseTransform = rollMotor.Transform
    end

    rememberPoseMotor(findCharacterMotor({ "Waist" }))
    rememberPoseMotor(findCharacterMotor({ "LeftHip", "Left Hip" }))
    rememberPoseMotor(findCharacterMotor({ "RightHip", "Right Hip" }))
    rememberPoseMotor(findCharacterMotor({ "LeftShoulder", "Left Shoulder" }))
    rememberPoseMotor(findCharacterMotor({ "RightShoulder", "Right Shoulder" }))
end

local function applyRollPose(alpha)
    if not rollMotor or not rollMotor.Parent or not rollMotorBaseTransform then
        return
    end

    local eased = 0.5 - 0.5 * math.cos(alpha * math.pi)
    local fullRotation = alpha * math.pi * 2
    local lift = math.sin(alpha * math.pi) * 0.85
    rollMotor.Transform = rollMotorBaseTransform
        * CFrame.new(0, lift, 0)
        * CFrame.Angles(-fullRotation, 0, 0)

    for motor, baseTransform in rollPoseMotors do
        local name = motor.Name
        local tuck = math.sin(alpha * math.pi)
        if string.find(name, "Hip") then
            motor.Transform = baseTransform * CFrame.Angles(math.rad(45) * tuck, 0, 0)
        elseif string.find(name, "Shoulder") then
            motor.Transform = baseTransform * CFrame.Angles(math.rad(-38) * tuck, 0, 0)
        elseif name == "Waist" then
            motor.Transform = baseTransform * CFrame.Angles(math.rad(-18) * tuck, 0, 0)
        end
    end

    if eased >= 1 then
        restoreRollPose()
    end
end

local function rollSpeed(alpha)
    local eased = alpha * alpha * (3 - 2 * alpha)
    return GameConfig.Movement.DodgeRollStartSpeed
        + (GameConfig.Movement.DodgeRollEndSpeed - GameConfig.Movement.DodgeRollStartSpeed)
            * eased
end

local function sendCrouchState()
    if movementIntentRemote then
        movementIntentRemote:FireServer({ Crouching = crouching })
    end
end

local function setCrouching(value)
    value = value == true
    if crouching == value then
        return
    end
    if value then
        if
            player:GetAttribute("EverLeafStaggered") == true
            or dodgeUntil > os.clock()
            or not humanoid
            or humanoid.FloorMaterial == Enum.Material.Air
        then
            return
        end
        sprintHeld = false
    end
    crouching = value
    if humanoid then
        humanoid.CameraOffset = if crouching
            then GameConfig.Movement.CrouchCameraOffset
            else Vector3.zero
    end
    sendCrouchState()
end

local function tryJump()
    if crouching then
        setCrouching(false)
    end
    if player:GetAttribute("EverLeafStaggered") == true then
        return
    end
    if not humanoid or humanoid.Health <= 0 then
        return
    end
    if humanoid.FloorMaterial == Enum.Material.Air then
        return
    end
    humanoid.Jump = true
end

local function tryDodge()
    if crouching then
        setCrouching(false)
    end
    if player:GetAttribute("EverLeafStaggered") == true then
        return
    end
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
    CombatFacing.Reset()

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
    dodgeStartedAt = now
    dodgeUntil = now + GameConfig.Movement.DodgeDuration
    humanoid.AutoRotate = false
    humanoid.WalkSpeed = 0
    humanoid:Move(Vector3.zero, false)
    root.CFrame = CFrame.lookAt(root.Position, root.Position + dodgeDirection)

    if movementIntentRemote then
        movementIntentRemote:FireServer({
            Dodge = true,
            DirectionX = dodgeDirection.X,
            DirectionZ = dodgeDirection.Z,
        })
    end

    clearDodgeMover()
    beginRollPose()
    dodgeAttachment = Instance.new("Attachment")
    dodgeAttachment.Name = "EverLeafDodgeAttachment"
    dodgeAttachment.Parent = root

    dodgeVelocity = Instance.new("LinearVelocity")
    dodgeVelocity.Name = "EverLeafDodgeVelocity"
    dodgeVelocity.Attachment0 = dodgeAttachment
    dodgeVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    dodgeVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
    dodgeVelocity.PrimaryTangentAxis = Vector3.xAxis
    dodgeVelocity.SecondaryTangentAxis = Vector3.zAxis
    dodgeVelocity.PlaneVelocity = Vector2.new(
        dodgeDirection.X * GameConfig.Movement.DodgeRollStartSpeed,
        dodgeDirection.Z * GameConfig.Movement.DodgeRollStartSpeed
    )
    dodgeVelocity.ForceLimitsEnabled = true
    dodgeVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
    dodgeVelocity.MaxPlanarAxesForce = Vector2.new(90000, 90000)
    dodgeVelocity.Parent = root

    local velocity = root.AssemblyLinearVelocity
    root.AssemblyLinearVelocity = Vector3.new(
        dodgeDirection.X * GameConfig.Movement.DodgeRollStartSpeed,
        velocity.Y,
        dodgeDirection.Z * GameConfig.Movement.DodgeRollStartSpeed
    )
    player:SetAttribute("LastLocalDodgeAt", now)
end

function ThirdPersonController.Start()
    local remotes = ReplicatedStorage:WaitForChild(Net.RemoteFolderName, 5)
    if remotes then
        local remote = remotes:WaitForChild(Net.Events.MovementIntent, 5)
        if remote and remote:IsA("RemoteEvent") then
            movementIntentRemote = remote
        end
    end

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
            if not crouching then
                sprintHeld = true
            end
        elseif input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.ButtonR3 then
            setCrouching(not crouching)
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
            if player:GetAttribute("EverLeafStaggered") == true then
                CombatFacing.Reset()
                clearDodgeMover()
                dodgeUntil = 0
                dodgeStartedAt = -math.huge
                dodgeDirection = Vector3.zero
                if crouching then
                    setCrouching(false)
                end
                humanoid.AutoRotate = true
                humanoid.WalkSpeed = 0
                humanoid:Move(Vector3.zero, false)
                return
            end
            if dodgeUntil > 0 then
                if now < dodgeUntil and root and root.Parent then
                    humanoid.WalkSpeed = 0
                    humanoid:Move(Vector3.zero, false)
                    local alpha =
                        math.clamp((now - dodgeStartedAt) / GameConfig.Movement.DodgeDuration, 0, 1)
                    applyRollPose(alpha)
                    if dodgeVelocity and dodgeVelocity.Parent then
                        local speed = rollSpeed(alpha)
                        dodgeVelocity.PlaneVelocity =
                            Vector2.new(dodgeDirection.X * speed, dodgeDirection.Z * speed)
                    end
                    return
                end

                clearDodgeMover()
                dodgeUntil = 0
                dodgeStartedAt = -math.huge
                dodgeDirection = Vector3.zero
                if crouching then
                    setCrouching(false)
                end
                humanoid.AutoRotate = true
            end

            if root and root.Parent then
                CombatFacing.Apply(root, humanoid, now)
            end

            if inputBlocked() then
                humanoid:Move(Vector3.zero, false)
                return
            end

            humanoid.WalkSpeed = if crouching
                then GameConfig.Movement.CrouchSpeed
                else if sprintHeld
                    then GameConfig.Movement.SprintSpeed
                    else GameConfig.Movement.WalkSpeed
            humanoid:Move(getWorldMoveDirection(), false)
        end
    )
end

return ThirdPersonController
