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

local COLORS = table.freeze({
    Backdrop = Color3.fromRGB(5, 10, 9),
    PanelDeep = Color3.fromRGB(13, 20, 19),
    Panel = Color3.fromRGB(18, 28, 26),
    PanelRaised = Color3.fromRGB(24, 37, 34),
    Surface = Color3.fromRGB(31, 46, 42),
    SurfaceHover = Color3.fromRGB(39, 59, 52),
    Border = Color3.fromRGB(69, 108, 91),
    BorderStrong = Color3.fromRGB(102, 155, 130),
    Text = Color3.fromRGB(239, 246, 242),
    Muted = Color3.fromRGB(154, 181, 168),
    Faint = Color3.fromRGB(103, 128, 116),
    Accent = Color3.fromRGB(102, 211, 154),
    AccentSoft = Color3.fromRGB(54, 111, 83),
    AccentDark = Color3.fromRGB(37, 80, 61),
    Lumen = Color3.fromRGB(121, 244, 183),
    LumenPale = Color3.fromRGB(205, 255, 229),
    Bark = Color3.fromRGB(68, 50, 36),
    BarkLight = Color3.fromRGB(104, 78, 52),
    Moss = Color3.fromRGB(58, 103, 72),
    Health = Color3.fromRGB(207, 78, 81),
    Mana = Color3.fromRGB(72, 135, 218),
    Exp = Color3.fromRGB(102, 211, 154),
    Gold = Color3.fromRGB(232, 193, 105),
    Purple = Color3.fromRGB(177, 137, 224),
    Warning = Color3.fromRGB(231, 165, 87),
    Danger = Color3.fromRGB(214, 91, 91),
})

local HOTKEYS = table.freeze({
    CHARACTER = "C",
    INVENTORY = "I",
    SKILLS = "K",
    QUESTS = "J",
    SETTINGS = "M",
})

local function ratio(value, maximum)
    if type(value) ~= "number" or type(maximum) ~= "number" or maximum <= 0 then
        return 0
    end
    return math.clamp(value / maximum, 0, 1)
end

local function withChrome(children, radius, strokeColor, strokeTransparency, thickness)
    local result = table.clone(children or {})
    result.Corner = React.createElement("UICorner", {
        CornerRadius = UDim.new(0, radius or 10),
    })
    if strokeColor then
        result.Stroke = React.createElement("UIStroke", {
            Color = strokeColor,
            Transparency = strokeTransparency or 0.38,
            Thickness = thickness or 1,
        })
    end
    return result
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
        TextTransparency = props.TextTransparency or 0,
        Visible = props.Visible ~= false,
        ZIndex = props.ZIndex or 2,
    })
end

local function Panel(props)
    local children = table.clone(props.Children or {})
    children.SurfaceGradient = React.createElement("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(29, 45, 40)),
            ColorSequenceKeypoint.new(0.48, props.BackgroundColor3 or COLORS.Panel),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 18, 17)),
        }),
        Rotation = 110,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.08),
            NumberSequenceKeypoint.new(0.55, 0.22),
            NumberSequenceKeypoint.new(1, 0.04),
        }),
    })
    if props.Ornamented then
        children.TopEtch = React.createElement("Frame", {
            Position = UDim2.fromOffset(14, 7),
            Size = UDim2.new(1, -28, 0, 1),
            BackgroundColor3 = props.OrnamentColor or COLORS.Lumen,
            BackgroundTransparency = 0.62,
            BorderSizePixel = 0,
            ZIndex = (props.ZIndex or 1) + 1,
        })
        children.BottomEtch = React.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 14, 1, -7),
            Size = UDim2.new(1, -28, 0, 1),
            BackgroundColor3 = props.OrnamentColor or COLORS.Lumen,
            BackgroundTransparency = 0.78,
            BorderSizePixel = 0,
            ZIndex = (props.ZIndex or 1) + 1,
        })
    end
    return React.createElement(
        "Frame",
        {
            AnchorPoint = props.AnchorPoint,
            Position = props.Position,
            Size = props.Size,
            BackgroundColor3 = props.BackgroundColor3 or COLORS.Panel,
            BackgroundTransparency = props.BackgroundTransparency or 0.04,
            BorderSizePixel = 0,
            Visible = props.Visible ~= false,
            ClipsDescendants = props.ClipsDescendants or false,
            ZIndex = props.ZIndex or 1,
        },
        withChrome(
            children,
            props.Radius or 12,
            props.StrokeColor or COLORS.Border,
            props.StrokeTransparency or 0.35,
            props.StrokeThickness or 1
        )
    )
end

local function Button(props)
    local active = props.Active ~= false
    local background = props.BackgroundColor3
        or if props.Tone == "accent"
            then COLORS.AccentDark
            else if props.Tone == "danger" then Color3.fromRGB(91, 45, 46) else COLORS.Surface
    local children = {
        Gradient = React.createElement("UIGradient", {
            Color = ColorSequence.new(background:Lerp(Color3.new(1, 1, 1), 0.08), background),
            Rotation = 90,
            Transparency = NumberSequence.new(0.06),
        }),
        Edge = React.createElement("Frame", {
            Position = UDim2.fromOffset(7, 4),
            Size = UDim2.new(1, -14, 0, 1),
            BackgroundColor3 = props.Tone == "accent" and COLORS.Lumen or COLORS.BorderStrong,
            BackgroundTransparency = active and 0.55 or 0.85,
            BorderSizePixel = 0,
            ZIndex = (props.ZIndex or 4) + 1,
        }),
    }
    return React.createElement("TextButton", {
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = props.Size,
        BackgroundColor3 = background,
        BackgroundTransparency = active and 0 or 0.32,
        BorderSizePixel = 0,
        Text = props.Text or "",
        TextColor3 = active and (props.TextColor3 or COLORS.Text) or COLORS.Faint,
        TextSize = props.TextSize or 12,
        TextWrapped = props.Wrapped or false,
        Font = props.Bold == false and Enum.Font.GothamMedium or Enum.Font.GothamBold,
        AutoButtonColor = active,
        Active = active,
        Selectable = active,
        ZIndex = props.ZIndex or 4,
        [React.Event.Activated] = if active then props.OnActivated else nil,
    }, withChrome(children, props.Radius or 8, props.StrokeColor or COLORS.Border, 0.52, 1))
end

local function Pill(props)
    return React.createElement(
        "Frame",
        {
            Position = props.Position,
            Size = props.Size,
            BackgroundColor3 = props.Color or COLORS.Surface,
            BackgroundTransparency = 0.06,
            BorderSizePixel = 0,
            ZIndex = props.ZIndex or 3,
        },
        withChrome({
            Text = React.createElement(Label, {
                Size = UDim2.fromScale(1, 1),
                Text = props.Text,
                TextSize = props.TextSize or 11,
                Bold = true,
                Align = Enum.TextXAlignment.Center,
                Color = props.TextColor or COLORS.Text,
                ZIndex = (props.ZIndex or 3) + 1,
            }),
        }, props.Radius or 999, props.StrokeColor or props.Color or COLORS.Border, 0.55, 1)
    )
end

local function Bar(props)
    local fraction = ratio(props.Value or 0, props.Maximum or 1)
    return React.createElement(
        "Frame",
        {
            Position = props.Position,
            Size = props.Size,
            BackgroundColor3 = COLORS.PanelDeep,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = props.ZIndex or 2,
        },
        withChrome({
            Fill = React.createElement("Frame", {
                Size = UDim2.fromScale(fraction, 1),
                BackgroundColor3 = props.Color,
                BorderSizePixel = 0,
                ZIndex = (props.ZIndex or 2) + 1,
            }, withChrome(nil, 6)),
            Shine = React.createElement("Frame", {
                Position = UDim2.fromScale(0, 0),
                Size = UDim2.fromScale(1, 0.38),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.88,
                BorderSizePixel = 0,
                ZIndex = (props.ZIndex or 2) + 2,
            }),
            Text = React.createElement(Label, {
                Size = UDim2.fromScale(1, 1),
                Text = props.Text,
                TextSize = props.TextSize or 11,
                Bold = true,
                Align = Enum.TextXAlignment.Center,
                ZIndex = (props.ZIndex or 2) + 3,
            }),
        }, 6, COLORS.Border, 0.62, 1)
    )
end

local function LeafGlyph(props)
    local z = props.ZIndex or 4
    local color = props.Color or COLORS.Lumen
    return React.createElement("Frame", {
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = props.Size or UDim2.fromOffset(28, 28),
        BackgroundTransparency = 1,
        ZIndex = z,
    }, {
        LeafA = React.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.43, 0.44),
            Size = UDim2.fromOffset(11, 18),
            Rotation = -38,
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            ZIndex = z + 1,
        }, withChrome(nil, 999)),
        LeafB = React.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.62, 0.58),
            Size = UDim2.fromOffset(8, 14),
            Rotation = 42,
            BackgroundColor3 = color:Lerp(Color3.new(1, 1, 1), 0.16),
            BorderSizePixel = 0,
            ZIndex = z + 1,
        }, withChrome(nil, 999)),
        Stem = React.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.51, 0.64),
            Size = UDim2.fromOffset(2, 18),
            Rotation = 34,
            BackgroundColor3 = COLORS.LumenPale,
            BackgroundTransparency = 0.18,
            BorderSizePixel = 0,
            ZIndex = z + 2,
        }, withChrome(nil, 999)),
    })
end

