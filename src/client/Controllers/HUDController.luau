local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CatalogClient = require(script.Parent.Parent.Services.CatalogClient)
local ProfileStore = require(script.Parent.Parent.State.ProfileStore)
local ProgressionMath = require(ReplicatedStorage.Shared.Math.ProgressionMath)

local HUDController = {}

local player = Players.LocalPlayer
local view = nil
local healthConnection = nil
local maxHealthConnection = nil
local currentHumanoid = nil
local latestProfile = nil

local function makeText(parent, name, text, size, position, textSize, alignment)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(235, 241, 237)
    label.TextStrokeTransparency = 0.78
    label.Font = Enum.Font.GothamMedium
    label.TextSize = textSize
    label.TextXAlignment = alignment or Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function makePanel(parent, name, size, position, anchor)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.AnchorPoint = anchor or Vector2.zero
    frame.BackgroundColor3 = Color3.fromRGB(16, 23, 22)
    frame.BackgroundTransparency = 0.16
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(91, 129, 113)
    stroke.Transparency = 0.5
    stroke.Thickness = 1
    stroke.Parent = frame
    return frame
end

local function makeBar(parent, name, position, color)
    local track = Instance.new("Frame")
    track.Name = name
    track.Position = position
    track.Size = UDim2.fromOffset(276, 22)
    track.BackgroundColor3 = Color3.fromRGB(28, 33, 33)
    track.BorderSizePixel = 0
    track.ClipsDescendants = true
    track.Parent = parent
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, 6)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 6)

    local text = makeText(
        track,
        "Value",
        "",
        UDim2.fromScale(1, 1),
        UDim2.fromScale(0, 0),
        13,
        Enum.TextXAlignment.Center
    )
    text.Font = Enum.Font.GothamBold
    text.ZIndex = 3
    return track, fill, text
end

