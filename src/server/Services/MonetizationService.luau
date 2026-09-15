local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MonetizationConfig = require(ReplicatedStorage.Shared.MonetizationConfig)
local MonetizationRules = require(ReplicatedStorage.Shared.Logic.MonetizationRules)
local CosmeticDefinitions = require(ReplicatedStorage.Shared.CosmeticDefinitions)
local Net = require(ReplicatedStorage.Shared.Net)
local AchievementService = require(script.Parent.AchievementService)
local AuditLogService = require(script.Parent.AuditLogService)
local CosmeticService = require(script.Parent.CosmeticService)
local PlayerDataService = require(script.Parent.PlayerDataService)

local MonetizationService = {}
local initialized = false
local changedEvent = Instance.new("BindableEvent")
MonetizationService.Changed = changedEvent.Event
local receiptStoreName = if RunService:IsStudio()
    then "EverLeafPurchaseReceipts_Studio_v1"
    else "EverLeafPurchaseReceipts_v1"
local receiptStore = DataStoreService:GetDataStore(receiptStoreName)

local function worldNotice(player, kind, title, body, duration)
    if not player or player.Parent ~= Players then
        return
    end
    local remotes = ReplicatedStorage:FindFirstChild(Net.RemoteFolderName)
    local remote = remotes and remotes:FindFirstChild(Net.Events.WorldNotice)
    if remote and remote:IsA("RemoteEvent") then
        remote:FireClient(player, {
            Kind = kind,
            Title = title,
            Body = body,
            Duration = duration or 4,
        })
    end
end

local function setFounder(player, value)
    local nextValue = value == true
    if player:GetAttribute("EverLeafFounder") == nextValue then
        return false
    end
    player:SetAttribute("EverLeafFounder", nextValue)
    changedEvent:Fire(player)
    return true
end

local function setMembership(player, isSubscribed, isRenewing)
    local nextSubscribed = isSubscribed == true
    local nextRenewing = isRenewing == true
    local changed = player:GetAttribute("EverLeafMember") ~= nextSubscribed
        or player:GetAttribute("EverLeafMembershipRenewing") ~= nextRenewing
    player:SetAttribute("EverLeafMember", nextSubscribed)
    player:SetAttribute("EverLeafMembershipRenewing", nextRenewing)
    if changed then
        changedEvent:Fire(player)
    end
    return changed
end

local function grantFounderCosmetics(profile)
    local changed = false
    for _, cosmeticId in { "founder_title", "founder_lumen_aura" } do
        local granted = CosmeticService.Grant(profile, cosmeticId)
        changed = granted or changed
    end

    if not profile.Cosmetics.Equipped.Title or profile.Cosmetics.Equipped.Title == "" then
        local equipped = CosmeticService.Equip(profile, "Title", "founder_title")
        changed = equipped or changed
    end
    if not profile.Cosmetics.Equipped.Aura or profile.Cosmetics.Equipped.Aura == "" then
        local equipped = CosmeticService.Equip(profile, "Aura", "founder_lumen_aura")
        changed = equipped or changed
    end
    return changed
end

local function refreshFounder(player)
    local success, ownsPass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(
            player.UserId,
            MonetizationConfig.FounderPassId
        )
    end)
    if not success then
        warn(
            string.format(
                "[MonetizationService] Founder lookup failed for %s: %s",
                player.Name,
                tostring(ownsPass)
            )
        )
        return false, "founder_lookup_failed"
    end
    if player.Parent ~= Players then
        return false, "player_left"
    end

    setFounder(player, ownsPass == true)
    if ownsPass == true then
        local profile = PlayerDataService.Get(player)
        if profile then
            local badgeChanged =
                AchievementService.UnlockAndAward(player, profile, "everleaf_founder")
            local cosmeticChanged = grantFounderCosmetics(profile)
            if badgeChanged or cosmeticChanged then
                PlayerDataService.NotifyChanged(player)
            end
        end
    end
    return true, ownsPass == true
end

local function grantMonthlyMemberCosmetic(player, profile)
    local period = os.date("!%Y-%m")
    local cosmeticId = MonetizationConfig.MonthlyMemberCosmetics[period]
    if not cosmeticId then
        return false
    end
    local granted = CosmeticService.Grant(profile, cosmeticId)
    if not granted then
        return false
    end
    local definition = CosmeticDefinitions[cosmeticId]
    local slotName = definition and definition.Slot
    if
        slotName
        and (not profile.Cosmetics.Equipped[slotName] or profile.Cosmetics.Equipped[slotName] == "")
    then
        CosmeticService.Equip(profile, slotName, cosmeticId)
    end
    PlayerDataService.NotifyChanged(player)
    worldNotice(
        player,
        "reward",
        "Monthly Member Cosmetic",
        string.format(
            "%s has been added to your permanent cosmetic collection.",
            definition and definition.DisplayName or cosmeticId
        ),
        6
    )
    return true