local function ShardGlyph(props)
    local z = props.ZIndex or 4
    return React.createElement("Frame", {
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = props.Size or UDim2.fromOffset(30, 30),
        BackgroundTransparency = 1,
        ZIndex = z,
    }, {
        Left = React.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.34, 0.58),
            Size = UDim2.fromOffset(7, 13),
            Rotation = -14,
            BackgroundColor3 = Color3.fromRGB(71, 184, 137),
            BorderSizePixel = 0,
            ZIndex = z + 1,
        }, withChrome(nil, 2, COLORS.Lumen, 0.25, 1)),
        Main = React.createElement(
            "Frame",
            {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.54, 0.46),
                Size = UDim2.fromOffset(9, 18),
                Rotation = 4,
                BackgroundColor3 = COLORS.Lumen,
                BorderSizePixel = 0,
                ZIndex = z + 2,
            },
            withChrome({
                Shine = React.createElement("Frame", {
                    Position = UDim2.fromOffset(2, 2),
                    Size = UDim2.fromOffset(2, 9),
                    BackgroundColor3 = COLORS.LumenPale,
                    BackgroundTransparency = 0.12,
                    BorderSizePixel = 0,
                    ZIndex = z + 3,
                }, withChrome(nil, 999)),
            }, 2, COLORS.LumenPale, 0.18, 1)
        ),
        Right = React.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.72, 0.62),
            Size = UDim2.fromOffset(6, 11),
            Rotation = 18,
            BackgroundColor3 = Color3.fromRGB(85, 216, 163),
            BorderSizePixel = 0,
            ZIndex = z + 1,
        }, withChrome(nil, 2, COLORS.Lumen, 0.35, 1)),
    })
end

local function MarkGlyph(props)
    local z = props.ZIndex or 4
    return React.createElement("Frame", {
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = props.Size or UDim2.fromOffset(30, 30),
        BackgroundTransparency = 1,
        ZIndex = z,
    }, {
        Outer = React.createElement(
            "Frame",
            {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(20, 20),
                BackgroundColor3 = COLORS.Gold,
                BorderSizePixel = 0,
                ZIndex = z + 1,
            },
            withChrome({
                Inner = React.createElement(
                    "Frame",
                    {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromOffset(12, 12),
                        BackgroundColor3 = COLORS.Bark,
                        BorderSizePixel = 0,
                        ZIndex = z + 2,
                    },
                    withChrome({
                        Rune = React.createElement("Frame", {
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.fromScale(0.5, 0.5),
                            Size = UDim2.fromOffset(4, 9),
                            Rotation = 45,
                            BackgroundColor3 = Color3.fromRGB(255, 228, 145),
                            BorderSizePixel = 0,
                            ZIndex = z + 3,
                        }, withChrome(nil, 1)),
                    }, 999)
                ),
            }, 999, Color3.fromRGB(255, 231, 159), 0.12, 1)
        ),
    })
end

local function prettyId(value)
    local text = tostring(value or ""):gsub("_", " ")
    return (
        text:gsub("(%a)([%w']*)", function(first, rest)
            return string.upper(first) .. rest
        end)
    )
end

local function objectiveText(objective, progress)
    if not objective then
        return "Explore Lumenreach"
    end
    local current = math.min(tonumber(progress) or 0, tonumber(objective.Required) or 1)
    local required = tonumber(objective.Required) or 1
    if objective.Type == "Defeat" then
        return string.format("Defeat %s  %d/%d", prettyId(objective.Target), current, required)
    elseif objective.Type == "Collect" then
        return string.format("Collect %s  %d/%d", prettyId(objective.Target), current, required)
    elseif objective.Type == "Explore" then
        return string.format("Explore %s  %d/%d", prettyId(objective.Target), current, required)
    end
    return string.format(
        "%s %s  %d/%d",
        tostring(objective.Type),
        prettyId(objective.Target),
        current,
        required
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
            else if skillId then tostring(skillId) else "Empty"
        local occupied = skillId ~= nil and skillId ~= ""
        children["Slot" .. index] = React.createElement(
            "Frame",
            {
                Position = UDim2.fromOffset(9 + (index - 1) * 72, 8),
                Size = UDim2.fromOffset(64, 58),
                BackgroundColor3 = occupied and COLORS.PanelRaised or COLORS.PanelDeep,
                BackgroundTransparency = occupied and 0.02 or 0.2,
                BorderSizePixel = 0,
                ZIndex = 3,
            },
            withChrome({
                Key = React.createElement(
                    "Frame",
                    {
                        Position = UDim2.fromOffset(5, 5),
                        Size = UDim2.fromOffset(20, 18),
                        BackgroundColor3 = occupied and COLORS.AccentDark or COLORS.Surface,
                        BorderSizePixel = 0,
                        ZIndex = 4,
                    },
                    withChrome({
                        Text = React.createElement(Label, {
                            Size = UDim2.fromScale(1, 1),
                            Text = tostring(index),
                            TextSize = 10,
                            Bold = true,
                            Align = Enum.TextXAlignment.Center,
                            Color = occupied and COLORS.Accent or COLORS.Muted,
                            ZIndex = 5,
                        }),
                    }, 5)
                ),
                Skill = React.createElement(Label, {
                    Position = UDim2.fromOffset(5, 25),
                    Size = UDim2.new(1, -10, 0, 28),
                    Text = displayName,
                    TextSize = 9,
                    Align = Enum.TextXAlignment.Center,
                    Wrapped = true,
                    Color = occupied and COLORS.Text or COLORS.Faint,
                    ZIndex = 4,
                }),
            }, 9, occupied and COLORS.BorderStrong or COLORS.Border, occupied and 0.34 or 0.65, 1)
        )
    end

    return React.createElement(Panel, {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -18),
        Size = UDim2.fromOffset(586, 74),
        Visible = props.Visible ~= false,
        BackgroundColor3 = COLORS.PanelDeep,
        BackgroundTransparency = 0.1,
        StrokeColor = COLORS.BorderStrong,
        StrokeTransparency = 0.48,
        Children = children,
    })
end

local function Objective(props)
    local profile = props.Profile or {}
    local active = profile.Quests and profile.Quests.Active
    local title = "Explore Lumenreach"
    local progressText = "Speak with Ilyra at Wayfarer Camp"
    local ready = false

    if active then
        local questId, state = next(active)
        if questId then
            local catalog = CatalogClient.Get()
            local definition = catalog and catalog.Quests and catalog.Quests[questId]
            title = definition and definition.DisplayName or tostring(questId)
            ready = state.ReadyToTurnIn == true
            if ready then
                progressText = "Ready to turn in"
            else
                local objective = definition and definition.Objectives and definition.Objectives[1]
                local progress = state.Progress and state.Progress[1] or 0
                progressText = objectiveText(objective, progress)
            end
        end
    end

    return React.createElement(Panel, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 26, 0.5, -10),
        Size = UDim2.fromOffset(324, 104),
        Visible = not props.Hidden,
        BackgroundColor3 = COLORS.PanelDeep,
        BackgroundTransparency = 0.08,
        Ornamented = true,
        OrnamentColor = ready and COLORS.Gold or COLORS.Lumen,
        Children = {
            Crest = React.createElement(LeafGlyph, {
                Position = UDim2.fromOffset(286, 10),
                Size = UDim2.fromOffset(24, 24),
                Color = ready and COLORS.Gold or COLORS.Lumen,
                ZIndex = 4,
            }),
            Accent = React.createElement("Frame", {
                Position = UDim2.fromOffset(0, 14),
                Size = UDim2.fromOffset(3, 74),
                BackgroundColor3 = ready and COLORS.Gold or COLORS.Accent,
                BorderSizePixel = 0,
                ZIndex = 3,
            }),
            Header = React.createElement(Label, {
                Position = UDim2.fromOffset(16, 9),
                Size = UDim2.new(1, -32, 0, 20),
                Text = ready and "OBJECTIVE · COMPLETE" or "CURRENT OBJECTIVE",
                TextSize = 10,
                Bold = true,
                Color = ready and COLORS.Gold or COLORS.Accent,
                ZIndex = 3,
            }),
            Title = React.createElement(Label, {
                Position = UDim2.fromOffset(16, 32),
                Size = UDim2.new(1, -32, 0, 26),
                Text = title,
                TextSize = 15,
                Bold = true,
                ZIndex = 3,
            }),
            Progress = React.createElement(Label, {
                Position = UDim2.fromOffset(16, 61),
                Size = UDim2.new(1, -32, 0, 28),
                Text = progressText,
                TextSize = 11,
                Wrapped = true,
                Color = ready and COLORS.Gold or COLORS.Muted,
                ZIndex = 3,
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
    local compactVisible = not props.UiOpen

    return React.createElement(React.Fragment, nil, {
        Status = React.createElement(Panel, {
            Position = UDim2.fromOffset(24, 78),
            Size = UDim2.fromOffset(306, 118),
            BackgroundColor3 = COLORS.PanelDeep,
            BackgroundTransparency = 0.08,
            StrokeColor = COLORS.BorderStrong,
            Ornamented = true,
            OrnamentColor = COLORS.Lumen,
            Children = {
                LevelPill = React.createElement(Pill, {
                    Position = UDim2.fromOffset(16, 12),
                    Size = UDim2.fromOffset(72, 24),
                    Text = string.format("LV %d", level),
                    Color = COLORS.AccentDark,
                    TextColor = COLORS.Accent,
                    ZIndex = 3,
                }),
                Region = React.createElement(Label, {
                    Position = UDim2.fromOffset(98, 11),
                    Size = UDim2.new(1, -112, 0, 26),
                    Text = "LUMENREACH",
                    TextSize = 11,
                    Bold = true,
                    Color = COLORS.Muted,
                    Align = Enum.TextXAlignment.Right,
                    ZIndex = 3,
                }),
                HP = React.createElement(Bar, {
                    Position = UDim2.fromOffset(16, 45),
                    Size = UDim2.fromOffset(274, 22),
                    Value = props.Health,
                    Maximum = props.MaxHealth,
                    Color = COLORS.Health,
                    Text = string.format(
                        "HP   %d / %d",
                        math.floor(props.Health + 0.5),
                        math.floor(props.MaxHealth + 0.5)
                    ),
                }),
                MP = React.createElement(Bar, {
                    Position = UDim2.fromOffset(16, 75),
                    Size = UDim2.fromOffset(274, 22),
                    Value = currentMP,
                    Maximum = maxMP,
                    Color = COLORS.Mana,
                    Text = string.format("MP   %d / %d", math.floor(currentMP), math.floor(maxMP)),
                }),
            },
        }),
        Currency = React.createElement(Panel, {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -24, 0, 78),
            Size = UDim2.fromOffset(214, 76),
            BackgroundColor3 = COLORS.PanelDeep,
            BackgroundTransparency = 0.1,
            Ornamented = true,
            OrnamentColor = COLORS.Gold,
            Visible = compactVisible,
            Children = {
                ShardsIcon = React.createElement(
                    "Frame",
                    {
                        Position = UDim2.fromOffset(11, 9),
                        Size = UDim2.fromOffset(34, 27),
                        BackgroundColor3 = COLORS.AccentDark,
                        BackgroundTransparency = 0.08,
                        BorderSizePixel = 0,
                        ZIndex = 3,
                    },
                    withChrome({
                        Glyph = React.createElement(ShardGlyph, {
                            Position = UDim2.fromScale(0.5, 0.5),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Size = UDim2.fromOffset(28, 24),
                            ZIndex = 4,
                        }),
                    }, 8, COLORS.Lumen, 0.4, 1)
                ),
                Shards = React.createElement(Label, {
                    Position = UDim2.fromOffset(52, 10),
                    Size = UDim2.new(1, -60, 0, 24),
                    Text = string.format("%d  Shards", tonumber(currencies.Shards) or 0),
                    Align = Enum.TextXAlignment.Right,
                    TextSize = 12,
                    ZIndex = 3,
                }),
                MarksIcon = React.createElement(
                    "Frame",
                    {
                        Position = UDim2.fromOffset(11, 41),
                        Size = UDim2.fromOffset(34, 27),
                        BackgroundColor3 = Color3.fromRGB(79, 61, 40),
                        BackgroundTransparency = 0.06,
                        BorderSizePixel = 0,
                        ZIndex = 3,
                    },
                    withChrome({
                        Glyph = React.createElement(MarkGlyph, {
                            Position = UDim2.fromScale(0.5, 0.5),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Size = UDim2.fromOffset(28, 24),
                            ZIndex = 4,
                        }),
                    }, 8, COLORS.Gold, 0.42, 1)
                ),
                Marks = React.createElement(Label, {
                    Position = UDim2.fromOffset(52, 42),
                    Size = UDim2.new(1, -60, 0, 24),
                    Text = string.format("%d  Marks", tonumber(currencies.Marks) or 0),
                    Align = Enum.TextXAlignment.Right,
                    TextSize = 12,
                    ZIndex = 3,
                }),
            },
        }),
        Objective = React.createElement(Objective, {
            Profile = profile,
            Hidden = props.UiOpen,
        }),
        ExpTrack = React.createElement(
            "Frame",
            {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, -100),
                Size = UDim2.fromOffset(586, 11),
                BackgroundColor3 = COLORS.PanelDeep,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Visible = compactVisible,
                ZIndex = 2,
            },
            withChrome({
                Fill = React.createElement("Frame", {
                    Size = UDim2.fromScale(ratio(exp, needed), 1),
                    BackgroundColor3 = COLORS.Exp,
                    BorderSizePixel = 0,
                    ZIndex = 3,
                }, withChrome(nil, 6)),
            }, 6, COLORS.Border, 0.58, 1)
        ),
        ExpText = React.createElement(Label, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -113),
            Size = UDim2.fromOffset(300, 18),
            Text = string.format("EXP  %d / %d", exp, needed),
            TextSize = 10,
            Color = COLORS.Muted,
            Align = Enum.TextXAlignment.Center,
            Visible = compactVisible,
            ZIndex = 3,
        }),
        Hotbar = React.createElement(Hotbar, {
            Profile = profile,
            Visible = compactVisible,
        }),
    })
