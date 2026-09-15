local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local ActionClient = require(script.Parent.Parent.Services.ActionClient)
local CatalogClient = require(script.Parent.Parent.Services.CatalogClient)
local PartyStore = require(script.Parent.Parent.State.PartyStore)
local ProfileStore = require(script.Parent.Parent.State.ProfileStore)
local SkillCooldownStore = require(script.Parent.Parent.State.SkillCooldownStore)
local EverLeafIcons = require(script.Parent.Parent.UI.EverLeafIcons)
local NotificationStore = require(script.Parent.Parent.UI.NotificationStore)
local StatText = require(script.Parent.Parent.UI.StatText)
local BossHud = require(script.Parent.Parent.UI.Components.BossHud)
local PartyHud = require(script.Parent.Parent.UI.Components.PartyHud)
local PartyOverlay = require(script.Parent.Parent.UI.Components.PartyOverlay)
local PlayerDamageFeedback = require(script.Parent.Parent.UI.Components.PlayerDamageFeedback)
local AdvancementOverlay = require(script.Parent.Parent.UI.Components.AdvancementOverlay)
local CosmeticsPanel = require(script.Parent.Parent.UI.Components.CosmeticsPanel)
local ShopOverlay = require(script.Parent.Parent.UI.Components.ShopOverlay)
local PremiumShopPanel = require(script.Parent.Parent.UI.Components.PremiumShopPanel)
local ToastStack = require(script.Parent.Parent.UI.Components.ToastStack)
local EquipmentEligibilityRules = require(ReplicatedStorage.Shared.Logic.EquipmentEligibilityRules)
local EquipmentComparisonRules = require(ReplicatedStorage.Shared.Logic.EquipmentComparisonRules)
local SkillProgressionRules = require(ReplicatedStorage.Shared.Logic.SkillProgressionRules)
local Net = require(ReplicatedStorage.Shared.Net)
local ProgressionMath = require(ReplicatedStorage.Shared.Math.ProgressionMath)
local StatusEffectDefinitions = require(ReplicatedStorage.Shared.StatusEffectDefinitions)

local ReactUIController = {}
local player = Players.LocalPlayer
local reactRoot = nil

local UI_REFERENCE_SIZE = Vector2.new(1280, 720)
local UI_MAX_SCALE = 1.6

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
    COSMETICS = "V",
    STORE = "O",
    SETTINGS = "M",
})

local GAMEPAD_HOTBAR_LABELS = table.freeze({ "DL", "DU", "DR", "DD", "L1", "R1", "L2", "R3" })

local function inputModeFromType(inputType)
    if inputType and string.find(inputType.Name, "Gamepad", 1, true) then
        return "GAMEPAD"
    elseif inputType == Enum.UserInputType.Touch then
        return "TOUCH"
    end
    return "KEYBOARD"
end

local function selectNamedObject(name)
    if type(name) ~= "string" or name == "" then
        return
    end
    task.defer(function()
        local playerGui = player:FindFirstChildOfClass("PlayerGui")
        local mount = playerGui and playerGui:FindFirstChild("EverLeafReactMount")
        local target = mount and mount:FindFirstChild(name, true)
        if target and target:IsA("GuiObject") and target.Visible and target.Selectable then
            GuiService.SelectedObject = target
        end
    end)
end

local NAV_ICONS = table.freeze({
    CHARACTER = EverLeafIcons.Character,
    INVENTORY = EverLeafIcons.Inventory,
    SKILLS = EverLeafIcons.Skills,
    QUESTS = EverLeafIcons.Quests,
    COSMETICS = EverLeafIcons.Mark,
    STORE = EverLeafIcons.Shard,
    SETTINGS = EverLeafIcons.Settings,
})

local SKILL_ICONS = table.freeze({
    beginner_strike = EverLeafIcons.BeginnerStrike,
    steady_footing = EverLeafIcons.SteadyFooting,
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
        TextTruncate = props.TextTruncate or Enum.TextTruncate.None,
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
        children.FrameArt = React.createElement("ImageLabel", {
            Position = UDim2.fromScale(0, 0),
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Image = EverLeafIcons.FrameBorder,
            ImageTransparency = 0.08,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(64, 64, 192, 192),
            SliceScale = 0.72,
            ZIndex = (props.ZIndex or 1) + 2,
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

local function ResourceMeter(props)
    local fraction = ratio(props.Value or 0, props.Maximum or 1)
    local z = props.ZIndex or 3
    return React.createElement(
        "Frame",
        {
            Position = props.Position,
            Size = props.Size,
            BackgroundColor3 = Color3.fromRGB(8, 15, 14),
            BackgroundTransparency = 0.02,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = z,
        },
        withChrome({
            Tag = React.createElement(
                "Frame",
                {
                    Size = UDim2.fromOffset(42, props.Size.Y.Offset),
                    BackgroundColor3 = props.TagColor,
                    BackgroundTransparency = 0.08,
                    BorderSizePixel = 0,
                    ZIndex = z + 1,
                },
                withChrome({
                    Text = React.createElement(Label, {
                        Size = UDim2.fromScale(1, 1),
                        Text = props.Tag,
                        TextSize = 10,
                        Bold = true,
                        Align = Enum.TextXAlignment.Center,
                        Color = COLORS.Text,
                        ZIndex = z + 2,
                    }),
                }, 5)
            ),
            Track = React.createElement(
                "Frame",
                {
                    Position = UDim2.fromOffset(48, 5),
                    Size = UDim2.new(1, -55, 1, -10),
                    BackgroundColor3 = Color3.fromRGB(25, 34, 32),
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    ZIndex = z + 1,
                },
                withChrome({
                    Fill = React.createElement(
                        "Frame",
                        {
                            Size = UDim2.fromScale(fraction, 1),
                            BackgroundColor3 = props.FillColor,
                            BorderSizePixel = 0,
                            ZIndex = z + 2,
                        },
                        withChrome({
                            Gradient = React.createElement("UIGradient", {
                                Color = ColorSequence.new({
                                    ColorSequenceKeypoint.new(
                                        0,
                                        props.FillColor:Lerp(Color3.new(1, 1, 1), 0.12)
                                    ),
                                    ColorSequenceKeypoint.new(
                                        1,
                                        props.FillColor:Lerp(Color3.new(0, 0, 0), 0.14)
                                    ),
                                }),
                            }),
                        }, 4)
                    ),
                    Value = React.createElement(Label, {
                        Size = UDim2.fromScale(1, 1),
                        Text = props.Text,
                        TextSize = 10,
                        Bold = true,
                        Align = Enum.TextXAlignment.Center,
                        ZIndex = z + 3,
                    }),
                }, 4, COLORS.Border, 0.72, 1)
            ),
        }, 6, COLORS.BorderStrong, 0.58, 1)
    )
end

local function Icon(props)
    return React.createElement("ImageLabel", {
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = props.Size or UDim2.fromOffset(28, 28),
        BackgroundTransparency = 1,
        Image = props.Image or "",
        ImageTransparency = props.ImageTransparency or 0,
        ScaleType = Enum.ScaleType.Fit,
        ResampleMode = Enum.ResamplerMode.Default,
        ZIndex = props.ZIndex or 4,
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

local function regionDisplayName(profile)
    local world = profile and profile.World or {}
    local regionId = world.RegionId or "lumenreach"
    local catalog = CatalogClient.Get()
    local region = catalog and catalog.Regions and catalog.Regions[regionId]
    return region and region.DisplayName or prettyId(regionId), regionId
end

local function objectiveText(objective, progress, fallbackText)
    if not objective then
        return fallbackText or "Explore"
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
    local now, setNow = React.useState(os.clock())
    React.useEffect(function()
        local active = true
        task.spawn(function()
            while active do
                task.wait(0.1)
                if active then
                    setNow(os.clock())
                end
            end
        end)
        return function()
            active = false
        end
    end, {})

    local catalog = CatalogClient.Get()
    local profile = props.Profile or {}
    local hotbar = profile.Skills and profile.Skills.Hotbar or {}
    local resources = profile.Resources or {}
    local currentMP = tonumber(resources.CurrentMP) or 0
    local children = {}

    for index = 1, 8 do
        local skillId = hotbar[tostring(index)] or hotbar[index]
        local definition = skillId and catalog and catalog.Skills and catalog.Skills[skillId]
        local displayName = if definition
            then definition.DisplayName
            else if skillId then tostring(skillId) else "Empty"
        local occupied = skillId ~= nil and skillId ~= ""
        local mpCost = definition and (tonumber(definition.MPCost) or 0) or 0
        local cooldownDuration = definition and (tonumber(definition.Cooldown) or 0) or 0
        local cooldownRemaining = occupied and SkillCooldownStore.Remaining(skillId, now) or 0
        local cooldownFraction = if cooldownDuration > 0
            then math.clamp(cooldownRemaining / cooldownDuration, 0, 1)
            else 0
        local lowMP = occupied and mpCost > currentMP
        local strokeColor = if lowMP
            then COLORS.Danger
            else if occupied then COLORS.BorderStrong else COLORS.Border

        children["Slot" .. index] = React.createElement(
            "Frame",
            {
                Position = UDim2.fromOffset(9 + (index - 1) * 72, 8),
                Size = UDim2.fromOffset(64, 58),
                BackgroundColor3 = occupied and COLORS.PanelRaised or COLORS.PanelDeep,
                BackgroundTransparency = occupied and 0.02 or 0.2,
                BorderSizePixel = 0,
                ClipsDescendants = true,
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
                        ZIndex = 6,
                    },
                    withChrome({
                        Text = React.createElement(Label, {
                            Size = UDim2.fromScale(1, 1),
                            Text = props.InputMode == "GAMEPAD" and GAMEPAD_HOTBAR_LABELS[index]
                                or tostring(index),
                            TextSize = 10,
                            Bold = true,
                            Align = Enum.TextXAlignment.Center,
                            Color = lowMP and Color3.fromRGB(255, 182, 182)
                                or if occupied then COLORS.Accent else COLORS.Muted,
                            ZIndex = 7,
                        }),
                    }, 5)
                ),
                Cost = occupied and mpCost > 0 and React.createElement(Label, {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -4, 0, 4),
                    Size = UDim2.fromOffset(34, 14),
                    Text = tostring(mpCost) .. " MP",
                    TextSize = 7,
                    Bold = true,
                    Align = Enum.TextXAlignment.Right,
                    Color = lowMP and Color3.fromRGB(255, 151, 151) or COLORS.Mana,
                    ZIndex = 7,
                }) or nil,
                SkillIcon = occupied
                        and React.createElement(Icon, {
                            Position = UDim2.new(0.5, 0, 0, 8),
                            AnchorPoint = Vector2.new(0.5, 0),
                            Size = UDim2.fromOffset(30, 30),
                            Image = SKILL_ICONS[skillId] or EverLeafIcons.Skills,
                            ImageTransparency = cooldownRemaining > 0 and 0.42
                                or if lowMP then 0.28 else 0,
                            ZIndex = 4,
                        })
                    or nil,
                CooldownBack = cooldownRemaining > 0 and React.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Position = UDim2.new(0.5, 0, 0, 7),
                    Size = UDim2.fromOffset(36, 34),
                    BackgroundColor3 = COLORS.Backdrop,
                    BackgroundTransparency = 0.12 + (1 - cooldownFraction) * 0.28,
                    BorderSizePixel = 0,
                    ZIndex = 5,
                }, withChrome(nil, 6, COLORS.Border, 0.7, 1)) or nil,
                Cooldown = cooldownRemaining > 0 and React.createElement(Label, {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Position = UDim2.new(0.5, 0, 0, 12),
                    Size = UDim2.fromOffset(44, 24),
                    Text = if cooldownRemaining >= 10
                        then string.format("%.0f", cooldownRemaining)
                        else string.format("%.1f", cooldownRemaining),
                    TextSize = 11,
                    Bold = true,
                    Align = Enum.TextXAlignment.Center,
                    Color = COLORS.Text,
                    ZIndex = 8,
                }) or nil,
                Skill = React.createElement(Label, {
                    Position = UDim2.fromOffset(4, 38),
                    Size = UDim2.new(1, -8, 0, 16),
                    Text = occupied and displayName or "Empty",
                    TextSize = 8,
                    Align = Enum.TextXAlignment.Center,
                    Wrapped = true,
                    Color = lowMP and Color3.fromRGB(225, 151, 151)
                        or if occupied then COLORS.Text else COLORS.Faint,
                    ZIndex = 7,
                }),
            }, 9, strokeColor, occupied and 0.34 or 0.65, 1)
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
    local regionName, regionId = regionDisplayName(profile)
    local catalog = CatalogClient.Get()
    local title = "Explore " .. regionName
    local progressText = if regionId == "lumenreach"
        then "Speak with Ilyra at Wayfarer Camp"
        else "Speak with local Wayfarers or check your quest log for available work"
    local ready = false

    if active then
        local questId, state = next(active)
        if questId then
            local definition = catalog and catalog.Quests and catalog.Quests[questId]
            title = definition and definition.DisplayName or tostring(questId)
            ready = state.ReadyToTurnIn == true
            if ready then
                progressText = "Ready to turn in"
            else
                local objective = definition and definition.Objectives and definition.Objectives[1]
                local progress = state.Progress and state.Progress[1] or 0
                progressText = objectiveText(objective, progress, "Explore " .. regionName)
            end
        end
    end

    local accent = ready and COLORS.Gold or COLORS.Lumen
    return React.createElement(Panel, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 26, 0.5, -8),
        Size = UDim2.fromOffset(338, 112),
        Visible = not props.Hidden,
        BackgroundColor3 = Color3.fromRGB(10, 18, 17),
        BackgroundTransparency = 0.04,
        Radius = 7,
        StrokeColor = accent,
        StrokeTransparency = 0.42,
        Children = {
            Rail = React.createElement("Frame", {
                Size = UDim2.fromOffset(5, 112),
                BackgroundColor3 = accent,
                BorderSizePixel = 0,
                ZIndex = 3,
            }),
            IconBack = React.createElement(
                "Frame",
                {
                    Position = UDim2.fromOffset(18, 18),
                    Size = UDim2.fromOffset(46, 46),
                    BackgroundColor3 = ready and Color3.fromRGB(79, 60, 35)
                        or Color3.fromRGB(25, 65, 49),
                    BorderSizePixel = 0,
                    ZIndex = 3,
                },
                withChrome({
                    Icon = React.createElement(Icon, {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromOffset(34, 34),
                        Image = EverLeafIcons.Objective,
                        ZIndex = 4,
                    }),
                }, 9, accent, 0.46, 1)
            ),
            Kicker = React.createElement(Label, {
                Position = UDim2.fromOffset(78, 16),
                Size = UDim2.new(1, -94, 0, 18),
                Text = ready and "READY TO TURN IN" or "CURRENT OBJECTIVE",
                TextSize = 9,
                Bold = true,
                Color = accent,
                ZIndex = 4,
            }),
            Title = React.createElement(Label, {
                Position = UDim2.fromOffset(78, 34),
                Size = UDim2.new(1, -94, 0, 28),
                Text = title,
                TextSize = 15,
                Bold = true,
                ZIndex = 4,
            }),
            Divider = React.createElement("Frame", {
                Position = UDim2.fromOffset(78, 67),
                Size = UDim2.new(1, -94, 0, 1),
                BackgroundColor3 = accent,
                BackgroundTransparency = 0.72,
                BorderSizePixel = 0,
                ZIndex = 3,
            }),
            Progress = React.createElement(Label, {
                Position = UDim2.fromOffset(78, 72),
                Size = UDim2.new(1, -94, 0, 28),
                Text = progressText,
                TextSize = 10,
                Wrapped = true,
                Color = COLORS.Muted,
                VerticalAlign = Enum.TextYAlignment.Top,
                ZIndex = 4,
            }),
        },
    })
