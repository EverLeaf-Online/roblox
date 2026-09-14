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
    if not InventoryService.CanAdd(profile, itemId, quantity) then
        return false, "inventory_full"
    end
    local total = unitPrice * quantity
    local spent, reason = CurrencyService.Spend(profile, shop.Currency, total)
    if not spent then
        return false, reason
    end
    local added, addReason = InventoryService.Add(profile, itemId, quantity)
    if not added then
        CurrencyService.Add(profile, shop.Currency, total)
        return false, addReason
    end
    return true
end

function ShopService.Sell(player, profile, shopId, itemId, quantity)
    quantity = quantity or 1
    if not InteractionSessionService.ValidateShop(player, shopId) then
        return false, "shop_session_required"
    end
    local definition = InventoryService.GetDefinition(itemId)
    local price = definition and definition.SellPrice
    if not price then
        return false, "item_not_sellable"
    end
    local removed, reason = InventoryService.Remove(profile, itemId, quantity)
    if not removed then
        return false, reason
    end
    CurrencyService.Add(profile, price.Currency, price.Amount * quantity)
    return true
end

return ShopService
