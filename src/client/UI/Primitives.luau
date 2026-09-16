local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local EverLeafIcons = require(script.Parent.EverLeafIcons)
local Theme = require(script.Parent.Theme)

local COLORS = Theme.Colors
local Primitives = {}

function Primitives.WithChrome(children, radius, strokeColor, strokeTransparency, thickness)
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

function Primitives.Label(props)
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

function Primitives.Panel(props)
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
        Primitives.WithChrome(
            children,
            props.Radius or 12,
            props.StrokeColor or COLORS.Border,
            props.StrokeTransparency or 0.35,
            props.StrokeThickness or 1
        )
    )
end

function Primitives.Button(props)
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
    return React.createElement(
        "TextButton",
        {
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
        },
        Primitives.WithChrome(
            children,
            props.Radius or 8,
            props.StrokeColor or COLORS.Border,
            0.52,
            1
        )
    )
end

function Primitives.Pill(props)
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
        Primitives.WithChrome({
            Text = React.createElement(Primitives.Label, {
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

function Primitives.ResourceMeter(props)
    local maximum = tonumber(props.Maximum) or 1
    local value = tonumber(props.Value) or 0
    local fraction = if maximum > 0 then math.clamp(value / maximum, 0, 1) else 0
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
        Primitives.WithChrome({
            Tag = React.createElement(
                "Frame",
                {
                    Size = UDim2.fromOffset(42, props.Size.Y.Offset),
                    BackgroundColor3 = props.TagColor,
                    BackgroundTransparency = 0.08,
                    BorderSizePixel = 0,
                    ZIndex = z + 1,
                },
                Primitives.WithChrome({
                    Text = React.createElement(Primitives.Label, {
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
                Primitives.WithChrome({
                    Fill = React.createElement(
                        "Frame",
                        {
                            Size = UDim2.fromScale(fraction, 1),
                            BackgroundColor3 = props.FillColor,
                            BorderSizePixel = 0,
                            ZIndex = z + 2,
                        },
                        Primitives.WithChrome({
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
                    Value = React.createElement(Primitives.Label, {
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

function Primitives.Icon(props)
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

return table.freeze(Primitives)
