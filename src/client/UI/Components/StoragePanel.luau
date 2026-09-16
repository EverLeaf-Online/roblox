local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local COLORS = table.freeze({
    Panel = Color3.fromRGB(18, 28, 26),
    Raised = Color3.fromRGB(24, 37, 34),
    Surface = Color3.fromRGB(31, 46, 42),
    Border = Color3.fromRGB(69, 108, 91),
    Accent = Color3.fromRGB(102, 211, 154),
    Text = Color3.fromRGB(239, 246, 242),
    Muted = Color3.fromRGB(154, 181, 168),
    Faint = Color3.fromRGB(103, 128, 116),
    Gold = Color3.fromRGB(232, 193, 105),
})

local function corner(radius)
    return React.createElement("UICorner", { CornerRadius = UDim.new(0, radius or 7) })
end

local function stroke(color, transparency)
    return React.createElement("UIStroke", {
        Color = color or COLORS.Border,
        Transparency = transparency or 0.58,
        Thickness = 1,
    })
end

local function itemName(catalog, itemId)
    local item = catalog.Items and catalog.Items[itemId]
    return item and item.DisplayName or tostring(itemId or "Unknown")
end

local function listColumn(title, slots, capacity, selectedIndex, setSelectedIndex, catalog, x)
    local children = {
        Title = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(10, 7),
            Size = UDim2.new(1, -20, 0, 20),
            BackgroundTransparency = 1,
            Text = string.format("%s  %d/%d", title, #slots, tonumber(capacity) or 0),
            TextColor3 = COLORS.Text,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 7,
        }),
    }

    local rows = {}
    for index, slot in slots do
        local selected = selectedIndex == index
        rows["Slot_" .. index] = React.createElement("TextButton", {
            Size = UDim2.new(1, -8, 0, 42),
            BackgroundColor3 = selected and Color3.fromRGB(37, 80, 61) or COLORS.Raised,
            BorderSizePixel = 0,
            Text = "",
            ZIndex = 8,
            [React.Event.Activated] = function()
                setSelectedIndex(index)
            end,
        }, {
            Corner = corner(6),
            Stroke = stroke(selected and COLORS.Accent or COLORS.Border, selected and 0.3 or 0.68),
            Name = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(10, 4),
                Size = UDim2.new(1, -20, 0, 18),
                BackgroundTransparency = 1,
                Text = itemName(catalog, slot.ItemId),
                TextColor3 = COLORS.Text,
                TextSize = 9,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 9,
            }),
            Quantity = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(10, 22),
                Size = UDim2.new(1, -20, 0, 14),
                BackgroundTransparency = 1,
                Text = string.format("x%d", tonumber(slot.Quantity) or 0),
                TextColor3 = COLORS.Faint,
                TextSize = 8,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 9,
            }),
        })
    end
    if #slots == 0 then
        rows.Empty = React.createElement("TextLabel", {
            Size = UDim2.new(1, -8, 0, 48),
            BackgroundTransparency = 1,
            Text = title == "INVENTORY" and "Your inventory is empty." or "Storage is empty.",
            TextColor3 = COLORS.Faint,
            TextSize = 9,
            Font = Enum.Font.Gotham,
            TextWrapped = true,
            ZIndex = 8,
        })
    end

    children.List = React.createElement("ScrollingFrame", {
        Position = UDim2.fromOffset(8, 34),
        Size = UDim2.new(1, -16, 1, -42),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = COLORS.Border,
        CanvasSize = UDim2.fromOffset(0, math.max(0, #slots * 48)),
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        ZIndex = 7,
    }, {
        Layout = React.createElement("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
        Rows = React.createElement(React.Fragment, nil, rows),
    })

    return React.createElement("Frame", {
        Position = UDim2.fromOffset(x, 42),
        Size = UDim2.fromOffset(245, 336),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        ZIndex = 6,
    }, {
        Corner = corner(9),
        Stroke = stroke(),
        Children = React.createElement(React.Fragment, nil, children),
    })
end

local function transferButton(text, y, enabled, onActivated)
    return React.createElement("TextButton", {
        Position = UDim2.fromOffset(255, y),
        Size = UDim2.fromOffset(86, 36),
        BackgroundColor3 = enabled and COLORS.Surface or COLORS.Panel,
        BackgroundTransparency = enabled and 0 or 0.45,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = enabled and COLORS.Text or COLORS.Faint,
        TextSize = 8,
        Font = Enum.Font.GothamBold,
        TextWrapped = true,
        AutoButtonColor = enabled,
        Active = enabled,
        ZIndex = 10,
        [React.Event.Activated] = function()
            if enabled then
                onActivated()
            end
        end,
    }, {
        Corner = corner(7),
        Stroke = stroke(enabled and COLORS.Accent or COLORS.Border, enabled and 0.45 or 0.8),
    })
end

local function StoragePanel(props)
    local profile = props.Profile or {}
    local catalog = props.Catalog or {}
    local inventory = profile.Inventory or { Capacity = 0, Slots = {} }
    local storage = profile.Storage or { Capacity = 0, Slots = {} }
    local inventorySlots = inventory.Slots or {}
    local storageSlots = storage.Slots or {}
    local selectedInventory, setSelectedInventory = React.useState(1)
    local selectedStorage, setSelectedStorage = React.useState(1)

    local invSlot = inventorySlots[selectedInventory]
    local storageSlot = storageSlots[selectedStorage]
    local invoke = props.OnInvoke

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, {
        Header = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(4, 0),
            Size = UDim2.new(1, -8, 0, 26),
            BackgroundTransparency = 1,
            Text = "WAYFARER STORAGE",
            TextColor3 = COLORS.Text,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6,
        }),
        Hint = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(4, 22),
            Size = UDim2.new(1, -8, 0, 18),
            BackgroundTransparency = 1,
            Text = "Move items atomically between your carried inventory and persistent storage.",
            TextColor3 = COLORS.Faint,
            TextSize = 8,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6,
        }),
        Inventory = listColumn(
            "INVENTORY",
            inventorySlots,
            inventory.Capacity,
            selectedInventory,
            setSelectedInventory,
            catalog,
            0
        ),
        Storage = listColumn(
            "STORAGE",
            storageSlots,
            storage.Capacity,
            selectedStorage,
            setSelectedStorage,
            catalog,
            351
        ),
        DepositOne = transferButton("DEPOSIT 1 →", 122, invSlot ~= nil, function()
            invoke(
                "storage.deposit",
                { InventoryIndex = selectedInventory, Quantity = 1 },
                "Deposited item."
            )
        end),
        DepositStack = transferButton("DEPOSIT STACK →", 164, invSlot ~= nil, function()
            invoke(
                "storage.deposit",
                { InventoryIndex = selectedInventory, Quantity = invSlot and invSlot.Quantity or 1 },
                "Deposited stack."
            )
        end),
        WithdrawOne = transferButton("← WITHDRAW 1", 236, storageSlot ~= nil, function()
            invoke(
                "storage.withdraw",
                { StorageIndex = selectedStorage, Quantity = 1 },
                "Withdrew item."
            )
        end),
        WithdrawStack = transferButton("← WITHDRAW STACK", 278, storageSlot ~= nil, function()
            invoke("storage.withdraw", {
                StorageIndex = selectedStorage,
                Quantity = storageSlot and storageSlot.Quantity or 1,
            }, "Withdrew stack.")
        end),
        Security = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(252, 385),
            Size = UDim2.fromOffset(95, 40),
            BackgroundTransparency = 1,
            Text = "SERVER\nAUTHORITATIVE",
            TextColor3 = COLORS.Gold,
            TextSize = 7,
            Font = Enum.Font.GothamBold,
            TextWrapped = true,
            ZIndex = 6,
        }),
    })
end

return StoragePanel
