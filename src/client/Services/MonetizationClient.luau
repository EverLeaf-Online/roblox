local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage.Shared.MonetizationConfig)
local Net = require(ReplicatedStorage.Shared.Net)

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
            Name = (supportInfo and supportInfo.Name) or "Support EverLeaf",
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

local function runPrompt(callback)
    local success, err = pcall(callback)
    if not success then
        return false, tostring(err)
    end
    return true
end

function MonetizationClient.RefreshEntitlements()
    local remotes = ReplicatedStorage:FindFirstChild(Net.RemoteFolderName)
    local remote = remotes and remotes:FindFirstChild(Net.Functions.RefreshEntitlements)
    if not remote or not remote:IsA("RemoteFunction") then
        return false, "entitlement_remote_unavailable"
    end
    local success, ok, result = pcall(function()
        return remote:InvokeServer()
    end)
    if not success then
        return false, tostring(ok)
    end
    return ok == true, result
end

function MonetizationClient.PromptFounder()
    if not MonetizationConfig.FounderSalesEnabled then
        return false, "founder_sales_disabled"
    end
    if player:GetAttribute("EverLeafFounder") == true then
        return false, "already_owned"
    end
    return runPrompt(function()
        MarketplaceService:PromptGamePassPurchase(player, MonetizationConfig.FounderPassId)
    end)
end

function MonetizationClient.PromptSupport()
    if not MonetizationConfig.SupportSalesEnabled then
        return false, "support_sales_disabled"
    end
    return runPrompt(function()
        MarketplaceService:PromptProductPurchase(player, MonetizationConfig.SupportProductId)
    end)
end

function MonetizationClient.PromptMembership()
    if not MonetizationConfig.MembershipSalesEnabled then
        return false, "membership_coming_soon"
    end
    if player:GetAttribute("EverLeafMember") == true then
        return false, "already_subscribed"
    end
    return runPrompt(function()
        MarketplaceService:PromptSubscriptionPurchase(
            player,
            MonetizationConfig.MembershipSubscriptionId
        )
    end)
end

function MonetizationClient.PromptCancelMembership()
    if player:GetAttribute("EverLeafMember") ~= true then
        return false, "no_active_membership"
    end
    if player:GetAttribute("EverLeafMembershipRenewing") ~= true then
        return false, "membership_not_renewing"
    end
    local ok, reason = runPrompt(function()
        MarketplaceService:PromptCancelSubscription(
            player,
            MonetizationConfig.MembershipSubscriptionId
        )
    end)
    if not ok then
        return false, reason
    end

    task.spawn(function()
        task.wait(3)
        MonetizationClient.RefreshEntitlements()
        task.wait(10)
        MonetizationClient.RefreshEntitlements()
    end)
    return true
end

return MonetizationClient