end

local function StatusStrip(props)
    local now, setNow = React.useState(os.clock())
    React.useEffect(function()
        local active = true
        task.spawn(function()
            while active do
                task.wait(0.1)
                if active then
                    setNow(os.clock())
                end
            end
        end)
        return function()
            active = false
        end
    end, {})

    local profile = props.Profile or {}
    local receivedAt = tonumber(profile.StatusEffectsLocalReceivedAt) or now
    local elapsed = math.max(0, now - receivedAt)
    local entries = {}
    for effectId, snapshotRemaining in profile.StatusEffects or {} do
        local remaining = math.max(0, (tonumber(snapshotRemaining) or 0) - elapsed)
        if remaining > 0 then
            local definition = StatusEffectDefinitions[effectId] or {}
            table.insert(entries, {
                Id = effectId,
                Name = definition.ShortName or definition.DisplayName or prettyId(effectId),
                Kind = definition.Kind or "Debuff",
                Remaining = remaining,
            })
        end
    end
    table.sort(entries, function(a, b)
        if a.Kind ~= b.Kind then
            return a.Kind == "Debuff"
        end
        return a.Id < b.Id
    end)

    if #entries == 0 or props.Hidden then
        return nil
    end

    local children = {}
    for index = 1, math.min(3, #entries) do
        local entry = entries[index]
        local debuff = entry.Kind == "Debuff"
        local accent = debuff and Color3.fromRGB(220, 103, 92) or COLORS.Lumen
        children[entry.Id] = React.createElement(
            "Frame",
            {
                Position = UDim2.fromOffset((index - 1) * 108, 0),
                Size = UDim2.fromOffset(102, 32),
                BackgroundColor3 = COLORS.PanelDeep,
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                ZIndex = 4,
            },
            withChrome({
                Rail = React.createElement("Frame", {
                    Size = UDim2.fromOffset(3, 32),
                    BackgroundColor3 = accent,
                    BorderSizePixel = 0,
                    ZIndex = 5,
                }),
                Name = React.createElement(Label, {
                    Position = UDim2.fromOffset(9, 3),
                    Size = UDim2.new(1, -14, 0, 13),
                    Text = string.upper(entry.Name),
                    TextSize = 7,
                    Bold = true,
                    Color = accent,
                    ZIndex = 6,
                }),
                Time = React.createElement(Label, {
                    Position = UDim2.fromOffset(9, 15),
                    Size = UDim2.new(1, -14, 0, 13),
                    Text = if entry.Remaining < 1
                        then string.format("%.1fs", entry.Remaining)
                        else string.format("%ds", math.ceil(entry.Remaining)),
                    TextSize = 8,
                    Color = COLORS.Muted,
                    ZIndex = 6,
                }),
            }, 6, accent, 0.5, 1)
        )
    end

    return React.createElement("Frame", {
        Position = UDim2.fromOffset(24, 236),
        Size = UDim2.fromOffset(326, 32),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, children)
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
    local regionName = regionDisplayName(profile)
    local compactVisible = not props.UiOpen

    return React.createElement(React.Fragment, nil, {
        Status = React.createElement(Panel, {
            Position = UDim2.fromOffset(24, 98),
            Size = UDim2.fromOffset(326, 130),
            BackgroundColor3 = Color3.fromRGB(10, 18, 17),
            BackgroundTransparency = 0.03,
            Radius = 7,
            StrokeColor = COLORS.BorderStrong,
            StrokeTransparency = 0.42,
            Visible = compactVisible,
            Children = {
                TopAccent = React.createElement("Frame", {
                    Position = UDim2.fromOffset(14, 8),
                    Size = UDim2.new(1, -28, 0, 2),
                    BackgroundColor3 = COLORS.Lumen,
                    BackgroundTransparency = 0.28,
                    BorderSizePixel = 0,
                    ZIndex = 3,
                }),
                Level = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 14),
                    Size = UDim2.fromOffset(100, 28),
                    Text = string.format("LEVEL %d", level),
                    TextSize = 12,
                    Bold = true,
                    Color = COLORS.LumenPale,
                    ZIndex = 4,
                }),
                Region = React.createElement(Label, {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -16, 0, 14),
                    Size = UDim2.fromOffset(150, 28),
                    Text = string.upper(regionName),
                    TextSize = 10,
                    Bold = true,
                    Color = COLORS.Muted,
                    Align = Enum.TextXAlignment.Right,
                    ZIndex = 4,
                }),
                HP = React.createElement(ResourceMeter, {
                    Position = UDim2.fromOffset(16, 46),
                    Size = UDim2.fromOffset(294, 30),
                    Tag = "HP",
                    TagColor = Color3.fromRGB(117, 44, 48),
                    FillColor = COLORS.Health,
                    Value = props.Health,
                    Maximum = props.MaxHealth,
                    Text = string.format(
                        "%d / %d",
                        math.floor(props.Health + 0.5),
                        math.floor(props.MaxHealth + 0.5)
                    ),
                    ZIndex = 4,
                }),
                MP = React.createElement(ResourceMeter, {
                    Position = UDim2.fromOffset(16, 84),
                    Size = UDim2.fromOffset(294, 30),
                    Tag = "MP",
                    TagColor = Color3.fromRGB(45, 79, 126),
                    FillColor = COLORS.Mana,
                    Value = currentMP,
                    Maximum = maxMP,
                    Text = string.format("%d / %d", math.floor(currentMP), math.floor(maxMP)),
                    ZIndex = 4,
                }),
            },
        }),
        StatusEffects = React.createElement(StatusStrip, {
            Profile = profile,
            Hidden = props.UiOpen,
        }),
        Currency = React.createElement(Panel, {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -24, 0, 98),
            Size = UDim2.fromOffset(238, 106),
            BackgroundColor3 = Color3.fromRGB(10, 18, 17),
            BackgroundTransparency = 0.03,
            Radius = 7,
            StrokeColor = COLORS.BorderStrong,
            StrokeTransparency = 0.42,
            Visible = compactVisible,
            Children = {
                Header = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 10),
                    Size = UDim2.new(1, -32, 0, 18),
                    Text = "WAYFARER WALLET",
                    TextSize = 9,
                    Bold = true,
                    Color = COLORS.Faint,
                    ZIndex = 4,
                }),
                Divider = React.createElement("Frame", {
                    Position = UDim2.fromOffset(16, 31),
                    Size = UDim2.new(1, -32, 0, 1),
                    BackgroundColor3 = COLORS.BorderStrong,
                    BackgroundTransparency = 0.72,
                    BorderSizePixel = 0,
                    ZIndex = 3,
                }),
                ShardIcon = React.createElement(Icon, {
                    Position = UDim2.fromOffset(14, 37),
                    Size = UDim2.fromOffset(30, 30),
                    Image = EverLeafIcons.Shard,
                    ZIndex = 4,
                }),
                ShardName = React.createElement(Label, {
                    Position = UDim2.fromOffset(52, 36),
                    Size = UDim2.fromOffset(92, 30),
                    Text = "SHARDS",
                    TextSize = 10,
                    Bold = true,
                    Color = COLORS.Muted,
                    ZIndex = 4,
                }),
                ShardValue = React.createElement(Label, {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -16, 0, 36),
                    Size = UDim2.fromOffset(70, 30),
                    Text = tostring(tonumber(currencies.Shards) or 0),
                    TextSize = 15,
                    Bold = true,
                    Align = Enum.TextXAlignment.Right,
                    Color = COLORS.LumenPale,
                    ZIndex = 4,
                }),
                MarkIcon = React.createElement(Icon, {
                    Position = UDim2.fromOffset(14, 69),
                    Size = UDim2.fromOffset(30, 30),
                    Image = EverLeafIcons.Mark,
                    ZIndex = 4,
                }),
                MarkName = React.createElement(Label, {
                    Position = UDim2.fromOffset(52, 68),
                    Size = UDim2.fromOffset(92, 30),
                    Text = "MARKS",
                    TextSize = 10,
                    Bold = true,
                    Color = COLORS.Muted,
                    ZIndex = 4,
                }),
                MarkValue = React.createElement(Label, {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -16, 0, 68),
                    Size = UDim2.fromOffset(70, 30),
                    Text = tostring(tonumber(currencies.Marks) or 0),
                    TextSize = 15,
                    Bold = true,
                    Align = Enum.TextXAlignment.Right,
                    Color = COLORS.Gold,
                    ZIndex = 4,
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
                Size = UDim2.fromOffset(586, 10),
                BackgroundColor3 = Color3.fromRGB(8, 15, 14),
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
                }, withChrome(nil, 4)),
            }, 4, COLORS.Border, 0.62, 1)
        ),
        ExpText = React.createElement(Label, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -112),
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
            InputMode = props.InputMode,
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
        actionChildren.DialogueQuest = React.createElement(Button, {
            Position = UDim2.fromOffset(22, 198),
            Size = UDim2.fromOffset(220, 44),
            Text = questButtonText,
            Active = questButtonEnabled,
            Tone = readyToTurnIn and "accent" or nil,
            OnActivated = activateQuestButton,
            ZIndex = 24,
        })
    end
    if description.ShopId and props.OnOpenShop then
        actionChildren.DialogueShop = React.createElement(Button, {
            Position = UDim2.fromOffset(22, questId and 250 or 198),
            Size = UDim2.fromOffset(220, 44),
            Text = "OPEN " .. string.upper(description.ShopDisplayName or "SHOP"),
            Tone = "accent",
            OnActivated = props.OnOpenShop,
            ZIndex = 24,
        })
    end
    if description.AdvancementMentor and props.OnOpenAdvancement then
        local currentTier = tonumber(profile.AdvancementTier) or 0
        local targetTier = tonumber(description.AdvancementTargetTier) or 1
        local advancementText = if targetTier == 1
            then if currentTier >= 1 then "FIRST PATH BOUND" else "CHOOSE FIRST PATH"
            else if currentTier >= targetTier
                then string.format("TIER %d COMPLETE", targetTier)
                else string.format("ADVANCE TO TIER %d", targetTier)
        actionChildren.DialogueAdvancement = React.createElement(Button, {
            Position = UDim2.fromOffset(22, questId and 250 or 198),
            Size = UDim2.fromOffset(220, 44),
            Text = advancementText,
            Tone = "accent",
            Active = currentTier == targetTier - 1,
            OnActivated = props.OnOpenAdvancement,
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
                Crest = React.createElement(Icon, {
                    Position = UDim2.fromOffset(16, 12),
                    Size = UDim2.fromOffset(34, 34),
                    Image = EverLeafIcons.Character,
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
                DialogueClose = React.createElement(Button, {
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

local function equipmentRequirementText(definition, catalog)
    if not definition or definition.Type ~= "Equipment" then
        return ""
    end
    local parts = {}
    local requiredLevel = tonumber(definition.RequiredLevel) or 1
    local requiredTier = tonumber(definition.RequiredAdvancementTier) or 0
    if requiredLevel > 1 then
        table.insert(parts, "Level " .. tostring(requiredLevel))
    end
    if requiredTier > 0 then
        table.insert(parts, "Tier " .. tostring(requiredTier))
    end
    local familyId = definition.FamilyId
    if type(familyId) == "string" and familyId ~= "" then
        local family = catalog and catalog.Families and catalog.Families[familyId]
        table.insert(parts, family and family.DisplayName or prettyId(familyId))
    end
    return #parts > 0 and ("Requires " .. table.concat(parts, " · ")) or "No requirements"
end

local EQUIPMENT_LOCK_TEXT = table.freeze({
    wrong_family = "WRONG FAMILY",
    tier_too_low = "TIER REQUIRED",
    level_too_low = "LEVEL REQUIRED",
})

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
        table.insert(parts, StatText.Format(statName, amount))
    end
    return table.concat(parts, "  ·  ")
end

local function CharacterPanel(profile, invoke)
    local stats = profile.Stats or {}
    local derived = profile.Derived or {}
    local level = tonumber(profile.Level) or 1
    local ap = tonumber(profile.AP) or 0
    local sp = tonumber(profile.SP) or 0
    local advancementTier = tonumber(profile.AdvancementTier) or 0
    local catalog = CatalogClient.Get() or {}
    local family = type(profile.FamilyId) == "string"
            and profile.FamilyId ~= ""
            and catalog.Families
            and catalog.Families[profile.FamilyId]
        or nil
    local advancementTitle = if family
        then if advancementTier >= 2 and family.SecondAdvancement
            then family.SecondAdvancement.DisplayName
            else family.DisplayName
        else nil
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
                    Size = UDim2.fromOffset(300, 24),
                    Text = advancementTitle
                            and string.format("%s · Tier %d", advancementTitle, advancementTier)
                        or "Unbound Wayfarer · Tier 0",
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
                    Position = UDim2.new(1, -248, 0, 39),
                    Size = UDim2.fromOffset(228, 18),
                    Text = string.format(
                        "HP %s  ·  MP %s",
                        tostring(derived.MaxHP or "—"),
                        tostring(derived.MaxMP or "—")
                    ),
                    TextSize = 10,
                    Color = COLORS.Muted,
                    Align = Enum.TextXAlignment.Right,
                    ZIndex = 5,
                }),
                CombatStats = React.createElement(Label, {
                    Position = UDim2.new(1, -390, 0, 58),
                    Size = UDim2.fromOffset(370, 18),
                    Text = string.format(
                        "DEF %s  ·  ATK SPD %.1f%%  ·  CRIT %.1f%%  ·  CRIT DMG %.0f%%",
                        tostring(derived.Defense or "—"),
                        tonumber(derived.AttackSpeed) or 0,
                        (tonumber(derived.CritChance) or 0) * 100,
                        (tonumber(derived.CritMultiplier) or 1) * 100
                    ),
                    TextSize = 9,
                    Color = COLORS.Faint,
                    Align = Enum.TextXAlignment.Right,
                    ZIndex = 5,
                }),
            },
        }),
    }

    local names = { "Might", "Finesse", "Insight", "Fortune" }
    local descriptions = {
        Might = "Power, Max HP, and Defense",
        Finesse = "Agile scaling and Crit Damage",
        Insight = "Technique scaling and Max MP",
        Fortune = "Crit Chance and opportunistic scaling",
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

    local founderActive = player:GetAttribute("EverLeafFounder") == true
    local memberActive = player:GetAttribute("EverLeafMember") == true
    local equippedCosmetics = profile.Cosmetics and profile.Cosmetics.Equipped or {}
    local founderTitleEquipped = equippedCosmetics.Title == "founder_title"
    local founderAuraEquipped = equippedCosmetics.Aura == "founder_lumen_aura"
    local recognition = "WAYFARER"
    local recognitionColor = COLORS.Muted
    if founderActive then
        recognition = "EVERLEAF FOUNDER · BADGE + PERMANENT COSMETICS"
        recognitionColor = COLORS.Gold
    elseif memberActive then
        recognition = "EVERLEAF MEMBER · ACTIVE MEMBERSHIP"
        recognitionColor = COLORS.Accent
    end
    children.Recognition = React.createElement(Panel, {
        Position = UDim2.fromOffset(0, 356),
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = COLORS.PanelRaised,
        StrokeTransparency = 0.62,
        Children = {
            Label = React.createElement(Label, {
                Position = UDim2.fromOffset(14, 5),
                Size = UDim2.new(1, -28, 0, 14),
                Text = "RECOGNITION",
                TextSize = 8,
                Bold = true,
                Color = COLORS.Faint,
                ZIndex = 5,
            }),
            Value = React.createElement(Label, {
                Position = UDim2.fromOffset(14, 19),
                Size = UDim2.new(1, founderActive and -220 or -28, 0, 20),
                Text = recognition,
                TextSize = 9,
                Bold = true,
                Color = recognitionColor,
                ZIndex = 5,
            }),
            TitleToggle = founderActive and React.createElement(Button, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -106, 0.5, 0),
                Size = UDim2.fromOffset(92, 30),
                Text = founderTitleEquipped and "TITLE ON" or "TITLE OFF",
                Tone = founderTitleEquipped and "accent" or nil,
                OnActivated = function()
                    invoke(
                        "cosmetic.equip",
                        {
                            Slot = "Title",
                            CosmeticId = founderTitleEquipped and "" or "founder_title",
                        },
                        founderTitleEquipped and "Founder title hidden."
                            or "Founder title equipped."
                    )
                end,
                ZIndex = 6,
            }) or nil,
            AuraToggle = founderActive
                    and React.createElement(Button, {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -8, 0.5, 0),
                        Size = UDim2.fromOffset(92, 30),
                        Text = founderAuraEquipped and "AURA ON" or "AURA OFF",
                        Tone = founderAuraEquipped and "accent" or nil,
                        OnActivated = function()
                            invoke(
                                "cosmetic.equip",
                                {
                                    Slot = "Aura",
                                    CosmeticId = founderAuraEquipped and "" or "founder_lumen_aura",
                                },
                                founderAuraEquipped and "Founder aura hidden."
                                    or "Founder aura equipped."
                            )
                        end,
                        ZIndex = 6,
                    })
                or nil,
        },
    })

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

    local capacity = math.max(#rows, tonumber(inventory.Capacity) or 48)
    local gridColumns = 6
    local gridCell = 50
    local gridGap = 4
    local gridChildren = {
        Layout = React.createElement("UIGridLayout", {
            CellSize = UDim2.fromOffset(gridCell, gridCell),
            CellPadding = UDim2.fromOffset(gridGap, gridGap),
            FillDirection = Enum.FillDirection.Horizontal,
            FillDirectionMaxCells = gridColumns,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }),
        Padding = React.createElement("UIPadding", {
            PaddingTop = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
        }),
    }

    for visualIndex = 1, capacity do
        local row = rows[visualIndex]
        if row then
            local slot = row.Slot
            local definition = catalog.Items and catalog.Items[slot.ItemId]
            local selected = selectedRow and selectedRow.Index == row.Index
            local itemEligible = true
            if definition and definition.Type == "Equipment" then
                itemEligible = EquipmentEligibilityRules.CanEquip(profile, definition)
            end
            local displayName = definition and definition.DisplayName or tostring(slot.ItemId)
            local typeText = definition and definition.Type or "Item"
            local shortType = string.upper(string.sub(typeText, 1, 3))
            gridChildren["InventorySlot_" .. tostring(visualIndex)] = React.createElement(
                "TextButton",
                {
                    LayoutOrder = visualIndex,
                    BackgroundColor3 = selected and COLORS.AccentDark or COLORS.PanelRaised,
                    BackgroundTransparency = selected and 0 or 0.05,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = true,
                    Selectable = true,
                    ZIndex = 5,
                    [React.Event.Activated] = function()
                        setSelectedInventoryIndex(row.Index)
                    end,
                },
                withChrome(
                    {
                        SlotIndex = React.createElement(Label, {
                            Position = UDim2.fromOffset(5, 3),
                            Size = UDim2.fromOffset(18, 12),
                            Text = tostring(visualIndex),
                            TextSize = 7,
                            Bold = true,
                            Color = COLORS.Faint,
                            ZIndex = 6,
                        }),
                        Lock = not itemEligible
                                and React.createElement(Label, {
                                    AnchorPoint = Vector2.new(1, 0),
                                    Position = UDim2.new(1, -5, 0, 3),
                                    Size = UDim2.fromOffset(12, 12),
                                    Text = "!",
                                    TextSize = 9,
                                    Bold = true,
                                    Align = Enum.TextXAlignment.Center,
                                    Color = COLORS.Danger,
                                    ZIndex = 7,
                                })
                            or nil,
                        Name = React.createElement(Label, {
                            Position = UDim2.fromOffset(5, 15),
                            Size = UDim2.new(1, -10, 0, 22),
                            Text = displayName,
                            TextSize = 7,
                            Bold = true,
                            Align = Enum.TextXAlignment.Center,
                            Wrapped = true,
                            Color = selected and COLORS.LumenPale or COLORS.Text,
                            ZIndex = 6,
                        }),
                        Type = React.createElement(Label, {
                            Position = UDim2.fromOffset(5, 37),
                            Size = UDim2.fromOffset(24, 10),
                            Text = shortType,
                            TextSize = 6,
                            Bold = true,
                            Color = itemEligible and COLORS.Faint or COLORS.Danger,
                            ZIndex = 6,
                        }),
                        Quantity = React.createElement(Label, {
                            AnchorPoint = Vector2.new(1, 1),
                            Position = UDim2.new(1, -4, 1, -3),
                            Size = UDim2.fromOffset(25, 11),
                            Text = (tonumber(slot.Quantity) or 0) > 1
                                    and string.format("×%d", tonumber(slot.Quantity) or 0)
                                or "",
                            TextSize = 7,
                            Bold = true,
                            Align = Enum.TextXAlignment.Right,
                            Color = selected and COLORS.Accent or COLORS.Muted,
                            ZIndex = 6,
                        }),
                    },
                    7,
                    selected and COLORS.BorderStrong or COLORS.Border,
                    selected and 0.18 or 0.68,
                    1
                )
            )
        else
            gridChildren["InventoryEmpty_" .. tostring(visualIndex)] = React.createElement(
                "Frame",
                {
                    LayoutOrder = visualIndex,
                    BackgroundColor3 = COLORS.PanelDeep,
                    BackgroundTransparency = 0.35,
                    BorderSizePixel = 0,
                    ZIndex = 4,
                },
                withChrome({
                    SlotIndex = React.createElement(Label, {
                        Position = UDim2.fromOffset(5, 3),
                        Size = UDim2.fromOffset(18, 12),
                        Text = tostring(visualIndex),
                        TextSize = 7,
                        Color = COLORS.Faint,
                        ZIndex = 5,
                    }),
                    Empty = React.createElement(Label, {
                        Position = UDim2.fromOffset(4, 17),
                        Size = UDim2.new(1, -8, 0, 18),
                        Text = "EMPTY",
                        TextSize = 6,
                        Bold = true,
                        Align = Enum.TextXAlignment.Center,
                        Color = COLORS.Faint,
                        TextTransparency = 0.3,
                        ZIndex = 5,
                    }),
                }, 7, COLORS.Border, 0.82, 1)
            )
        end
    end
    local gridRows = math.ceil(capacity / gridColumns)
    local gridCanvasHeight = 12 + gridRows * gridCell + math.max(0, gridRows - 1) * gridGap

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
                    Position = UDim2.fromOffset(0, (index - 1) * 23),
                    Size = UDim2.new(1, 0, 0, 21),
                    BackgroundColor3 = COLORS.PanelRaised,
                    BackgroundTransparency = 0.14,
                    BorderSizePixel = 0,
                    ZIndex = 5,
                },
                withChrome({
                    Slot = React.createElement(Label, {
                        Position = UDim2.fromOffset(10, 0),
                        Size = UDim2.fromOffset(72, 21),
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
                        Size = UDim2.fromOffset(34, 18),
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
    local selectedSubtype = selectedDefinition
        and (
            selectedDefinition.WeaponType
            or selectedDefinition.ArmorType
            or selectedDefinition.AccessoryType
        )
    local selectedType = if selectedSubtype
        then string.format("Equipment · %s", prettyId(selectedSubtype))
        else selectedDefinition and selectedDefinition.Type or "Inventory"
    local equipEligible = true
    local equipReason = nil
    if selectedDefinition and selectedDefinition.Type == "Equipment" then
        equipEligible, equipReason = EquipmentEligibilityRules.CanEquip(profile, selectedDefinition)
    end
    local requirementText = equipmentRequirementText(selectedDefinition, catalog)
    local details = if selectedDefinition
        then if selectedDefinition.Type == "Equipment"
            then string.format(
                "%s · %s",
                tostring(selectedDefinition.EquipmentSlot or "Equipment"),
                requirementText
            )
            else string.format(
                "%s%s",
                selectedType,
                selectedSlot and (" · Quantity " .. tostring(selectedSlot.Quantity or 0)) or ""
            )
        else "Choose an inventory item to inspect it."
    local statsText = itemStatsText(selectedDefinition)
    local equippedComparisonDefinition = nil
    local comparisonEntries = {}
    if selectedDefinition and selectedDefinition.Type == "Equipment" then
        local equipmentSlot = selectedDefinition.EquipmentSlot
        local equippedItemId = equipmentSlot and equipment[equipmentSlot]
        equippedComparisonDefinition = equippedItemId
                and equippedItemId ~= ""
                and catalog.Items
                and catalog.Items[equippedItemId]
            or nil
        comparisonEntries =
            EquipmentComparisonRules.Compare(selectedDefinition, equippedComparisonDefinition)
    end
    local comparisonChildren = {}
    for index, entry in comparisonEntries do
        if index > 8 then
            break
        end
        local column = (index - 1) % 2
        local row = math.floor((index - 1) / 2)
        comparisonChildren["Delta_" .. tostring(entry.Stat)] = React.createElement(Label, {
            Position = UDim2.fromOffset(column * 111, row * 12),
            Size = UDim2.fromOffset(108, 12),
            Text = StatText.FormatDelta(entry.Stat, entry.Delta),
            TextSize = 7,
            Bold = true,
            Color = entry.Delta > 0 and COLORS.Accent or COLORS.Danger,
            ZIndex = 7,
        })
    end
    if
        #comparisonEntries == 0
        and selectedDefinition
        and selectedDefinition.Type == "Equipment"
    then
        comparisonChildren.NoChange = React.createElement(Label, {
            Size = UDim2.fromOffset(220, 20),
            Text = equippedComparisonDefinition and "No stat change"
                or "No stat bonuses to compare",
            TextSize = 8,
            Color = COLORS.Faint,
            ZIndex = 7,
        })
    end

    local action = nil
    if selectedDefinition and selectedRow then
        if selectedDefinition.Type == "Equipment" then
            action = React.createElement(Button, {
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.fromOffset(136, 28),
                Text = equipEligible and "EQUIP" or (EQUIPMENT_LOCK_TEXT[equipReason] or "LOCKED"),
                Tone = equipEligible and "accent" or nil,
                Active = equipEligible,
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
                Size = UDim2.fromOffset(136, 28),
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
            CanvasSize = UDim2.fromOffset(0, math.max(330, gridCanvasHeight)),
            BackgroundColor3 = COLORS.PanelDeep,
            BackgroundTransparency = 0.18,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = COLORS.BorderStrong,
            ZIndex = 4,
        }, withChrome(gridChildren, 10, COLORS.Border, 0.55, 1)),
        Details = React.createElement(Panel, {
            Position = UDim2.fromOffset(348, 0),
            Size = UDim2.fromOffset(250, 214),
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
                    Position = UDim2.fromOffset(14, 59),
                    Size = UDim2.new(1, -28, 0, 28),
                    Text = details,
                    TextSize = 10,
                    Wrapped = true,
                    Color = COLORS.Muted,
                    VerticalAlign = Enum.TextYAlignment.Top,
                    ZIndex = 6,
                }),
                Stats = React.createElement(Label, {
                    Position = UDim2.fromOffset(14, 87),
                    Size = UDim2.new(1, -28, 0, 22),
                    Text = statsText ~= "" and statsText or "No stat bonuses",
                    TextSize = 9,
                    Color = statsText ~= "" and COLORS.Gold or COLORS.Faint,
                    Wrapped = true,
                    ZIndex = 6,
                }),
                CompareTitle = React.createElement(Label, {
                    Position = UDim2.fromOffset(14, 109),
                    Size = UDim2.new(1, -28, 0, 14),
                    Text = selectedDefinition
                            and selectedDefinition.Type == "Equipment"
                            and (equippedComparisonDefinition and ("VS " .. string.upper(
                                equippedComparisonDefinition.DisplayName or "EQUIPPED"
                            )) or "VS EMPTY SLOT")
                        or "",
                    TextSize = 7,
                    Bold = true,
                    Color = COLORS.Muted,
                    ZIndex = 6,
                }),
                Compare = React.createElement("Frame", {
                    Position = UDim2.fromOffset(14, 124),
                    Size = UDim2.new(1, -28, 0, 48),
                    BackgroundTransparency = 1,
                    ZIndex = 6,
                }, comparisonChildren),
                Requirement = React.createElement(Label, {
                    Position = UDim2.fromOffset(14, 173),
                    Size = UDim2.new(1, -28, 0, 12),
                    Text = selectedDefinition
                            and selectedDefinition.Type == "Equipment"
                            and (equipEligible and "Requirements met" or requirementText)
                        or "",
                    TextSize = 8,
                    Bold = selectedDefinition and selectedDefinition.Type == "Equipment",
                    Color = equipEligible and COLORS.Accent or COLORS.Danger,
                    ZIndex = 6,
                }),
                Action = React.createElement("Frame", {
                    Position = UDim2.fromOffset(14, 186),
                    Size = UDim2.fromOffset(136, 28),
                    BackgroundTransparency = 1,
                    ZIndex = 6,
                }, { Action = action }),
            },
        }),
        EquippedTitle = React.createElement(Label, {
            Position = UDim2.fromOffset(348, 220),
            Size = UDim2.fromOffset(250, 22),
            Text = "EQUIPPED",
            TextSize = 11,
            Bold = true,
            Color = COLORS.Muted,
            ZIndex = 5,
        }),
        Equipped = React.createElement("Frame", {
            Position = UDim2.fromOffset(348, 244),
            Size = UDim2.fromOffset(250, 160),
            BackgroundTransparency = 1,
            ZIndex = 4,
        }, equipmentChildren),
    })