end

local function Dialogue(props)
    local description = props.Description
    local profile = props.Profile or {}
    local status, setStatus = React.useState("Choose an action · Esc closes")
    if not description then
        return nil
    end

    local questId = description.QuestOffers and description.QuestOffers[1]
    local quests = profile.Quests or {}
    local completed = questId ~= nil and quests.Completed and quests.Completed[questId] == true
    local activeState = questId ~= nil and quests.Active and quests.Active[questId] or nil
    local active = activeState ~= nil
    local readyToTurnIn = activeState ~= nil and activeState.ReadyToTurnIn == true
    local questButtonText = if completed
        then "QUEST COMPLETE"
        else if readyToTurnIn
            then "TURN IN QUEST"
            else if active then "QUEST ACTIVE" else "ACCEPT QUEST"
    local questButtonEnabled = questId ~= nil and not completed and (not active or readyToTurnIn)

    local function activateQuestButton()
        if not questButtonEnabled then
            return
        end
        local action = if readyToTurnIn then "quest.turnin" else "quest.start"
        local ok, result = ActionClient.Invoke(action, {
            NpcId = description.NpcId,
            QuestId = questId,
        })
        if ok then
            setStatus(
                if readyToTurnIn then "Quest completed. Rewards received." else "Quest accepted."
            )
        else
            setStatus(string.format("Quest unavailable: %s", tostring(result)))
        end
    end

    local function buyShopItem(itemId, displayName)
        if not description.ShopId or not itemId then
            return
        end
        local ok, result = ActionClient.Invoke("shop.buy", {
            ShopId = description.ShopId,
            ItemId = itemId,
            Quantity = 1,
        })
        setStatus(
            if ok
                then string.format("Purchased %s.", displayName or "item")
                else string.format("Purchase failed: %s", tostring(result))
        )
    end

    local actionChildren = {}
    if questId then
        actionChildren.Quest = React.createElement(Button, {
            Position = UDim2.fromOffset(22, 198),
            Size = UDim2.fromOffset(220, 44),
            Text = questButtonText,
            Active = questButtonEnabled,
            Tone = readyToTurnIn and "accent" or nil,
            OnActivated = activateQuestButton,
            ZIndex = 24,
        })
    end

    local shopItems = description.ShopItems or {}
    local shopChildren = {}
    for index, shopItem in shopItems do
        if index > 3 then
            break
        end
        shopChildren["Shop" .. tostring(index)] = React.createElement(
            "Frame",
            {
                Position = UDim2.fromOffset((index - 1) * 166, 0),
                Size = UDim2.fromOffset(156, 88),
                BackgroundColor3 = COLORS.PanelRaised,
                BorderSizePixel = 0,
                ZIndex = 23,
            },
            withChrome({
                Name = React.createElement(Label, {
                    Position = UDim2.fromOffset(10, 8),
                    Size = UDim2.new(1, -20, 0, 34),
                    Text = shopItem.DisplayName or "Item",
                    TextSize = 11,
                    Bold = true,
                    Wrapped = true,
                    ZIndex = 24,
                }),
                Buy = React.createElement(Button, {
                    Position = UDim2.fromOffset(10, 51),
                    Size = UDim2.new(1, -20, 0, 27),
                    Text = string.format(
                        "BUY · %s %s",
                        tostring(shopItem.Price or "?"),
                        string.upper(description.ShopCurrency or "")
                    ),
                    TextSize = 9,
                    Tone = "accent",
                    OnActivated = function()
                        buyShopItem(shopItem.ItemId, shopItem.DisplayName)
                    end,
                    ZIndex = 25,
                }),
            }, 9, COLORS.Border, 0.45, 1)
        )
    end

    return React.createElement(React.Fragment, nil, {
        Backdrop = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = COLORS.Backdrop,
            BackgroundTransparency = 0.76,
            BorderSizePixel = 0,
            ZIndex = 18,
        }),
        Panel = React.createElement(Panel, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -28),
            Size = UDim2.fromOffset(760, 360),
            BackgroundColor3 = COLORS.PanelDeep,
            StrokeColor = COLORS.BorderStrong,
            StrokeTransparency = 0.18,
            StrokeThickness = 1.2,
            Ornamented = true,
            OrnamentColor = COLORS.Lumen,
            ZIndex = 20,
            Children = {
                Accent = React.createElement("Frame", {
                    Position = UDim2.fromOffset(0, 0),
                    Size = UDim2.fromOffset(5, 360),
                    BackgroundColor3 = COLORS.Accent,
                    BorderSizePixel = 0,
                    ZIndex = 22,
                }),
                Crest = React.createElement(LeafGlyph, {
                    Position = UDim2.fromOffset(18, 15),
                    Size = UDim2.fromOffset(30, 30),
                    Color = COLORS.Lumen,
                    ZIndex = 23,
                }),
                Kicker = React.createElement(Label, {
                    Position = UDim2.fromOffset(54, 14),
                    Size = UDim2.fromOffset(260, 18),
                    Text = "WAYFARER INTERACTION",
                    TextSize = 10,
                    Bold = true,
                    Color = COLORS.Accent,
                    ZIndex = 22,
                }),
                Title = React.createElement(Label, {
                    Position = UDim2.fromOffset(54, 34),
                    Size = UDim2.new(1, -130, 0, 34),
                    Text = description.DisplayName or "Traveler",
                    TextSize = 24,
                    Bold = true,
                    ZIndex = 22,
                }),
                Close = React.createElement(Button, {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -16, 0, 16),
                    Size = UDim2.fromOffset(42, 36),
                    Text = "×",
                    TextSize = 21,
                    OnActivated = props.OnClose,
                    ZIndex = 24,
                }),
                Divider = React.createElement("Frame", {
                    Position = UDim2.fromOffset(22, 76),
                    Size = UDim2.new(1, -44, 0, 1),
                    BackgroundColor3 = COLORS.Border,
                    BackgroundTransparency = 0.52,
                    BorderSizePixel = 0,
                    ZIndex = 22,
                }),
                Body = React.createElement(Label, {
                    Position = UDim2.fromOffset(22, 90),
                    Size = UDim2.new(1, -44, 0, 84),
                    Text = description.DialogueText or "The trails are open. Stay alert out there.",
                    TextSize = 15,
                    Wrapped = true,
                    VerticalAlign = Enum.TextYAlignment.Top,
                    Color = COLORS.Text,
                    ZIndex = 22,
                }),
                QuestAction = React.createElement(React.Fragment, nil, actionChildren),
                ShopHeader = if #shopItems > 0
                    then React.createElement(Label, {
                        Position = UDim2.fromOffset(258, 181),
                        Size = UDim2.fromOffset(220, 18),
                        Text = "SUPPLIES",
                        TextSize = 10,
                        Bold = true,
                        Color = COLORS.Muted,
                        ZIndex = 22,
                    })
                    else nil,
                ShopArea = React.createElement("Frame", {
                    Position = UDim2.fromOffset(258, 202),
                    Size = UDim2.fromOffset(490, 90),
                    BackgroundTransparency = 1,
                    ZIndex = 22,
                }, shopChildren),
                Status = React.createElement(
                    "Frame",
                    {
                        Position = UDim2.fromOffset(22, 310),
                        Size = UDim2.new(1, -44, 0, 32),
                        BackgroundColor3 = COLORS.PanelRaised,
                        BackgroundTransparency = 0.18,
                        BorderSizePixel = 0,
                        ZIndex = 22,
                    },
                    withChrome({
                        Text = React.createElement(Label, {
                            Position = UDim2.fromOffset(12, 0),
                            Size = UDim2.new(1, -24, 1, 0),
                            Text = status,
                            TextSize = 11,
                            Color = COLORS.Muted,
                            ZIndex = 23,
                        }),
                    }, 7)
                ),
            },
        }),
    })