end

local function refreshMembership(player)
    if not MonetizationRules.ShouldRefreshMembership(MonetizationConfig) then
        setMembership(player, false, false)
        return true, false
    end

    local success, status = pcall(function()
        return MarketplaceService:GetUserSubscriptionStatusAsync(
            player,
            MonetizationConfig.MembershipSubscriptionId
        )
    end)
    if not success then
        warn(
            string.format(
                "[MonetizationService] Membership lookup failed for %s: %s",
                player.Name,
                tostring(status)
            )
        )
        return false, "membership_lookup_failed"
    end
    if player.Parent ~= Players then
        return false, "player_left"
    end

    local subscribed = type(status) == "table" and status.IsSubscribed == true
    local renewing = type(status) == "table" and status.IsRenewing == true
    setMembership(player, subscribed, renewing)
    if subscribed then
        local profile = PlayerDataService.Get(player)
        if profile then
            grantMonthlyMemberCosmetic(player, profile)
        end
    end
    return true, subscribed
end

local function recordSupportReceipt(receiptInfo)
    local purchaseId = tostring(receiptInfo.PurchaseId or "")
    if purchaseId == "" then
        return false, false, "missing_purchase_id"
    end

    local inserted = false
    local success, result = pcall(function()
        return receiptStore:UpdateAsync("receipt:" .. purchaseId, function(existing)
            if existing ~= nil then
                return existing
            end
            inserted = true
            return {
                PurchaseId = purchaseId,
                ProductId = receiptInfo.ProductId,
                PlayerId = receiptInfo.PlayerId,
                PlaceIdWherePurchased = receiptInfo.PlaceIdWherePurchased,
                CurrencySpent = receiptInfo.CurrencySpent,
                RecordedAt = os.time(),
            }
        end)
    end)
    if not success then
        return false, false, tostring(result)
    end
    return true, inserted, result
end

local function processReceipt(receiptInfo)
    if receiptInfo.ProductId ~= MonetizationConfig.SupportProductId then
        warn(
            string.format(
                "[MonetizationService] No handler for developer product %s",
                tostring(receiptInfo.ProductId)
            )
        )
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local recorded, inserted, reason = recordSupportReceipt(receiptInfo)
    if not recorded then
        warn(
            string.format(
                "[MonetizationService] Receipt %s deferred: %s",
                tostring(receiptInfo.PurchaseId),
                tostring(reason)
            )
        )
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if inserted then
        AuditLogService.Record(
            "monetization",
            player,
            string.format(
                "support product receipt granted purchase=%s product=%d spent=%s",
                tostring(receiptInfo.PurchaseId),
                receiptInfo.ProductId,
                tostring(receiptInfo.CurrencySpent)
            )
        )
        if player then
            player:SetAttribute("EverLeafLastSupportAt", os.time())
            worldNotice(
                player,
                "success",
                "Thank You",
                "Thank you for supporting EverLeaf Online and helping Lumenreach grow.",
                5
            )
        end
    end

    return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.RefreshEntitlementsNow(player)
    if not player or not player:IsA("Player") or player.Parent ~= Players then
        return false, "invalid_player"
    end
    local founderOk, founderResult = refreshFounder(player)
    local membershipOk, membershipResult = refreshMembership(player)
    if not founderOk then
        return false, founderResult
    end
    if not membershipOk then
        return false, membershipResult
    end
    return true, MonetizationService.GetSnapshot(player)
end

function MonetizationService.RefreshEntitlements(player)
    task.spawn(function()
        MonetizationService.RefreshEntitlementsNow(player)
    end)
end

function MonetizationService.OnProfileLoaded(player)
    setFounder(player, false)
    setMembership(player, false, false)
    MonetizationService.RefreshEntitlements(player)
end

function MonetizationService.IsFounder(player)
    return player:GetAttribute("EverLeafFounder") == true
end

function MonetizationService.IsMember(player)
    return player:GetAttribute("EverLeafMember") == true
end

