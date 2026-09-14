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
    no_target = "No enemy in range",
    out_of_range = "Move closer",
    out_of_depth = "Target is off the combat plane",
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
    label.Position = UDim2.fromScale(0.5, 0.88)
    label.Size = UDim2.fromOffset(360, 42)
    label.BackgroundTransparency = 0.25
    label.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.65
    label.Font = Enum.Font.GothamBold
    label.TextSize = 20
    label.Visible = false
    label.ZIndex = 20
    label.Parent = getCombatGui()

    feedbackLabel = label
    return label
end

local function showFeedback(text)
    feedbackGeneration += 1
    local generation = feedbackGeneration
    local label = getFeedbackLabel()
    label.Text = text
    label.Visible = true

    task.delay(0.9, function()
        if generation == feedbackGeneration and label.Parent then
            label.Visible = false
        end
    end)
end

local function playPrototypePunch()
    local character = player.Character
    if not character then
        return
    end

    local shoulder = character:FindFirstChild("RightShoulder", true)
    if not shoulder or not shoulder:IsA("Motor6D") then
        return
    end

    local original = shoulder.Transform
    local forward = original * CFrame.Angles(math.rad(-55), 0, math.rad(10))
    local outTween = TweenService:Create(
        shoulder,
        TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Transform = forward }
    )
    local backTween = TweenService:Create(
        shoulder,
        TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Transform = original }
    )

    outTween:Play()
    outTween.Completed:Once(function()
        backTween:Play()
    end)
end

local function performAttack()
    if attacking or not attackRemote then
        return
    end
    if GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() then
        return
    end

    attacking = true
    playPrototypePunch()

    task.spawn(function()
        local invokeOk, attackOk, resultOrReason = pcall(function()
            return attackRemote:InvokeServer()
        end)

        if not invokeOk then
            showFeedback("Attack request failed")
        elseif not attackOk then
            showFeedback(reasonText[resultOrReason] or tostring(resultOrReason))
        else
            local damage = resultOrReason and resultOrReason.Damage
            if damage then
                showFeedback(string.format("Hit for %d", damage))
            else
                showFeedback("Hit")
            end
        end

        task.delay(0.12, function()
            attacking = false
        end)
    end)
end

local function createAttackButton()
    if attackButton and attackButton.Parent then
        return
    end

    local button = Instance.new("TextButton")
    button.Name = "AttackButton"
    button.AnchorPoint = Vector2.new(1, 1)
    button.Position = UDim2.fromScale(0.97, 0.92)
    button.Size = UDim2.fromOffset(160, 54)
    button.BackgroundColor3 = Color3.fromRGB(31, 35, 45)
    button.BackgroundTransparency = 0.08
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 18
    button.Text = "ATTACK  [Z]"
    button.AutoButtonColor = true
    button.ZIndex = 20
    button.Parent = getCombatGui()
    button.Activated:Connect(performAttack)

    attackButton = button
end

function CombatController.Start()
    local remotes = ReplicatedStorage:WaitForChild(Net.RemoteFolderName)
    attackRemote = remotes:WaitForChild(Net.Functions.BasicAttack)

    createAttackButton()

    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Z or input.KeyCode == Enum.KeyCode.ButtonR2 then
            performAttack()
        end
    end)
end

return CombatController
