local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local ActionClient = require(script.Parent.Parent.Services.ActionClient)
local CatalogClient = require(script.Parent.Parent.Services.CatalogClient)
local ProfileStore = require(script.Parent.Parent.State.ProfileStore)
local Net = require(ReplicatedStorage.Shared.Net)
local ProgressionMath = require(ReplicatedStorage.Shared.Math.ProgressionMath)

local ReactUIController = {}
local player = Players.LocalPlayer
local reactRoot = nil

local COLORS = {
    Panel = Color3.fromRGB(17, 24, 23),
    PanelSoft = Color3.fromRGB(27, 37, 35),
    Border = Color3.fromRGB(91, 129, 113),
    Text = Color3.fromRGB(234, 242, 237),
    Muted = Color3.fromRGB(160, 190, 176),
    Accent = Color3.fromRGB(113, 207, 155),
    Health = Color3.fromRGB(190, 72, 73),
    Mana = Color3.fromRGB(66, 128, 198),
    Exp = Color3.fromRGB(111, 197, 142),
}

local function ratio(value, maximum)
    if type(value) ~= "number" or type(maximum) ~= "number" or maximum <= 0 then
        return 0
    end
    return math.clamp(value / maximum, 0, 1)
end

local function roundedChildren(children, radius, strokeColor)
    local result = table.clone(children or {})
    result.Corner = React.createElement("UICorner", {
        CornerRadius = UDim.new(0, radius or 10),
    })
    if strokeColor then
        result.Stroke = React.createElement("UIStroke", {
            Color = strokeColor,
            Transparency = 0.5,
            Thickness = 1,
        })
    end
    return result
end

local function Panel(props)
    return React.createElement("Frame", {
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = props.Size,
        BackgroundColor3 = props.BackgroundColor3 or COLORS.Panel,
        BackgroundTransparency = props.BackgroundTransparency or 0.1,
        BorderSizePixel = 0,
        Visible = props.Visible ~= false,
        ZIndex = props.ZIndex or 1,
    }, roundedChildren(props.Children, props.Radius, COLORS.Border))
end

local function Label(props)
    return React.createElement("TextLabel", {
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = props.Size,
        BackgroundTransparency = 1,
        Text = props.Text or "",
        TextColor3 = props.Color or COLORS.Text,
        TextSize = props.TextSize or 14,
        Font = props.Bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
        TextXAlignment = props.Align or Enum.TextXAlignment.Left,
        TextYAlignment = props.VerticalAlign or Enum.TextYAlignment.Center,
        TextWrapped = props.Wrapped or false,
        ZIndex = props.ZIndex or 2,
    })
end

local function Bar(props)
    local fraction = ratio(props.Value or 0, props.Maximum or 1)
    return React.createElement(
        "Frame",
        {
            Position = props.Position,
            Size = props.Size,
            BackgroundColor3 = Color3.fromRGB(29, 35, 34),
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 2,
        },
        roundedChildren({
            Fill = React.createElement("Frame", {
                Size = UDim2.fromScale(fraction, 1),
                BackgroundColor3 = props.Color,
                BorderSizePixel = 0,
                ZIndex = 2,
            }, roundedChildren(nil, 6)),
            Text = React.createElement(Label, {
                Position = UDim2.fromScale(0, 0),
                Size = UDim2.fromScale(1, 1),
                Text = props.Text,
                TextSize = 12,
                Bold = true,
                Align = Enum.TextXAlignment.Center,
                ZIndex = 3,
            }),
        }, 6)
    )
end

local function Hotbar(props)
    local catalog = CatalogClient.Get()
    local profile = props.Profile or {}
    local hotbar = profile.Skills and profile.Skills.Hotbar or {}
    local children = {}

    for index = 1, 8 do
        local skillId = hotbar[tostring(index)] or hotbar[index]
        local definition = skillId and catalog and catalog.Skills and catalog.Skills[skillId]
        local displayName = if definition
            then definition.DisplayName
            else if skillId then tostring(skillId) else "—"

        children["Slot" .. index] = React.createElement(
            "Frame",
            {
                Position = UDim2.fromOffset(10 + (index - 1) * 75, 9),
                Size = UDim2.fromOffset(66, 56),
                BackgroundColor3 = COLORS.PanelSoft,
                BorderSizePixel = 0,
            },
            roundedChildren({
                Key = React.createElement(Label, {
                    Position = UDim2.fromOffset(6, 2),
                    Size = UDim2.fromOffset(16, 16),
                    Text = tostring(index),
                    TextSize = 10,
                    Color = COLORS.Muted,
                }),
                Skill = React.createElement(Label, {
                    Position = UDim2.fromOffset(4, 20),
                    Size = UDim2.new(1, -8, 0, 30),
                    Text = displayName,
                    TextSize = 10,
                    Align = Enum.TextXAlignment.Center,
                    Wrapped = true,
                }),
            }, 8)
        )
    end

    return React.createElement(Panel, {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -20),
        Size = UDim2.fromOffset(616, 74),
        Children = children,
    })
