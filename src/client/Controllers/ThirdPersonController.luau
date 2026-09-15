local GuiService = game:GetService("GuiService")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
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
local rollTrack = nil
local rollAnimation = nil
local rollCharacter = nil

local function stopRollAnimation(fadeTime)
    if rollTrack and rollTrack.IsPlaying then
        rollTrack:Stop(fadeTime or 0.06)
    end
end

local function destroyRollAnimation()
    stopRollAnimation(0)
    rollTrack = nil
    if rollAnimation then
        rollAnimation:Destroy()
        rollAnimation = nil
    end
    rollCharacter = nil
end

local function clearDodgeMover()
    stopRollAnimation(0.06)
    if dodgeVelocity then
        dodgeVelocity:Destroy()
        dodgeVelocity = nil
    end
    if dodgeAttachment then
        dodgeAttachment:Destroy()
        dodgeAttachment = nil
    end
end

local function makePose(name, transform)
    local pose = Instance.new("Pose")
    pose.Name = name
    pose.Weight = 1
    pose.CFrame = transform or CFrame.new()
    pose.EasingStyle = Enum.PoseEasingStyle.CubicV2
    pose.EasingDirection = Enum.PoseEasingDirection.InOut
    return pose
end

local function addR15RollKeyframe(sequence, time, spinDegrees, tuck)
    local keyframe = Instance.new("Keyframe")
    keyframe.Time = time

    local rootPose = makePose("HumanoidRootPart")
    rootPose.Weight = 0
    local lower = makePose(
        "LowerTorso",
        CFrame.new(0, -0.9 * tuck, 0.15 * tuck) * CFrame.Angles(math.rad(spinDegrees), 0, 0)
    )
    local upper = makePose("UpperTorso", CFrame.Angles(math.rad(-18 * tuck), 0, 0))
    local head = makePose("Head", CFrame.Angles(math.rad(24 * tuck), 0, 0))
    local leftArm = makePose(
        "LeftUpperArm",
        CFrame.Angles(math.rad(-68 * tuck), math.rad(-8 * tuck), math.rad(-18 * tuck))
    )
    local rightArm = makePose(
        "RightUpperArm",
        CFrame.Angles(math.rad(-68 * tuck), math.rad(8 * tuck), math.rad(18 * tuck))
    )
    local leftLeg =
        makePose("LeftUpperLeg", CFrame.Angles(math.rad(78 * tuck), 0, math.rad(-8 * tuck)))
    local rightLeg =
        makePose("RightUpperLeg", CFrame.Angles(math.rad(78 * tuck), 0, math.rad(8 * tuck)))

    upper:AddSubPose(head)
    upper:AddSubPose(leftArm)
    upper:AddSubPose(rightArm)
    lower:AddSubPose(upper)
    lower:AddSubPose(leftLeg)
    lower:AddSubPose(rightLeg)
    rootPose:AddSubPose(lower)
    keyframe:AddPose(rootPose)
    sequence:AddKeyframe(keyframe)
end

local function addR6RollKeyframe(sequence, time, spinDegrees, tuck)
    local keyframe = Instance.new("Keyframe")
    keyframe.Time = time

    local rootPose = makePose("HumanoidRootPart")
    rootPose.Weight = 0
    local torso = makePose(
        "Torso",
        CFrame.new(0, -0.8 * tuck, 0.15 * tuck) * CFrame.Angles(math.rad(spinDegrees), 0, 0)
    )
    torso:AddSubPose(makePose("Head", CFrame.Angles(math.rad(22 * tuck), 0, 0)))
    torso:AddSubPose(
        makePose("Left Arm", CFrame.Angles(math.rad(-64 * tuck), 0, math.rad(-16 * tuck)))
    )
    torso:AddSubPose(
        makePose("Right Arm", CFrame.Angles(math.rad(-64 * tuck), 0, math.rad(16 * tuck)))
    )
    torso:AddSubPose(
        makePose("Left Leg", CFrame.Angles(math.rad(72 * tuck), 0, math.rad(-6 * tuck)))
    )
    torso:AddSubPose(
        makePose("Right Leg", CFrame.Angles(math.rad(72 * tuck), 0, math.rad(6 * tuck)))
    )
    rootPose:AddSubPose(torso)
    keyframe:AddPose(rootPose)
    sequence:AddKeyframe(keyframe)
end

local function buildLocalRollAnimationId(rigType)
    local sequence = Instance.new("KeyframeSequence")
    sequence.Name = "EverLeafCombatRollSequence"
    sequence.Loop = false
    sequence.Priority = Enum.AnimationPriority.Action4

    local addFrame = if rigType == Enum.HumanoidRigType.R6
        then addR6RollKeyframe
        else addR15RollKeyframe
    local frameCount = 12
    for index = 0, frameCount do
        local alpha = index / frameCount
        local time = GameConfig.Movement.DodgeDuration * alpha
        local spinDegrees = -360 * alpha
        local tuck = math.sin(alpha * math.pi) ^ 0.72
        addFrame(sequence, time, spinDegrees, tuck)
    end

    local ok, animationId = pcall(function()
        return KeyframeSequenceProvider:RegisterKeyframeSequence(sequence)
    end)
    sequence:Destroy()
    if not ok then
        warn(
            string.format(
                "[ThirdPersonController] local roll sequence registration failed: %s",
                tostring(animationId)
            )
        )
        return nil
    end
    return animationId
end