end

local function SkillsPanel(
    profile,
    catalog,
    invoke,
    selectedSkillId,
    setSelectedSkillId,
    selectedHotbarSlot,
    setSelectedHotbarSlot,
    inputMode
)
    local learned = profile.Skills and profile.Skills.Learned or {}
    local hotbar = profile.Skills and profile.Skills.Hotbar or {}
    local skillRows = {}
    for skillId, definition in catalog.Skills or {} do
        local familyId = definition.FamilyId
        if familyId == nil or familyId == "" or familyId == profile.FamilyId then
            table.insert(
                skillRows,
                { Id = skillId, Definition = definition, Rank = learned[skillId] or 0 }
            )
        end
    end
    table.sort(skillRows, function(a, b)
        local aTier = tonumber(a.Definition.RequiredTier) or 0
        local bTier = tonumber(b.Definition.RequiredTier) or 0
        if aTier ~= bTier then
            return aTier < bTier
        end
        local aKind = a.Definition.Kind == "Passive" and 1 or 0
        local bKind = b.Definition.Kind == "Passive" and 1 or 0
        if aKind ~= bKind then
            return aKind < bKind
        end
        return (a.Definition.DisplayName or a.Id) < (b.Definition.DisplayName or b.Id)
    end)

    local rowById = {}
    local selected = nil
    for _, row in skillRows do
        rowById[row.Id] = row
        if row.Id == selectedSkillId then
            selected = row
        end
    end
    selected = selected or skillRows[1]

    local function ruleDefinition(row)
        if not row then
            return nil
        end
        local definition = table.clone(row.Definition)
        definition.Id = row.Id
        definition.CurrentRank = row.Rank
        return definition
    end

    local function missingPrerequisiteText(definition)
        if not definition then
            return ""
        end
        for _, requirement in definition.Prerequisites or {} do
            local have = tonumber(learned[requirement.SkillId]) or 0
            local needed = math.max(1, tonumber(requirement.Rank) or 1)
            if have < needed then
                local requiredDefinition = catalog.Skills and catalog.Skills[requirement.SkillId]
                local requiredName = requiredDefinition and requiredDefinition.DisplayName
                    or prettyId(requirement.SkillId)
                return string.format("Requires %s Rank %d", requiredName, needed)
            end
        end
        return ""
    end

    local function learnReasonText(row, reason)
        if not row then
            return "Select a skill"
        end
        local definition = row.Definition
        if reason == "wrong_family" then
            return "Not available to your family"
        elseif reason == "level_too_low" then
            return "Requires Level " .. tostring(definition.RequiredLevel or 1)
        elseif reason == "tier_too_low" then
            return "Requires Advancement Tier " .. tostring(definition.RequiredTier or 0)
        elseif reason == "prerequisite_unmet" then
            return missingPrerequisiteText(definition)
        elseif reason == "insufficient_sp" then
            return string.format("Requires %d SP", tonumber(definition.SPCostPerRank) or 1)
        elseif reason == "max_rank" then
            return "Maximum rank reached"
        end
        return "Ready to learn"
    end

    local function passiveBonusText(definition)
        local entries = {}
        for statName, amount in definition and definition.PassiveBonuses or {} do
            table.insert(entries, StatText.Format(statName, amount) .. " / rank")
        end
        table.sort(entries)
        return table.concat(entries, " · ")
    end

    local treeChildren = {
        FoundationTitle = React.createElement(Label, {
            Position = UDim2.fromOffset(12, 7),
            Size = UDim2.fromOffset(118, 18),
            Text = "WAYFARER FOUNDATION",
            TextSize = 7,
            Bold = true,
            Align = Enum.TextXAlignment.Center,
            Color = COLORS.Muted,
            ZIndex = 6,
        }),
        FamilyTitle = React.createElement(Label, {
            Position = UDim2.fromOffset(148, 7),
            Size = UDim2.fromOffset(118, 18),
            Text = profile.FamilyId ~= "" and string.upper(prettyId(profile.FamilyId))
                or "FAMILY PATH",
            TextSize = 7,
            Bold = true,
            Align = Enum.TextXAlignment.Center,
            Color = profile.FamilyId ~= "" and COLORS.Accent or COLORS.Faint,
            ZIndex = 6,
        }),
    }

    local nodePositions = {}
    local function addTreeNode(row, x, y, laneLabel)
        if not row then
            return
        end
        nodePositions[row.Id] = { X = x, Y = y }
        local definition = row.Definition
        local rule = ruleDefinition(row)
        local learnable = SkillProgressionRules.CanLearn(profile, rule)
        local learnedSkill = row.Rank > 0
        local selectedRow = selected and selected.Id == row.Id
        local nodeColor = if selectedRow
            then COLORS.AccentDark
            else if learnedSkill
                then Color3.fromRGB(36, 69, 52)
                else if learnable then Color3.fromRGB(75, 65, 40) else COLORS.PanelRaised
        local strokeColor = if learnedSkill
            then COLORS.Accent
            else if learnable then COLORS.Gold else COLORS.Border
        treeChildren["SkillTreeNode_" .. row.Id] = React.createElement(
            "TextButton",
            {
                Position = UDim2.fromOffset(x, y),
                Size = UDim2.fromOffset(122, 64),
                BackgroundColor3 = nodeColor,
                BackgroundTransparency = selectedRow and 0 or 0.04,
                BorderSizePixel = 0,
                Text = "",
                Selectable = true,
                ZIndex = 8,
                [React.Event.Activated] = function()
                    setSelectedSkillId(row.Id)
                end,
            },
            withChrome({
                Kind = React.createElement(Label, {
                    Position = UDim2.fromOffset(7, 5),
                    Size = UDim2.new(1, -14, 0, 12),
                    Text = string.format(
                        "%s · %s",
                        laneLabel,
                        string.upper(definition.Kind or "SKILL")
                    ),
                    TextSize = 6,
                    Bold = true,
                    Align = Enum.TextXAlignment.Center,
                    Color = learnedSkill and COLORS.Accent
                        or if learnable then COLORS.Gold else COLORS.Faint,
                    ZIndex = 9,
                }),
                Name = React.createElement(Label, {
                    Position = UDim2.fromOffset(7, 18),
                    Size = UDim2.new(1, -14, 0, 28),
                    Text = definition.DisplayName or row.Id,
                    TextSize = 8,
                    Bold = true,
                    Align = Enum.TextXAlignment.Center,
                    Wrapped = true,
                    Color = selectedRow and COLORS.LumenPale or COLORS.Text,
                    ZIndex = 9,
                }),
                Rank = React.createElement(Label, {
                    Position = UDim2.fromOffset(7, 47),
                    Size = UDim2.new(1, -14, 0, 12),
                    Text = string.format("RANK %d/%d", row.Rank, definition.MaxRank or 1),
                    TextSize = 6,
                    Bold = true,
                    Align = Enum.TextXAlignment.Center,
                    Color = learnedSkill and COLORS.Accent
                        or if learnable then COLORS.Gold else COLORS.Faint,
                    ZIndex = 9,
                }),
            }, 8, strokeColor, (learnedSkill or learnable) and 0.28 or 0.72, 1)
        )
        if not learnedSkill and not learnable then
            treeChildren["SkillTreeLock_" .. row.Id] = React.createElement(Label, {
                Position = UDim2.fromOffset(x + 101, y + 4),
                Size = UDim2.fromOffset(16, 16),
                Text = "×",
                TextSize = 10,
                Bold = true,
                Align = Enum.TextXAlignment.Center,
                Color = COLORS.Danger,
                ZIndex = 10,
            })
        end
    end

    local beginnerRow = rowById.beginner_strike
    local steadyRow = rowById.steady_footing
    addTreeNode(beginnerRow, 8, 34, "COMMON")
    addTreeNode(steadyRow, 8, 132, "COMMON")

    local tierOneActive = nil
    local tierOnePassive = nil
    local tierTwoActive = nil
    for _, row in skillRows do
        if row.Definition.FamilyId == profile.FamilyId and profile.FamilyId ~= "" then
            local tier = tonumber(row.Definition.RequiredTier) or 0
            if tier == 1 and row.Definition.Kind == "Active" then
                tierOneActive = tierOneActive or row
            elseif tier == 1 and row.Definition.Kind == "Passive" then
                tierOnePassive = tierOnePassive or row
            elseif tier >= 2 and row.Definition.Kind == "Active" then
                tierTwoActive = tierTwoActive or row
            end
        end
    end
    addTreeNode(tierOneActive, 144, 34, "TIER 1")
    addTreeNode(tierOnePassive, 144, 132, "TIER 1")
    addTreeNode(tierTwoActive, 144, 252, "TIER 2")

    local function addConnector(fromId, toId, key)
        local from = nodePositions[fromId]
        local to = nodePositions[toId]
        if not from or not to then
            return
        end
        local x = from.X + 61
        local top = from.Y + 64
        local bottom = to.Y
        treeChildren[key] = React.createElement("Frame", {
            Position = UDim2.fromOffset(x - 1, top),
            Size = UDim2.fromOffset(2, math.max(0, bottom - top)),
            BackgroundColor3 = COLORS.BorderStrong,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            ZIndex = 5,
        })
    end
    if beginnerRow and steadyRow then
        addConnector(beginnerRow.Id, steadyRow.Id, "FoundationConnector")
    end
    if tierOneActive and tierOnePassive then
        addConnector(tierOneActive.Id, tierOnePassive.Id, "FamilyConnector")
    end
    if profile.FamilyId == "" then
        treeChildren.NoFamily = React.createElement(Label, {
            Position = UDim2.fromOffset(148, 54),
            Size = UDim2.fromOffset(118, 90),
            Text = "Complete your first advancement to reveal a family path.",
            TextSize = 8,
            Wrapped = true,
            Align = Enum.TextXAlignment.Center,
            Color = COLORS.Faint,
            ZIndex = 6,
        })
    elseif tierTwoActive then
        treeChildren.TierTwoDivider = React.createElement(Label, {
            Position = UDim2.fromOffset(148, 217),
            Size = UDim2.fromOffset(118, 24),
            Text = "TIER 2 ADVANCEMENT",
            TextSize = 6,
            Bold = true,
            Align = Enum.TextXAlignment.Center,
            Color = COLORS.Gold,
            ZIndex = 6,
        })
    end

    local selectedDefinition = selected and selected.Definition or nil
    local selectedRank = selected and selected.Rank or 0
    local selectedRuleDefinition = ruleDefinition(selected)
    local selectedCanLearn, selectedLearnReason =
        if selectedRuleDefinition
            then SkillProgressionRules.CanLearn(profile, selectedRuleDefinition)
            else false,
        "invalid_skill"
    local selectedRequirementText = selected
            and learnReasonText(selected, selectedCanLearn and nil or selectedLearnReason)
        or "Select a skill"
    local selectedPassiveBonuses = passiveBonusText(selectedDefinition)
    local boundSlot = nil
    if selected then
        for index = 1, 8 do
            if (hotbar[tostring(index)] or hotbar[index]) == selected.Id then
                boundSlot = index
                break
            end
        end
    end
    local selectedSlotSkillId = hotbar[tostring(selectedHotbarSlot)] or hotbar[selectedHotbarSlot]
    local selectedSlotDefinition = selectedSlotSkillId
            and catalog.Skills
            and catalog.Skills[selectedSlotSkillId]
        or nil
    local canBind = selected ~= nil
        and selectedRank > 0
        and selectedDefinition ~= nil
        and selectedDefinition.Kind == "Active"
    local assignEnabled = canBind and boundSlot ~= selectedHotbarSlot

    local bindingText = "Select an active learned skill, then choose a hotbar slot below."
    if selectedDefinition and selectedDefinition.Kind ~= "Active" then
        bindingText = if selectedPassiveBonuses ~= ""
            then "Passive · " .. selectedPassiveBonuses
            else "Passive skills are always active and do not occupy a hotbar slot."
    elseif selected and selectedRank <= 0 then
        bindingText = "Learn at least one rank before assigning this skill."
    elseif boundSlot then
        bindingText = string.format("Currently bound to hotbar slot %d.", boundSlot)
    elseif canBind then
        bindingText = string.format("Ready to bind to hotbar slot %d.", selectedHotbarSlot)
    end

    local hotbarChildren = {}
    for index = 1, 8 do
        local skillId = hotbar[tostring(index)] or hotbar[index]
        local definition = skillId and catalog.Skills and catalog.Skills[skillId]
        local displayName = if definition
            then definition.DisplayName
            else if skillId and skillId ~= "" then prettyId(skillId) else "Empty"
        local selectedSlot = selectedHotbarSlot == index
        local selectedSkillBound = selected and skillId == selected.Id
        local column = (index - 1) % 4
        local row = math.floor((index - 1) / 4)
        local keyLabel = inputMode == "GAMEPAD" and GAMEPAD_HOTBAR_LABELS[index] or tostring(index)
        hotbarChildren["SkillHotbarSlot_" .. tostring(index)] = React.createElement(
            "TextButton",
            {
                Position = UDim2.fromOffset(12 + column * 68, 31 + row * 52),
                Size = UDim2.fromOffset(62, 46),
                BackgroundColor3 = selectedSlot and COLORS.AccentDark
                    or if selectedSkillBound then Color3.fromRGB(47, 68, 52) else COLORS.PanelRaised,
                BackgroundTransparency = selectedSlot and 0 or 0.08,
                BorderSizePixel = 0,
                Text = "",
                Selectable = true,
                ZIndex = 7,
                [React.Event.Activated] = function()
                    setSelectedHotbarSlot(index)
                end,
            },
            withChrome({
                Key = React.createElement(Label, {
                    Position = UDim2.fromOffset(5, 3),
                    Size = UDim2.fromOffset(18, 14),
                    Text = keyLabel,
                    TextSize = 8,
                    Bold = true,
                    Align = Enum.TextXAlignment.Center,
                    Color = selectedSlot and COLORS.LumenPale or COLORS.Accent,
                    ZIndex = 8,
                }),
                Skill = React.createElement(Label, {
                    Position = UDim2.fromOffset(4, 18),
                    Size = UDim2.new(1, -8, 0, 24),
                    Text = displayName,
                    TextSize = 7,
                    Bold = skillId ~= nil and skillId ~= "",
                    Align = Enum.TextXAlignment.Center,
                    Wrapped = true,
                    Color = selectedSlot and COLORS.Text
                        or if skillId and skillId ~= "" then COLORS.Muted else COLORS.Faint,
                    ZIndex = 8,
                }),
            }, 6, selectedSlot and COLORS.Lumen or COLORS.Border, selectedSlot and 0.2 or 0.65, 1)
        )
    end

    hotbarChildren.Selected = React.createElement(Label, {
        Position = UDim2.fromOffset(12, 136),
        Size = UDim2.fromOffset(142, 22),
        Text = string.format(
            "SLOT %d · %s",
            selectedHotbarSlot,
            selectedSlotDefinition and selectedSlotDefinition.DisplayName or "Empty"
        ),
        TextSize = 8,
        Bold = true,
        Color = COLORS.Faint,
        ZIndex = 7,
    })
    hotbarChildren.Clear = React.createElement(Button, {
        Position = UDim2.fromOffset(162, 133),
        Size = UDim2.fromOffset(120, 27),
        Text = "CLEAR SLOT " .. tostring(selectedHotbarSlot),
        TextSize = 8,
        Active = selectedSlotSkillId ~= nil and selectedSlotSkillId ~= "",
        OnActivated = function()
            invoke(
                "skill.hotbar",
                { Index = selectedHotbarSlot, SkillId = "" },
                string.format("Hotbar slot %d cleared.", selectedHotbarSlot)
            )
        end,
        ZIndex = 8,
    })

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, {
        TreeTitle = React.createElement(Label, {
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(275, 24),
            Text = string.format("SKILL TREE  ·  SP %d", tonumber(profile.SP) or 0),
            TextSize = 12,
            Bold = true,
            Color = COLORS.Muted,
            ZIndex = 5,
        }),
        Tree = React.createElement("Frame", {
            Position = UDim2.fromOffset(0, 32),
            Size = UDim2.fromOffset(282, 354),
            BackgroundColor3 = COLORS.PanelDeep,
            BackgroundTransparency = 0.18,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 4,
        }, withChrome(treeChildren, 10, COLORS.Border, 0.55, 1)),
        Detail = React.createElement(Panel, {
            Position = UDim2.fromOffset(302, 0),
            Size = UDim2.fromOffset(296, 210),
            BackgroundColor3 = COLORS.PanelRaised,
            Children = {
                Icon = selected and React.createElement(Icon, {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -14, 0, 12),
                    Size = UDim2.fromOffset(52, 52),
                    Image = SKILL_ICONS[selected.Id] or EverLeafIcons.Skills,
                    ZIndex = 7,
                }) or nil,
                Kicker = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 12),
                    Size = UDim2.new(1, -82, 0, 18),
                    Text = selectedDefinition and string.upper(selectedDefinition.Kind or "SKILL")
                        or "SKILL",
                    TextSize = 9,
                    Bold = true,
                    Color = COLORS.Accent,
                    ZIndex = 6,
                }),
                Name = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 34),
                    Size = UDim2.new(1, -86, 0, 30),
                    Text = selectedDefinition and selectedDefinition.DisplayName
                        or "Select a skill",
                    TextSize = 17,
                    Bold = true,
                    Wrapped = true,
                    ZIndex = 6,
                }),
                Rank = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 70),
                    Size = UDim2.new(1, -32, 0, 20),
                    Text = selectedDefinition
                            and string.format(
                                "Rank %d/%d · Lv %d · Tier %d · %d SP%s",
                                selectedRank,
                                selectedDefinition.MaxRank or 1,
                                selectedDefinition.RequiredLevel or 1,
                                selectedDefinition.RequiredTier or 0,
                                selectedDefinition.SPCostPerRank or 1,
                                selectedDefinition.Kind == "Active"
                                        and string.format(
                                            " · %d MP / %.1fs",
                                            tonumber(selectedDefinition.MPCost) or 0,
                                            tonumber(selectedDefinition.Cooldown) or 0
                                        )
                                    or ""
                            )
                        or "",
                    TextSize = 10,
                    Color = COLORS.Gold,
                    ZIndex = 6,
                }),
                Description = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 96),
                    Size = UDim2.new(1, -32, 0, 35),
                    Text = selectedDefinition and selectedDefinition.Description or "",
                    TextSize = 8,
                    Color = COLORS.Muted,
                    Wrapped = true,
                    VerticalAlign = Enum.TextYAlignment.Top,
                    ZIndex = 6,
                }),
                Requirement = React.createElement(Label, {
                    Position = UDim2.fromOffset(16, 133),
                    Size = UDim2.new(1, -32, 0, 20),
                    Text = if selectedDefinition and selectedDefinition.Kind == "Passive"
                        then bindingText
                        else selectedRequirementText,
                    TextSize = 8,
                    Bold = true,
                    Color = if selectedCanLearn or selectedRank > 0
                        then COLORS.Accent
                        else COLORS.Warning,
                    Wrapped = true,
                    ZIndex = 6,
                }),
                RankUp = selected
                        and React.createElement(Button, {
                            Position = UDim2.fromOffset(16, 158),
                            Size = UDim2.fromOffset(126, 38),
                            Text = if selectedCanLearn
                                then "RANK UP"
                                else if selectedLearnReason == "max_rank"
                                    then "MAX RANK"
                                    else "LOCKED",
                            Tone = selectedCanLearn and "accent" or nil,
                            Active = selectedCanLearn,
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
                Assign = selected
                        and React.createElement(Button, {
                            Position = UDim2.fromOffset(152, 158),
                            Size = UDim2.fromOffset(126, 38),
                            Text = if selectedDefinition.Kind ~= "Active"
                                then "PASSIVE SKILL"
                                else if selectedRank <= 0
                                    then "LEARN FIRST"
                                    else if boundSlot == selectedHotbarSlot
                                        then "SLOT " .. tostring(selectedHotbarSlot) .. " BOUND"
                                        else "ASSIGN SLOT " .. tostring(selectedHotbarSlot),
                            Tone = assignEnabled and "accent" or nil,
                            Active = assignEnabled,
                            OnActivated = function()
                                invoke(
                                    "skill.hotbar",
                                    { Index = selectedHotbarSlot, SkillId = selected.Id },
                                    string.format("Assigned to hotbar slot %d.", selectedHotbarSlot)
                                )
                            end,
                            ZIndex = 7,
                        })
                    or nil,
            },
        }),
        HotbarEditor = React.createElement(Panel, {
            Position = UDim2.fromOffset(302, 218),
            Size = UDim2.fromOffset(296, 168),
            BackgroundColor3 = COLORS.PanelDeep,
            StrokeTransparency = 0.58,
            Children = {
                Title = React.createElement(Label, {
                    Position = UDim2.fromOffset(12, 8),
                    Size = UDim2.new(1, -24, 0, 18),
                    Text = "HOTBAR · SELECT A SLOT",
                    TextSize = 9,
                    Bold = true,
                    Color = COLORS.Muted,
                    ZIndex = 7,
                }),
                Slots = React.createElement("Frame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    ZIndex = 6,
                }, hotbarChildren),
            },
        }),
    })
