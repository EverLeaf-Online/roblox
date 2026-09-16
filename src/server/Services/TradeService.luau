local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local TradeRules = require(ReplicatedStorage.Shared.Logic.TradeRules)
local InventoryService = require(script.Parent.InventoryService)
local ItemDefinitions = require(script.Parent.Parent.Content.ItemDefinitions)
local PlayerDataService = require(script.Parent.PlayerDataService)
local ProfileSchema = require(script.Parent.Parent.Data.ProfileSchema)

local TradeService = {}
local requests = {}
local sessions = {}
local nextTradeId = 0
local event = Instance.new("BindableEvent")
TradeService.Event = event.Event

local function enabled()
    return GameConfig.Features.Trading == true
end

local function regionId(player)
    local profile = PlayerDataService.Get(player)
    return profile and profile.World and profile.World.RegionId or nil
end

local function rootPosition(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then
        return nil
    end
    return root.Position
end

local function distanceBetween(a, b)
    local ap = rootPosition(a)
    local bp = rootPosition(b)
    if not ap or not bp then
        return math.huge
    end
    return (ap - bp).Magnitude
end

local function otherPlayer(session, player)
    if session.A == player then
        return session.B
    elseif session.B == player then
        return session.A
    end
    return nil
end

local function offerFor(session, player)
    return session.Offers[player]
end

local function copyOffer(offer)
    local items = {}
    for itemId, quantity in offer.Items do
        table.insert(items, { ItemId = itemId, Quantity = quantity })
    end
    table.sort(items, function(a, b)
        return a.ItemId < b.ItemId
    end)
    return { Items = items, Shards = offer.Shards or 0 }
end

local function snapshot(session, player)
    local other = otherPlayer(session, player)
    if not other then
        return nil
    end
    return {
        TradeId = session.Id,
        OtherUserId = other.UserId,
        OtherName = other.Name,
        OtherDisplayName = other.DisplayName,
        SelfOffer = copyOffer(offerFor(session, player)),
        OtherOffer = copyOffer(offerFor(session, other)),
        SelfLocked = session.Locked[player] == true,
        OtherLocked = session.Locked[other] == true,
        SelfConfirmed = session.Confirmed[player] == true,
        OtherConfirmed = session.Confirmed[other] == true,
    }
end

local function fireSession(session)
    for _, player in { session.A, session.B } do
        if player.Parent == Players then
            event:Fire(player, { Type = "Changed", Trade = snapshot(session, player) })
        end
    end
end

local function clearRequest(target, reason)
    local request = requests[target]
    if not request then
        return
    end
    requests[target] = nil
    if target.Parent == Players then
        event:Fire(target, { Type = "RequestCleared", Reason = reason })
    end
    local source = request.From
    if source and source.Parent == Players then
        event:Fire(source, { Type = "RequestCleared", Reason = reason })
    end
end

local function clearRequestsFor(player)
    clearRequest(player, "cancelled")
    for target, request in requests do
        if request.From == player then
            clearRequest(target, "cancelled")
        end
    end
end

local function endSession(session, eventType, reason)
    if not session or session.Closed then
        return
    end
    session.Closed = true
    sessions[session.A] = nil
    sessions[session.B] = nil
    for _, player in { session.A, session.B } do
        if player.Parent == Players then
            event:Fire(player, { Type = eventType, Reason = reason })
        end
    end
end

local function resetApproval(session)
    session.Locked[session.A] = false
    session.Locked[session.B] = false
    session.Confirmed[session.A] = false
    session.Confirmed[session.B] = false
end

local function validateOffer(profile, offer)
    if type(profile) ~= "table" or type(offer) ~= "table" then
        return false, "invalid_offer"
    end
    local distinct = 0
    for itemId, quantity in offer.Items do
        distinct += 1
        local definition = ItemDefinitions[itemId]
        if not definition or definition.Tradeable == false then
            return false, "item_not_tradeable"
        end
        if not TradeRules.ValidQuantity(quantity) then
            return false, "invalid_quantity"
        end
        if InventoryService.Count(profile, itemId) < quantity then
            return false, "item_changed"
        end
    end
    if distinct > TradeRules.MaxOfferTypes then
        return false, "offer_full"
    end
    if
        not TradeRules.ValidShardAmount(
            offer.Shards or 0,
            profile.Currencies and profile.Currencies.Shards
        )
    then
        return false, "invalid_shards"
    end
    return true
end

local function commitProfile(target, source)
    for key in target do
        target[key] = nil
    end
    for key, value in source do
        target[key] = value
    end
end

local function executeTrade(session)
    local profileA = PlayerDataService.Get(session.A)
    local profileB = PlayerDataService.Get(session.B)
    if not profileA or not profileB then
        return false, "profile_not_loaded"
    end
    local offerA = offerFor(session, session.A)
    local offerB = offerFor(session, session.B)
    local okA, reasonA = validateOffer(profileA, offerA)
    if not okA then
        return false, reasonA
    end
    local okB, reasonB = validateOffer(profileB, offerB)
    if not okB then
        return false, reasonB
    end

    local workA = ProfileSchema.DeepCopy(profileA)
    local workB = ProfileSchema.DeepCopy(profileB)
    for itemId, quantity in offerA.Items do
        local ok, reason = InventoryService.Remove(workA, itemId, quantity)
        if not ok then
            return false, reason
        end
    end
    for itemId, quantity in offerB.Items do
        local ok, reason = InventoryService.Remove(workB, itemId, quantity)
        if not ok then
            return false, reason
        end
    end
    workA.Currencies.Shards -= offerA.Shards or 0
    workB.Currencies.Shards -= offerB.Shards or 0

    for itemId, quantity in offerB.Items do
        local ok, reason = InventoryService.Add(workA, itemId, quantity)
        if not ok then
            return false, reason == "inventory_full" and "recipient_inventory_full" or reason
        end
    end
    for itemId, quantity in offerA.Items do
        local ok, reason = InventoryService.Add(workB, itemId, quantity)
        if not ok then
            return false, reason == "inventory_full" and "recipient_inventory_full" or reason
        end
    end
    workA.Currencies.Shards += offerB.Shards or 0
    workB.Currencies.Shards += offerA.Shards or 0

    -- Both profiles are fully validated on detached copies before either live profile is changed.
    -- This function contains no yields, so the two commits are one server task transaction.
    commitProfile(profileA, workA)
    commitProfile(profileB, workB)
    PlayerDataService.NotifyChanged(session.A)
    PlayerDataService.NotifyChanged(session.B)
    return true
end

function TradeService.IsEnabled()
    return enabled()
end

function TradeService.GetSnapshot(player)
    local session = sessions[player]
    return session and snapshot(session, player) or nil
end

function TradeService.Request(player, targetUserId)
    if not enabled() then
        return false, "trading_not_enabled"
    end
    local target = Players:GetPlayerByUserId(targetUserId)
    if not target or target == player then
        return false, "invalid_target"
    end
    local allowed, reason = TradeRules.CanRequest(
        sessions[player] ~= nil,
        sessions[target] ~= nil or requests[target] ~= nil,
        regionId(player) ~= nil and regionId(player) == regionId(target),
        distanceBetween(player, target)
    )
    if not allowed then
        return false, reason
    end
    if not PlayerDataService.Get(player) or not PlayerDataService.Get(target) then
        return false, "profile_not_loaded"
    end
    clearRequestsFor(player)
    requests[target] = { From = player, ExpiresAt = os.clock() + TradeRules.InviteSeconds }
    event:Fire(target, {
        Type = "Request",
        FromUserId = player.UserId,
        FromName = player.Name,
        FromDisplayName = player.DisplayName,
        Duration = TradeRules.InviteSeconds,
    })
    event:Fire(
        player,
        { Type = "RequestSent", TargetUserId = target.UserId, TargetName = target.Name }
    )
    return true
end

function TradeService.Accept(player)
    if not enabled() then
        return false, "trading_not_enabled"
    end
    local request = requests[player]
    if not request then
        return false, "no_trade_request"
    end
    if request.ExpiresAt <= os.clock() then
        clearRequest(player, "expired")
        return false, "trade_request_expired"
    end
    local source = request.From
    if not source or source.Parent ~= Players then
        clearRequest(player, "source_left")
        return false, "invalid_target"
    end
    local allowed, reason = TradeRules.CanRequest(
        sessions[source] ~= nil,
        sessions[player] ~= nil,
        regionId(source) ~= nil and regionId(source) == regionId(player),
        distanceBetween(source, player)
    )
    if not allowed then
        clearRequest(player, reason)
        return false, reason
    end
    requests[player] = nil
    nextTradeId += 1
    local session = {
        Id = nextTradeId,
        A = source,
        B = player,
        Offers = {
            [source] = { Items = {}, Shards = 0 },
            [player] = { Items = {}, Shards = 0 },
        },
        Locked = { [source] = false, [player] = false },
        Confirmed = { [source] = false, [player] = false },
    }
    sessions[source] = session
    sessions[player] = session
    fireSession(session)
    return true, snapshot(session, player)
end

function TradeService.Decline(player)
    if not requests[player] then
        return false, "no_trade_request"
    end
    clearRequest(player, "declined")
    return true
end

function TradeService.AddItem(player, inventoryIndex, quantity)
    local session = sessions[player]
    if not session then
        return false, "not_trading"
    end
    if session.Locked[player] then
        return false, "offer_locked"
    end
    local profile = PlayerDataService.Get(player)
    local slot = profile and profile.Inventory and profile.Inventory.Slots[inventoryIndex]
    if not slot then
        return false, "empty_slot"
    end
    local definition = ItemDefinitions[slot.ItemId]
    if not definition or definition.Tradeable == false then
        return false, "item_not_tradeable"
    end
    local offer = offerFor(session, player)
    local already = offer.Items[slot.ItemId] or 0
    local distinct = 0
    for _ in offer.Items do
        distinct += 1
    end
    local allowed, reason = TradeRules.CanAddItem(
        InventoryService.Count(profile, slot.ItemId),
        already,
        quantity,
        distinct,
        offer.Items[slot.ItemId] == nil
    )
    if not allowed then
        return false, reason
    end
    offer.Items[slot.ItemId] = already + quantity
    resetApproval(session)
    fireSession(session)
    return true, snapshot(session, player)
end

function TradeService.RemoveItem(player, itemId, quantity)
    local session = sessions[player]
    if not session then
        return false, "not_trading"
    end
    if session.Locked[player] then
        return false, "offer_locked"
    end
    local offer = offerFor(session, player)
    local existing = offer.Items[itemId]
    if not existing or not TradeRules.ValidQuantity(quantity) then
        return false, "item_not_offered"
    end
    local remaining = existing - quantity
    if remaining > 0 then
        offer.Items[itemId] = remaining
    else
        offer.Items[itemId] = nil
    end
    resetApproval(session)
    fireSession(session)
    return true, snapshot(session, player)
end

function TradeService.SetShards(player, amount)
    local session = sessions[player]
    if not session then
        return false, "not_trading"
    end
    if session.Locked[player] then
        return false, "offer_locked"
    end
    local profile = PlayerDataService.Get(player)
    if not profile or not TradeRules.ValidShardAmount(amount, profile.Currencies.Shards) then
        return false, "invalid_shards"
    end
    offerFor(session, player).Shards = amount
    resetApproval(session)
    fireSession(session)
    return true, snapshot(session, player)
end

function TradeService.Lock(player)
    local session = sessions[player]
    if not session then
        return false, "not_trading"
    end
    local profile = PlayerDataService.Get(player)
    local ok, reason = validateOffer(profile, offerFor(session, player))
    if not ok then
        return false, reason
    end
    session.Locked[player] = true
    session.Confirmed[player] = false
    fireSession(session)
    return true, snapshot(session, player)
end

function TradeService.Unlock(player)
    local session = sessions[player]
    if not session then
        return false, "not_trading"
    end
    resetApproval(session)
    fireSession(session)
    return true, snapshot(session, player)
end

function TradeService.Confirm(player)
    local session = sessions[player]
    if not session then
        return false, "not_trading"
    end
    local other = otherPlayer(session, player)
    if not session.Locked[player] or not session.Locked[other] then
        return false, "both_offers_must_be_locked"
    end
    local ok, reason = validateOffer(PlayerDataService.Get(player), offerFor(session, player))
    if not ok then
        resetApproval(session)
        fireSession(session)
        return false, reason
    end
    session.Confirmed[player] = true
    if session.Confirmed[other] ~= true then
        fireSession(session)
        return true, snapshot(session, player)
    end
    local committed, commitReason = executeTrade(session)
    if not committed then
        resetApproval(session)
        fireSession(session)
        return false, commitReason
    end
    endSession(session, "Completed", "trade_complete")
    return true, { Completed = true }
end

function TradeService.Cancel(player)
    clearRequestsFor(player)
    local session = sessions[player]
    if not session then
        return true
    end
    endSession(session, "Cancelled", "cancelled")
    return true
end

function TradeService.Init()
    Players.PlayerRemoving:Connect(function(player)
        clearRequestsFor(player)
        local session = sessions[player]
        if session then
            endSession(session, "Cancelled", "player_left")
        end
    end)
end

return TradeService
