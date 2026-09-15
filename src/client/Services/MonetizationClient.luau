local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage.Shared.MonetizationConfig)

local MonetizationClient = {}
local player = Players.LocalPlayer
local cachedCatalog = nil
local cachedAt = 0
local CACHE_SECONDS = 30

local function fetchProduct(assetId, infoType)
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfoAsync(assetId, infoType)
    end)
    if success and type(info) == "table" then
        return info
    end
    return nil
end

local function fetchSubscription(subscriptionId)
    local success, info = pcall(function()
        return MarketplaceService:GetSubscriptionProductInfoAsync(subscriptionId)
    end)
    if success and type(info) == "table" then
        return info
    end
    return nil
end

local function priceFrom(info)
    local price = info and tonumber(info.PriceInRobux)
    return price and math.max(0, math.floor(price)) or nil
end

function MonetizationClient.GetCatalog(forceRefresh)
    if not forceRefresh and cachedCatalog and os.clock() - cachedAt < CACHE_SECONDS then
        return cachedCatalog
    end

    local founderInfo = fetchProduct(MonetizationConfig.FounderPassId, Enum.InfoType.GamePass)
    local supportInfo = fetchProduct(MonetizationConfig.SupportProductId, Enum.InfoType.Product)
    local membershipInfo = fetchSubscription(MonetizationConfig.MembershipSubscriptionId)

    cachedCatalog = {
        Founder = {
            Id = MonetizationConfig.FounderPassId,
            Name = (founderInfo and founderInfo.Name) or "EverLeaf Founder",
            PriceInRobux = priceFrom(founderInfo),
            Enabled = MonetizationConfig.FounderSalesEnabled,
        },
        Support = {
            Id = MonetizationConfig.SupportProductId,
            Name = (supportInfo and supportInfo.Name) or "Support EverLeaf – 50",
            PriceInRobux = priceFrom(supportInfo),
            Enabled = MonetizationConfig.SupportSalesEnabled,
        },
        Membership = {
            Id = MonetizationConfig.MembershipSubscriptionId,
            Name = (membershipInfo and membershipInfo.Name) or "EverLeaf Membership",
            PriceInRobux = priceFrom(membershipInfo),
            Enabled = MonetizationConfig.MembershipSalesEnabled,
        },
    }
    cachedAt = os.clock()
    return cachedCatalog
end

function MonetizationClient.PromptFounder()
    if not MonetizationConfig.FounderSalesEnabled then
        return false, "founder_sales_disabled"
    end
    if player:GetAttribute("EverLeafFounder") == true then
        return false, "already_owned"
    end
    MarketplaceService:PromptGamePassPurchase(player, MonetizationConfig.FounderPassId)
    return true
end

function MonetizationClient.PromptSupport()
    if not MonetizationConfig.SupportSalesEnabled then
        return false, "support_sales_disabled"
    end
    MarketplaceService:PromptProductPurchase(player, MonetizationConfig.SupportProductId)
    return true
end

function MonetizationClient.PromptMembership()
    if not MonetizationConfig.MembershipSalesEnabled then
        return false, "membership_coming_soon"
    end
    if player:GetAttribute("EverLeafMember") == true then
        return false, "already_subscribed"
    end
    MarketplaceService:PromptSubscriptionPurchase(
        player,
        MonetizationConfig.MembershipSubscriptionId
    )
    return true
end

return MonetizationClient
