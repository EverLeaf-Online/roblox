local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Net = require(ReplicatedStorage.Shared.Net)

local CombatController = {}
local player = Players.LocalPlayer
local feedbackGeneration = 0
local feedbackLabel = nil
local attackButton = nil
local attackRemote = nil
local attacking = false

local reasonText = {
    cooldown = "Attack is on cooldown",
    no_target = "No enemy in front of you",
    out_of_range = "Move closer",
    target_unavailable = "Target is unavailable",
    character_unavailable = "Character is unavailable",
    rate_limited = "Slow down",
}

local function getCombatGui()
    local playerGui = player:WaitForChild("PlayerGui")
    local existing = playerGui:FindFirstChild("EverLeafCombatGui")
    if existing then
        return existing
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "EverLeafCombatGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = playerGui
    return gui
end

local function getFeedbackLabel()
    if feedbackLabel and feedbackLabel.Parent then
        return feedbackLabel
    end

    local label = Instance.new("TextLabel")
    label.Name = "Message"
    label.AnchorPoint = Vector2.new(0.5, 1)
    label.Position = UDim2.fromScale(0.5, 0.84)
    label.Size = UDim2.fromOffset(320, 38)
    label.BackgroundTransparency = 0.08
    label.BackgroundColor3 = Color3.fromRGB(17, 25, 23)
    label.TextColor3 = Color3.fromRGB(235, 244, 239)
    label.TextStrokeTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 15
    label.Visible = false
    label.ZIndex = 20
    label.Parent = getCombatGui()

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = label
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(91, 129, 113)
    stroke.Transparency = 0.35
    stroke.Thickness = 1
    stroke.Parent = label
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = label

    feedbackLabel = label
    return label
end

local function showFeedback(text, tone)
    feedbackGeneration += 1
    local generation = feedbackGeneration
    local label = getFeedbackLabel()
    label.Text = text
    label.TextTransparency = 0
    label.BackgroundTransparency = 0.08
    label.TextColor3 = if tone == "success"
        then Color3.fromRGB(151, 232, 183)
        else if tone == "warning"
            then Color3.fromRGB(235, 188, 105)
            else Color3.fromRGB(235, 244, 239)
    label.Visible = true

    task.delay(0.72, function()
        if generation == feedbackGeneration and label.Parent then
            TweenService:Create(label, TweenInfo.new(0.18), {
                TextTransparency = 1,
                BackgroundTransparency = 1,
            }):Play()
            task.delay(0.2, function()
                if generation == feedbackGeneration and label.Parent then
                    label.Visible = false
                end
            end)
        end
    end)
end

local function findMotor(character, names)
    for _, name in names do
        local joint = character:FindFirstChild(name, true)
        if joint and joint:IsA("Motor6D") then
            return joint
        end
    end
    return nil
end

local function playPoseTween(joint, targetC0, duration, easingStyle, easingDirection)
    if not joint or not joint.Parent then
        return nil
    end

    local tween = TweenService:Create(
        joint,
        TweenInfo.new(duration, easingStyle, easingDirection),
        { C0 = targetC0 }
    )
    tween:Play()
    return tween
end

