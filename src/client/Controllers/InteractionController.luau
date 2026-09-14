local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ActionClient = require(script.Parent.Parent.Services.ActionClient)
local Net = require(ReplicatedStorage.Shared.Net)

local InteractionController = {}

local player = Players.LocalPlayer
local panel = nil
local titleLabel = nil
local bodyLabel = nil
local statusLabel = nil
local questButton = nil
local shopButton = nil
local currentDescription = nil

local function styleButton(button)
    button.BackgroundColor3 = Color3.fromRGB(45, 65, 61)
    button.BackgroundTransparency = 0.05
    button.TextColor3 = Color3.fromRGB(234, 246, 238)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 15
    button.AutoButtonColor = true
end

local function ensureGui()
    if panel and panel.Parent then
        return panel
    end

    local playerGui = player:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "EverLeafInteractionGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "DialoguePanel"
    frame.AnchorPoint = Vector2.new(0.5, 1)
    frame.Position = UDim2.fromScale(0.5, 0.96)
    frame.Size = UDim2.fromOffset(580, 236)
    frame.BackgroundColor3 = Color3.fromRGB(19, 26, 25)
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(103, 151, 131)
    stroke.Transparency = 0.35
    stroke.Thickness = 1.5
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Position = UDim2.fromOffset(22, 16)
    title.Size = UDim2.new(1, -92, 0, 32)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(196, 236, 211)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.Parent = frame

    local close = Instance.new("TextButton")
    close.Name = "Close"
    close.AnchorPoint = Vector2.new(1, 0)
    close.Position = UDim2.new(1, -16, 0, 14)
    close.Size = UDim2.fromOffset(42, 36)
    close.BackgroundColor3 = Color3.fromRGB(47, 53, 52)
    close.Text = "×"
    close.TextColor3 = Color3.new(1, 1, 1)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 24
    close.Parent = frame
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)
    close.Activated:Connect(function()
        frame.Visible = false
        currentDescription = nil
    end)

    local body = Instance.new("TextLabel")
    body.Name = "Body"
    body.Position = UDim2.fromOffset(22, 56)
    body.Size = UDim2.new(1, -44, 0, 62)
    body.BackgroundTransparency = 1
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.TextColor3 = Color3.fromRGB(222, 229, 224)
    body.Font = Enum.Font.Gotham
    body.TextSize = 16
    body.Parent = frame

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Position = UDim2.fromOffset(22, 122)
    status.Size = UDim2.new(1, -44, 0, 24)
    status.BackgroundTransparency = 1
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextColor3 = Color3.fromRGB(159, 207, 187)
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 14
    status.Parent = frame

    local quest = Instance.new("TextButton")
    quest.Name = "QuestButton"
    quest.Position = UDim2.fromOffset(22, 164)
    quest.Size = UDim2.fromOffset(250, 48)
    quest.Text = "ACCEPT QUEST"
    styleButton(quest)
    quest.Parent = frame
    Instance.new("UICorner", quest).CornerRadius = UDim.new(0, 9)

    local shop = Instance.new("TextButton")
    shop.Name = "ShopButton"
    shop.Position = UDim2.fromOffset(286, 164)
    shop.Size = UDim2.fromOffset(272, 48)
    shop.Text = "BUY SMALL TONIC · 2 SHARDS"
    styleButton(shop)
    shop.Parent = frame
    Instance.new("UICorner", shop).CornerRadius = UDim.new(0, 9)

    quest.Activated:Connect(function()
        local description = currentDescription
        local questId = description and description.QuestOffers and description.QuestOffers[1]
        if not questId then
            return
        end
        local ok, result = ActionClient.Invoke("quest.start", {
            NpcId = description.NpcId,
            QuestId = questId,
        })
        status.Text = if ok then "Quest accepted." else string.format("Quest: %s", tostring(result))
    end)

    shop.Activated:Connect(function()
        local description = currentDescription
        if not description or not description.ShopId then
            return
        end
        local ok, result = ActionClient.Invoke("shop.buy", {
            ShopId = description.ShopId,
            ItemId = "small_tonic",
            Quantity = 1,
        })
        status.Text = if ok
            then "Small Tonic purchased."
            else string.format("Shop: %s", tostring(result))
    end)

    panel = frame
    titleLabel = title
    bodyLabel = body
    statusLabel = status
    questButton = quest
    shopButton = shop
    return frame
end

local function showInteraction(description)
    local frame = ensureGui()
    currentDescription = description

    titleLabel.Text = description.DisplayName or "Traveler"
    bodyLabel.Text =
        "The grove beyond the camp is stirring. Test your strength there, then return when you're ready to travel deeper into Lumenreach."
    statusLabel.Text = "E to interact · Left click to attack · Q to dodge"
    questButton.Visible = description.QuestOffers ~= nil and #description.QuestOffers > 0
    shopButton.Visible = description.ShopId ~= nil and description.ShopId ~= ""
    frame.Visible = true
end

function InteractionController.Start()
    ensureGui()
    local remotes = ReplicatedStorage:WaitForChild(Net.RemoteFolderName, 5)
    if not remotes then
        warn("[InteractionController] EverLeafRemotes was not found")
        return
    end

    local remote = remotes:WaitForChild(Net.Events.InteractionEvent, 5)
    if not remote or not remote:IsA("RemoteEvent") then
        warn("[InteractionController] InteractionEvent was not found")
        return
    end

    remote.OnClientEvent:Connect(function(eventName, payload)
        if eventName == "open" and type(payload) == "table" then
            showInteraction(payload)
        end
    end)
end

return InteractionController