local function ensureView()
    if view and view.Gui and view.Gui.Parent then
        return view
    end

    local playerGui = player:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "EverLeafHUD"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.DisplayOrder = 5
    gui.Parent = playerGui

    local statusPanel =
        makePanel(gui, "StatusPanel", UDim2.fromOffset(316, 112), UDim2.fromOffset(22, 22))
    local level = makeText(
        statusPanel,
        "Level",
        "LV. 1",
        UDim2.fromOffset(120, 26),
        UDim2.fromOffset(18, 10),
        18
    )
    level.Font = Enum.Font.GothamBold
    local hpTrack, hpFill, hpText =
        makeBar(statusPanel, "HP", UDim2.fromOffset(18, 43), Color3.fromRGB(185, 70, 71))
    local mpTrack, mpFill, mpText =
        makeBar(statusPanel, "MP", UDim2.fromOffset(18, 73), Color3.fromRGB(63, 126, 194))

    local currencyPanel = makePanel(
        gui,
        "CurrencyPanel",
        UDim2.fromOffset(224, 72),
        UDim2.new(1, -22, 0, 22),
        Vector2.new(1, 0)
    )
    local shards = makeText(
        currencyPanel,
        "Shards",
        "◇ 0 Shards",
        UDim2.new(1, -28, 0, 26),
        UDim2.fromOffset(14, 9),
        15,
        Enum.TextXAlignment.Right
    )
    local marks = makeText(
        currencyPanel,
        "Marks",
        "✦ 0 Marks",
        UDim2.new(1, -28, 0, 26),
        UDim2.fromOffset(14, 37),
        15,
        Enum.TextXAlignment.Right
    )

    local questPanel = makePanel(
        gui,
        "QuestPanel",
        UDim2.fromOffset(318, 92),
        UDim2.new(0, 22, 0.5, -20),
        Vector2.new(0, 0.5)
    )
    makeText(
        questPanel,
        "Header",
        "OBJECTIVE",
        UDim2.new(1, -28, 0, 24),
        UDim2.fromOffset(14, 10),
        13
    ).Font =
        Enum.Font.GothamBold
    local questTitle = makeText(
        questPanel,
        "QuestTitle",
        "Explore Lumenreach",
        UDim2.new(1, -28, 0, 24),
        UDim2.fromOffset(14, 34),
        15
    )
    local questProgress = makeText(
        questPanel,
        "QuestProgress",
        "Speak with the Lumen Guide",
        UDim2.new(1, -28, 0, 24),
        UDim2.fromOffset(14, 59),
        13
    )
    questProgress.TextColor3 = Color3.fromRGB(166, 199, 184)

    local hotbar = makePanel(
        gui,
        "Hotbar",
        UDim2.fromOffset(616, 74),
        UDim2.new(0.5, 0, 1, -22),
        Vector2.new(0.5, 1)
    )
    local hotbarSlots = {}
    for index = 1, 8 do
        local slot = Instance.new("Frame")
        slot.Name = string.format("Slot%d", index)
        slot.Position = UDim2.fromOffset(10 + (index - 1) * 75, 9)
        slot.Size = UDim2.fromOffset(66, 56)
        slot.BackgroundColor3 = Color3.fromRGB(31, 41, 39)
        slot.BorderSizePixel = 0
        slot.Parent = hotbar
        Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 8)

        local key = makeText(
            slot,
            "Key",
            tostring(index),
            UDim2.fromOffset(18, 18),
            UDim2.fromOffset(5, 3),
            11
        )
        key.TextColor3 = Color3.fromRGB(153, 185, 169)
        local skill = makeText(
            slot,
            "Skill",
            "—",
            UDim2.new(1, -8, 0, 28),
            UDim2.fromOffset(4, 22),
            11,
            Enum.TextXAlignment.Center
        )
        skill.TextWrapped = true
        hotbarSlots[index] = skill
    end

    local expTrack = Instance.new("Frame")
    expTrack.Name = "ExpBar"
    expTrack.AnchorPoint = Vector2.new(0.5, 1)
    expTrack.Position = UDim2.new(0.5, 0, 1, -101)
    expTrack.Size = UDim2.fromOffset(616, 13)
    expTrack.BackgroundColor3 = Color3.fromRGB(27, 32, 31)
    expTrack.BorderSizePixel = 0
    expTrack.ClipsDescendants = true
    expTrack.Parent = gui
    Instance.new("UICorner", expTrack).CornerRadius = UDim.new(0, 6)

    local expFill = Instance.new("Frame")
    expFill.Name = "Fill"
    expFill.Size = UDim2.fromScale(0, 1)
    expFill.BackgroundColor3 = Color3.fromRGB(111, 197, 142)
    expFill.BorderSizePixel = 0
    expFill.Parent = expTrack
    Instance.new("UICorner", expFill).CornerRadius = UDim.new(0, 6)

    local expText = makeText(
        gui,
        "ExpText",
        "EXP 0 / 75",
        UDim2.fromOffset(300, 18),
        UDim2.new(0.5, 0, 1, -118),
        12,
        Enum.TextXAlignment.Center
    )
    expText.AnchorPoint = Vector2.new(0.5, 1)

    local controls = makeText(
        gui,
        "Controls",
        "LMB Attack   ·   Q Dodge   ·   Shift Sprint   ·   E Interact",
        UDim2.fromOffset(520, 20),
        UDim2.new(0.5, 0, 1, -184),
        12,
        Enum.TextXAlignment.Center
    )
    controls.AnchorPoint = Vector2.new(0.5, 1)
    controls.TextColor3 = Color3.fromRGB(179, 194, 185)

    view = {
        Gui = gui,
        Level = level,
        HPTrack = hpTrack,
        HPFill = hpFill,
        HPText = hpText,
        MPTrack = mpTrack,
        MPFill = mpFill,
        MPText = mpText,
        Shards = shards,
        Marks = marks,
        QuestTitle = questTitle,
        QuestProgress = questProgress,
        HotbarSlots = hotbarSlots,
        ExpFill = expFill,
        ExpText = expText,
    }
    return view
end

local function ratio(value, maximum)
    if type(value) ~= "number" or type(maximum) ~= "number" or maximum <= 0 then
        return 0
    end
    return math.clamp(value / maximum, 0, 1)
end

