local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local function prettySource(value)
    local text = tostring(value or "Impact"):gsub("_", " ")
    return (
        text:gsub("(%a)([%w']*)", function(first, rest)
            return string.upper(first) .. rest
        end)
    )
end

local function PlayerDamageFeedback(props)
    local event = props.Event
    local fade, setFade = React.useState(0)

    React.useEffect(function()
        if not event then
            setFade(1)
            return nil
        end
        local active = true
        setFade(0)
        task.spawn(function()
            task.wait(0.14)
            for step = 1, 8 do
                if not active then
                    return
                end
                setFade(step / 8)
                task.wait(0.045)
            end
        end)
        return function()
            active = false
        end
    end, { event and event.Id })

    if not event then
        return nil
    end

    local amount = math.max(0, tonumber(event.Amount) or 0)
    local mitigated = math.max(0, tonumber(event.Mitigated) or 0)
    local stagger = math.max(0, tonumber(event.Stagger) or 0)
    local heavy = event.Heavy == true
    local accent = heavy and Color3.fromRGB(230, 93, 66) or Color3.fromRGB(207, 78, 81)
    local edgeTransparency = math.clamp(0.72 + fade * 0.27, 0, 1)
    local textTransparency = math.clamp(fade, 0, 1)
    local detailParts = {}
    if mitigated > 0 then
        table.insert(detailParts, string.format("DEF absorbed %d", mitigated))
    end
    if stagger >= 0.4 then
        table.insert(detailParts, "STAGGER")
    end
    table.insert(detailParts, prettySource(event.SourceId))

    local edgeThickness = heavy and 92 or 64
    local edges = {
        Top = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, edgeThickness),
            BackgroundColor3 = accent,
            BackgroundTransparency = edgeTransparency,
            BorderSizePixel = 0,
            ZIndex = 71,
        }),
        Bottom = React.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, edgeThickness),
            BackgroundColor3 = accent,
            BackgroundTransparency = edgeTransparency,
            BorderSizePixel = 0,
            ZIndex = 71,
        }),
        Left = React.createElement("Frame", {
            Size = UDim2.new(0, edgeThickness, 1, 0),
            BackgroundColor3 = accent,
            BackgroundTransparency = edgeTransparency,
            BorderSizePixel = 0,
            ZIndex = 71,
        }),
        Right = React.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.fromScale(1, 0),
            Size = UDim2.new(0, edgeThickness, 1, 0),
            BackgroundColor3 = accent,
            BackgroundTransparency = edgeTransparency,
            BorderSizePixel = 0,
            ZIndex = 71,
        }),
    }

    return React.createElement(React.Fragment, nil, {
        Edges = React.createElement(React.Fragment, nil, edges),
        Readout = React.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.69),
            Size = UDim2.fromOffset(260, 64),
            BackgroundColor3 = Color3.fromRGB(17, 22, 21),
            BackgroundTransparency = math.clamp(0.12 + fade * 0.82, 0, 1),
            BorderSizePixel = 0,
            ZIndex = 72,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
            Stroke = React.createElement("UIStroke", {
                Color = accent,
                Transparency = math.clamp(0.28 + fade * 0.72, 0, 1),
                Thickness = heavy and 2 or 1,
            }),
            Amount = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(12, 7),
                Size = UDim2.new(1, -24, 0, 28),
                BackgroundTransparency = 1,
                Text = string.format("-%d HP", amount),
                TextColor3 = Color3.fromRGB(255, 225, 218),
                TextTransparency = textTransparency,
                TextSize = heavy and 22 or 19,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 73,
            }),
            Detail = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(12, 37),
                Size = UDim2.new(1, -24, 0, 18),
                BackgroundTransparency = 1,
                Text = table.concat(detailParts, "  ·  "),
                TextColor3 = Color3.fromRGB(191, 205, 198),
                TextTransparency = textTransparency,
                TextSize = 8,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 73,
            }),
        }),
    })
end

return PlayerDamageFeedback
