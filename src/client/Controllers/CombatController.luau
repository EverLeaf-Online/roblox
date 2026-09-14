local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)

local CombatController = {}
local player = Players.LocalPlayer
local feedbackGeneration = 0
local feedbackLabel = nil

local reasonText = {
    cooldown = "Attack is on cooldown",
    out_of_range = "Move closer",
    out_of_depth = "Target is off the combat plane",
    target_unavailable = "Target is unavailable",
    character_unavailable = "Character is unavailable",
    rate_limited = "Slow down",
}

local function getFeedbackLabel()
    if feedbackLabel and feedbackLabel.Parent then
        return feedbackLabel
    end

    local playerGui = player:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "EverLeafCombatFeedback"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = playerGui

    local label = Instance.new("TextLabel")
    label.Name = "Message"
    label.AnchorPoint = Vector2.new(0.5, 1)
    label.Position = UDim2.fromScale(0.5, 0.88)
    label.Size = UDim2.fromOffset(360, 42)
    label.BackgroundTransparency = 0.35
    label.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.65
    label.Font = Enum.Font.GothamBold
    label.TextSize = 20
    label.Visible = false
    label.Parent = gui

    feedbackLabel = label
    return label
end

local function showFeedback(text)
    feedbackGeneration += 1
    local generation = feedbackGeneration
    local label = getFeedbackLabel()
    label.Text = text
    label.Visible = true

    task.delay(0.75, function()
        if generation == feedbackGeneration and label.Parent then
            label.Visible = false
        end
    end)
end

local function findNearestEnemy()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil
    end

    local nearest = nil
    local nearestDistance = math.huge
    for _, enemy in CollectionService:GetTagged("EverLeafEnemy") do
        if enemy:IsA("Model") then
            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
            if enemyRoot then
                local delta = enemyRoot.Position - root.Position
                local distance = Vector2.new(delta.X, delta.Y).Magnitude
                if
                    distance < nearestDistance
                    and distance <= GameConfig.Combat.BasicAttackRange
                then
                    nearest = enemy
                    nearestDistance = distance
                end
            end
        end
    end
    return nearest
end

function CombatController.Start()
    local remotes = ReplicatedStorage:WaitForChild(Net.RemoteFolderName)
    local basicAttack = remotes:WaitForChild(Net.Functions.BasicAttack)

    ContextActionService:BindAction(
        "EverLeafBasicAttack",
        function(_, inputState)
            if inputState ~= Enum.UserInputState.Begin then
                return Enum.ContextActionResult.Sink
            end

            local target = findNearestEnemy()
            if not target then
                showFeedback("No enemy in range")
                return Enum.ContextActionResult.Sink
            end

            task.spawn(function()
                local invokeOk, attackOk, resultOrReason = pcall(function()
                    return basicAttack:InvokeServer(target)
                end)

                if not invokeOk then
                    showFeedback("Attack request failed")
                    return
                end

                if not attackOk then
                    showFeedback(reasonText[resultOrReason] or tostring(resultOrReason))
                    return
                end

                local damage = resultOrReason and resultOrReason.Damage
                if damage then
                    showFeedback(string.format("Hit for %d", damage))
                else
                    showFeedback("Hit")
                end
            end)

            return Enum.ContextActionResult.Sink
        end,
        true,
        Enum.KeyCode.LeftControl,
        Enum.KeyCode.RightControl,
        Enum.KeyCode.F,
        Enum.KeyCode.ButtonR2
    )

    ContextActionService:SetTitle("EverLeafBasicAttack", "Attack")
    ContextActionService:SetPosition("EverLeafBasicAttack", UDim2.fromScale(0.78, 0.78))
end

return CombatController
