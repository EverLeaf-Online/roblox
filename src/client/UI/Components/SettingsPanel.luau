local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local Primitives = require(script.Parent.Parent.Primitives)
local Theme = require(script.Parent.Parent.Theme)

local COLORS = Theme.Colors
local Button = Primitives.Button
local Label = Primitives.Label
local Panel = Primitives.Panel
local withChrome = Primitives.WithChrome

local function SettingsPanel(props)
    local profile = props.Profile or {}
    local invoke = props.OnInvoke or function() end
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

return SettingsPanel