end

local function QuestsPanel(profile, catalog, filter, setFilter)
    filter = filter or "ACTIVE"
    local active = profile.Quests and profile.Quests.Active or {}
    local completed = profile.Quests and profile.Quests.Completed or {}
    local activeRows = {}
    local readyCount = 0
    for questId, state in active do
        if state.ReadyToTurnIn == true then
            readyCount += 1
        end
        table.insert(activeRows, { Id = questId, State = state })
    end
    table.sort(activeRows, function(a, b)
        if a.State.ReadyToTurnIn ~= b.State.ReadyToTurnIn then
            return a.State.ReadyToTurnIn == true
        end
        local aDefinition = catalog.Quests and catalog.Quests[a.Id]
        local bDefinition = catalog.Quests and catalog.Quests[b.Id]
        local aLevel = tonumber(aDefinition and aDefinition.MinimumLevel) or 0
        local bLevel = tonumber(bDefinition and bDefinition.MinimumLevel) or 0
        if aLevel ~= bLevel then
            return aLevel < bLevel
        end
        local aName = aDefinition and aDefinition.DisplayName or a.Id
        local bName = bDefinition and bDefinition.DisplayName or b.Id
        return aName < bName
    end)

    local completedRows = {}
    for questId, done in completed do
        if done then
            local definition = catalog.Quests and catalog.Quests[questId]
            table.insert(completedRows, {
                Id = questId,
                Name = definition and definition.DisplayName or questId,
                Definition = definition,
            })
        end
    end
    table.sort(completedRows, function(a, b)
        return a.Name < b.Name
    end)

    local filterButtons = {}
    local filters = {
        { Id = "ACTIVE", Count = #activeRows },
        { Id = "READY", Count = readyCount },
        { Id = "COMPLETED", Count = #completedRows },
    }
    for index, entry in filters do
        local selected = filter == entry.Id
        filterButtons["QuestFilter_" .. entry.Id] = React.createElement(Button, {
            Position = UDim2.fromOffset((index - 1) * 196, 0),
            Size = UDim2.fromOffset(186, 30),
            Text = string.format("%s · %d", entry.Id, entry.Count),
            TextSize = 9,
            Tone = selected and "accent" or nil,
            OnActivated = function()
                setFilter(entry.Id)
            end,
            ZIndex = 6,
        })
    end

    local listChildren = {}
    local y = 0
    if filter == "COMPLETED" then
        for _, row in completedRows do
            listChildren["Completed_" .. row.Id] = React.createElement(Panel, {
                Position = UDim2.fromOffset(0, y),
                Size = UDim2.new(1, -8, 0, 56),
                BackgroundColor3 = COLORS.PanelRaised,
                StrokeTransparency = 0.68,
                Children = {
                    Check = React.createElement(Label, {
                        Position = UDim2.fromOffset(12, 0),
                        Size = UDim2.fromOffset(28, 56),
                        Text = "✓",
                        TextSize = 15,
                        Bold = true,
                        Color = COLORS.Accent,
                        Align = Enum.TextXAlignment.Center,
                        ZIndex = 6,
                    }),
                    Name = React.createElement(Label, {
                        Position = UDim2.fromOffset(50, 8),
                        Size = UDim2.new(1, -62, 0, 22),
                        Text = row.Name,
                        TextSize = 12,
                        Bold = true,
                        Color = COLORS.Muted,
                        ZIndex = 6,
                    }),
                    Meta = React.createElement(Label, {
                        Position = UDim2.fromOffset(50, 31),
                        Size = UDim2.new(1, -62, 0, 16),
                        Text = string.format(
                            "Completed%s",
                            row.Definition
                                    and row.Definition.MinimumLevel
                                    and (" · Level " .. tostring(row.Definition.MinimumLevel))
                                or ""
                        ),
                        TextSize = 8,
                        Color = COLORS.Faint,
                        ZIndex = 6,
                    }),
                },
            })
            y += 64
        end
    else
        for _, row in activeRows do
            local ready = row.State.ReadyToTurnIn == true
            if filter == "ACTIVE" or ready then
                local definition = catalog.Quests and catalog.Quests[row.Id]
                local name = definition and definition.DisplayName or row.Id
                local objectives = definition and definition.Objectives or {}
                local progressLines = {}
                for index, objective in objectives do
                    table.insert(
                        progressLines,
                        objectiveText(
                            objective,
                            row.State.Progress and row.State.Progress[index] or 0
                        )
                    )
                end
                local height = 78 + math.max(0, #progressLines - 1) * 18
                listChildren[row.Id] = React.createElement(Panel, {
                    Position = UDim2.fromOffset(0, y),
                    Size = UDim2.new(1, -8, 0, height),
                    BackgroundColor3 = COLORS.PanelRaised,
                    StrokeColor = ready and COLORS.Gold or COLORS.Border,
                    StrokeTransparency = ready and 0.25 or 0.6,
                    Children = {
                        Status = React.createElement(Pill, {
                            Position = UDim2.fromOffset(12, 10),
                            Size = UDim2.fromOffset(ready and 96 or 64, 21),
                            Text = ready and "TURN IN" or "ACTIVE",
                            TextSize = 9,
                            Color = ready and Color3.fromRGB(94, 74, 42) or COLORS.AccentDark,
                            TextColor = ready and COLORS.Gold or COLORS.Accent,
                            ZIndex = 6,
                        }),
                        Level = React.createElement(Label, {
                            AnchorPoint = Vector2.new(1, 0),
                            Position = UDim2.new(1, -14, 0, 11),
                            Size = UDim2.fromOffset(90, 18),
                            Text = definition
                                    and definition.MinimumLevel
                                    and ("LEVEL " .. tostring(definition.MinimumLevel))
                                or "",
                            TextSize = 8,
                            Bold = true,
                            Align = Enum.TextXAlignment.Right,
                            Color = COLORS.Faint,
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
        end
    end

    if next(listChildren) == nil then
        local emptyText = if filter == "READY"
            then "No quests are ready to turn in."
            else if filter == "COMPLETED"
                then "No completed quests yet."
                else "No active quests. Talk to a Wayfarer or region contact."
        listChildren.Empty = React.createElement(Label, {
            Position = UDim2.fromOffset(16, 16),
            Size = UDim2.new(1, -32, 0, 48),
            Text = emptyText,
            TextSize = 11,
            Wrapped = true,
            Color = COLORS.Faint,
            ZIndex = 5,
        })
        y = 80
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, {
        Filters = React.createElement("Frame", {
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(598, 32),
            BackgroundTransparency = 1,
            ZIndex = 5,
        }, filterButtons),
        QuestList = React.createElement("ScrollingFrame", {
            Position = UDim2.fromOffset(0, 42),
            Size = UDim2.fromOffset(598, 344),
            CanvasSize = UDim2.fromOffset(0, math.max(344, y)),
            BackgroundColor3 = COLORS.PanelDeep,
            BackgroundTransparency = 0.18,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = COLORS.BorderStrong,
            ZIndex = 4,
        }, withChrome(listChildren, 10, COLORS.Border, 0.55, 1)),
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
    local status, setStatus = React.useState(nil)
    local selectedInventoryIndex, setSelectedInventoryIndex = React.useState(1)
    local selectedSkillId, setSelectedSkillId = React.useState("beginner_strike")
    local selectedHotbarSlot, setSelectedHotbarSlot = React.useState(1)
    local questFilter, setQuestFilter = React.useState("ACTIVE")
    local catalog = CatalogClient.Get() or {}
    local tabs = {
        "CHARACTER",
        "INVENTORY",
        "SKILLS",
        "QUESTS",
        "COSMETICS",
        "STORE",
        "SETTINGS",
    }
    local navStep = 46
    local navRowHeight = 38
    local navHeight = #tabs * navStep - (navStep - navRowHeight)
    local navFooterY = 82 + navHeight + 12

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
        content = SkillsPanel(
            profile,
            catalog,
            invoke,
            selectedSkillId,
            setSelectedSkillId,
            selectedHotbarSlot,
            setSelectedHotbarSlot,
            props.InputMode
        )
    elseif activeTab == "QUESTS" then
        content = QuestsPanel(profile, catalog, questFilter, setQuestFilter)
    elseif activeTab == "COSMETICS" then
        content = React.createElement(CosmeticsPanel, {
            Profile = profile,
            Catalog = catalog,
            OnInvoke = invoke,
        })
    elseif activeTab == "STORE" then
        content = React.createElement(PremiumShopPanel)
    else
        content = SettingsPanel(profile, invoke)
    end

    local navChildren = {}
    for index, tabName in tabs do
        local selected = activeTab == tabName
        navChildren["MenuNav_" .. tabName] = React.createElement(
            "TextButton",
            {
                Position = UDim2.fromOffset(0, (index - 1) * navStep),
                Size = UDim2.new(1, 0, 0, navRowHeight),
                BackgroundColor3 = selected and COLORS.AccentDark or COLORS.PanelRaised,
                BackgroundTransparency = selected and 0 or 0.22,
                BorderSizePixel = 0,
                Text = "",
                Selectable = true,
                ZIndex = 34,
                [React.Event.Activated] = function()
                    if props.OnTabChanged then
                        props.OnTabChanged(tabName)
                    end
                end,
            },
            withChrome({
                Icon = React.createElement(Icon, {
                    Position = UDim2.fromOffset(9, 6),
                    Size = UDim2.fromOffset(26, 26),
                    Image = NAV_ICONS[tabName],
                    ImageTransparency = selected and 0 or 0.25,
                    ZIndex = 35,
                }),
                Hotkey = React.createElement(Pill, {
                    Position = UDim2.new(1, -29, 0.5, -10),
                    Size = UDim2.fromOffset(20, 20),
                    Text = HOTKEYS[tabName],
                    TextSize = 8,
                    Color = selected and COLORS.AccentDark or COLORS.Surface,
                    TextColor = selected and COLORS.LumenPale or COLORS.Faint,
                    ZIndex = 36,
                }),
                Name = React.createElement(Label, {
                    Position = UDim2.fromOffset(47, 0),
                    Size = UDim2.new(1, -82, 1, 0),
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
                        Brand = React.createElement(Label, {
                            AnchorPoint = Vector2.new(0.5, 0),
                            Position = UDim2.new(0.5, 0, 0, 7),
                            Size = UDim2.fromOffset(280, 30),
                            Text = "EVERLEAF",
                            TextSize = 24,
                            Bold = true,
                            Align = Enum.TextXAlignment.Center,
                            Color = COLORS.LumenPale,
                            ZIndex = 33,
                        }),
                        BrandLine = React.createElement("Frame", {
                            AnchorPoint = Vector2.new(0.5, 0),
                            Position = UDim2.new(0.5, 0, 0, 38),
                            Size = UDim2.fromOffset(150, 2),
                            BackgroundColor3 = COLORS.Lumen,
                            BackgroundTransparency = 0.35,
                            BorderSizePixel = 0,
                            ZIndex = 33,
                        }),
                        Subtitle = React.createElement(Label, {
                            AnchorPoint = Vector2.new(0.5, 0),
                            Position = UDim2.new(0.5, 0, 0, 42),
                            Size = UDim2.fromOffset(280, 16),
                            Text = string.format(
                                "WAYFARER RECORD · LEVEL %d",
                                tonumber(profile.Level) or 1
                            ),
                            TextSize = 9,
                            Align = Enum.TextXAlignment.Center,
                            Color = COLORS.Faint,
                            ZIndex = 33,
                        }),
                        MainMenuClose = React.createElement(Button, {
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
                    Size = UDim2.fromOffset(152, navHeight),
                    BackgroundTransparency = 1,
                    ZIndex = 33,
                }, navChildren),
                NavFooter = React.createElement(Panel, {
                    Position = UDim2.fromOffset(18, navFooterY),
                    Size = UDim2.fromOffset(152, 76),
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
                            Position = UDim2.fromOffset(12, 29),
                            Size = UDim2.new(1, -24, 0, 40),
                            Text = props.InputMode == "GAMEPAD"
                                    and "D-PAD/L/R Skills · X Interact\nB Back · START Menu"
                                or "1–8 Skills · E Interact\nQ Dodge · Esc Close",
                            TextSize = 8,
                            Color = COLORS.Faint,
                            VerticalAlign = Enum.TextYAlignment.Top,
                            ZIndex = 34,
                        }),
                    },
                }),
                Content = React.createElement("Frame", {
                    Position = UDim2.fromOffset(188, 82),
                    Size = UDim2.fromOffset(614, 442),
                    BackgroundTransparency = 1,
                    ZIndex = 33,
                }, { Content = content }),
                Status = status
                        and React.createElement(
                            "Frame",
                            {
                                Position = UDim2.fromOffset(188, 496),
                                Size = UDim2.fromOffset(614, 28),
                                BackgroundColor3 = COLORS.Panel,
                                BackgroundTransparency = 0.08,
                                BorderSizePixel = 0,
                                ZIndex = 36,
                            },
                            withChrome({
                                Text = React.createElement(Label, {
                                    Position = UDim2.fromOffset(12, 0),
                                    Size = UDim2.new(1, -24, 1, 0),
                                    Text = status,
                                    TextSize = 9,
                                    Color = COLORS.Muted,
                                    ZIndex = 37,
                                }),
                            }, 7)
                        )
                    or nil,
            },
        }),
    })
end

local function DeathOverlay(props)
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
                    Text = string.format(
                        "Returning to %s safe point...",
                        props.RegionName or "your region"
                    ),
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

local function inventoryTotals(profile)
    local totals = {}
    local inventory = profile and profile.Inventory
    for _, slot in inventory and inventory.Slots or {} do
        local itemId = slot.ItemId
        if itemId then
            totals[itemId] = (totals[itemId] or 0) + (tonumber(slot.Quantity) or 0)
        end
    end
    return totals
end

local function displayQuestName(questId)
    local catalog = CatalogClient.Get()
    local definition = catalog and catalog.Quests and catalog.Quests[questId]
    return definition and definition.DisplayName or prettyId(questId)
end

local function displayItemName(itemId)
    local catalog = CatalogClient.Get()
    local definition = catalog and catalog.Items and catalog.Items[itemId]
    return definition and definition.DisplayName or prettyId(itemId)
end

local function displayFamilyName(familyId)
    local catalog = CatalogClient.Get()
    local definition = catalog and catalog.Families and catalog.Families[familyId]
    return definition and definition.DisplayName or prettyId(familyId)
end

local function emitProfileNotifications(previous, current)
    if type(previous) ~= "table" or type(current) ~= "table" then
        return
    end

    local oldLevel = tonumber(previous.Level) or 1
    local newLevel = tonumber(current.Level) or oldLevel
    if newLevel > oldLevel then
        NotificationStore.Push(
            "success",
            "Level Up",
            string.format("You reached Level %d.", newLevel),
            4.5
        )
    end

    local oldFamily = previous.FamilyId or ""
    local newFamily = current.FamilyId or ""
    if newFamily ~= "" and newFamily ~= oldFamily then
        NotificationStore.Push(
            "success",
            "First Advancement",
            string.format("Your path is now %s.", displayFamilyName(newFamily)),
            5.5
        )
    end

    local oldCurrencies = previous.Currencies or {}
    for currency, amount in current.Currencies or {} do
        local delta = (tonumber(amount) or 0) - (tonumber(oldCurrencies[currency]) or 0)
        if delta > 0 then
            NotificationStore.Push(
                "reward",
                "Reward",
                string.format("+%d %s", delta, tostring(currency)),
                3
            )
        end
    end

    local oldItems = inventoryTotals(previous)
    local newItems = inventoryTotals(current)
    for itemId, amount in newItems do
        local delta = amount - (oldItems[itemId] or 0)
        if delta > 0 then
            NotificationStore.Push(
                "reward",
                "Item Received",
                string.format("%s ×%d", displayItemName(itemId), delta),
                3.2
            )
        end
    end

    local oldQuests = previous.Quests or {}
    local newQuests = current.Quests or {}
    local oldActive = oldQuests.Active or {}
    for questId, state in newQuests.Active or {} do
        local oldState = oldActive[questId]
        if oldState == nil then
            NotificationStore.Push("quest", "Quest Accepted", displayQuestName(questId), 4)
        elseif oldState.ReadyToTurnIn ~= true and state.ReadyToTurnIn == true then
            NotificationStore.Push("quest", "Quest Ready", displayQuestName(questId), 4)
        end
    end
    local oldCompleted = oldQuests.Completed or {}
    for questId, completed in newQuests.Completed or {} do
        if completed == true and oldCompleted[questId] ~= true then
            NotificationStore.Push("success", "Quest Complete", displayQuestName(questId), 4.5)
        end
    end
end

local function App()
    local profile, setProfile = React.useState(ProfileStore.Get())
    local interaction, setInteraction = React.useState(nil)
    local shopOpen, setShopOpen = React.useState(false)
    local advancementOpen, setAdvancementOpen = React.useState(false)
    local partyOpen, setPartyOpen = React.useState(false)
    local partyState, setPartyState = React.useState(PartyStore.GetState())
    local menuOpen, setMenuOpen = React.useState(false)
    local menuTab, setMenuTab = React.useState("CHARACTER")
    local health, setHealth = React.useState(100)
    local maxHealth, setMaxHealth = React.useState(100)
    local dead, setDead = React.useState(false)
    local damageFeedback, setDamageFeedback = React.useState(nil)
    local inputMode, setInputMode =
        React.useState(inputModeFromType(UserInputService:GetLastInputType()))
    local previousProfile = React.useRef(profile)
    local damageFeedbackGeneration = React.useRef(0)

    React.useEffect(function()
        local connection = UserInputService.LastInputTypeChanged:Connect(function(inputType)
            setInputMode(inputModeFromType(inputType))
        end)
        return function()
            connection:Disconnect()
        end
    end, {})

    React.useEffect(function()
        local previousInviteUserId = nil
        local previousReadyPurpose = nil
        local previousReadyResultGeneration = nil
        local connection = PartyStore.Changed:Connect(function(snapshot)
            setPartyState(snapshot)

            local invite = snapshot and snapshot.Invite
            if invite and invite.FromUserId ~= previousInviteUserId then
                previousInviteUserId = invite.FromUserId
                NotificationStore.Push(
                    "party",
                    "Party Invite",
                    string.format(
                        "%s invited you. Press P or Select to respond.",
                        invite.FromName or "A Wayfarer"
                    ),
                    5
                )
            elseif not invite then
                previousInviteUserId = nil
            end

            local readyCheck = snapshot and snapshot.ReadyCheck
            if readyCheck and readyCheck.Purpose ~= previousReadyPurpose then
                previousReadyPurpose = readyCheck.Purpose
                NotificationStore.Push(
                    "party",
                    "Belforge Ready Check",
                    string.format(
                        "%s is assembling the party. Press P or Select to respond.",
                        readyCheck.LeaderName or "Your party leader"
                    ),
                    6
                )
            elseif not readyCheck then
                previousReadyPurpose = nil
            end

            local readyResult = snapshot and snapshot.ReadyResult
            if readyResult and readyResult.Generation ~= previousReadyResultGeneration then
                previousReadyResultGeneration = readyResult.Generation
                if readyResult.Type == "Complete" then
                    setPartyOpen(false)
                    NotificationStore.Push(
                        "success",
                        "Party Ready",
                        "Belforge group entry confirmed.",
                        3.5
                    )
                elseif readyResult.Type == "Cleared" then
                    local reason = readyResult.Reason
                    if reason == "expired" then
                        NotificationStore.Push(
                            "info",
                            "Ready Check Expired",
                            "The Belforge ready check timed out.",
                            3.5
                        )
                    elseif reason == "declined" then
                        NotificationStore.Push(
                            "info",
                            "Ready Check Cancelled",
                            "A party member declined the Belforge pull.",
                            3.5
                        )
                    elseif reason == "party_changed" then
                        NotificationStore.Push(
                            "info",
                            "Ready Check Cancelled",
                            "The party roster changed.",
                            3.5
                        )
                    end
                end
            end
        end)
        return function()
            connection:Disconnect()
        end
    end, {})

    React.useEffect(function()
        local connection = ProfileStore.Subscribe(function(snapshot)
            emitProfileNotifications(previousProfile.current, snapshot)
            previousProfile.current = snapshot
            setProfile(snapshot)
        end)
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
            setShopOpen(false)
            setAdvancementOpen(false)
            setPartyOpen(false)
            setMenuOpen(false)
            setDamageFeedback(nil)
            damageFeedbackGeneration.current += 1
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
        local remote = remotes and remotes:FindFirstChild(Net.Events.PlayerDamageEvent)
        if not remote or not remote:IsA("RemoteEvent") then
            warn("[ReactUI] PlayerDamageEvent was not found")
            return nil
        end

        local connection = remote.OnClientEvent:Connect(function(payload)
            if type(payload) ~= "table" then
                return
            end
            damageFeedbackGeneration.current += 1
            local generation = damageFeedbackGeneration.current
            local nextPayload = table.clone(payload)
            nextPayload.Id = generation
            setDamageFeedback(nextPayload)
            task.delay(0.7, function()
                if damageFeedbackGeneration.current == generation then
                    setDamageFeedback(nil)
                end
            end)
        end)
        return function()
            connection:Disconnect()
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
                setShopOpen(false)
                setAdvancementOpen(false)
                setPartyOpen(false)
                setInteraction(payload)
            end
        end)
        return function()
            connection:Disconnect()
        end
    end, {})

    React.useEffect(function()
        player:SetAttribute(
            "EverLeafUiCapture",
            interaction ~= nil or shopOpen or advancementOpen or partyOpen or menuOpen or dead
        )
        return function()
            player:SetAttribute("EverLeafUiCapture", false)
        end
    end, { interaction, shopOpen, advancementOpen, partyOpen, menuOpen, dead })

    React.useEffect(function()
        if inputMode ~= "GAMEPAD" then
            return nil
        end

        local targetName = nil
        if advancementOpen and interaction then
            targetName = if tonumber(interaction.AdvancementTargetTier) == 2
                then "AdvancementConfirm"
                else "AdvancementFamily_ironbloom"
        elseif shopOpen then
            targetName = "ShopBuyTab"
        elseif interaction then
            targetName = "DialogueClose"
        elseif partyOpen then
            local readyCheck = partyState and partyState.ReadyCheck
            if readyCheck then
                local selfReady = false
                for _, member in readyCheck.Members or {} do
                    if member.UserId == player.UserId then
                        selfReady = member.Ready == true
                        break
                    end
                end
                targetName = if selfReady then "PartyReadyDecline" else "PartyReady"
            else
                targetName = if partyState and partyState.Invite
                    then "PartyAccept"
                    else "PartyPrimary"
            end
        elseif menuOpen then
            targetName = "MenuNav_" .. menuTab
        end

        if targetName then
            selectNamedObject(targetName)
        else
            local selected = GuiService.SelectedObject
            local playerGui = player:FindFirstChildOfClass("PlayerGui")
            local mount = playerGui and playerGui:FindFirstChild("EverLeafReactMount")
            if selected and mount and selected:IsDescendantOf(mount) then
                GuiService.SelectedObject = nil
            end
        end
        return nil
    end, {
        inputMode,
        interaction,
        shopOpen,
        advancementOpen,
        partyOpen,
        partyState,
        menuOpen,
        menuTab,
    })

    React.useEffect(function()
        local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if dead then
                return
            end

            local keyCode = input.KeyCode
            local uiLayerOpen = interaction ~= nil
                or shopOpen
                or advancementOpen
                or partyOpen
                or menuOpen

            if keyCode == Enum.KeyCode.ButtonB and uiLayerOpen then
                if advancementOpen then
                    setAdvancementOpen(false)
                elseif shopOpen then
                    setShopOpen(false)
                elseif interaction ~= nil then
                    setInteraction(nil)
                elseif partyOpen then
                    setPartyOpen(false)
                elseif menuOpen then
                    setMenuOpen(false)
                end
                return
            end

            if
                keyCode == Enum.KeyCode.ButtonStart
                and interaction == nil
                and not shopOpen
                and not advancementOpen
                and not partyOpen
            then
                setMenuOpen(not menuOpen)
                return
            end

            if
                menuOpen and (keyCode == Enum.KeyCode.ButtonL1 or keyCode == Enum.KeyCode.ButtonR1)
            then
                local tabs = {
                    "CHARACTER",
                    "INVENTORY",
                    "SKILLS",
                    "QUESTS",
                    "COSMETICS",
                    "STORE",
                    "SETTINGS",
                }
                local currentIndex = table.find(tabs, menuTab) or 1
                local direction = keyCode == Enum.KeyCode.ButtonR1 and 1 or -1
                local nextIndex = ((currentIndex - 1 + direction) % #tabs) + 1
                setMenuTab(tabs[nextIndex])
                return
            end

            if
                (keyCode == Enum.KeyCode.P or keyCode == Enum.KeyCode.ButtonSelect)
                and interaction == nil
                and not shopOpen
                and not advancementOpen
                and not menuOpen
            then
                setPartyOpen(not partyOpen)
                return
            end

            if gameProcessed then
                return
            end

            if interaction == nil and not shopOpen and not advancementOpen and not partyOpen then
                local tabByKey = {
                    [Enum.KeyCode.C] = "CHARACTER",
                    [Enum.KeyCode.I] = "INVENTORY",
                    [Enum.KeyCode.K] = "SKILLS",
                    [Enum.KeyCode.J] = "QUESTS",
                    [Enum.KeyCode.V] = "COSMETICS",
                    [Enum.KeyCode.O] = "STORE",
                    [Enum.KeyCode.M] = "SETTINGS",
                }
                local requestedTab = tabByKey[keyCode]
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

            if keyCode == Enum.KeyCode.Escape then
                if advancementOpen then
                    setAdvancementOpen(false)
                elseif shopOpen then
                    setShopOpen(false)
                elseif interaction ~= nil then
                    setInteraction(nil)
                elseif partyOpen then
                    setPartyOpen(false)
                elseif menuOpen then
                    setMenuOpen(false)
                end
            end
        end)
        return function()
            connection:Disconnect()
        end
    end, { interaction, shopOpen, advancementOpen, partyOpen, menuOpen, menuTab, dead })

    local uiOpen = interaction ~= nil or shopOpen or advancementOpen or partyOpen or menuOpen
    return React.createElement(React.Fragment, nil, {
        HUD = React.createElement(HUD, {
            Profile = profile,
            Health = health,
            MaxHealth = maxHealth,
            UiOpen = uiOpen,
            InputMode = inputMode,
        }),
        PartyHud = React.createElement(PartyHud, {
            Party = partyState and partyState.Party,
            Hidden = uiOpen or dead,
        }),
        PartyOverlay = partyOpen and React.createElement(PartyOverlay, {
            PartyState = partyState,
            OnClose = function()
                setPartyOpen(false)
            end,
        }) or nil,
        Menu = menuOpen and React.createElement(MainMenu, {
            Profile = profile,
            ActiveTab = menuTab,
            OnTabChanged = setMenuTab,
            InputMode = inputMode,
            OnClose = function()
                setMenuOpen(false)
            end,
        }) or nil,
        Dialogue = interaction
                and not shopOpen
                and not advancementOpen
                and not partyOpen
                and React.createElement(Dialogue, {
                    Description = interaction,
                    Profile = profile,
                    OnOpenShop = function()
                        if interaction.ShopId then
                            setShopOpen(true)
                        end
                    end,
                    OnOpenAdvancement = function()
                        if interaction.AdvancementMentor then
                            setAdvancementOpen(true)
                        end
                    end,
                    OnClose = function()
                        setInteraction(nil)
                    end,
                })
            or nil,
        Shop = shopOpen and interaction and interaction.ShopId and React.createElement(
            ShopOverlay,
            {
                Description = interaction,
                Profile = profile,
                Catalog = CatalogClient.Get() or {},
                OnClose = function()
                    setShopOpen(false)
                end,
            }
        ) or nil,
        Advancement = advancementOpen
                and interaction
                and interaction.AdvancementMentor
                and React.createElement(AdvancementOverlay, {
                    Profile = profile,
                    Catalog = CatalogClient.Get() or {},
                    MentorNpcId = interaction.NpcId,
                    TargetTier = interaction.AdvancementTargetTier,
                    OnClose = function()
                        setAdvancementOpen(false)
                    end,
                })
            or nil,
        Boss = React.createElement(BossHud, { Hidden = uiOpen or dead }),
        Toasts = React.createElement(ToastStack),
        DamageFeedback = React.createElement(PlayerDamageFeedback, { Event = damageFeedback }),
        Death = dead and React.createElement(DeathOverlay, {
            RegionName = regionDisplayName(profile),
        }) or nil,
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

    local scaledRoot = Instance.new("Frame")
    scaledRoot.Name = "ScaledRoot"
    -- Keep the reference canvas top-left anchored. Centering a fixed 1280x720
    -- frame with a UIScale caused its unscaled anchor offset to push HUD panels
    -- off-screen on smaller/wider Studio play windows.
    scaledRoot.AnchorPoint = Vector2.new(0, 0)
    scaledRoot.Position = UDim2.fromOffset(0, 0)
    scaledRoot.Size = UDim2.fromOffset(UI_REFERENCE_SIZE.X, UI_REFERENCE_SIZE.Y)
    scaledRoot.BackgroundTransparency = 1
    scaledRoot.BorderSizePixel = 0
    scaledRoot.ClipsDescendants = false
    scaledRoot.Parent = mount

    local uiScale = Instance.new("UIScale")
    uiScale.Name = "ResponsiveScale"
    uiScale.Parent = scaledRoot

    local viewportConnection = nil
    local function updateScale()
        local camera = Workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or UI_REFERENCE_SIZE
        local fit = math.min(viewport.X / UI_REFERENCE_SIZE.X, viewport.Y / UI_REFERENCE_SIZE.Y)
        local scale = math.clamp(fit, 0.1, UI_MAX_SCALE)
        uiScale.Scale = scale

        -- Center the *scaled* reference canvas using explicit pixel margins.
        -- This keeps every HUD edge inside the viewport while still allowing
        -- intentional letterbox space on aspect ratios unlike 16:9.
        local scaledWidth = UI_REFERENCE_SIZE.X * scale
        local scaledHeight = UI_REFERENCE_SIZE.Y * scale
        local offsetX = math.max(0, (viewport.X - scaledWidth) * 0.5)
        local offsetY = math.max(0, (viewport.Y - scaledHeight) * 0.5)
        scaledRoot.Position = UDim2.fromOffset(math.floor(offsetX + 0.5), math.floor(offsetY + 0.5))
    end

    local function bindCamera()
        if viewportConnection then
            viewportConnection:Disconnect()
            viewportConnection = nil
        end
        local camera = Workspace.CurrentCamera
        if camera then
            viewportConnection =
                camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
        end
        updateScale()
    end

    local cameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
    bindCamera()
    mount.Destroying:Once(function()
        cameraConnection:Disconnect()
        if viewportConnection then
            viewportConnection:Disconnect()
        end
    end)

    reactRoot = ReactRoblox.createRoot(scaledRoot)
    reactRoot:render(React.createElement(App))
end

return ReactUIController
