local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileTransaction = require(ReplicatedStorage.Shared.Logic.ProfileTransaction)
local ShopDefinitions = require(script.Parent.Parent.Content.ShopDefinitions)
local CurrencyService = require(script.Parent.CurrencyService)
local InteractionSessionService = require(script.Parent.InteractionSessionService)
local InventoryService = require(script.Parent.InventoryService)

local ShopService = {}

function ShopService.Buy(player, profile, shopId, itemId, quantity)
    quantity = quantity or 1
    if not InteractionSessionService.ValidateShop(player, shopId) then
        return false, "shop_session_required"
    end
    if type(quantity) ~= "number" or quantity % 1 ~= 0 or quantity < 1 or quantity > 99 then
        return false, "invalid_quantity"
    end
    local shop = ShopDefinitions[shopId]
    local unitPrice = shop and shop.Items[itemId]
    if not shop or not unitPrice then
        return false, "item_not_sold_here"
    end

    return ProfileTransaction.Run(profile, function(workingProfile)
        if not InventoryService.CanAdd(workingProfile, itemId, quantity) then
            return false, "inventory_full"
        end
        local total = unitPrice * quantity
        local spent, reason = CurrencyService.Spend(workingProfile, shop.Currency, total)
        if not spent then
            return false, reason
        end
        local added, addReason = InventoryService.Add(workingProfile, itemId, quantity)
        if not added then
            return false, addReason
        end
        return true, { ItemId = itemId, Quantity = quantity, Total = total }
    end)
end

function ShopService.Sell(player, profile, shopId, itemId, quantity)
    quantity = quantity or 1
    if not InteractionSessionService.ValidateShop(player, shopId) then
        return false, "shop_session_required"
    end
    if type(quantity) ~= "number" or quantity % 1 ~= 0 or quantity < 1 or quantity > 99 then
        return false, "invalid_quantity"
    end
    local definition = InventoryService.GetDefinition(itemId)
    local price = definition and definition.SellPrice
    if not price then
        return false, "item_not_sellable"
    end

    return ProfileTransaction.Run(profile, function(workingProfile)
        local removed, reason = InventoryService.Remove(workingProfile, itemId, quantity)
        if not removed then
            return false, reason
        end
        local added, addReason =
            CurrencyService.Add(workingProfile, price.Currency, price.Amount * quantity)
        if not added then
            return false, addReason
        end
        return true, { ItemId = itemId, Quantity = quantity, Total = price.Amount * quantity }
    end)
end

return ShopService