end

local function itemStatsText(definition)
    if not definition or type(definition.Stats) ~= "table" then
        return ""
    end
    local parts = {}
    local keys = {}
    for statName in definition.Stats do
        table.insert(keys, statName)
    end
    table.sort(keys)
    for _, statName in keys do
        local amount = definition.Stats[statName]
        table.insert(parts, string.format("%s +%s", statName, tostring(amount)))
    end
    return table.concat(parts, "  ·  ")
end

local function CharacterPanel(profile, invoke)
    local stats = profile.Stats or {}
    local derived = profile.Derived or {}
    local level = tonumber(profile.Level) or 1
    local ap = tonumber(profile.AP) or 0
    local sp = tonumber(profile.SP) or 0
    local children = {
        Summary = React.createElement(Panel, {
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, 0, 0, 86),
            BackgroundColor3 = COLORS.PanelRaised,
            Children = {
                Level = React.createElement(Label, {
                    Position = UDim2.fromOffset(18, 10),
                    Size = UDim2.fromOffset(190, 28),
                    Text = string.format("LEVEL %d", level),
                    TextSize = 21,
                    Bold = true,
                    Color = COLORS.Accent,
                    ZIndex = 5,
                }),
                Tier = React.createElement(Label, {
                    Position = UDim2.fromOffset(18, 43),
                    Size = UDim2.fromOffset(260, 24),
                    Text = string.format(
                        "Advancement Tier %d",
                        tonumber(profile.AdvancementTier) or 0
                    ),
                    TextSize = 12,
                    Color = COLORS.Muted,
                    ZIndex = 5,
                }),
                AP = React.createElement(Pill, {
                    Position = UDim2.new(1, -166, 0, 17),
                    Size = UDim2.fromOffset(68, 26),
                    Text = string.format("AP %d", ap),
                    Color = COLORS.AccentDark,
                    TextColor = COLORS.Accent,
                    ZIndex = 5,
                }),
                SP = React.createElement(Pill, {
                    Position = UDim2.new(1, -88, 0, 17),
                    Size = UDim2.fromOffset(68, 26),
                    Text = string.format("SP %d", sp),
                    Color = Color3.fromRGB(68, 54, 85),
                    TextColor = COLORS.Purple,
                    ZIndex = 5,
                }),
                Resources = React.createElement(Label, {
                    Position = UDim2.new(1, -310, 0, 50),
                    Size = UDim2.fromOffset(290, 22),
                    Text = string.format(
                        "Max HP %s   ·   Max MP %s",
                        tostring(derived.MaxHP or "—"),
                        tostring(derived.MaxMP or "—")
                    ),
                    TextSize = 11,
                    Color = COLORS.Muted,
                    Align = Enum.TextXAlignment.Right,
                    ZIndex = 5,
                }),
            },
        }),
    }

    local names = { "Might", "Finesse", "Insight", "Fortune" }
    local descriptions = {
        Might = "Power and physical damage",
        Finesse = "Precision and agile weapon scaling",
        Insight = "Technique and magical aptitude",
        Fortune = "Luck-oriented progression hooks",
    }
    for index, statName in names do
        local column = (index - 1) % 2
        local row = math.floor((index - 1) / 2)
        children[statName] = React.createElement(Panel, {
            Position = UDim2.fromOffset(column * 302, 104 + row * 126),
            Size = UDim2.fromOffset(286, 110),
            BackgroundColor3 = COLORS.PanelRaised,
            StrokeTransparency = 0.55,
            Children = {
                Name = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 12),
                    Size = UDim2.fromOffset(150, 22),
                    Text = string.upper(statName),
                    TextSize = 12,
                    Bold = true,
                    Color = COLORS.Muted,
                    ZIndex = 5,
                }),
                Value = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 36),
                    Size = UDim2.fromOffset(110, 34),
                    Text = tostring(tonumber(stats[statName]) or 0),
                    TextSize = 28,
                    Bold = true,
                    ZIndex = 5,
                }),
                Description = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 72),
                    Size = UDim2.fromOffset(188, 24),
                    Text = descriptions[statName],
                    TextSize = 10,
                    Color = COLORS.Faint,
                    Wrapped = true,
                    ZIndex = 5,
                }),
                Add = React.createElement(Button, {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -14, 0, 39),
                    Size = UDim2.fromOffset(52, 38),
                    Text = "+1",
                    Tone = "accent",
                    Active = ap > 0,
                    OnActivated = function()
                        invoke(
                            "stat.allocate",
                            { StatName = statName, Amount = 1 },
                            "+1 " .. statName
                        )
                    end,
                    ZIndex = 6,
                }),
            },
        })
    end
    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, children)
end

