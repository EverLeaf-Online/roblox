local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Net = require(ReplicatedStorage.Shared.Net)
local ProfileStore = require(script.Parent.Parent.State.ProfileStore)
local CombatPresentation = require(script.Parent.Parent.Presentation.CombatPresentation)

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
    local profile = ProfileStore.Get()
    local familyId = profile and profile.FamilyId or ""
    local animationEndsAt = os.clock() + CombatPresentation.GetBasicAttackDuration(familyId)
    faceCameraDirection()
    CombatPresentation.PlayBasicAttack(familyId)

    task.spawn(function()
        local invokeOk, attackOk, resultOrReason = pcall(function()
            return attackRemote:InvokeServer()
        end)

        if not invokeOk then
            showFeedback("Attack request failed", "warning")
        elseif not attackOk then
            showFeedback(reasonText[resultOrReason] or tostring(resultOrReason), "warning")
        else
            local result = resultOrReason or {}
            CombatPresentation.PlayHit(familyId, result.TargetPosition, result.Dodged == true)
            local damage = result.Damage
            if result.Dodged == true then
                showFeedback("Enemy dodged", "warning")
            elseif damage then
                if result.Critical == true then
                    showFeedback(string.format("Critical · %d damage", damage), "success")
                else
                    showFeedback(string.format("Hit · %d damage", damage), "success")
                end
            else
                showFeedback("Hit", "success")
            end
        end

        task.delay(math.max(0, animationEndsAt - os.clock()), function()
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
