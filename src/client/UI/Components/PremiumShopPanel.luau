local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local MonetizationConfig = require(ReplicatedStorage.Shared.MonetizationConfig)
local MonetizationClient = require(script.Parent.Parent.Parent.Services.MonetizationClient)
local NotificationStore = require(script.Parent.Parent.NotificationStore)

local player = Players.LocalPlayer

local COLORS = table.freeze({
    Panel = Color3.fromRGB(16, 27, 24),
    Card = Color3.fromRGB(24, 38, 34),
    CardOwned = Color3.fromRGB(29, 64, 48),
    Border = Color3.fromRGB(75, 118, 98),
    Accent = Color3.fromRGB(111, 231, 168),
    Text = Color3.fromRGB(239, 246, 242),
    Muted = Color3.fromRGB(150, 178, 164),
    Faint = Color3.fromRGB(103, 128, 116),
    Gold = Color3.fromRGB(232, 193, 105),
})

local function priceText(entry)
    local price = entry and entry.PriceInRobux
    if type(price) == "number" then
        return string.format("%d ROBUX", price)
    end
    return "ROBLOX PRICE"
end

local function ProductCard(props)
    local owned = props.Owned == true
    local enabled = if owned then props.OwnedActionEnabled == true else props.Enabled ~= false
    local buttonText = props.ButtonText
    if owned then
        buttonText = props.OwnedText or "OWNED"
    elseif props.Enabled == false then
        buttonText = "COMING SOON"
    end

    return React.createElement("Frame", {
        Position = props.Position,
        Size = UDim2.new(1, -8, 0, 106),
        BackgroundColor3 = owned and COLORS.CardOwned or COLORS.Card,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 9) }),
        Stroke = React.createElement("UIStroke", {
            Color = owned and COLORS.Accent or COLORS.Border,
            Transparency = owned and 0.28 or 0.55,
        }),
        Title = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(14, 10),
            Size = UDim2.new(1, -166, 0, 22),
            BackgroundTransparency = 1,
            Text = props.Title,
            TextColor3 = owned and COLORS.Accent or COLORS.Text,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6,
        }),
        Price = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(14, 32),
            Size = UDim2.new(1, -166, 0, 18),
            BackgroundTransparency = 1,
            Text = props.Price,
            TextColor3 = COLORS.Gold,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6,
        }),
        Description = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(14, 54),
            Size = UDim2.new(1, -166, 0, 42),
            BackgroundTransparency = 1,
            Text = props.Description,
            TextColor3 = COLORS.Muted,
            TextSize = 9,
            TextWrapped = true,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 6,
        }),
        Action = React.createElement("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(132, 42),
            BackgroundColor3 = if owned
                then Color3.fromRGB(37, 79, 59)
                else if enabled then Color3.fromRGB(40, 91, 65) else Color3.fromRGB(39, 48, 45),
            BackgroundTransparency = enabled and 0 or 0.18,
            BorderSizePixel = 0,
            Text = buttonText,
            TextColor3 = enabled and COLORS.Text or (owned and COLORS.Accent or COLORS.Faint),
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            Active = enabled,
            Selectable = enabled,
            AutoButtonColor = enabled,
            ZIndex = 6,
            [React.Event.Activated] = if enabled then props.OnActivated else nil,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
            Stroke = React.createElement("UIStroke", {
                Color = enabled and COLORS.Accent or COLORS.Border,
                Transparency = enabled and 0.42 or 0.72,
            }),
        }),
    })
end

