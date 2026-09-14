local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SideScrollerController = {}

local player = Players.LocalPlayer
local leftHeld = false
local rightHeld = false
local thumbstickX = 0
local humanoid = nil

local function setDigital(direction, inputState)
    local pressed = inputState == Enum.UserInputState.Begin
        or inputState == Enum.UserInputState.Change
    if direction < 0 then
        leftHeld = pressed
    else
        rightHeld = pressed
    end
    return Enum.ContextActionResult.Sink
end

local function onJump(_, inputState)
    if inputState == Enum.UserInputState.Begin and humanoid then
        humanoid.Jump = true
    end
    return Enum.ContextActionResult.Sink
end

local function attachCharacter(character)
    humanoid = character:WaitForChild("Humanoid")
    humanoid.AutoRotate = true
end

function SideScrollerController.Start()
    local playerScripts = player:WaitForChild("PlayerScripts")
    local playerModule = require(playerScripts:WaitForChild("PlayerModule"))
    playerModule:GetControls():Disable()

    ContextActionService:BindAction("EverLeafMoveLeft", function(_, state)
        return setDigital(-1, state)
    end, true, Enum.KeyCode.A, Enum.KeyCode.Left, Enum.KeyCode.DPadLeft)

    ContextActionService:BindAction("EverLeafMoveRight", function(_, state)
        return setDigital(1, state)
    end, true, Enum.KeyCode.D, Enum.KeyCode.Right, Enum.KeyCode.DPadRight)

    ContextActionService:BindAction(
        "EverLeafJump",
        onJump,
        true,
        Enum.KeyCode.Space,
        Enum.KeyCode.ButtonA
    )
    ContextActionService:SetTitle("EverLeafMoveLeft", "◀")
    ContextActionService:SetTitle("EverLeafMoveRight", "▶")
    ContextActionService:SetTitle("EverLeafJump", "Jump")
    ContextActionService:SetPosition("EverLeafMoveLeft", UDim2.fromScale(0.06, 0.78))
    ContextActionService:SetPosition("EverLeafMoveRight", UDim2.fromScale(0.16, 0.78))
    ContextActionService:SetPosition("EverLeafJump", UDim2.fromScale(0.88, 0.72))

    UserInputService.InputChanged:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Thumbstick1 then
            thumbstickX = math.abs(input.Position.X) >= 0.15 and input.Position.X or 0
        end
    end)

    player.CharacterAdded:Connect(attachCharacter)
    if player.Character then
        task.spawn(attachCharacter, player.Character)
    end

    RunService:BindToRenderStep(
        "EverLeaf2DMovement",
        Enum.RenderPriority.Input.Value + 1,
        function()
            if not humanoid or humanoid.Health <= 0 then
                return
            end

            local digital = (rightHeld and 1 or 0) - (leftHeld and 1 or 0)
            local axis = math.abs(thumbstickX) >= 0.15 and thumbstickX or digital
            humanoid:Move(Vector3.new(axis, 0, 0), false)
        end
    )
end

return SideScrollerController
