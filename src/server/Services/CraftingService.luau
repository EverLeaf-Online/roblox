local RecipeDefinitions = require(script.Parent.Parent.Content.RecipeDefinitions)
local InventoryService = require(script.Parent.InventoryService)
local CraftingService = {}

function CraftingService.Craft(profile, recipeId, quantity)
    quantity = quantity or 1
    if type(quantity) ~= "number" or quantity % 1 ~= 0 or quantity < 1 or quantity > 99 then
        return false, "invalid_quantity"
    end
    local recipe = RecipeDefinitions[recipeId]
    if not recipe then
        return false, "unknown_recipe"
    end
    for itemId, amount in recipe.Inputs do
        if InventoryService.Count(profile, itemId) < amount * quantity then
            return false, "missing_ingredients"
        end
    end
    local outputQuantity = recipe.Output.Quantity * quantity
    if not InventoryService.CanAdd(profile, recipe.Output.ItemId, outputQuantity) then
        return false, "inventory_full"
    end
    for itemId, amount in recipe.Inputs do
        InventoryService.Remove(profile, itemId, amount * quantity)
    end
    return InventoryService.Add(profile, recipe.Output.ItemId, outputQuantity)
end

return CraftingService
