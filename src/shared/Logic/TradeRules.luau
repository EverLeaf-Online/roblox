local TradeRules = {}

TradeRules.MaxDistance = 25
TradeRules.MaxOfferTypes = 12
TradeRules.MaxShardOffer = 1_000_000_000
TradeRules.InviteSeconds = 30

function TradeRules.CanRequest(sourceBusy, targetBusy, sameRegion, distance)
    if sourceBusy then
        return false, "source_busy"
    end
    if targetBusy then
        return false, "target_busy"
    end
    if not sameRegion then
        return false, "different_region"
    end
    distance = tonumber(distance)
    if not distance or distance ~= distance or distance > TradeRules.MaxDistance then
        return false, "too_far"
    end
    return true
end

function TradeRules.ValidQuantity(quantity)
    return type(quantity) == "number"
        and quantity % 1 == 0
        and quantity >= 1
        and quantity <= 999_999
end

function TradeRules.ValidShardAmount(amount, balance)
    return type(amount) == "number"
        and amount % 1 == 0
        and amount >= 0
        and amount <= TradeRules.MaxShardOffer
        and amount <= math.max(0, math.floor(tonumber(balance) or 0))
end

function TradeRules.CanAddItem(available, alreadyOffered, quantity, distinctCount, isNewType)
    if not TradeRules.ValidQuantity(quantity) then
        return false, "invalid_quantity"
    end
    available = math.max(0, math.floor(tonumber(available) or 0))
    alreadyOffered = math.max(0, math.floor(tonumber(alreadyOffered) or 0))
    if alreadyOffered + quantity > available then
        return false, "insufficient_quantity"
    end
    if
        isNewType
        and math.max(0, math.floor(tonumber(distinctCount) or 0)) >= TradeRules.MaxOfferTypes
    then
        return false, "offer_full"
    end
    return true
end

return table.freeze(TradeRules)
