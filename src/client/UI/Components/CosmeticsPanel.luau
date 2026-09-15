local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local COLORS = table.freeze({
    Panel = Color3.fromRGB(18, 28, 26),
    Raised = Color3.fromRGB(24, 37, 34),
    Surface = Color3.fromRGB(31, 46, 42),
    Border = Color3.fromRGB(69, 108, 91),
    Accent = Color3.fromRGB(102, 211, 154),
    Lumen = Color3.fromRGB(121, 244, 183),
    Text = Color3.fromRGB(239, 246, 242),
    Muted = Color3.fromRGB(154, 181, 168),
    Faint = Color3.fromRGB(103, 128, 116),
    Gold = Color3.fromRGB(232, 193, 105),
})

local function corner(radius)
    return React.createElement("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function stroke(color, transparency)
    return React.createElement("UIStroke", {
        Color = color or COLORS.Border,
        Transparency = transparency or 0.55,
        Thickness = 1,
    })
end

local function CosmeticsPanel(props)
    local profile = props.Profile or {}
    local catalog = props.Catalog or {}
    local cosmetics = profile.Cosmetics or {}
    local owned = cosmetics.Owned or {}
    local equipped = cosmetics.Equipped or {}
    local definitions = catalog.Cosmetics or {}
    local selectedId, setSelectedId = React.useState(nil)

    local rows = {}
    for cosmeticId, isOwned in owned do
        local definition = definitions[cosmeticId]
        if isOwned == true and definition then
            table.insert(rows, { Id = cosmeticId, Definition = definition })
        end
    end
    table.sort(rows, function(a, b)
        local aName = a.Definition.DisplayName or a.Id
        local bName = b.Definition.DisplayName or b.Id
        return aName < bName
    end)

    local selected = nil
    for _, row in rows do
        if row.Id == selectedId then
            selected = row
            break
        end
    end
    selected = selected or rows[1]

    local listChildren = {}
    for index, row in rows do
        local definition = row.Definition
        local isEquipped = equipped[definition.Slot] == row.Id
        listChildren["Cosmetic_" .. row.Id] = React.createElement("TextButton", {
            Position = UDim2.fromOffset(0, (index - 1) * 58),
            Size = UDim2.new(1, -8, 0, 50),
            BackgroundColor3 = selected and selected.Id == row.Id and Color3.fromRGB(37, 80, 61)
                or COLORS.Raised,
            BorderSizePixel = 0,
            Text = "",
            ZIndex = 6,
            [React.Event.Activated] = function()
                setSelectedId(row.Id)
            end,
        }, {
            Corner = corner(7),
            Stroke = stroke(
                selected and selected.Id == row.Id and COLORS.Accent or COLORS.Border,
                0.55
            ),
            Name = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(11, 6),
                Size = UDim2.new(1, -22, 0, 19),
                BackgroundTransparency = 1,
                Text = definition.DisplayName or row.Id,
                TextColor3 = COLORS.Text,
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 7,
            }),
            Meta = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(11, 27),
                Size = UDim2.new(1, -22, 0, 16),
                BackgroundTransparency = 1,
                Text = string.upper(definition.Slot or "COSMETIC")
                    .. (isEquipped and " · EQUIPPED" or ""),
                TextColor3 = isEquipped and COLORS.Lumen or COLORS.Faint,
                TextSize = 8,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 7,
            }),
        })
    end

    local selectedDefinition = selected and selected.Definition or nil
    local selectedEquipped = selectedDefinition and equipped[selectedDefinition.Slot] == selected.Id
        or false

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, {
        Header = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(4, 0),
            Size = UDim2.new(1, -8, 0, 27),
            BackgroundTransparency = 1,
            Text = "COSMETIC COLLECTION",
            TextColor3 = COLORS.Text,
            TextSize = 17,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
        }),
        Subheader = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(4, 27),
            Size = UDim2.new(1, -8, 0, 22),
            BackgroundTransparency = 1,
            Text = "Cosmetics are visual-only. Equip earned titles, auras, trails, outfits, and weapon skins here.",
            TextColor3 = COLORS.Muted,
            TextSize = 9,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
        }),
        List = React.createElement("ScrollingFrame", {
            Position = UDim2.fromOffset(4, 58),
            Size = UDim2.fromOffset(246, 342),
            BackgroundColor3 = COLORS.Panel,
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = COLORS.Border,
            CanvasSize = UDim2.fromOffset(0, math.max(342, #rows * 58)),
            AutomaticCanvasSize = Enum.AutomaticSize.None,
            ZIndex = 5,
        }, {
            Corner = corner(9),
            Stroke = stroke(COLORS.Border, 0.62),
            Empty = #rows == 0
                    and React.createElement("TextLabel", {
                        Position = UDim2.fromOffset(16, 20),
                        Size = UDim2.new(1, -32, 0, 90),
                        BackgroundTransparency = 1,
                        Text = "No permanent cosmetics yet. Founder rewards and monthly member collectibles will appear here when earned.",
                        TextColor3 = COLORS.Faint,
                        TextSize = 10,
                        TextWrapped = true,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Top,
                        ZIndex = 6,
                    })
                or nil,
            Rows = React.createElement("Frame", {
                Position = UDim2.fromOffset(8, 8),
                Size = UDim2.new(1, -8, 1, -8),
                BackgroundTransparency = 1,
                ZIndex = 6,
            }, listChildren),
        }),
        Detail = React.createElement("Frame", {
            Position = UDim2.fromOffset(264, 58),
            Size = UDim2.new(1, -268, 0, 342),
            BackgroundColor3 = COLORS.Panel,
            BackgroundTransparency = 0.04,
            BorderSizePixel = 0,
            ZIndex = 5,
        }, {
            Corner = corner(9),
            Stroke = stroke(COLORS.Border, 0.48),
            Empty = selected == nil and React.createElement("TextLabel", {
                Position = UDim2.fromOffset(18, 18),
                Size = UDim2.new(1, -36, 0, 80),
                BackgroundTransparency = 1,
                Text = "Select an earned cosmetic to inspect it.",
                TextColor3 = COLORS.Faint,
                TextSize = 11,
                TextWrapped = true,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6,
            }) or nil,
            Name = selected and React.createElement("TextLabel", {
                Position = UDim2.fromOffset(18, 16),
                Size = UDim2.new(1, -36, 0, 26),
                BackgroundTransparency = 1,
                Text = selectedDefinition.DisplayName or selected.Id,
                TextColor3 = COLORS.Text,
                TextSize = 16,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6,
            }) or nil,
            Slot = selected and React.createElement("TextLabel", {
                Position = UDim2.fromOffset(18, 45),
                Size = UDim2.new(1, -36, 0, 18),
                BackgroundTransparency = 1,
                Text = string.upper(selectedDefinition.Slot or "COSMETIC")
                    .. (selectedEquipped and " · CURRENTLY EQUIPPED" or " · OWNED"),
                TextColor3 = selectedEquipped and COLORS.Lumen or COLORS.Gold,
                TextSize = 9,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6,
            }) or nil,
            Description = selected and React.createElement("TextLabel", {
                Position = UDim2.fromOffset(18, 78),
                Size = UDim2.new(1, -36, 0, 112),
                BackgroundTransparency = 1,
                Text = selectedDefinition.Description or "EverLeaf cosmetic reward.",
                TextColor3 = COLORS.Muted,
                TextSize = 10,
                TextWrapped = true,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                ZIndex = 6,
            }) or nil,
            Source = selected
                    and React.createElement("TextLabel", {
                        Position = UDim2.fromOffset(18, 200),
                        Size = UDim2.new(1, -36, 0, 44),
                        BackgroundTransparency = 1,
                        Text = selectedDefinition.Entitlement == "Founder"
                                and "SOURCE · EVERLEAF FOUNDER"
                            or selectedDefinition.Entitlement == "Membership" and "SOURCE · ACTIVE MEMBERSHIP"
                            or "SOURCE · PERMANENT REWARD",
                        TextColor3 = COLORS.Faint,
                        TextSize = 9,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Top,
                        ZIndex = 6,
                    })
                or nil,
            Action = selected
                    and React.createElement("TextButton", {
                        AnchorPoint = Vector2.new(0, 1),
                        Position = UDim2.new(0, 18, 1, -18),
                        Size = UDim2.new(1, -36, 0, 42),
                        BackgroundColor3 = selectedEquipped and COLORS.Surface
                            or Color3.fromRGB(37, 80, 61),
                        BorderSizePixel = 0,
                        Text = selectedEquipped and "UNEQUIP" or "EQUIP",
                        TextColor3 = selectedEquipped and COLORS.Muted or COLORS.Lumen,
                        TextSize = 11,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 6,
                        [React.Event.Activated] = function()
                            if props.OnInvoke then
                                props.OnInvoke(
                                    "cosmetic.equip",
                                    {
                                        Slot = selectedDefinition.Slot,
                                        CosmeticId = selectedEquipped and "" or selected.Id,
                                    },
                                    selectedEquipped and "Cosmetic unequipped."
                                        or (
                                            (selectedDefinition.DisplayName or selected.Id)
                                            .. " equipped."
                                        )
                                )
                            end
                        end,
                    }, {
                        Corner = corner(8),
                        Stroke = stroke(selectedEquipped and COLORS.Border or COLORS.Accent, 0.45),
                    })
                or nil,
        }),
    })
end

return CosmeticsPanel