function MonetizationService.GetSnapshot(player)
    return {
        Founder = MonetizationService.IsFounder(player),
        Member = MonetizationService.IsMember(player),
        MembershipRenewing = player:GetAttribute("EverLeafMembershipRenewing") == true,
    }
end

function MonetizationService.GetPriceLevels(userIds)
    if type(userIds) ~= "table" or #userIds == 0 then
        return false, "invalid_user_ids"
    end
    local success, result = pcall(function()
        return MarketplaceService:GetUsersPriceLevelsAsync(userIds)
    end)
    if not success or type(result) ~= "table" then
        return false, "price_level_lookup_failed"
    end
    local lookup = {}
    for _, info in result do
        if type(info.UserId) == "number" and type(info.PriceLevel) == "number" then
            lookup[info.UserId] = info.PriceLevel
        end
    end
    return true, lookup
end

function MonetizationService.CanGift(sender, recipient)
    if not MonetizationConfig.GiftingEnabled then
        return false, "gifting_disabled"
    end
    if not sender or not recipient or not sender:IsA("Player") or not recipient:IsA("Player") then
        return false, "invalid_players"
    end
    local ok, levels = MonetizationService.GetPriceLevels({ sender.UserId, recipient.UserId })
    if not ok then
        return false, levels
    end
    local senderLevel = levels[sender.UserId]
    local recipientLevel = levels[recipient.UserId]
    if type(senderLevel) ~= "number" or type(recipientLevel) ~= "number" then
        return false, "price_level_missing"
    end
    return senderLevel >= recipientLevel,
        senderLevel >= recipientLevel and nil or "regional_price_mismatch"
end

function MonetizationService.CanTradePaidItems(userA, userB)
    if not MonetizationConfig.PaidItemTradingEnabled then
        return false, "paid_item_trading_disabled"
    end
    if not userA or not userB or not userA:IsA("Player") or not userB:IsA("Player") then
        return false, "invalid_players"
    end
    local ok, levels = MonetizationService.GetPriceLevels({ userA.UserId, userB.UserId })
    if not ok then
        return false, levels
    end
    local a = levels[userA.UserId]
    local b = levels[userB.UserId]
    if type(a) ~= "number" or type(b) ~= "number" then
        return false, "price_level_missing"
    end
    return a == b, a == b and nil or "regional_price_mismatch"
end

function MonetizationService.HasBenefit(player, benefitId)
    if type(benefitId) ~= "string" then
        return false
    end
    if
        MonetizationService.IsFounder(player)
        and table.find(MonetizationConfig.Benefits.Founder, benefitId)
    then
        return true
    end
    if
        MonetizationService.IsMember(player)
        and table.find(MonetizationConfig.Benefits.Membership, benefitId)
    then
        return true
    end
    return false
end

function MonetizationService.Init()
    if initialized then
        return
    end
    initialized = true

    local configOk, configReason = MonetizationRules.Validate(MonetizationConfig)
    if not configOk then
        error(
            string.format(
                "[MonetizationService] Invalid monetization config: %s",
                tostring(configReason)
            )
        )
    end

    MarketplaceService.ProcessReceipt = processReceipt

    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
        if passId ~= MonetizationConfig.FounderPassId or not wasPurchased then
            return
        end
        task.spawn(function()
            local ok, owns = refreshFounder(player)
            if ok and owns then
                worldNotice(
                    player,
                    "success",
                    "EverLeaf Founder",
                    "Founder status confirmed. Your permanent Founder badge has been awarded.",
                    5
                )
            end
        end)
    end)

    MarketplaceService.PromptSubscriptionPurchaseFinished:Connect(
        function(player, subscriptionId, didTryPurchasing)
            if
                subscriptionId ~= MonetizationConfig.MembershipSubscriptionId
                or not didTryPurchasing
            then
                return
            end
            task.spawn(function()
                -- Subscription state can lag the prompt-finished event briefly.
                for attempt = 1, 3 do
                    if attempt > 1 then
                        task.wait(attempt)
                    end
                    local ok, subscribed = refreshMembership(player)
                    if ok and subscribed then
                        worldNotice(
                            player,
                            "success",
                            "EverLeaf Membership",
                            "Membership is active. Your member benefits are now enabled.",
                            5
                        )
                        return
                    end
                end
            end)
        end
    )

    Players.PlayerRemoving:Connect(function(player)
        setFounder(player, false)
        setMembership(player, false, false)
    end)
end

return MonetizationService