local function InventoryPanel(
    profile,
    catalog,
    invoke,
    selectedInventoryIndex,
    setSelectedInventoryIndex
)
    local inventory = profile.Inventory or {}
    local rows = {}
    for index, slot in inventory.Slots or {} do
        table.insert(rows, { Index = index, Slot = slot })
    end
    table.sort(rows, function(a, b)
        return a.Index < b.Index
    end)

    local selectedRow = nil
    for _, row in rows do
        if row.Index == selectedInventoryIndex then
            selectedRow = row
            break
        end
    end
    selectedRow = selectedRow or rows[1]
    local selectedSlot = selectedRow and selectedRow.Slot or nil
    local selectedDefinition = selectedSlot and catalog.Items and catalog.Items[selectedSlot.ItemId]
        or nil

    local listChildren = {}
    for visualIndex, row in rows do
        local slot = row.Slot
        local definition = catalog.Items and catalog.Items[slot.ItemId]
        local selected = selectedRow and selectedRow.Index == row.Index
        local typeText = definition and definition.Type or "Item"
        listChildren["Item" .. tostring(row.Index)] = React.createElement(
            "TextButton",
            {
                Position = UDim2.fromOffset(0, (visualIndex - 1) * 48),
                Size = UDim2.new(1, -8, 0, 42),
                BackgroundColor3 = selected and COLORS.AccentDark or COLORS.PanelRaised,
                BackgroundTransparency = selected and 0 or 0.06,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = true,
                ZIndex = 5,
                [React.Event.Activated] = function()
                    setSelectedInventoryIndex(row.Index)
                end,
            },
            withChrome({
                Name = React.createElement(Label, {
                    Position = UDim2.fromOffset(12, 4),
                    Size = UDim2.new(1, -74, 0, 20),
                    Text = definition and definition.DisplayName or tostring(slot.ItemId),
                    TextSize = 11,
                    Bold = true,
                    Color = selected and COLORS.Accent or COLORS.Text,
                    ZIndex = 6,
                }),
                Type = React.createElement(Label, {
                    Position = UDim2.fromOffset(12, 23),
                    Size = UDim2.new(1, -90, 0, 14),
                    Text = typeText,
                    TextSize = 9,
                    Color = selected and Color3.fromRGB(181, 224, 202) or COLORS.Faint,
                    ZIndex = 6,
                }),
                Quantity = React.createElement(Label, {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.fromOffset(54, 20),
                    Text = string.format("×%d", tonumber(slot.Quantity) or 0),
                    TextSize = 11,
                    Bold = true,
                    Align = Enum.TextXAlignment.Right,
                    Color = selected and COLORS.Accent or COLORS.Muted,
                    ZIndex = 6,
                }),
            }, 8, selected and COLORS.BorderStrong or COLORS.Border, selected and 0.2 or 0.6, 1)
        )
    end

    local equipment = profile.Equipment or {}
    local equipmentChildren = {}
    local slots = { "Weapon", "Head", "Body", "Legs", "Accessory", "Ring1", "Ring2" }
    for index, slotName in slots do
        local itemId = equipment[slotName]
        local definition = itemId and itemId ~= "" and catalog.Items and catalog.Items[itemId]
        equipmentChildren[slotName] =
            React.createElement(
                "Frame",
                {
                    Position = UDim2.fromOffset(0, (index - 1) * 29),
                    Size = UDim2.new(1, 0, 0, 27),
                    BackgroundColor3 = COLORS.PanelRaised,
                    BackgroundTransparency = 0.14,
                    BorderSizePixel = 0,
                    ZIndex = 5,
                },
                withChrome({
                    Slot = React.createElement(Label, {
                        Position = UDim2.fromOffset(10, 0),
                        Size = UDim2.fromOffset(72, 27),
                        Text = string.upper(slotName),
                        TextSize = 8,
                        Bold = true,
                        Color = COLORS.Faint,
                        ZIndex = 6,
                    }),
                    Item = React.createElement(Label, {
                        Position = UDim2.fromOffset(84, 0),
                        Size = UDim2.new(1, -130, 1, 0),
                        Text = definition and definition.DisplayName or "Empty",
                        TextSize = 10,
                        Color = definition and COLORS.Text or COLORS.Faint,
                        ZIndex = 6,
                    }),
                    Unequip = definition and React.createElement(Button, {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -5, 0.5, 0),
                        Size = UDim2.fromOffset(38, 23),
                        Text = "×",
                        TextSize = 12,
                        Tone = "danger",
                        OnActivated = function()
                            invoke(
                                "equipment.unequip",
                                { Slot = slotName },
                                slotName .. " unequipped."
                            )
                        end,
                        ZIndex = 7,
                    }) or nil,
                }, 7, COLORS.Border, 0.68, 1)
            )
    end

    local selectedName = selectedDefinition and selectedDefinition.DisplayName or "Select an item"
    local selectedType = selectedDefinition and selectedDefinition.Type or "Inventory"
    local details = if selectedDefinition
        then string.format(
            "%s%s%s",
            selectedType,
            selectedDefinition.EquipmentSlot
                    and (" · " .. tostring(selectedDefinition.EquipmentSlot))
                or "",
            selectedSlot and (" · Quantity " .. tostring(selectedSlot.Quantity or 0)) or ""
        )
        else "Choose an inventory item to inspect it."
    local statsText = itemStatsText(selectedDefinition)

    local action = nil
    if selectedDefinition and selectedRow then
        if selectedDefinition.Type == "Equipment" then
            action = React.createElement(Button, {
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.fromOffset(136, 36),
                Text = "EQUIP",
                Tone = "accent",
                OnActivated = function()
                    invoke(
                        "equipment.equip",
                        { InventoryIndex = selectedRow.Index },
                        selectedName .. " equipped."
                    )
                end,
                ZIndex = 7,
            })
        elseif selectedDefinition.Type == "Consumable" then
            action = React.createElement(Button, {
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.fromOffset(136, 36),
                Text = "USE",
                Tone = "accent",
                OnActivated = function()
                    invoke(
                        "inventory.use",
                        { ItemId = selectedSlot.ItemId },
                        selectedName .. " used."
                    )
                end,
                ZIndex = 7,
            })
        end
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, {
        InventoryTitle = React.createElement(Label, {
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(330, 26),
            Text = string.format(
                "INVENTORY  ·  %d / %d",
                #rows,
                tonumber(inventory.Capacity) or 48
            ),
            TextSize = 12,
            Bold = true,
            Color = COLORS.Muted,
            ZIndex = 5,
        }),
        InventoryList = React.createElement("ScrollingFrame", {
            Position = UDim2.fromOffset(0, 32),
            Size = UDim2.fromOffset(330, 330),
            CanvasSize = UDim2.fromOffset(0, math.max(330, #rows * 48)),
            BackgroundColor3 = COLORS.PanelDeep,
            BackgroundTransparency = 0.18,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = COLORS.BorderStrong,
            ZIndex = 4,
        }, withChrome(listChildren, 10, COLORS.Border, 0.55, 1)),
        Details = React.createElement(Panel, {
            Position = UDim2.fromOffset(348, 0),
            Size = UDim2.fromOffset(250, 148),
            BackgroundColor3 = COLORS.PanelRaised,
            Children = {
                Kicker = React.createElement(Label, {
                    Position = UDim2.fromOffset(14, 10),
                    Size = UDim2.new(1, -28, 0, 18),
                    Text = string.upper(selectedType),
                    TextSize = 9,
                    Bold = true,
                    Color = COLORS.Accent,
                    ZIndex = 6,
                }),
                Name = React.createElement(Label, {
                    Position = UDim2.fromOffset(14, 30),
                    Size = UDim2.new(1, -28, 0, 30),
                    Text = selectedName,
                    TextSize = 16,
                    Bold = true,
                    Wrapped = true,
                    ZIndex = 6,
                }),
                DetailsText = React.createElement(Label, {
                    Position = UDim2.fromOffset(14, 66),
                    Size = UDim2.new(1, -28, 0, 38),
                    Text = details,
                    TextSize = 10,
                    Wrapped = true,
                    Color = COLORS.Muted,
                    VerticalAlign = Enum.TextYAlignment.Top,
                    ZIndex = 6,
                }),
                Stats = React.createElement(Label, {
                    Position = UDim2.fromOffset(14, 91),
                    Size = UDim2.new(1, -28, 0, 22),
                    Text = statsText ~= "" and statsText or "No stat bonuses",
                    TextSize = 9,
                    Color = statsText ~= "" and COLORS.Gold or COLORS.Faint,
                    Wrapped = true,
                    ZIndex = 6,
                }),
                Action = React.createElement("Frame", {
                    Position = UDim2.fromOffset(14, 111),
                    Size = UDim2.fromOffset(136, 36),
                    BackgroundTransparency = 1,
                    ZIndex = 6,
                }, { Action = action }),
            },
        }),
        EquippedTitle = React.createElement(Label, {
            Position = UDim2.fromOffset(348, 158),
            Size = UDim2.fromOffset(250, 22),
            Text = "EQUIPPED",
            TextSize = 11,
            Bold = true,
            Color = COLORS.Muted,
            ZIndex = 5,
        }),
        Equipped = React.createElement("Frame", {
            Position = UDim2.fromOffset(348, 184),
            Size = UDim2.fromOffset(250, 210),
            BackgroundTransparency = 1,
            ZIndex = 4,
        }, equipmentChildren),
    })
end

local function SkillsPanel(profile, catalog, invoke, selectedSkillId, setSelectedSkillId)
    local learned = profile.Skills and profile.Skills.Learned or {}
    local skillRows = {}
    for skillId, definition in catalog.Skills or {} do
        table.insert(
            skillRows,
            { Id = skillId, Definition = definition, Rank = learned[skillId] or 0 }
        )
    end
    table.sort(skillRows, function(a, b)
        return (a.Definition.DisplayName or a.Id) < (b.Definition.DisplayName or b.Id)
    end)
    local selected = nil
    for _, row in skillRows do
        if row.Id == selectedSkillId then
            selected = row
            break
        end
    end
    selected = selected or skillRows[1]

    local listChildren = {}
    for index, row in skillRows do
        local selectedRow = selected and selected.Id == row.Id
        listChildren[row.Id] = React.createElement(
            "TextButton",
            {
                Position = UDim2.fromOffset(0, (index - 1) * 64),
                Size = UDim2.new(1, -8, 0, 56),
                BackgroundColor3 = selectedRow and COLORS.AccentDark or COLORS.PanelRaised,
                BorderSizePixel = 0,
                Text = "",
                ZIndex = 5,
                [React.Event.Activated] = function()
                    setSelectedSkillId(row.Id)
                end,
            },
            withChrome(
                {
                    Name = React.createElement(Label, {
                        Position = UDim2.fromOffset(12, 8),
                        Size = UDim2.new(1, -24, 0, 20),
                        Text = row.Definition.DisplayName or row.Id,
                        TextSize = 12,
                        Bold = true,
                        Color = selectedRow and COLORS.Accent or COLORS.Text,
                        ZIndex = 6,
                    }),
                    Meta = React.createElement(Label, {
                        Position = UDim2.fromOffset(12, 31),
                        Size = UDim2.new(1, -24, 0, 17),
                        Text = string.format(
                            "%s  ·  Rank %d/%d",
                            row.Definition.Kind or "Skill",
                            row.Rank,
                            row.Definition.MaxRank or 1
                        ),
                        TextSize = 9,
                        Color = selectedRow and COLORS.Text or COLORS.Faint,
                        ZIndex = 6,
                    }),
                },
                9,
                selectedRow and COLORS.BorderStrong or COLORS.Border,
                selectedRow and 0.28 or 0.65,
                1
            )
        )
    end

    local selectedDefinition = selected and selected.Definition or nil
    local selectedRank = selected and selected.Rank or 0
    local hotbar = profile.Skills and profile.Skills.Hotbar or {}
    local slot1 = hotbar["1"] or hotbar[1]
    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, {
        ListTitle = React.createElement(Label, {
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(275, 24),
            Text = string.format("SKILLS  ·  SP %d", tonumber(profile.SP) or 0),
            TextSize = 12,
            Bold = true,
            Color = COLORS.Muted,
            ZIndex = 5,
        }),
        List = React.createElement("ScrollingFrame", {
            Position = UDim2.fromOffset(0, 32),
            Size = UDim2.fromOffset(282, 354),
            CanvasSize = UDim2.fromOffset(0, math.max(354, #skillRows * 64)),
            BackgroundColor3 = COLORS.PanelDeep,
            BackgroundTransparency = 0.18,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = COLORS.BorderStrong,
            ZIndex = 4,
        }, withChrome(listChildren, 10, COLORS.Border, 0.55, 1)),
        Detail = React.createElement(Panel, {
            Position = UDim2.fromOffset(302, 0),
            Size = UDim2.fromOffset(296, 270),
            BackgroundColor3 = COLORS.PanelRaised,
            Children = {
                Kicker = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 12),
                    Size = UDim2.new(1, -32, 0, 18),
                    Text = selectedDefinition and string.upper(selectedDefinition.Kind or "SKILL")
                        or "SKILL",
                    TextSize = 9,
                    Bold = true,
                    Color = COLORS.Accent,
                    ZIndex = 6,
                }),
                Name = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 34),
                    Size = UDim2.new(1, -32, 0, 34),
                    Text = selectedDefinition and selectedDefinition.DisplayName
                        or "Select a skill",
                    TextSize = 19,
                    Bold = true,
                    Wrapped = true,
                    ZIndex = 6,
                }),
                Rank = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 76),
                    Size = UDim2.new(1, -32, 0, 24),
                    Text = selectedDefinition and string.format(
                        "Rank %d / %d",
                        selectedRank,
                        selectedDefinition.MaxRank or 1
                    ) or "",
                    TextSize = 12,
                    Color = COLORS.Gold,
                    ZIndex = 6,
                }),
                Requirements = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 108),
                    Size = UDim2.new(1, -32, 0, 46),
                    Text = selectedDefinition and string.format(
                        "Requires Level %d · Tier %d",
                        selectedDefinition.RequiredLevel or 1,
                        selectedDefinition.RequiredTier or 0
                    ) or "",
                    TextSize = 11,
                    Color = COLORS.Muted,
                    Wrapped = true,
                    VerticalAlign = Enum.TextYAlignment.Top,
                    ZIndex = 6,
                }),
                Slot = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 158),
                    Size = UDim2.new(1, -32, 0, 22),
                    Text = string.format(
                        "Hotbar Slot 1: %s",
                        slot1
                                and (catalog.Skills[slot1] and catalog.Skills[slot1].DisplayName or slot1)
                            or "Empty"
                    ),
                    TextSize = 10,
                    Color = COLORS.Faint,
                    ZIndex = 6,
                }),
                RankUp = selected
                        and React.createElement(Button, {
                            Position = UDim2.fromOffset(16, 198),
                            Size = UDim2.fromOffset(126, 38),
                            Text = "RANK UP",
                            Tone = "accent",
                            Active = (tonumber(profile.SP) or 0) > 0
                                and selectedRank < (selectedDefinition.MaxRank or 1),
                            OnActivated = function()
                                invoke(
                                    "skill.learn",
                                    { SkillId = selected.Id },
                                    (selectedDefinition.DisplayName or selected.Id) .. " ranked up."
                                )
                            end,
                            ZIndex = 7,
                        })
                    or nil,
                Assign = selected and selectedRank > 0 and React.createElement(Button, {
                    Position = UDim2.fromOffset(152, 198),
                    Size = UDim2.fromOffset(126, 38),
                    Text = "ASSIGN SLOT 1",
                    OnActivated = function()
                        invoke(
                            "skill.hotbar",
                            { Index = 1, SkillId = selected.Id },
                            "Assigned to hotbar slot 1."
                        )
                    end,
                    ZIndex = 7,
                }) or nil,
            },
        }),
        Tip = React.createElement(Panel, {
            Position = UDim2.fromOffset(302, 288),
            Size = UDim2.fromOffset(296, 98),
            BackgroundColor3 = COLORS.PanelDeep,
            StrokeTransparency = 0.62,
            Children = {
                Title = React.createElement(Label, {
                    Position = UDim2.fromOffset(14, 10),
                    Size = UDim2.new(1, -28, 0, 20),
                    Text = "HOTBAR",
                    TextSize = 10,
                    Bold = true,
                    Color = COLORS.Muted,
                    ZIndex = 6,
                }),
                Body = React.createElement(Label, {
                    Position = UDim2.fromOffset(14, 32),
                    Size = UDim2.new(1, -28, 0, 48),
                    Text = "Press 1–8 during gameplay to activate assigned skills. K opens this panel directly.",
                    TextSize = 10,
                    Wrapped = true,
                    Color = COLORS.Faint,
                    VerticalAlign = Enum.TextYAlignment.Top,
                    ZIndex = 6,
                }),
            },
        }),
    })