end

local function Objective(props)
    local profile = props.Profile or {}
    local active = profile.Quests and profile.Quests.Active
    local title = "Explore Lumenreach"
    local progressText = "Speak with the Lumen Guide"

    if active then
        local questId, state = next(active)
        if questId then
            local catalog = CatalogClient.Get()
            local definition = catalog and catalog.Quests and catalog.Quests[questId]
            title = definition and definition.DisplayName or tostring(questId)
            local objective = definition and definition.Objectives and definition.Objectives[1]
            local progress = state.Progress and state.Progress[1] or 0
            if objective then
                progressText =
                    string.format("Defeat targets: %d / %d", progress, objective.Required or 1)
            end
        end
    end

    return React.createElement(Panel, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 22, 0.5, -20),
        Size = UDim2.fromOffset(318, 92),
        Visible = not props.Hidden,
        Children = {
            Header = React.createElement(Label, {
                Position = UDim2.fromOffset(14, 8),
                Size = UDim2.new(1, -28, 0, 22),
                Text = "OBJECTIVE",
                TextSize = 12,
                Bold = true,
            }),
            Title = React.createElement(Label, {
                Position = UDim2.fromOffset(14, 31),
                Size = UDim2.new(1, -28, 0, 25),
                Text = title,
                TextSize = 15,
            }),
            Progress = React.createElement(Label, {
                Position = UDim2.fromOffset(14, 57),
                Size = UDim2.new(1, -28, 0, 22),
                Text = progressText,
                TextSize = 12,
                Color = COLORS.Muted,
            }),
        },
    })
end

local function HUD(props)
    local profile = props.Profile or {}
    local level = tonumber(profile.Level) or 1
    local exp = tonumber(profile.Exp) or 0
    local needed = ProgressionMath.ExpToNextLevel(level)
    local resources = profile.Resources or {}
    local derived = profile.Derived or {}
    local currencies = profile.Currencies or {}
    local currentMP = tonumber(resources.CurrentMP) or 0
    local maxMP = tonumber(derived.MaxMP) or 1

    return React.createElement(React.Fragment, nil, {
        Status = React.createElement(Panel, {
            Position = UDim2.fromOffset(22, 22),
            Size = UDim2.fromOffset(316, 112),
            Children = {
                Level = React.createElement(Label, {
                    Position = UDim2.fromOffset(18, 8),
                    Size = UDim2.fromOffset(150, 28),
                    Text = string.format("LV. %d", level),
                    TextSize = 18,
                    Bold = true,
                }),
                HP = React.createElement(Bar, {
                    Position = UDim2.fromOffset(18, 42),
                    Size = UDim2.fromOffset(276, 22),
                    Value = props.Health,
                    Maximum = props.MaxHealth,
                    Color = COLORS.Health,
                    Text = string.format(
                        "HP  %d / %d",
                        math.floor(props.Health + 0.5),
                        math.floor(props.MaxHealth + 0.5)
                    ),
                }),
                MP = React.createElement(Bar, {
                    Position = UDim2.fromOffset(18, 72),
                    Size = UDim2.fromOffset(276, 22),
                    Value = currentMP,
                    Maximum = maxMP,
                    Color = COLORS.Mana,
                    Text = string.format("MP  %d / %d", math.floor(currentMP), math.floor(maxMP)),
                }),
            },
        }),
        Currency = React.createElement(Panel, {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -22, 0, 22),
            Size = UDim2.fromOffset(224, 72),
            Children = {
                Shards = React.createElement(Label, {
                    Position = UDim2.fromOffset(14, 8),
                    Size = UDim2.new(1, -28, 0, 26),
                    Text = string.format("◇ %d Shards", tonumber(currencies.Shards) or 0),
                    Align = Enum.TextXAlignment.Right,
                }),
                Marks = React.createElement(Label, {
                    Position = UDim2.fromOffset(14, 36),
                    Size = UDim2.new(1, -28, 0, 26),
                    Text = string.format("✦ %d Marks", tonumber(currencies.Marks) or 0),
                    Align = Enum.TextXAlignment.Right,
                }),
            },
        }),
        Objective = React.createElement(Objective, {
            Profile = profile,
            Hidden = props.DialogueOpen,
        }),
        Exp = React.createElement(
            "Frame",
            {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, -101),
                Size = UDim2.fromOffset(616, 13),
                BackgroundColor3 = Color3.fromRGB(27, 32, 31),
                BorderSizePixel = 0,
                ClipsDescendants = true,
            },
            roundedChildren({
                Fill = React.createElement("Frame", {
                    Size = UDim2.fromScale(ratio(exp, needed), 1),
                    BackgroundColor3 = COLORS.Exp,
                    BorderSizePixel = 0,
                }, roundedChildren(nil, 6)),
            }, 6)
        ),
        ExpText = React.createElement(Label, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -116),
            Size = UDim2.fromOffset(300, 18),
            Text = string.format("EXP %d / %d", exp, needed),
            TextSize = 11,
            Align = Enum.TextXAlignment.Center,
        }),
        Hotbar = React.createElement(Hotbar, {
            Profile = profile,
        }),
    })
