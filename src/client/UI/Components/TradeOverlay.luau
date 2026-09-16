local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local ActionClient = require(script.Parent.Parent.Parent.Services.ActionClient)
local NotificationStore = require(script.Parent.Parent.NotificationStore)

local localPlayer = Players.LocalPlayer
local COLORS = table.freeze({
    Backdrop = Color3.fromRGB(5, 10, 9),
    Panel = Color3.fromRGB(15, 24, 22),
    Raised = Color3.fromRGB(24, 37, 34),
    Surface = Color3.fromRGB(31, 46, 42),
    Border = Color3.fromRGB(69, 108, 91),
    Text = Color3.fromRGB(239, 246, 242),
    Muted = Color3.fromRGB(154, 181, 168),
    Faint = Color3.fromRGB(103, 128, 116),
    Accent = Color3.fromRGB(102, 211, 154),
    Lumen = Color3.fromRGB(121, 244, 183),
    Gold = Color3.fromRGB(232, 193, 105),
    Danger = Color3.fromRGB(214, 91, 91),
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

local function run(action, payload, success, setStatus)
    local ok, result = ActionClient.Invoke(action, payload or {})
    if not ok then
        local message = tostring(result or "trade_action_failed")
        setStatus(message)
        NotificationStore.Push("error", "Trade", message, 3)
        return false, result
    end
    setStatus(success or "Trade updated.")
    return true, result
end

local function button(_name, text, position, size, enabled, activated, tone)
    local color = if tone == "danger"
        then Color3.fromRGB(75, 40, 40)
        elseif tone == "gold" then Color3.fromRGB(83, 66, 34)
        else COLORS.Surface
    return React.createElement("TextButton", {
        Position = position,
        Size = size,
        BackgroundColor3 = color,
        BackgroundTransparency = enabled and 0 or 0.45,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = enabled and COLORS.Text or COLORS.Faint,
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = enabled,
        Selectable = enabled,
        Active = enabled,
        ZIndex = 73,
        [React.Event.Activated] = function()
            if enabled and activated then
                activated()
            end
        end,
    }, {
        Corner = corner(6),
        Stroke = stroke(tone == "danger" and COLORS.Danger or COLORS.Border, 0.5),
    })
end

local function label(text, position, size, textSize, color, bold, alignment)
    return React.createElement("TextLabel", {
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or COLORS.Text,
        TextSize = textSize or 10,
        Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
        TextXAlignment = alignment or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        ZIndex = 73,
    })
end

local function offerText(offer)
    local lines = {}
    for _, item in offer and offer.Items or {} do
        table.insert(
            lines,
            string.format("%s ×%d", tostring(item.ItemId):gsub("_", " "), item.Quantity)
        )
    end
    if offer and (offer.Shards or 0) > 0 then
        table.insert(lines, string.format("%d Shards", offer.Shards))
    end
    if #lines == 0 then
        return "Nothing offered"
    end
    return table.concat(lines, "\n")
end

local function TradeOverlay(props)
    local tradeState = props.TradeState or {}
    local profile = props.Profile or {}
    local request = tradeState.Request
    local sent = tradeState.Sent
    local trade = tradeState.Trade
    local status, setStatus = React.useState("Trades are validated and committed by the server.")
    local shardText, setShardText = React.useState("0")
    local revision, setRevision = React.useState(0)

    React.useEffect(function()
        local function refresh()
            setRevision(function(value)
                return value + 1
            end)
        end
        local added = Players.PlayerAdded:Connect(refresh)
        local removing = Players.PlayerRemoving:Connect(refresh)
        return function()
            added:Disconnect()
            removing:Disconnect()
        end
    end, {})
    local _ = revision

    local children = {
        Header = label(
            "WAYFARER TRADE",
            UDim2.fromOffset(22, 14),
            UDim2.fromOffset(360, 28),
            19,
            COLORS.Lumen,
            true
        ),
        Subtitle = label(
            "Direct player exchange · server-authoritative · both sides lock and confirm",
            UDim2.fromOffset(22, 43),
            UDim2.fromOffset(610, 20),
            9,
            COLORS.Faint,
            false
        ),
        Close = button(
            "TradeClose",
            "×",
            UDim2.new(1, -56, 0, 14),
            UDim2.fromOffset(34, 30),
            true,
            props.OnClose,
            "danger"
        ),
        Status = label(
            status,
            UDim2.fromOffset(22, 430),
            UDim2.new(1, -44, 0, 34),
            9,
            COLORS.Muted,
            false
        ),
    }

    if request and not trade then
        children.RequestTitle = label(
            string.format(
                "%s wants to trade",
                request.FromDisplayName or request.FromName or "A Wayfarer"
            ),
            UDim2.fromOffset(40, 122),
            UDim2.new(1, -80, 0, 40),
            17,
            COLORS.Text,
            true,
            Enum.TextXAlignment.Center
        )
        children.RequestBody = label(
            "Accept only when you are ready to review the complete offer. No items move until both players lock and confirm.",
            UDim2.fromOffset(90, 175),
            UDim2.new(1, -180, 0, 60),
            10,
            COLORS.Muted,
            false,
            Enum.TextXAlignment.Center
        )
        children.Accept = button(
            "TradeAccept",
            "ACCEPT TRADE",
            UDim2.new(0.5, -150, 0, 255),
            UDim2.fromOffset(140, 38),
            true,
            function()
                run("trade.accept", {}, "Trade opened.", setStatus)
            end
        )
        children.Decline = button(
            "TradeDecline",
            "DECLINE",
            UDim2.new(0.5, 10, 0, 255),
            UDim2.fromOffset(140, 38),
            true,
            function()
                run("trade.decline", {}, "Trade declined.", setStatus)
            end,
            "danger"
        )
    elseif sent and not trade then
        children.Sent = label(
            "Trade request sent to " .. tostring(sent.TargetName or "Wayfarer") .. ".",
            UDim2.fromOffset(60, 165),
            UDim2.new(1, -120, 0, 44),
            14,
            COLORS.Text,
            true,
            Enum.TextXAlignment.Center
        )
        children.CancelSent = button(
            "TradeCancel",
            "CANCEL REQUEST",
            UDim2.new(0.5, -80, 0, 235),
            UDim2.fromOffset(160, 38),
            true,
            function()
                run("trade.cancel", {}, "Request cancelled.", setStatus)
            end,
            "danger"
        )
    elseif trade then
        local inventory = profile.Inventory or {}
        local rows = inventory.Slots or {}
        children.Partner = label(
            "Trading with " .. tostring(trade.OtherDisplayName or trade.OtherName or "Wayfarer"),
            UDim2.fromOffset(22, 72),
            UDim2.fromOffset(610, 24),
            12,
            COLORS.Gold,
            true
        )
        children.InventoryTitle = label(
            "YOUR INVENTORY",
            UDim2.fromOffset(22, 105),
            UDim2.fromOffset(250, 20),
            9,
            COLORS.Faint,
            true
        )
        local inventoryChildren = {}
        for index = 1, math.min(#rows, 8) do
            local slot = rows[index]
            inventoryChildren["Row" .. index] = React.createElement("Frame", {
                Position = UDim2.fromOffset(0, (index - 1) * 32),
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = COLORS.Raised,
                BorderSizePixel = 0,
                ZIndex = 72,
            }, {
                Corner = corner(5),
                Name = label(
                    tostring(slot.ItemId):gsub("_", " ") .. "  ×" .. tostring(slot.Quantity),
                    UDim2.fromOffset(8, 0),
                    UDim2.new(1, -105, 1, 0),
                    8,
                    COLORS.Text,
                    false
                ),
                One = button(
                    "TradeAddOne" .. index,
                    "+1",
                    UDim2.new(1, -92, 0, 3),
                    UDim2.fromOffset(40, 22),
                    not trade.SelfLocked,
                    function()
                        run(
                            "trade.add_item",
                            { InventoryIndex = index, Quantity = 1 },
                            "Added item.",
                            setStatus
                        )
                    end
                ),
                Stack = button(
                    "TradeAddStack" .. index,
                    "+ALL",
                    UDim2.new(1, -49, 0, 3),
                    UDim2.fromOffset(45, 22),
                    not trade.SelfLocked,
                    function()
                        run(
                            "trade.add_item",
                            { InventoryIndex = index, Quantity = slot.Quantity },
                            "Added stack.",
                            setStatus
                        )
                    end
                ),
            })
        end
        children.Inventory = React.createElement("ScrollingFrame", {
            Position = UDim2.fromOffset(22, 129),
            Size = UDim2.fromOffset(270, 258),
            BackgroundColor3 = COLORS.Panel,
            BackgroundTransparency = 0.15,
            BorderSizePixel = 0,
            CanvasSize = UDim2.fromOffset(0, math.max(258, math.min(#rows, 8) * 32)),
            ScrollBarThickness = 4,
            ZIndex = 71,
        }, inventoryChildren)

        children.SelfTitle = label(
            "YOUR OFFER" .. (trade.SelfLocked and " · LOCKED" or ""),
            UDim2.fromOffset(310, 105),
            UDim2.fromOffset(155, 20),
            9,
            trade.SelfLocked and COLORS.Lumen or COLORS.Faint,
            true
        )
        children.OtherTitle = label(
            "THEIR OFFER" .. (trade.OtherLocked and " · LOCKED" or ""),
            UDim2.fromOffset(478, 105),
            UDim2.fromOffset(155, 20),
            9,
            trade.OtherLocked and COLORS.Lumen or COLORS.Faint,
            true
        )
        children.SelfOffer = label(
            offerText(trade.SelfOffer),
            UDim2.fromOffset(310, 129),
            UDim2.fromOffset(155, 128),
            9,
            COLORS.Text,
            false
        )
        children.OtherOffer = label(
            offerText(trade.OtherOffer),
            UDim2.fromOffset(478, 129),
            UDim2.fromOffset(155, 128),
            9,
            COLORS.Text,
            false
        )

        children.ShardInput = React.createElement("TextBox", {
            Position = UDim2.fromOffset(310, 270),
            Size = UDim2.fromOffset(95, 30),
            BackgroundColor3 = COLORS.Raised,
            BorderSizePixel = 0,
            Text = shardText,
            PlaceholderText = "Shards",
            TextColor3 = COLORS.Text,
            PlaceholderColor3 = COLORS.Faint,
            TextSize = 9,
            Font = Enum.Font.GothamMedium,
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 73,
            [React.Change.Text] = function(box)
                setShardText(box.Text)
            end,
        }, { Corner = corner(5), Stroke = stroke() })
        children.SetShards = button(
            "TradeSetShards",
            "SET SHARDS",
            UDim2.fromOffset(412, 270),
            UDim2.fromOffset(94, 30),
            not trade.SelfLocked,
            function()
                local amount = math.max(0, math.floor(tonumber(shardText) or 0))
                run("trade.set_shards", { Amount = amount }, "Shard offer updated.", setStatus)
            end,
            "gold"
        )

        children.Lock = button(
            "TradeLock",
            trade.SelfLocked and "UNLOCK" or "LOCK OFFER",
            UDim2.fromOffset(310, 319),
            UDim2.fromOffset(145, 38),
            true,
            function()
                run(
                    trade.SelfLocked and "trade.unlock" or "trade.lock",
                    {},
                    trade.SelfLocked and "Offer unlocked." or "Offer locked.",
                    setStatus
                )
            end,
            trade.SelfLocked and nil or "gold"
        )
        local canConfirm = trade.SelfLocked and trade.OtherLocked and not trade.SelfConfirmed
        children.Confirm = button(
            "TradeConfirm",
            trade.SelfConfirmed and "CONFIRMED" or "CONFIRM TRADE",
            UDim2.fromOffset(465, 319),
            UDim2.fromOffset(168, 38),
            canConfirm,
            function()
                run("trade.confirm", {}, "Trade confirmation submitted.", setStatus)
            end
        )
        children.Cancel = button(
            "TradeCancel",
            "CANCEL",
            UDim2.fromOffset(310, 366),
            UDim2.fromOffset(323, 34),
            true,
            function()
                run("trade.cancel", {}, "Trade cancelled.", setStatus)
            end,
            "danger"
        )
    else
        children.BrowseTitle = label(
            "NEARBY WAYFARERS",
            UDim2.fromOffset(32, 96),
            UDim2.fromOffset(300, 24),
            11,
            COLORS.Faint,
            true
        )
        local candidates = {}
        for _, player in Players:GetPlayers() do
            if player ~= localPlayer then
                table.insert(candidates, player)
            end
        end
        table.sort(candidates, function(a, b)
            return string.lower(a.DisplayName) < string.lower(b.DisplayName)
        end)
        if #candidates == 0 then
            children.Empty = label(
                "No other Wayfarers are in this server.",
                UDim2.fromOffset(60, 170),
                UDim2.new(1, -120, 0, 50),
                12,
                COLORS.Muted,
                false,
                Enum.TextXAlignment.Center
            )
        else
            for index, player in candidates do
                children["Candidate" .. player.UserId] = React.createElement("Frame", {
                    Position = UDim2.fromOffset(32, 128 + (index - 1) * 46),
                    Size = UDim2.new(1, -64, 0, 40),
                    BackgroundColor3 = COLORS.Raised,
                    BorderSizePixel = 0,
                    ZIndex = 72,
                }, {
                    Corner = corner(6),
                    Name = label(
                        player.DisplayName .. "  @" .. player.Name,
                        UDim2.fromOffset(12, 0),
                        UDim2.new(1, -140, 1, 0),
                        10,
                        COLORS.Text,
                        true
                    ),
                    Request = button(
                        "TradeRequest" .. player.UserId,
                        "REQUEST",
                        UDim2.new(1, -116, 0.5, -14),
                        UDim2.fromOffset(104, 28),
                        true,
                        function()
                            run(
                                "trade.request",
                                { TargetUserId = player.UserId },
                                "Trade request sent.",
                                setStatus
                            )
                        end
                    ),
                })
            end
        end
    end

    return React.createElement(React.Fragment, nil, {
        Backdrop = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = COLORS.Backdrop,
            BackgroundTransparency = 0.45,
            BorderSizePixel = 0,
            ZIndex = 68,
        }),
        Panel = React.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(655, 480),
            BackgroundColor3 = COLORS.Panel,
            BorderSizePixel = 0,
            ZIndex = 70,
        }, children),
    })
end

return TradeOverlay