local function playAttackAnimation()
    local character = player.Character
    if not character then
        return
    end

    -- Roblox's built-in Animate script writes Motor6D.Transform every frame.
    -- Layer the combat pose through C0 instead so the attack remains visible
    -- while normal idle/run animations continue underneath it.
    local rightShoulder = findMotor(character, { "RightShoulder", "Right Shoulder" })
    if not rightShoulder then
        return
    end

    local leftShoulder = findMotor(character, { "LeftShoulder", "Left Shoulder" })
    local torsoJoint = findMotor(character, { "Waist", "RootJoint", "Root Joint" })

    local rightBase = rightShoulder.C0
    local leftBase = leftShoulder and leftShoulder.C0 or nil
    local torsoBase = torsoJoint and torsoJoint.C0 or nil

    task.spawn(function()
        local windup = playPoseTween(
            rightShoulder,
            rightBase * CFrame.Angles(math.rad(28), math.rad(-12), math.rad(36)),
            0.07,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        )
        if leftShoulder and leftBase then
            playPoseTween(
                leftShoulder,
                leftBase * CFrame.Angles(math.rad(-8), 0, math.rad(-12)),
                0.07,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            )
        end
        if torsoJoint and torsoBase then
            playPoseTween(
                torsoJoint,
                torsoBase * CFrame.Angles(0, math.rad(-16), 0),
                0.07,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            )
        end
        if windup then
            windup.Completed:Wait()
        end

        local strike = playPoseTween(
            rightShoulder,
            rightBase * CFrame.Angles(math.rad(-92), math.rad(10), math.rad(-14)),
            0.09,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        )
        if leftShoulder and leftBase then
            playPoseTween(
                leftShoulder,
                leftBase * CFrame.Angles(math.rad(8), 0, math.rad(8)),
                0.09,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            )
        end
        if torsoJoint and torsoBase then
            playPoseTween(
                torsoJoint,
                torsoBase * CFrame.Angles(0, math.rad(24), 0),
                0.09,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            )
        end
        if strike then
            strike.Completed:Wait()
        end

        playPoseTween(
            rightShoulder,
            rightBase,
            0.16,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.InOut
        )
        if leftShoulder and leftBase then
            playPoseTween(
                leftShoulder,
                leftBase,
                0.16,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.InOut
            )
        end
        if torsoJoint and torsoBase then
            playPoseTween(
                torsoJoint,
                torsoBase,
                0.16,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.InOut
            )
        end
    end)
end

local function faceCameraDirection()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local camera = workspace.CurrentCamera
    if not root or not camera then
        return
    end

    local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
    if look.Magnitude <= 0.001 then
        return
    end
    root.CFrame = CFrame.lookAt(root.Position, root.Position + look.Unit)
end

local function performAttack()
    if attacking or not attackRemote then
        return
    end
    if
        GuiService.MenuIsOpen
        or UserInputService:GetFocusedTextBox()
        or player:GetAttribute("EverLeafUiCapture") == true
    then
        return
    end

    attacking = true
    faceCameraDirection()
    playAttackAnimation()

    task.spawn(function()
        local invokeOk, attackOk, resultOrReason = pcall(function()
            return attackRemote:InvokeServer()
        end)

        if not invokeOk then
            showFeedback("Attack request failed", "warning")
        elseif not attackOk then
            showFeedback(reasonText[resultOrReason] or tostring(resultOrReason), "warning")
        else
            local damage = resultOrReason and resultOrReason.Damage
            if damage then
                showFeedback(string.format("Hit · %d damage", damage), "success")
            else
                showFeedback("Hit", "success")
            end
        end

        task.delay(0.12, function()
            attacking = false
        end)
    end)
end

local function createTouchAttackButton()
    if not UserInputService.TouchEnabled or attackButton and attackButton.Parent then
        return
    end

    local button = Instance.new("TextButton")
    button.Name = "AttackButton"
    button.AnchorPoint = Vector2.new(1, 1)
    button.Position = UDim2.fromScale(0.97, 0.92)
    button.Size = UDim2.fromOffset(144, 52)
    button.BackgroundColor3 = Color3.fromRGB(37, 80, 61)
    button.BackgroundTransparency = 0.04
    button.TextColor3 = Color3.fromRGB(226, 245, 235)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 15
    button.Text = "ATTACK"
    button.AutoButtonColor = true
    button.ZIndex = 20
    button.Parent = getCombatGui()
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(102, 155, 130)
    stroke.Transparency = 0.28
    stroke.Thickness = 1
    stroke.Parent = button
    button.Activated:Connect(performAttack)
    attackButton = button
end

function CombatController.Start()
    createTouchAttackButton()

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.KeyCode == Enum.KeyCode.ButtonR2
        then
            performAttack()
        end
    end)

    local remotes = ReplicatedStorage:WaitForChild(Net.RemoteFolderName, 5)
    if not remotes then
        warn("[CombatController] EverLeafRemotes folder was not found")
        return
    end

    local remote = remotes:WaitForChild(Net.Functions.BasicAttack, 5)
    if not remote or not remote:IsA("RemoteFunction") then
        warn("[CombatController] BasicAttack RemoteFunction was not found")
        return
    end

    attackRemote = remote
end

return CombatController