end

local function Dialogue(props)
    local description = props.Description
    local status, setStatus = React.useState("E to interact · Left click to attack · Q to dodge")
    if not description then
        return nil
    end

    local questId = description.QuestOffers and description.QuestOffers[1]

    local function acceptQuest()
        if not questId then
            return
        end
        local ok, result = ActionClient.Invoke("quest.start", {
            NpcId = description.NpcId,
            QuestId = questId,
        })
        setStatus(if ok then "Quest accepted." else string.format("Quest: %s", tostring(result)))
    end

    local function buyTonic()
        if not description.ShopId then
            return
        end
        local ok, result = ActionClient.Invoke("shop.buy", {
            ShopId = description.ShopId,
            ItemId = "small_tonic",
            Quantity = 1,
        })
        setStatus(
            if ok then "Small Tonic purchased." else string.format("Shop: %s", tostring(result))
        )
    end

    local buttonChildren = {}
    if questId then
        buttonChildren.Quest = React.createElement("TextButton", {
            Position = UDim2.fromOffset(22, 166),
            Size = UDim2.fromOffset(250, 48),
            BackgroundColor3 = Color3.fromRGB(45, 65, 61),
            BorderSizePixel = 0,
            Text = "ACCEPT QUEST",
            TextColor3 = COLORS.Text,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = true,
            [React.Event.Activated] = acceptQuest,
        }, roundedChildren(nil, 9))
    end
    if description.ShopId then
        buttonChildren.Shop = React.createElement("TextButton", {
            Position = UDim2.fromOffset(286, 166),
            Size = UDim2.fromOffset(272, 48),
            BackgroundColor3 = Color3.fromRGB(45, 65, 61),
            BorderSizePixel = 0,
            Text = "BUY SMALL TONIC · 2 SHARDS",
            TextColor3 = COLORS.Text,
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = true,
            [React.Event.Activated] = buyTonic,
        }, roundedChildren(nil, 9))
    end

    return React.createElement(Panel, {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.fromScale(0.5, 0.72),
        Size = UDim2.fromOffset(580, 236),
        ZIndex = 20,
        Children = {
            Title = React.createElement(Label, {
                Position = UDim2.fromOffset(22, 14),
                Size = UDim2.new(1, -92, 0, 34),
                Text = description.DisplayName or "Traveler",
                TextSize = 24,
                Bold = true,
                Color = Color3.fromRGB(196, 236, 211),
                ZIndex = 21,
            }),
            Close = React.createElement("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -16, 0, 14),
                Size = UDim2.fromOffset(42, 36),
                BackgroundColor3 = Color3.fromRGB(47, 53, 52),
                BorderSizePixel = 0,
                Text = "×",
                TextColor3 = COLORS.Text,
                TextSize = 22,
                Font = Enum.Font.GothamBold,
                ZIndex = 22,
                [React.Event.Activated] = props.OnClose,
            }, roundedChildren(nil, 8)),
            Body = React.createElement(Label, {
                Position = UDim2.fromOffset(22, 55),
                Size = UDim2.new(1, -44, 0, 68),
                Text = "The grove beyond the camp is stirring. Test your strength there, then return when you're ready to travel deeper into Lumenreach.",
                TextSize = 16,
                Wrapped = true,
                VerticalAlign = Enum.TextYAlignment.Top,
                ZIndex = 21,
            }),
            Status = React.createElement(Label, {
                Position = UDim2.fromOffset(22, 126),
                Size = UDim2.new(1, -44, 0, 26),
                Text = status,
                TextSize = 13,
                Color = COLORS.Muted,
                ZIndex = 21,
            }),
            Buttons = React.createElement(React.Fragment, nil, buttonChildren),
        },
    })
