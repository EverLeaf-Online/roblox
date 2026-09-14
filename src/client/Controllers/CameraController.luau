local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local CameraController = {}
local player = Players.LocalPlayer
local root = nil

local function attachCharacter(character)
    root = character:WaitForChild("HumanoidRootPart")
end

function CameraController.Start()
    player.CharacterAdded:Connect(attachCharacter)
    if player.Character then
        task.spawn(attachCharacter, player.Character)
    end

    local camera = Workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable

    RunService:BindToRenderStep(
        "EverLeafSideCamera",
        Enum.RenderPriority.Camera.Value + 1,
        function(deltaTime)
            if not root or not root.Parent then
                return
            end

            local movement = GameConfig.Movement
            local focus = root.Position + Vector3.new(0, movement.CameraLookHeight, 0)
            local desiredPosition = focus
                + Vector3.new(0, movement.CameraHeight, movement.CameraDistance)
            local desired = CFrame.lookAt(desiredPosition, focus)
            local alpha = 1 - math.exp(-movement.CameraResponsiveness * deltaTime)
            camera.CFrame = camera.CFrame:Lerp(desired, alpha)
        end
    )
end

return CameraController