end

local function QuestsPanel(profile, catalog)
    local active = profile.Quests and profile.Quests.Active or {}
    local completed = profile.Quests and profile.Quests.Completed or {}
    local activeRows = {}
    for questId, state in active do
        table.insert(activeRows, { Id = questId, State = state })
    end
    table.sort(activeRows, function(a, b)
        local aName = catalog.Quests and catalog.Quests[a.Id] and catalog.Quests[a.Id].DisplayName
            or a.Id
        local bName = catalog.Quests and catalog.Quests[b.Id] and catalog.Quests[b.Id].DisplayName
            or b.Id
        return aName < bName
    end)

    local activeChildren = {}
    if #activeRows == 0 then
        activeChildren.Empty = React.createElement(Label, {
            Position = UDim2.fromOffset(12, 12),
            Size = UDim2.new(1, -24, 0, 40),
            Text = "No active quests. Talk to the Wayfarers around camp.",
            TextSize = 11,
            Wrapped = true,
            Color = COLORS.Faint,
            ZIndex = 5,
        })
    end
    local y = 0
    for _, row in activeRows do
        local definition = catalog.Quests and catalog.Quests[row.Id]
        local name = definition and definition.DisplayName or row.Id
        local objectives = definition and definition.Objectives or {}
        local progressLines = {}
        for index, objective in objectives do
            table.insert(
                progressLines,
                objectiveText(objective, row.State.Progress and row.State.Progress[index] or 0)
            )
        end
        local height = 78 + math.max(0, #progressLines - 1) * 18
        activeChildren[row.Id] = React.createElement(Panel, {
            Position = UDim2.fromOffset(0, y),
            Size = UDim2.new(1, -8, 0, height),
            BackgroundColor3 = COLORS.PanelRaised,
            StrokeColor = row.State.ReadyToTurnIn and COLORS.Gold or COLORS.Border,
            StrokeTransparency = row.State.ReadyToTurnIn and 0.28 or 0.6,
            Children = {
                Status = React.createElement(Pill, {
                    Position = UDim2.fromOffset(12, 10),
                    Size = UDim2.fromOffset(row.State.ReadyToTurnIn and 96 or 64, 21),
                    Text = row.State.ReadyToTurnIn and "TURN IN" or "ACTIVE",
                    TextSize = 9,
                    Color = row.State.ReadyToTurnIn and Color3.fromRGB(94, 74, 42)
                        or COLORS.AccentDark,
                    TextColor = row.State.ReadyToTurnIn and COLORS.Gold or COLORS.Accent,
                    ZIndex = 6,
                }),
                Name = React.createElement(Label, {
                    Position = UDim2.fromOffset(12, 35),
                    Size = UDim2.new(1, -24, 0, 22),
                    Text = name,
                    TextSize = 13,
                    Bold = true,
                    ZIndex = 6,
                }),
                Progress = React.createElement(Label, {
                    Position = UDim2.fromOffset(12, 58),
                    Size = UDim2.new(1, -24, 0, math.max(18, #progressLines * 18)),
                    Text = #progressLines > 0 and table.concat(progressLines, "\n")
                        or "No objectives",
                    TextSize = 10,
                    Wrapped = true,
                    Color = COLORS.Muted,
                    VerticalAlign = Enum.TextYAlignment.Top,
                    ZIndex = 6,
                }),
            },
        })
        y += height + 10
    end

    local completedNames = {}
    for questId, done in completed do
        if done then
            local definition = catalog.Quests and catalog.Quests[questId]
            table.insert(completedNames, definition and definition.DisplayName or questId)
        end
    end
    table.sort(completedNames)
    local completedChildren = {}
    for index, name in completedNames do
        completedChildren["Done" .. index] = React.createElement(
            "Frame",
            {
                Position = UDim2.fromOffset(0, (index - 1) * 38),
                Size = UDim2.new(1, -8, 0, 32),
                BackgroundColor3 = COLORS.PanelRaised,
                BackgroundTransparency = 0.18,
                BorderSizePixel = 0,
                ZIndex = 5,
            },
            withChrome({
                Check = React.createElement(Label, {
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.fromOffset(22, 32),
                    Text = "✓",
                    TextSize = 12,
                    Bold = true,
                    Color = COLORS.Accent,
                    ZIndex = 6,
                }),
                Name = React.createElement(Label, {
                    Position = UDim2.fromOffset(34, 0),
                    Size = UDim2.new(1, -42, 1, 0),
                    Text = name,
                    TextSize = 10,
                    Color = COLORS.Muted,
                    ZIndex = 6,
                }),
            }, 7, COLORS.Border, 0.7, 1)
        )
    end
    if #completedNames == 0 then
        completedChildren.Empty = React.createElement(Label, {
            Position = UDim2.fromOffset(10, 10),
            Size = UDim2.new(1, -20, 0, 30),
            Text = "No completed quests yet.",
            TextSize = 10,
            Color = COLORS.Faint,
            ZIndex = 5,
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, {
        ActiveTitle = React.createElement(Label, {
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(370, 24),
            Text = string.format("ACTIVE QUESTS  ·  %d", #activeRows),
            TextSize = 12,
            Bold = true,
            Color = COLORS.Muted,
            ZIndex = 5,
        }),
        ActiveList = React.createElement("ScrollingFrame", {
            Position = UDim2.fromOffset(0, 32),
            Size = UDim2.fromOffset(374, 354),
            CanvasSize = UDim2.fromOffset(0, math.max(354, y)),
            BackgroundColor3 = COLORS.PanelDeep,
            BackgroundTransparency = 0.18,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = COLORS.BorderStrong,
            ZIndex = 4,
        }, withChrome(activeChildren, 10, COLORS.Border, 0.55, 1)),
        CompletedTitle = React.createElement(Label, {
            Position = UDim2.fromOffset(394, 0),
            Size = UDim2.fromOffset(204, 24),
            Text = string.format("COMPLETED  ·  %d", #completedNames),
            TextSize = 12,
            Bold = true,
            Color = COLORS.Muted,
            ZIndex = 5,
        }),
        CompletedList = React.createElement("ScrollingFrame", {
            Position = UDim2.fromOffset(394, 32),
            Size = UDim2.fromOffset(204, 354),
            CanvasSize = UDim2.fromOffset(0, math.max(354, #completedNames * 38)),
            BackgroundColor3 = COLORS.PanelDeep,
            BackgroundTransparency = 0.18,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = COLORS.BorderStrong,
            ZIndex = 4,
        }, withChrome(completedChildren, 10, COLORS.Border, 0.55, 1)),
    })
end

local function SettingsPanel(profile, invoke)
    local settings = profile.Settings or {}
    local music = tonumber(settings.MusicVolume) or 1
    local sfx = tonumber(settings.SfxVolume) or 1

    local function volumeRow(key, title, value, y)
        return React.createElement(Panel, {
            Position = UDim2.fromOffset(0, y),
            Size = UDim2.new(1, 0, 0, 92),
            BackgroundColor3 = COLORS.PanelRaised,
            Children = {
                Title = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 12),
                    Size = UDim2.fromOffset(220, 22),
                    Text = title,
                    TextSize = 13,
                    Bold = true,
                    ZIndex = 5,
                }),
                Percent = React.createElement(Label, {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -16, 0, 12),
                    Size = UDim2.fromOffset(90, 22),
                    Text = string.format("%d%%", math.floor(value * 100 + 0.5)),
                    TextSize = 12,
                    Bold = true,
                    Color = COLORS.Accent,
                    Align = Enum.TextXAlignment.Right,
                    ZIndex = 5,
                }),
                Track = React.createElement(
                    "Frame",
                    {
                        Position = UDim2.fromOffset(16, 49),
                        Size = UDim2.new(1, -150, 0, 10),
                        BackgroundColor3 = COLORS.PanelDeep,
                        BorderSizePixel = 0,
                        ClipsDescendants = true,
                        ZIndex = 5,
                    },
                    withChrome({
                        Fill = React.createElement("Frame", {
                            Size = UDim2.fromScale(value, 1),
                            BackgroundColor3 = COLORS.Accent,
                            BorderSizePixel = 0,
                            ZIndex = 6,
                        }, withChrome(nil, 5)),
                    }, 5, COLORS.Border, 0.65, 1)
                ),
                Minus = React.createElement(Button, {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -64, 0, 43),
                    Size = UDim2.fromOffset(42, 30),
                    Text = "−",
                    TextSize = 16,
                    OnActivated = function()
                        invoke("settings.update", { Key = key, Value = math.max(0, value - 0.1) })
                    end,
                    ZIndex = 6,
                }),
                Plus = React.createElement(Button, {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -14, 0, 43),
                    Size = UDim2.fromOffset(42, 30),
                    Text = "+",
                    TextSize = 16,
                    OnActivated = function()
                        invoke("settings.update", { Key = key, Value = math.min(1, value + 0.1) })
                    end,
                    ZIndex = 6,
                }),
            },
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, {
        Music = volumeRow("MusicVolume", "Music Volume", music, 0),
        Sfx = volumeRow("SfxVolume", "Sound Effects", sfx, 108),
        Damage = React.createElement(Panel, {
            Position = UDim2.fromOffset(0, 216),
            Size = UDim2.new(1, 0, 0, 92),
            BackgroundColor3 = COLORS.PanelRaised,
            Children = {
                Title = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 13),
                    Size = UDim2.fromOffset(250, 22),
                    Text = "Damage Numbers",
                    TextSize = 13,
                    Bold = true,
                    ZIndex = 5,
                }),
                Description = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 39),
                    Size = UDim2.new(1, -180, 0, 34),
                    Text = "Show floating combat damage above monsters.",
                    TextSize = 10,
                    Wrapped = true,
                    Color = COLORS.Muted,
                    ZIndex = 5,
                }),
                Toggle = React.createElement(Button, {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -16, 0.5, 0),
                    Size = UDim2.fromOffset(120, 40),
                    Text = settings.ShowDamageNumbers == false and "OFF" or "ON",
                    Tone = settings.ShowDamageNumbers == false and nil or "accent",
                    OnActivated = function()
                        invoke("settings.update", {
                            Key = "ShowDamageNumbers",
                            Value = settings.ShowDamageNumbers == false,
                        }, "Damage-number preference updated.")
                    end,
                    ZIndex = 6,
                }),
            },
        }),
        Hint = React.createElement(Label, {
            Position = UDim2.fromOffset(4, 332),
            Size = UDim2.new(1, -8, 0, 42),
            Text = "M opens Settings directly. Your settings are saved with your profile.",
            TextSize = 10,
            Wrapped = true,
            Color = COLORS.Faint,
            ZIndex = 5,
        }),
    })
