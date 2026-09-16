local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local CatalogClient = require(script.Parent.Parent.Parent.Services.CatalogClient)
local SkillCooldownStore = require(script.Parent.Parent.Parent.State.SkillCooldownStore)
local EverLeafIcons = require(script.Parent.Parent.EverLeafIcons)
local Primitives = require(script.Parent.Parent.Primitives)
local Theme = require(script.Parent.Parent.Theme)
local UiText = require(script.Parent.Parent.UiText)
local ProgressionMath = require(ReplicatedStorage.Shared.Math.ProgressionMath)
local StatusEffectDefinitions = require(ReplicatedStorage.Shared.StatusEffectDefinitions)

local COLORS = Theme.Colors
local Label = Primitives.Label
local Panel = Primitives.Panel
local Icon = Primitives.Icon
local ResourceMeter = Primitives.ResourceMeter
local withChrome = Primitives.WithChrome
local GAMEPAD_HOTBAR_LABELS = table.freeze({ "DL", "DU", "DR", "DD", "L1", "R1", "L2", "R3" })
local SKILL_ICONS = table.freeze({
    beginner_strike = EverLeafIcons.BeginnerStrike,
    steady_footing = EverLeafIcons.SteadyFooting,
})

local function hotbar(props)
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
    local bar = profile.Skills and profile.Skills.Hotbar or {}
    local resources = profile.Resources or {}
    local currentMP = tonumber(resources.CurrentMP) or 0
    local children = {}

    for index = 1, 8 do
        local skillId = bar[tostring(index)] or bar[index]
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

local function objective(props)
    local profile = props.Profile or {}
    local active = profile.Quests and profile.Quests.Active
    local regionName, regionId = UiText.RegionDisplayName(profile)
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
                local currentObjective = definition
                    and definition.Objectives
                    and definition.Objectives[1]
                local progress = state.Progress and state.Progress[1] or 0
                progressText =
                    UiText.ObjectiveText(currentObjective, progress, "Explore " .. regionName)
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

local function statusStrip(props)
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
                Name = definition.ShortName or definition.DisplayName or UiText.PrettyId(effectId),
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

local function MainHud(props)
    local profile = props.Profile or {}
    local level = tonumber(profile.Level) or 1
    local exp = tonumber(profile.Exp) or 0
    local needed = ProgressionMath.ExpToNextLevel(level)
    local resources = profile.Resources or {}
    local derived = profile.Derived or {}
    local currencies = profile.Currencies or {}
    local currentMP = tonumber(resources.CurrentMP) or 0
    local maxMP = tonumber(derived.MaxMP) or 1
    local regionName = UiText.RegionDisplayName(profile)
    local compactVisible = not props.UiOpen
    local expRatio = if needed > 0 then math.clamp(exp / needed, 0, 1) else 0

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
        StatusEffects = React.createElement(
            statusStrip,
            { Profile = profile, Hidden = props.UiOpen }
        ),
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
        Objective = React.createElement(objective, { Profile = profile, Hidden = props.UiOpen }),
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
                    Size = UDim2.fromScale(expRatio, 1),
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
        Hotbar = React.createElement(
            hotbar,
            { Profile = profile, Visible = compactVisible, InputMode = props.InputMode }
        ),
    })
end

return MainHud