local function PremiumShopPanel()
    local catalog, setCatalog = React.useState(nil)
    local founder, setFounder = React.useState(player:GetAttribute("EverLeafFounder") == true)
    local member, setMember = React.useState(player:GetAttribute("EverLeafMember") == true)
    local renewing, setRenewing =
        React.useState(player:GetAttribute("EverLeafMembershipRenewing") == true)

    React.useEffect(function()
        local alive = true
        task.spawn(function()
            local result = MonetizationClient.GetCatalog(true)
            if alive then
                setCatalog(result)
            end
        end)

        local founderConnection = player
            :GetAttributeChangedSignal("EverLeafFounder")
            :Connect(function()
                setFounder(player:GetAttribute("EverLeafFounder") == true)
            end)
        local memberConnection = player
            :GetAttributeChangedSignal("EverLeafMember")
            :Connect(function()
                setMember(player:GetAttribute("EverLeafMember") == true)
            end)
        local renewingConnection = player
            :GetAttributeChangedSignal("EverLeafMembershipRenewing")
            :Connect(function()
                setRenewing(player:GetAttribute("EverLeafMembershipRenewing") == true)
            end)
        return function()
            alive = false
            founderConnection:Disconnect()
            memberConnection:Disconnect()
            renewingConnection:Disconnect()
        end
    end, {})

    local founderEntry = catalog and catalog.Founder or { Enabled = true }
    local supportEntry = catalog and catalog.Support or { Enabled = true }
    local membershipEntry = catalog and catalog.Membership
        or { Enabled = MonetizationConfig.MembershipSalesEnabled }

    local function prompt(kind, callback)
        local ok, reason = callback()
        if ok then
            return
        end
        if reason == "already_owned" or reason == "already_subscribed" then
            NotificationStore.Push(
                "info",
                "Already Active",
                "You already have this entitlement.",
                3
            )
        elseif reason == "membership_coming_soon" then
            NotificationStore.Push(
                "info",
                "Membership Coming Soon",
                "Membership sales will open after all recurring benefits are live and verified.",
                4
            )
        else
            NotificationStore.Push("error", kind, tostring(reason or "purchase_unavailable"), 4)
        end
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, {
        Header = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(4, 0),
            Size = UDim2.new(1, -8, 0, 28),
            BackgroundTransparency = 1,
            Text = "EVERLEAF STORE",
            TextColor3 = COLORS.Text,
            TextSize = 18,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
        }),
        Subheader = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(4, 28),
            Size = UDim2.new(1, -8, 0, 30),
            BackgroundTransparency = 1,
            Text = "Support development with cosmetics and recognition — never pay-to-win power. Roblox managed pricing is shown live.",
            TextColor3 = COLORS.Muted,
            TextSize = 9,
            TextWrapped = true,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 5,
        }),
        Founder = React.createElement(ProductCard, {
            Position = UDim2.fromOffset(4, 66),
            Title = "EverLeaf Founder",
            Price = priceText(founderEntry),
            Description = "Permanent Founder badge, gold Founder title, and the Founder's Lumen cosmetic aura. No combat power.",
            ButtonText = "BECOME A FOUNDER",
            OwnedText = "FOUNDER OWNED",
            Owned = founder,
            Enabled = founderEntry.Enabled,
            OnActivated = function()
                prompt("Founder Purchase", MonetizationClient.PromptFounder)
            end,
        }),
        Support = React.createElement(ProductCard, {
            Position = UDim2.fromOffset(4, 180),
            Title = "Support EverLeaf",
            Price = priceText(supportEntry),
            Description = "Optional repeatable support purchase. Thank you for helping Lumenreach grow.",
            ButtonText = "SUPPORT",
            Enabled = supportEntry.Enabled,
            OnActivated = function()
                prompt("Support Purchase", MonetizationClient.PromptSupport)
            end,
        }),
        Membership = React.createElement(ProductCard, {
            Position = UDim2.fromOffset(4, 294),
            Title = "EverLeaf Membership",
            Price = priceText(membershipEntry) .. " / MONTH",
            Description = if member
                then if renewing
                    then "Membership active · renewal on. Includes Member recognition and monthly non-power cosmetic rewards."
                    else "Membership active through the current period · renewal off. Earned monthly cosmetics stay yours."
                else "Recurring Member recognition and monthly non-power cosmetic rewards while active. No combat power.",
            ButtonText = "JOIN MEMBERSHIP",
            OwnedText = renewing and "MANAGE RENEWAL" or "ENDING THIS PERIOD",
            Owned = member,
            OwnedActionEnabled = member and renewing,
            Enabled = membershipEntry.Enabled,
            OnActivated = function()
                if member then
                    prompt("Membership", MonetizationClient.PromptCancelMembership)
                else
                    prompt("Membership", MonetizationClient.PromptMembership)
                end
            end,
        }),
    })
end

return PremiumShopPanel