local function prepareRollAnimation(character)
    if rollTrack and rollAnimation and rollCharacter == character then
        return true
    end

    destroyRollAnimation()

    local currentHumanoid = character and character:FindFirstChildOfClass("Humanoid")
    local animator = currentHumanoid and currentHumanoid:FindFirstChildOfClass("Animator")
    if not character or not currentHumanoid or not animator then
        return false
    end

    local animationId = buildLocalRollAnimationId(currentHumanoid.RigType)
    if not animationId then
        return false
    end

    rollAnimation = Instance.new("Animation")
    rollAnimation.Name = "EverLeafCombatRoll"
    rollAnimation.AnimationId = animationId

    local ok, loaded = pcall(function()
        return animator:LoadAnimation(rollAnimation)
    end)
    if not ok or not loaded then
        destroyRollAnimation()
        warn("[ThirdPersonController] combat roll animation failed to load")
        return false
    end

    rollTrack = loaded
    rollTrack.Priority = Enum.AnimationPriority.Action4
    rollTrack.Looped = false
    rollCharacter = character
    return true
end

local function playRollAnimation()
    local character = player.Character
    local currentHumanoid = character and character:FindFirstChildOfClass("Humanoid")
    local animator = currentHumanoid and currentHumanoid:FindFirstChildOfClass("Animator")
    if not character or not currentHumanoid or not animator then
        return false
    end

    if not prepareRollAnimation(character) or not rollTrack then
        return false
    end

    -- Keep Roblox locomotion tracks alive underneath the Action4 roll.
    -- Stopping them here leaves Animate in a stale "moving but no run track"
    -- state when a direction key stays held, which looks like infinite sliding.
    -- Action4 already overrides Core/Idle/Movement visually during the roll.
    if rollTrack.IsPlaying then
        rollTrack:Stop(0)
    end
    rollTrack:Play(0.07, 1, 1)
    return true
end

local function attachCharacter(character)
    clearDodgeMover()
    destroyRollAnimation()
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
    task.defer(function()
        if player.Character == character then
            prepareRollAnimation(character)
        end
    end)
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

local function rollSpeed(alpha)
    local peakAlpha = GameConfig.Movement.DodgeRollPeakAlpha
    if alpha <= peakAlpha then
        local t = math.clamp(alpha / peakAlpha, 0, 1)
        local eased = math.sin(t * math.pi * 0.5)
        return GameConfig.Movement.DodgeRollStartSpeed
            + (GameConfig.Movement.DodgeRollPeakSpeed - GameConfig.Movement.DodgeRollStartSpeed)
                * eased
    end

    local t = math.clamp((alpha - peakAlpha) / (1 - peakAlpha), 0, 1)
    local eased = 0.5 - 0.5 * math.cos(t * math.pi)
    return GameConfig.Movement.DodgeRollPeakSpeed
        + (GameConfig.Movement.DodgeRollEndSpeed - GameConfig.Movement.DodgeRollPeakSpeed)
            * eased
end

local function currentGroundMoveSpeed()
    if crouching then
        return GameConfig.Movement.CrouchSpeed
    end
    if sprintHeld then
        return GameConfig.Movement.SprintSpeed
    end
    return GameConfig.Movement.WalkSpeed
end

local function finishDodge(interrupted)
    local finishedDirection = dodgeDirection
    clearDodgeMover()
    dodgeUntil = 0
    dodgeStartedAt = -math.huge
    dodgeDirection = Vector3.zero

    if not humanoid or not root or not root.Parent then
        return
    end

    root.AssemblyAngularVelocity = Vector3.zero
    humanoid.AutoRotate = true

    if finishedDirection.Magnitude > 0.01 then
        root.CFrame = CFrame.lookAt(root.Position, root.Position + finishedDirection)
    end

    if interrupted then
        humanoid.WalkSpeed = 0
        humanoid:Move(Vector3.zero, false)
        local velocity = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(0, math.min(velocity.Y, 0), 0)
        return
    end

    local moveDirection = getWorldMoveDirection()
    local moveSpeed = currentGroundMoveSpeed()
    humanoid.WalkSpeed = moveSpeed
    humanoid:Move(moveDirection, false)

    -- Remove dodge momentum immediately. If the player is still holding a
    -- direction, seed only normal locomotion velocity; otherwise stop cleanly.
    -- This prevents the LinearVelocity impulse from surviving into normal
    -- movement and producing the post-roll ice-slide bug.
    local velocity = root.AssemblyLinearVelocity
    if moveDirection.Magnitude > 0.01 then
        local horizontal = moveDirection.Unit * moveSpeed
        root.AssemblyLinearVelocity = Vector3.new(horizontal.X, velocity.Y, horizontal.Z)
    else
        root.AssemblyLinearVelocity = Vector3.new(0, velocity.Y, 0)
    end
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
    if not playRollAnimation() then
        dodgeUntil = 0
        dodgeStartedAt = -math.huge
        dodgeDirection = Vector3.zero
        humanoid.AutoRotate = true
        humanoid.WalkSpeed = GameConfig.Movement.WalkSpeed
        return
    end

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
                if dodgeUntil > 0 then
                    finishDodge(true)
                end
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
                    if dodgeVelocity and dodgeVelocity.Parent then
                        local speed = rollSpeed(alpha)
                        dodgeVelocity.PlaneVelocity =
                            Vector2.new(dodgeDirection.X * speed, dodgeDirection.Z * speed)
                    end
                    return
                end

                finishDodge(false)
                if crouching then
                    setCrouching(false)
                end
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
