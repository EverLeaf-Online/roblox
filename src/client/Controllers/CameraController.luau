local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local CameraController = {}
local player = Players.LocalPlayer
local root = nil
local character = nil
local yaw = 0
local pitch = math.rad(-10)
local gamepadLook = Vector2.zero

local function attachCharacter(newCharacter)
    character = newCharacter
    root = newCharacter:WaitForChild("HumanoidRootPart")
    local look = root.CFrame.LookVector
    yaw = math.atan2(-look.X, -look.Z)
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

            local focus = root.Position + Vector3.new(0, GameConfig.Camera.FocusHeight, 0)
            local orbit = CFrame.fromOrientation(pitch, yaw, 0)
            local desiredPosition = focus
                - orbit.LookVector * GameConfig.Camera.Distance
                + orbit.RightVector * GameConfig.Camera.ShoulderOffset

            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = if character then { character } else {}
            rayParams.IgnoreWater = false

            local ray = Workspace:Raycast(focus, desiredPosition - focus, rayParams)
            if ray then
                desiredPosition = ray.Position + ray.Normal * GameConfig.Camera.CollisionPadding
            end

            local desired = CFrame.lookAt(desiredPosition, focus)
            local alpha = 1 - math.exp(-GameConfig.Camera.Responsiveness * deltaTime)
            camera.CFrame = camera.CFrame:Lerp(desired, alpha)
        end
    )
end

return CameraController
