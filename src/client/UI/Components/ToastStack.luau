local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local NotificationStore = require(script.Parent.Parent.NotificationStore)

local COLORS = {
    success = Color3.fromRGB(103, 222, 157),
    quest = Color3.fromRGB(232, 193, 105),
    reward = Color3.fromRGB(128, 214, 244),
    warning = Color3.fromRGB(231, 165, 87),
    error = Color3.fromRGB(218, 91, 91),
    info = Color3.fromRGB(154, 181, 168),
}

local function ToastStack()
    local items, setItems = React.useState({})

    React.useEffect(function()
        local connection = NotificationStore.Subscribe(function(notification)
            setItems(function(current)
                local nextItems = table.clone(current)
                table.insert(nextItems, notification)
                while #nextItems > 4 do
                    table.remove(nextItems, 1)
                end
                return nextItems
            end)
            task.delay(notification.Duration, function()
                setItems(function(current)
                    local nextItems = {}
                    for _, item in current do
                        if item.Id ~= notification.Id then
                            table.insert(nextItems, item)
                        end
                    end
                    return nextItems
                end)
            end)
        end)
        return function()
            connection:Disconnect()
        end
    end, {})

    local children = {}
    for index, item in items do
        local accent = COLORS[item.Kind] or COLORS.info
        children["Toast" .. tostring(item.Id)] = React.createElement("Frame", {
            Position = UDim2.new(1, -370, 0, 94 + (index - 1) * 78),
            Size = UDim2.fromOffset(346, 66),
            BackgroundColor3 = Color3.fromRGB(10, 18, 17),
            BackgroundTransparency = 0.04,
            BorderSizePixel = 0,
            ZIndex = 70,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 7) }),
            Stroke = React.createElement(
                "UIStroke",
                { Color = accent, Transparency = 0.34, Thickness = 1 }
            ),
            Rail = React.createElement("Frame", {
                Size = UDim2.fromOffset(4, 66),
                BackgroundColor3 = accent,
                BorderSizePixel = 0,
                ZIndex = 71,
            }),
            Title = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(16, 9),
                Size = UDim2.new(1, -28, 0, 21),
                BackgroundTransparency = 1,
                Text = item.Title,
                TextColor3 = accent,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 72,
            }),
            Body = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(16, 31),
                Size = UDim2.new(1, -28, 0, 27),
                BackgroundTransparency = 1,
                Text = item.Body,
                TextColor3 = Color3.fromRGB(220, 232, 226),
                TextSize = 10,
                Font = Enum.Font.GothamMedium,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                ZIndex = 72,
            }),
        })
    end

    return React.createElement(React.Fragment, nil, children)
end

return ToastStack
