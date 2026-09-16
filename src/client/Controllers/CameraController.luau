local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local CameraImpulse = require(script.Parent.Parent.Presentation.CameraImpulse)

local CameraController = {}
local player = Players.LocalPlayer
local root = nil
local character = nil
local yaw = 0
local pitch = math.rad(-10)
local gamepadLook = Vector2.zero
local cameraArmLength = nil

local function attachCharacter(newCharacter)
    character = newCharacter
    root = newCharacter:WaitForChild("HumanoidRootPart")
    local look = root.CFrame.LookVector
    yaw = math.atan2(-look.X, -look.Z)
    cameraArmLength = nil
    CameraImpulse.Reset()
end

local function cameraInputBlocked()
    return GuiService.MenuIsOpen
        or UserInputService:GetFocusedTextBox() ~= nil
        or player:GetAttribute("EverLeafUiCapture") == true
end

local function updateMouseState()
    if cameraInputBlocked() then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    end
end

local function getCameraCollisionDistance(focus, idealOffset)
    local idealDistance = idealOffset.Magnitude
    if idealDistance <= 0.001 then
        return 0
    end

    local excluded = {}
    if character then
        table.insert(excluded, character)
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true

    for _ = 1, 10 do
        rayParams.FilterDescendantsInstances = excluded
        local ray = Workspace:Raycast(focus, idealOffset, rayParams)
        if not ray then
            return idealDistance
        end

        local hit = ray.Instance
        local blocksCamera = hit == Workspace.Terrain
        if hit:IsA("BasePart") then
            local collisionProxy = hit:GetAttribute("EverLeafCollisionProxy") == true
            blocksCamera = hit.CanCollide and (hit.Transparency < 0.95 or collisionProxy)
        end

        if blocksCamera then
            return math.max(
                GameConfig.Camera.MinimumCollisionDistance,
                ray.Distance - GameConfig.Camera.CollisionPadding
            )
        end

        table.insert(excluded, hit)
    end

    return idealDistance
end

function CameraController.Start()
    player.CharacterAdded:Connect(attachCharacter)
    if player.Character then
        task.spawn(attachCharacter, player.Character)
    end

    local camera = Workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = GameConfig.Camera.FieldOfView

    UserInputService.InputChanged:Connect(function(input)
        if cameraInputBlocked() then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement then
            yaw -= input.Delta.X * GameConfig.Camera.MouseSensitivity
            pitch = math.clamp(
                pitch - input.Delta.Y * GameConfig.Camera.MouseSensitivity,
                math.rad(GameConfig.Camera.MinPitchDegrees),
                math.rad(GameConfig.Camera.MaxPitchDegrees)
            )
        elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
            gamepadLook = Vector2.new(input.Position.X, input.Position.Y)
        end
    end)

    RunService:BindToRenderStep(
        "EverLeafThirdPersonCamera",
        Enum.RenderPriority.Camera.Value + 1,
        function(deltaTime)
            updateMouseState()
            if not root or not root.Parent then
                return
            end

            if
                not cameraInputBlocked()
                and gamepadLook.Magnitude >= GameConfig.Movement.GamepadDeadzone
            then
                yaw -= gamepadLook.X * GameConfig.Camera.GamepadSensitivity * deltaTime
                pitch = math.clamp(
                    pitch + gamepadLook.Y * GameConfig.Camera.GamepadSensitivity * deltaTime,
                    math.rad(GameConfig.Camera.MinPitchDegrees),
                    math.rad(GameConfig.Camera.MaxPitchDegrees)
                )
            end

            local currentCamera = Workspace.CurrentCamera
            if not currentCamera then
                return
            end
            camera = currentCamera
            if camera.CameraType ~= Enum.CameraType.Scriptable then
                camera.CameraType = Enum.CameraType.Scriptable
            end
            local focus = root.Position + Vector3.new(0, GameConfig.Camera.FocusHeight, 0)
            local orbit = CFrame.fromOrientation(pitch, yaw, 0)
            local idealOffset = -orbit.LookVector * GameConfig.Camera.Distance
                + orbit.RightVector * GameConfig.Camera.ShoulderOffset
            local idealDistance = idealOffset.Magnitude
            local targetArmLength = getCameraCollisionDistance(focus, idealOffset)

            if cameraArmLength == nil or targetArmLength < cameraArmLength then
                -- Initialize at the safe distance and pull in immediately so the
                -- camera never clips through solid geometry.
                cameraArmLength = targetArmLength
            else
                -- Ease back out after an obstruction clears. This hysteresis prevents
                -- foliage edges or rapidly changing ray hits from making the view pop.
                local recoveryAlpha = 1
                    - math.exp(-GameConfig.Camera.CollisionRecoveryResponsiveness * deltaTime)
                cameraArmLength += (targetArmLength - cameraArmLength) * recoveryAlpha
            end

            cameraArmLength = math.clamp(
                cameraArmLength,
                GameConfig.Camera.MinimumCollisionDistance,
                idealDistance
            )

            local desiredPosition = focus + idealOffset.Unit * cameraArmLength
            local desired = CFrame.lookAt(desiredPosition, focus)
            local alpha = 1 - math.exp(-GameConfig.Camera.Responsiveness * deltaTime)
            local smoothed = camera.CFrame:Lerp(desired, alpha)
            local impulsePosition, impulseRotation, fovOffset = CameraImpulse.Step(deltaTime)
            camera.CFrame = smoothed
                * CFrame.new(impulsePosition)
                * CFrame.Angles(
                    math.rad(impulseRotation.X),
                    math.rad(impulseRotation.Y),
                    math.rad(impulseRotation.Z)
                )
            camera.FieldOfView = GameConfig.Camera.FieldOfView + fovOffset
        end
    )
end

return CameraController
