local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileTransaction = require(ReplicatedStorage.Shared.Logic.ProfileTransaction)
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

    return ProfileTransaction.Run(profile, function(workingProfile)
        for itemId, amount in recipe.Inputs do
            if InventoryService.Count(workingProfile, itemId) < amount * quantity then
                return false, "missing_ingredients"
            end
        end

        -- Consume on the transaction copy before testing output capacity. This
        -- correctly allows recipes whose ingredients free the slot needed by
        -- the crafted result while remaining rollback-safe on any failure.
        for itemId, amount in recipe.Inputs do
            local removed, removeReason =
                InventoryService.Remove(workingProfile, itemId, amount * quantity)
            if not removed then
                return false, removeReason
            end
        end

        local outputQuantity = recipe.Output.Quantity * quantity
        local added, addReason =
            InventoryService.Add(workingProfile, recipe.Output.ItemId, outputQuantity)
        if not added then
            return false, addReason
        end
        return true,
            {
                ItemId = recipe.Output.ItemId,
                Quantity = outputQuantity,
            }
    end)
end

return CraftingService
