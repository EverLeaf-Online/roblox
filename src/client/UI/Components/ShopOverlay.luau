local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ActionClient = require(script.Parent.Parent.Parent.Services.ActionClient)
local NotificationStore = require(script.Parent.Parent.NotificationStore)
local ItemInfoCard = require(script.Parent.ItemInfoCard)

local function clampQuantity(value)
    return math.clamp(math.floor(tonumber(value) or 1), 1, 99)
end

local function ShopOverlay(props)
    local description = props.Description or {}
    local profile = props.Profile or {}
    local catalog = props.Catalog or {}
    local tab, setTab = React.useState("BUY")
    local selectedItemId, setSelectedItemId = React.useState(nil)
    local quantity, setQuantity = React.useState(1)
    local status, setStatus = React.useState("Select an item")

    local buyRows = {}
    for _, item in description.ShopItems or {} do
        table.insert(buyRows, item)
    end
    table.sort(buyRows, function(a, b)
        return tostring(a.DisplayName) < tostring(b.DisplayName)
    end)

    local sellRows = {}
    local inventory = profile.Inventory or {}
    for index, slot in inventory.Slots or {} do
        local definition = catalog.Items and catalog.Items[slot.ItemId]
        if definition and definition.SellPrice then
            table.insert(sellRows, {
                ItemId = slot.ItemId,
                DisplayName = definition.DisplayName or slot.ItemId,
                Quantity = slot.Quantity or 0,
                InventoryIndex = index,
                Price = definition.SellPrice.Amount or 0,
                Currency = definition.SellPrice.Currency or "Shards",
            })
        end
    end
    table.sort(sellRows, function(a, b)
        return tostring(a.DisplayName) < tostring(b.DisplayName)
    end)

    local rows = tab == "BUY" and buyRows or sellRows
    local selected = nil
    for _, row in rows do
        if row.ItemId == selectedItemId then
            selected = row
            break
        end
    end
    selected = selected or rows[1]
    local effectiveItemId = selected and selected.ItemId or nil
    local definition = effectiveItemId and catalog.Items and catalog.Items[effectiveItemId] or nil
    local maxQuantity = if tab == "SELL" and selected
        then math.max(1, tonumber(selected.Quantity) or 1)
        else 99
    local effectiveQuantity = math.clamp(quantity, 1, maxQuantity)

    local function invokeTransaction()
        if not selected or not effectiveItemId then
            return
        end
        local action = tab == "BUY" and "shop.buy" or "shop.sell"
        local payload = {
            ShopId = description.ShopId,
            ItemId = effectiveItemId,
            Quantity = effectiveQuantity,
        }
        local ok, result = ActionClient.Invoke(action, payload)
        if ok then
            local verb = tab == "BUY" and "Purchased" or "Sold"
            local message = string.format(
                "%s %dx %s",
                verb,
                effectiveQuantity,
                selected.DisplayName or effectiveItemId
            )
            setStatus(message)
            NotificationStore.Push("success", verb, message, 3)
            setQuantity(1)
        else
            local message = tostring(result or "transaction_failed")
            setStatus(message)
            NotificationStore.Push("error", "Shop action failed", message, 4)
        end
    end

    local listChildren = {}
    for index, row in rows do
        local itemId = row.ItemId
        local rowDefinition = catalog.Items and catalog.Items[itemId]
        local rowSelected = selected and selected.ItemId == itemId
        local price = if tab == "BUY" then row.Price or 0 else row.Price or 0
        local currency = if tab == "BUY"
            then description.ShopCurrency or "Shards"
            else row.Currency or "Shards"
        listChildren["Row" .. tostring(index)] = React.createElement("TextButton", {
            Position = UDim2.fromOffset(0, (index - 1) * 58),
            Size = UDim2.new(1, -8, 0, 50),
            BackgroundColor3 = rowSelected and Color3.fromRGB(31, 77, 57)
                or Color3.fromRGB(22, 34, 31),
            BackgroundTransparency = rowSelected and 0 or 0.08,
            BorderSizePixel = 0,
            Text = "",
            ZIndex = 54,
            [React.Event.Activated] = function()
                setSelectedItemId(itemId)
                setQuantity(1)
            end,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 7) }),
            Stroke = React.createElement("UIStroke", {
                Color = rowSelected and Color3.fromRGB(112, 228, 169)
                    or Color3.fromRGB(69, 108, 91),
                Transparency = rowSelected and 0.24 or 0.66,
            }),
            Name = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(12, 6),
                Size = UDim2.new(1, -112, 0, 20),
                BackgroundTransparency = 1,
                Text = row.DisplayName or (rowDefinition and rowDefinition.DisplayName) or itemId,
                TextColor3 = rowSelected and Color3.fromRGB(205, 255, 229)
                    or Color3.fromRGB(239, 246, 242),
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 55,
            }),
            Meta = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(12, 27),
                Size = UDim2.new(1, -112, 0, 16),
                BackgroundTransparency = 1,
                Text = tab == "SELL" and string.format("Owned: %d", tonumber(row.Quantity) or 0)
                    or string.upper((rowDefinition and rowDefinition.Type) or "ITEM"),
                TextColor3 = Color3.fromRGB(139, 169, 154),
                TextSize = 9,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 55,
            }),
            Price = React.createElement("TextLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.fromOffset(96, 30),
                BackgroundTransparency = 1,
                Text = string.format("%d %s", price, currency),
                TextColor3 = Color3.fromRGB(232, 193, 105),
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 55,
            }),
        })
    end

    local currencyName = description.ShopCurrency or "Shards"
    local balance = profile.Currencies and profile.Currencies[currencyName] or 0
    local unitPrice = selected and selected.Price or 0
    local total = unitPrice * effectiveQuantity

    return React.createElement(React.Fragment, nil, {
        Backdrop = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(3, 7, 6),
            BackgroundTransparency = 0.38,
            BorderSizePixel = 0,
            ZIndex = 48,
        }),
        Window = React.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(820, 520),
            BackgroundColor3 = Color3.fromRGB(10, 18, 17),
            BorderSizePixel = 0,
            ZIndex = 50,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 9) }),
            Stroke = React.createElement(
                "UIStroke",
                { Color = Color3.fromRGB(102, 155, 130), Transparency = 0.22, Thickness = 1.2 }
            ),
            Header = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 68),
                BackgroundColor3 = Color3.fromRGB(16, 28, 25),
                BorderSizePixel = 0,
                ZIndex = 51,
            }, {
                Title = React.createElement("TextLabel", {
                    Position = UDim2.fromOffset(22, 10),
                    Size = UDim2.fromOffset(420, 28),
                    BackgroundTransparency = 1,
                    Text = description.ShopDisplayName or "Wayfarer Shop",
                    TextColor3 = Color3.fromRGB(239, 246, 242),
                    TextSize = 20,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 52,
                }),
                Balance = React.createElement("TextLabel", {
                    Position = UDim2.fromOffset(22, 38),
                    Size = UDim2.fromOffset(420, 18),
                    BackgroundTransparency = 1,
                    Text = string.format("Balance: %d %s", tonumber(balance) or 0, currencyName),
                    TextColor3 = Color3.fromRGB(154, 181, 168),
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 52,
                }),
                Close = React.createElement("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -16, 0.5, 0),
                    Size = UDim2.fromOffset(42, 36),
                    BackgroundColor3 = Color3.fromRGB(31, 46, 42),
                    BorderSizePixel = 0,
                    Text = "×",
                    TextColor3 = Color3.fromRGB(239, 246, 242),
                    TextSize = 20,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 53,
                    [React.Event.Activated] = props.OnClose,
                }, {
                    Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 7) }),
                }),
            }),
            BuyTab = React.createElement("TextButton", {
                Position = UDim2.fromOffset(22, 82),
                Size = UDim2.fromOffset(112, 34),
                BackgroundColor3 = tab == "BUY" and Color3.fromRGB(37, 80, 61)
                    or Color3.fromRGB(24, 37, 34),
                BorderSizePixel = 0,
                Text = "BUY",
                TextColor3 = tab == "BUY" and Color3.fromRGB(121, 244, 183)
                    or Color3.fromRGB(154, 181, 168),
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                ZIndex = 52,
                [React.Event.Activated] = function()
                    setTab("BUY")
                    setSelectedItemId(nil)
                    setQuantity(1)
                end,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 7) }),
            }),
            SellTab = React.createElement("TextButton", {
                Position = UDim2.fromOffset(142, 82),
                Size = UDim2.fromOffset(112, 34),
                BackgroundColor3 = tab == "SELL" and Color3.fromRGB(37, 80, 61)
                    or Color3.fromRGB(24, 37, 34),
                BorderSizePixel = 0,
                Text = "SELL",
                TextColor3 = tab == "SELL" and Color3.fromRGB(121, 244, 183)
                    or Color3.fromRGB(154, 181, 168),
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                ZIndex = 52,
                [React.Event.Activated] = function()
                    setTab("SELL")
                    setSelectedItemId(nil)
                    setQuantity(1)
                end,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 7) }),
            }),
            List = React.createElement("ScrollingFrame", {
                Position = UDim2.fromOffset(22, 128),
                Size = UDim2.fromOffset(420, 330),
                CanvasSize = UDim2.fromOffset(0, math.max(330, #rows * 58)),
                BackgroundColor3 = Color3.fromRGB(7, 14, 13),
                BackgroundTransparency = 0.12,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                ScrollBarImageColor3 = Color3.fromRGB(93, 156, 126),
                ZIndex = 52,
            }, listChildren),
            Info = React.createElement(ItemInfoCard, {
                Position = UDim2.fromOffset(468, 128),
                Size = UDim2.fromOffset(326, 154),
                ItemId = effectiveItemId,
                Definition = definition,
                ZIndex = 53,
            }),
            QuantityLabel = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(468, 303),
                Size = UDim2.fromOffset(326, 20),
                BackgroundTransparency = 1,
                Text = "QUANTITY",
                TextColor3 = Color3.fromRGB(139, 169, 154),
                TextSize = 9,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 53,
            }),
            Minus = React.createElement("TextButton", {
                Position = UDim2.fromOffset(468, 329),
                Size = UDim2.fromOffset(42, 36),
                BackgroundColor3 = Color3.fromRGB(31, 46, 42),
                BorderSizePixel = 0,
                Text = "−",
                TextColor3 = Color3.fromRGB(239, 246, 242),
                TextSize = 16,
                Font = Enum.Font.GothamBold,
                ZIndex = 53,
                [React.Event.Activated] = function()
                    setQuantity(clampQuantity(effectiveQuantity - 1))
                end,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
            }),
            Quantity = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(518, 329),
                Size = UDim2.fromOffset(70, 36),
                BackgroundColor3 = Color3.fromRGB(17, 28, 25),
                BorderSizePixel = 0,
                Text = tostring(effectiveQuantity),
                TextColor3 = Color3.fromRGB(239, 246, 242),
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 53,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
            }),
            Plus = React.createElement("TextButton", {
                Position = UDim2.fromOffset(596, 329),
                Size = UDim2.fromOffset(42, 36),
                BackgroundColor3 = Color3.fromRGB(31, 46, 42),
                BorderSizePixel = 0,
                Text = "+",
                TextColor3 = Color3.fromRGB(239, 246, 242),
                TextSize = 16,
                Font = Enum.Font.GothamBold,
                ZIndex = 53,
                [React.Event.Activated] = function()
                    setQuantity(math.min(maxQuantity, effectiveQuantity + 1))
                end,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
            }),
            Total = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(468, 378),
                Size = UDim2.fromOffset(326, 22),
                BackgroundTransparency = 1,
                Text = selected and string.format(
                    "%s: %d %s",
                    tab == "BUY" and "Cost" or "Receive",
                    total,
                    tab == "BUY" and currencyName or (selected.Currency or "Shards")
                ) or "",
                TextColor3 = Color3.fromRGB(232, 193, 105),
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 53,
            }),
            Action = React.createElement("TextButton", {
                Position = UDim2.fromOffset(468, 411),
                Size = UDim2.fromOffset(326, 46),
                BackgroundColor3 = selected and Color3.fromRGB(37, 80, 61)
                    or Color3.fromRGB(27, 38, 35),
                BorderSizePixel = 0,
                Text = selected and (tab == "BUY" and "PURCHASE" or "SELL ITEMS")
                    or "SELECT AN ITEM",
                TextColor3 = selected and Color3.fromRGB(205, 255, 229)
                    or Color3.fromRGB(103, 128, 116),
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                Active = selected ~= nil,
                AutoButtonColor = selected ~= nil,
                ZIndex = 53,
                [React.Event.Activated] = selected and invokeTransaction or nil,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 7) }),
                Stroke = React.createElement(
                    "UIStroke",
                    { Color = Color3.fromRGB(102, 155, 130), Transparency = 0.42 }
                ),
            }),
            Status = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(22, 470),
                Size = UDim2.new(1, -44, 0, 26),
                BackgroundTransparency = 1,
                Text = status,
                TextColor3 = Color3.fromRGB(139, 169, 154),
                TextSize = 9,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 52,
            }),
        }),
    })
end

return ShopOverlay
