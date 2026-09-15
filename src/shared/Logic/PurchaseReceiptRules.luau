local PurchaseReceiptRules = {}

local function positiveInteger(value)
    return type(value) == "number" and value == value and value % 1 == 0 and value > 0
end

function PurchaseReceiptRules.ValidateIncoming(receiptInfo, expectedProductId)
    if type(receiptInfo) ~= "table" then
        return false, "invalid_receipt"
    end
    local purchaseId = tostring(receiptInfo.PurchaseId or "")
    if purchaseId == "" or #purchaseId > 128 then
        return false, "invalid_purchase_id"
    end
    if not positiveInteger(receiptInfo.ProductId) or receiptInfo.ProductId ~= expectedProductId then
        return false, "unexpected_product"
    end
    if not positiveInteger(receiptInfo.PlayerId) then
        return false, "invalid_player_id"
    end
    if receiptInfo.CurrencySpent ~= nil then
        if
            type(receiptInfo.CurrencySpent) ~= "number"
            or receiptInfo.CurrencySpent ~= receiptInfo.CurrencySpent
            or receiptInfo.CurrencySpent < 0
            or receiptInfo.CurrencySpent == math.huge
            or receiptInfo.CurrencySpent == -math.huge
        then
            return false, "invalid_currency_spent"
        end
    end
    return true, purchaseId
end

function PurchaseReceiptRules.MatchesStored(existing, receiptInfo)
    if type(existing) ~= "table" or type(receiptInfo) ~= "table" then
        return false
    end
    return tostring(existing.PurchaseId or "") == tostring(receiptInfo.PurchaseId or "")
        and existing.ProductId == receiptInfo.ProductId
        and existing.PlayerId == receiptInfo.PlayerId
end

return table.freeze(PurchaseReceiptRules)