end

local function MainMenu(props)
    local profile = props.Profile or {}
    local activeTab = props.ActiveTab or "CHARACTER"
    local status, setStatus = React.useState("Ready")
    local selectedInventoryIndex, setSelectedInventoryIndex = React.useState(1)
    local selectedSkillId, setSelectedSkillId = React.useState("beginner_strike")
    local catalog = CatalogClient.Get() or {}
    local tabs = { "CHARACTER", "INVENTORY", "SKILLS", "QUESTS", "SETTINGS" }

    local function invoke(action, payload, successText)
        local ok, result = ActionClient.Invoke(action, payload)
        if ok then
            setStatus(successText or "Updated.")
        else
            setStatus(string.format("%s · %s", action, tostring(result)))
        end
    end

    local content = nil
    if activeTab == "CHARACTER" then
        content = CharacterPanel(profile, invoke)
    elseif activeTab == "INVENTORY" then
        content = InventoryPanel(
            profile,
            catalog,
            invoke,
            selectedInventoryIndex,
            setSelectedInventoryIndex
        )
    elseif activeTab == "SKILLS" then
        content = SkillsPanel(profile, catalog, invoke, selectedSkillId, setSelectedSkillId)
    elseif activeTab == "QUESTS" then
        content = QuestsPanel(profile, catalog)
    else
        content = SettingsPanel(profile, invoke)
    end

    local navChildren = {}
    for index, tabName in tabs do
        local selected = activeTab == tabName
        navChildren[tabName] = React.createElement(
            "TextButton",
            {
                Position = UDim2.fromOffset(0, (index - 1) * 54),
                Size = UDim2.new(1, 0, 0, 46),
                BackgroundColor3 = selected and COLORS.AccentDark or COLORS.PanelRaised,
                BackgroundTransparency = selected and 0 or 0.22,
                BorderSizePixel = 0,
                Text = "",
                ZIndex = 34,
                [React.Event.Activated] = function()
                    if props.OnTabChanged then
                        props.OnTabChanged(tabName)
                    end
                    setStatus(tabName .. " opened")
                end,
            },
            withChrome({
                Key = React.createElement(Pill, {
                    Position = UDim2.fromOffset(9, 11),
                    Size = UDim2.fromOffset(25, 24),
                    Text = HOTKEYS[tabName],
                    TextSize = 10,
                    Color = selected and COLORS.Accent or COLORS.Surface,
                    TextColor = selected and COLORS.PanelDeep or COLORS.Muted,
                    ZIndex = 35,
                }),
                Leaf = if selected
                    then React.createElement(LeafGlyph, {
                        Position = UDim2.new(1, -28, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Size = UDim2.fromOffset(18, 18),
                        Color = COLORS.Lumen,
                        ZIndex = 36,
                    })
                    else nil,
                Name = React.createElement(Label, {
                    Position = UDim2.fromOffset(44, 0),
                    Size = UDim2.new(1, -78, 1, 0),
                    Text = tabName,
                    TextSize = 10,
                    Bold = true,
                    Color = selected and COLORS.Accent or COLORS.Muted,
                    ZIndex = 35,
                }),
            }, 9, selected and COLORS.BorderStrong or COLORS.Border, selected and 0.2 or 0.72, 1)
        )
    end

    return React.createElement(React.Fragment, nil, {
        Backdrop = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = COLORS.Backdrop,
            BackgroundTransparency = 0.48,
            BorderSizePixel = 0,
            ZIndex = 28,
        }),
        Menu = React.createElement(Panel, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(820, 540),
            BackgroundColor3 = COLORS.PanelDeep,
            StrokeColor = COLORS.BorderStrong,
            StrokeTransparency = 0.16,
            StrokeThickness = 1.2,
            Ornamented = true,
            OrnamentColor = COLORS.Lumen,
            ZIndex = 30,
            Children = {
                Header = React.createElement(
                    "Frame",
                    {
                        Position = UDim2.fromOffset(0, 0),
                        Size = UDim2.new(1, 0, 0, 64),
                        BackgroundColor3 = COLORS.Panel,
                        BorderSizePixel = 0,
                        ZIndex = 31,
                    },
                    withChrome({
                        Accent = React.createElement("Frame", {
                            Position = UDim2.fromOffset(0, 0),
                            Size = UDim2.fromOffset(5, 64),
                            BackgroundColor3 = COLORS.Accent,
                            BorderSizePixel = 0,
                            ZIndex = 33,
                        }),
                        Crest = React.createElement(LeafGlyph, {
                            Position = UDim2.fromOffset(18, 16),
                            Size = UDim2.fromOffset(30, 30),
                            Color = COLORS.Lumen,
                            ZIndex = 34,
                        }),
                        Brand = React.createElement(Label, {
                            Position = UDim2.fromOffset(54, 9),
                            Size = UDim2.fromOffset(218, 26),
                            Text = "EVERLEAF",
                            TextSize = 22,
                            Bold = true,
                            Color = COLORS.Accent,
                            ZIndex = 33,
                        }),
                        Subtitle = React.createElement(Label, {
                            Position = UDim2.fromOffset(54, 34),
                            Size = UDim2.fromOffset(308, 18),
                            Text = string.format(
                                "%s · Level %d",
                                string.upper(activeTab),
                                tonumber(profile.Level) or 1
                            ),
                            TextSize = 10,
                            Color = COLORS.Muted,
                            ZIndex = 33,
                        }),
                        Hint = React.createElement(Label, {
                            AnchorPoint = Vector2.new(1, 0.5),
                            Position = UDim2.new(1, -70, 0.5, 0),
                            Size = UDim2.fromOffset(300, 24),
                            Text = "C · I · K · J · M   switch panels",
                            TextSize = 9,
                            Color = COLORS.Faint,
                            Align = Enum.TextXAlignment.Right,
                            ZIndex = 33,
                        }),
                        Close = React.createElement(Button, {
                            AnchorPoint = Vector2.new(1, 0.5),
                            Position = UDim2.new(1, -16, 0.5, 0),
                            Size = UDim2.fromOffset(40, 36),
                            Text = "×",
                            TextSize = 19,
                            OnActivated = props.OnClose,
                            ZIndex = 34,
                        }),
                    }, 12)
                ),
                Nav = React.createElement("Frame", {
                    Position = UDim2.fromOffset(18, 82),
                    Size = UDim2.fromOffset(152, 262),
                    BackgroundTransparency = 1,
                    ZIndex = 33,
                }, navChildren),
                NavFooter = React.createElement(Panel, {
                    Position = UDim2.fromOffset(18, 360),
                    Size = UDim2.fromOffset(152, 126),
                    BackgroundColor3 = COLORS.Panel,
                    StrokeTransparency = 0.68,
                    Children = {
                        Title = React.createElement(Label, {
                            Position = UDim2.fromOffset(12, 10),
                            Size = UDim2.new(1, -24, 0, 18),
                            Text = "SHORTCUTS",
                            TextSize = 9,
                            Bold = true,
                            Color = COLORS.Muted,
                            ZIndex = 34,
                        }),
                        Body = React.createElement(Label, {
                            Position = UDim2.fromOffset(12, 31),
                            Size = UDim2.new(1, -24, 0, 76),
                            Text = "1–8  Skills\nE  Interact\nQ  Dodge\nEsc  Close",
                            TextSize = 9,
                            Color = COLORS.Faint,
                            VerticalAlign = Enum.TextYAlignment.Top,
                            ZIndex = 34,
                        }),
                    },
                }),
                Content = React.createElement("Frame", {
                    Position = UDim2.fromOffset(188, 82),
                    Size = UDim2.fromOffset(614, 404),
                    BackgroundTransparency = 1,
                    ZIndex = 33,
                }, { Content = content }),
                Status = React.createElement(
                    "Frame",
                    {
                        Position = UDim2.fromOffset(188, 496),
                        Size = UDim2.fromOffset(614, 28),
                        BackgroundColor3 = COLORS.Panel,
                        BackgroundTransparency = 0.12,
                        BorderSizePixel = 0,
                        ZIndex = 33,
                    },
                    withChrome({
                        Dot = React.createElement("Frame", {
                            Position = UDim2.fromOffset(10, 10),
                            Size = UDim2.fromOffset(8, 8),
                            BackgroundColor3 = COLORS.Accent,
                            BorderSizePixel = 0,
                            ZIndex = 34,
                        }, withChrome(nil, 999)),
                        Text = React.createElement(Label, {
                            Position = UDim2.fromOffset(26, 0),
                            Size = UDim2.new(1, -36, 1, 0),
                            Text = status,
                            TextSize = 9,
                            Color = COLORS.Muted,
                            ZIndex = 34,
                        }),
                    }, 7)
                ),
            },
        }),
    })