end

local function App()
    local profile, setProfile = React.useState(ProfileStore.Get())
    local interaction, setInteraction = React.useState(nil)
    local health, setHealth = React.useState(100)
    local maxHealth, setMaxHealth = React.useState(100)

    React.useEffect(function()
        local connection = ProfileStore.Subscribe(setProfile)
        return function()
            connection:Disconnect()
        end
    end, {})

    React.useEffect(function()
        local healthConnection = nil
        local maxConnection = nil

        local function bindCharacter(character)
            if healthConnection then
                healthConnection:Disconnect()
            end
            if maxConnection then
                maxConnection:Disconnect()
            end
            local humanoid = character:WaitForChild("Humanoid")
            setHealth(humanoid.Health)
            setMaxHealth(humanoid.MaxHealth)
            healthConnection = humanoid.HealthChanged:Connect(setHealth)
            maxConnection = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
                setMaxHealth(humanoid.MaxHealth)
            end)
        end

        local characterConnection = player.CharacterAdded:Connect(bindCharacter)
        if player.Character then
            task.spawn(bindCharacter, player.Character)
        end

        return function()
            characterConnection:Disconnect()
            if healthConnection then
                healthConnection:Disconnect()
            end
            if maxConnection then
                maxConnection:Disconnect()
            end
        end
    end, {})

    React.useEffect(function()
        local remotes = ReplicatedStorage:FindFirstChild(Net.RemoteFolderName)
        local remote = remotes and remotes:FindFirstChild(Net.Events.InteractionEvent)
        if not remote or not remote:IsA("RemoteEvent") then
            warn("[ReactUI] InteractionEvent was not found")
            return nil
        end

        local connection = remote.OnClientEvent:Connect(function(eventName, payload)
            if eventName == "open" and type(payload) == "table" then
                setInteraction(payload)
            end
        end)
        return function()
            connection:Disconnect()
        end
    end, {})

    React.useEffect(function()
        player:SetAttribute("EverLeafUiCapture", interaction ~= nil)
        return function()
            player:SetAttribute("EverLeafUiCapture", false)
        end
    end, { interaction })

    React.useEffect(function()
        local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if
                not gameProcessed
                and input.KeyCode == Enum.KeyCode.Escape
                and interaction ~= nil
            then
                setInteraction(nil)
            end
        end)
        return function()
            connection:Disconnect()
        end
    end, { interaction })

    return React.createElement("ScreenGui", {
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        DisplayOrder = 10,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, {
        HUD = React.createElement(HUD, {
            Profile = profile,
            Health = health,
            MaxHealth = maxHealth,
            DialogueOpen = interaction ~= nil,
        }),
        Dialogue = interaction and React.createElement(Dialogue, {
            Description = interaction,
            OnClose = function()
                setInteraction(nil)
            end,
        }) or nil,
    })
end

function ReactUIController.Start()
    local playerGui = player:WaitForChild("PlayerGui")
    local existing = playerGui:FindFirstChild("EverLeafReactMount")
    if existing then
        existing:Destroy()
    end

    local mount = Instance.new("Folder")
    mount.Name = "EverLeafReactMount"
    mount.Parent = playerGui

    reactRoot = ReactRoblox.createRoot(mount)
    reactRoot:render(React.createElement(App))
end

return ReactUIController