local function updateHealth()
    local ui = ensureView()
    local humanoid = currentHumanoid
    local health = humanoid and humanoid.Health or 0
    local maximum = humanoid and humanoid.MaxHealth or 1
    ui.HPFill.Size = UDim2.fromScale(ratio(health, maximum), 1)
    ui.HPText.Text =
        string.format("HP  %d / %d", math.floor(health + 0.5), math.floor(maximum + 0.5))
end

local function attachCharacter(character)
    if healthConnection then
        healthConnection:Disconnect()
        healthConnection = nil
    end
    if maxHealthConnection then
        maxHealthConnection:Disconnect()
        maxHealthConnection = nil
    end
    currentHumanoid = character:WaitForChild("Humanoid")
    healthConnection = currentHumanoid.HealthChanged:Connect(updateHealth)
    maxHealthConnection =
        currentHumanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
    updateHealth()
end

local function renderQuest(profile)
    local ui = ensureView()
    local active = profile.Quests and profile.Quests.Active
    if not active then
        ui.QuestTitle.Text = "Explore Lumenreach"
        ui.QuestProgress.Text = "Speak with the Lumen Guide"
        return
    end

    local questId, state = next(active)
    if not questId then
        ui.QuestTitle.Text = "Explore Lumenreach"
        ui.QuestProgress.Text = "Speak with the Lumen Guide"
        return
    end

    local catalog = CatalogClient.Get()
    local definition = catalog and catalog.Quests and catalog.Quests[questId]
    ui.QuestTitle.Text = definition and definition.DisplayName or tostring(questId)

    local objective = definition and definition.Objectives and definition.Objectives[1]
    local progress = state.Progress and state.Progress[1] or 0
    if objective then
        ui.QuestProgress.Text =
            string.format("Defeat targets: %d / %d", progress, objective.Required or 1)
    else
        ui.QuestProgress.Text = string.format("Progress: %d", progress)
    end
end

local function renderHotbar(profile)
    local ui = ensureView()
    local catalog = CatalogClient.Get()
    local hotbar = profile.Skills and profile.Skills.Hotbar or {}
    for index = 1, 8 do
        local skillId = hotbar[tostring(index)] or hotbar[index]
        local definition = skillId and catalog and catalog.Skills and catalog.Skills[skillId]
        ui.HotbarSlots[index].Text = if definition
            then definition.DisplayName
            else if skillId then tostring(skillId) else "—"
    end
end

local function renderProfile(profile)
    if type(profile) ~= "table" then
        return
    end
    latestProfile = profile
    local ui = ensureView()

    local level = tonumber(profile.Level) or 1
    local exp = tonumber(profile.Exp) or 0
    local needed = ProgressionMath.ExpToNextLevel(level)
    ui.Level.Text = string.format("LV. %d", level)
    ui.ExpFill.Size = UDim2.fromScale(ratio(exp, needed), 1)
    ui.ExpText.Text = string.format("EXP %d / %d", exp, needed)

    local resources = profile.Resources or {}
    local derived = profile.Derived or {}
    local currentMP = tonumber(resources.CurrentMP) or 0
    local maxMP = tonumber(derived.MaxMP) or 1
    ui.MPFill.Size = UDim2.fromScale(ratio(currentMP, maxMP), 1)
    ui.MPText.Text = string.format("MP  %d / %d", math.floor(currentMP), math.floor(maxMP))

    local currencies = profile.Currencies or {}
    ui.Shards.Text = string.format("◇ %d Shards", tonumber(currencies.Shards) or 0)
    ui.Marks.Text = string.format("✦ %d Marks", tonumber(currencies.Marks) or 0)

    renderQuest(profile)
    renderHotbar(profile)
    updateHealth()
end

function HUDController.Start()
    ensureView()
    player.CharacterAdded:Connect(attachCharacter)
    if player.Character then
        task.spawn(attachCharacter, player.Character)
    end

    ProfileStore.Subscribe(renderProfile)
    task.delay(1.5, function()
        if latestProfile then
            renderProfile(latestProfile)
        end
    end)
end

return HUDController