end

local function DeathOverlay()
    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(7, 8, 9),
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        ZIndex = 80,
    }, {
        Card = React.createElement(Panel, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(470, 178),
            BackgroundColor3 = Color3.fromRGB(24, 20, 20),
            StrokeColor = Color3.fromRGB(115, 73, 73),
            StrokeTransparency = 0.18,
            ZIndex = 81,
            Children = {
                Kicker = React.createElement(Label, {
                    Position = UDim2.fromOffset(22, 18),
                    Size = UDim2.new(1, -44, 0, 20),
                    Text = "THE LUMEN FADES",
                    TextSize = 10,
                    Bold = true,
                    Color = COLORS.Danger,
                    Align = Enum.TextXAlignment.Center,
                    ZIndex = 82,
                }),
                Title = React.createElement(Label, {
                    Position = UDim2.fromOffset(22, 46),
                    Size = UDim2.new(1, -44, 0, 44),
                    Text = "FALLEN",
                    TextSize = 34,
                    Bold = true,
                    Align = Enum.TextXAlignment.Center,
                    ZIndex = 82,
                }),
                Divider = React.createElement("Frame", {
                    Position = UDim2.fromOffset(72, 100),
                    Size = UDim2.new(1, -144, 0, 1),
                    BackgroundColor3 = Color3.fromRGB(106, 73, 73),
                    BackgroundTransparency = 0.35,
                    BorderSizePixel = 0,
                    ZIndex = 82,
                }),
                Subtitle = React.createElement(Label, {
                    Position = UDim2.fromOffset(22, 111),
                    Size = UDim2.new(1, -44, 0, 38),
                    Text = "Returning to Lumenreach Wayfarer Camp...",
                    TextSize = 13,
                    Color = COLORS.Muted,
                    Align = Enum.TextXAlignment.Center,
                    Wrapped = true,
                    ZIndex = 82,
                }),
            },
        }),
    })
end

local function App()
    local profile, setProfile = React.useState(ProfileStore.Get())
    local interaction, setInteraction = React.useState(nil)
    local menuOpen, setMenuOpen = React.useState(false)
    local menuTab, setMenuTab = React.useState("CHARACTER")
    local health, setHealth = React.useState(100)
    local maxHealth, setMaxHealth = React.useState(100)
    local dead, setDead = React.useState(false)

    React.useEffect(function()
        local connection = ProfileStore.Subscribe(setProfile)
        return function()
            connection:Disconnect()
        end
    end, {})

    React.useEffect(function()
        local healthConnection = nil
        local maxConnection = nil
        local bindGeneration = 0

        local function bindCharacter(character)
            bindGeneration += 1
            local generation = bindGeneration
            if healthConnection then
                healthConnection:Disconnect()
                healthConnection = nil
            end
            if maxConnection then
                maxConnection:Disconnect()
                maxConnection = nil
            end

            setInteraction(nil)
            setMenuOpen(false)
            setDead(false)
            player:SetAttribute("EverLeafUiCapture", false)

            local humanoid = character:WaitForChild("Humanoid")
            if generation ~= bindGeneration or character ~= player.Character then
                return
            end

            setHealth(humanoid.Health)
            setMaxHealth(humanoid.MaxHealth)
            setDead(humanoid.Health <= 0)
            healthConnection = humanoid.HealthChanged:Connect(function(value)
                if generation ~= bindGeneration then
                    return
                end
                setHealth(value)
                setDead(value <= 0)
            end)
            maxConnection = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
                if generation == bindGeneration then
                    setMaxHealth(humanoid.MaxHealth)
                end
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
                setMenuOpen(false)
                setInteraction(payload)
            end
        end)
        return function()
            connection:Disconnect()
        end
    end, {})

    React.useEffect(function()
        player:SetAttribute("EverLeafUiCapture", interaction ~= nil or menuOpen or dead)
        return function()
            player:SetAttribute("EverLeafUiCapture", false)
        end
    end, { interaction, menuOpen, dead })

    React.useEffect(function()
        local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or dead then
                return
            end

            if interaction == nil then
                local tabByKey = {
                    [Enum.KeyCode.C] = "CHARACTER",
                    [Enum.KeyCode.I] = "INVENTORY",
                    [Enum.KeyCode.K] = "SKILLS",
                    [Enum.KeyCode.J] = "QUESTS",
                    [Enum.KeyCode.M] = "SETTINGS",
                }
                local requestedTab = tabByKey[input.KeyCode]
                if requestedTab then
                    if menuOpen and menuTab == requestedTab then
                        setMenuOpen(false)
                    else
                        setMenuTab(requestedTab)
                        setMenuOpen(true)
                    end
                    return
                end
            end

            if input.KeyCode == Enum.KeyCode.Escape then
                if interaction ~= nil then
                    setInteraction(nil)
                elseif menuOpen then
                    setMenuOpen(false)
                end
            end
        end)
        return function()
            connection:Disconnect()
        end
    end, { interaction, menuOpen, menuTab, dead })

    local uiOpen = interaction ~= nil or menuOpen
    return React.createElement(React.Fragment, nil, {
        HUD = React.createElement(HUD, {
            Profile = profile,
            Health = health,
            MaxHealth = maxHealth,
            UiOpen = uiOpen,
        }),
        Menu = menuOpen and React.createElement(MainMenu, {
            Profile = profile,
            ActiveTab = menuTab,
            OnTabChanged = setMenuTab,
            OnClose = function()
                setMenuOpen(false)
            end,
        }) or nil,
        Dialogue = interaction and React.createElement(Dialogue, {
            Description = interaction,
            Profile = profile,
            OnClose = function()
                setInteraction(nil)
            end,
        }) or nil,
        Death = dead and React.createElement(DeathOverlay) or nil,
    })
end

function ReactUIController.Start()
    local playerGui = player:WaitForChild("PlayerGui")
    local existing = playerGui:FindFirstChild("EverLeafReactMount")
    if existing then
        existing:Destroy()
    end

    local mount = Instance.new("ScreenGui")
    mount.Name = "EverLeafReactMount"
    mount.ResetOnSpawn = false
    mount.IgnoreGuiInset = true
    mount.DisplayOrder = 10
    mount.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mount.Parent = playerGui

    reactRoot = ReactRoblox.createRoot(mount)
    reactRoot:render(React.createElement(App))
end

return ReactUIController
