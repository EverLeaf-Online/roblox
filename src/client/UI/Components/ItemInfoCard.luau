local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local StatText = require(script.Parent.Parent.StatText)

local function statText(definition)
    local parts = {}
    for name, value in definition and definition.Stats or {} do
        table.insert(parts, StatText.Format(name, value))
    end
    table.sort(parts)
    if definition and definition.Effects then
        if definition.Effects.RestoreHP then
            table.insert(parts, string.format("Restore %d HP", definition.Effects.RestoreHP))
        end
        if definition.Effects.RestoreMP then
            table.insert(parts, string.format("Restore %d MP", definition.Effects.RestoreMP))
        end
    end
    return #parts > 0 and table.concat(parts, "  ·  ") or "No combat modifiers"
end

local function ItemInfoCard(props)
    local definition = props.Definition
    if not definition then
        return React.createElement("Frame", {
            Position = props.Position,
            Size = props.Size or UDim2.fromOffset(250, 128),
            BackgroundTransparency = 1,
            ZIndex = props.ZIndex or 45,
        })
    end
    local z = props.ZIndex or 45
    local sell = definition.SellPrice
    local footer = sell and string.format("Sell: %d %s", sell.Amount or 0, sell.Currency or "")
        or "Cannot be sold"
    return React.createElement("Frame", {
        Position = props.Position,
        Size = props.Size or UDim2.fromOffset(250, 128),
        BackgroundColor3 = Color3.fromRGB(9, 17, 16),
        BorderSizePixel = 0,
        ZIndex = z,
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 7) }),
        Stroke = React.createElement(
            "UIStroke",
            { Color = Color3.fromRGB(93, 156, 126), Transparency = 0.34 }
        ),
        Kicker = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(12, 8),
            Size = UDim2.new(1, -24, 0, 16),
            BackgroundTransparency = 1,
            Text = string.upper(definition.Type or "ITEM"),
            TextColor3 = Color3.fromRGB(112, 228, 169),
            TextSize = 9,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = z + 1,
        }),
        Name = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(12, 25),
            Size = UDim2.new(1, -24, 0, 24),
            BackgroundTransparency = 1,
            Text = definition.DisplayName or props.ItemId or "Item",
            TextColor3 = Color3.fromRGB(239, 246, 242),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = z + 1,
        }),
        Meta = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(12, 52),
            Size = UDim2.new(1, -24, 0, 38),
            BackgroundTransparency = 1,
            Text = statText(definition),
            TextWrapped = true,
            TextColor3 = Color3.fromRGB(160, 190, 175),
            TextSize = 10,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = z + 1,
        }),
        Footer = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(12, 97),
            Size = UDim2.new(1, -24, 0, 19),
            BackgroundTransparency = 1,
            Text = footer,
            TextColor3 = Color3.fromRGB(232, 193, 105),
            TextSize = 9,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = z + 1,
        }),
    })
end

return ItemInfoCard
