local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local InventoryRules = require(ReplicatedStorage.Shared.Logic.InventoryRules)
local ProfileTransaction = require(ReplicatedStorage.Shared.Logic.ProfileTransaction)
local ItemDefinitions = require(script.Parent.Parent.Content.ItemDefinitions)

local StorageService = {}

local function ensureInventory(profile)
    profile.Inventory = profile.Inventory or { Capacity = 48, Slots = {} }
    profile.Inventory.Slots = profile.Inventory.Slots or {}
    return profile.Inventory
end

local function ensureStorage(profile)
    profile.Storage = profile.Storage or { Capacity = 96, Slots = {} }
    profile.Storage.Slots = profile.Storage.Slots or {}
    return profile.Storage
end

local function validTransferIndex(index)
    return type(index) == "number" and index % 1 == 0 and index >= 1 and index <= 512
end

local function validQuantity(quantity)
    return type(quantity) == "number" and quantity % 1 == 0 and quantity >= 1 and quantity <= 9999
end

function StorageService.IsEnabled()
    return GameConfig.Features.Storage == true
end

function StorageService.Deposit(profile, inventoryIndex, quantity)
    if not StorageService.IsEnabled() then
        return false, "storage_not_enabled"
    end
    if
        type(profile) ~= "table"
        or not validTransferIndex(inventoryIndex)
        or not validQuantity(quantity)
    then
        return false, "invalid_storage_request"
    end

    return ProfileTransaction.Run(profile, function(workingProfile)
        local inventory = ensureInventory(workingProfile)
        local storage = ensureStorage(workingProfile)
        local slot = inventory.Slots[inventoryIndex]
        if type(slot) ~= "table" then
            return false, "empty_slot"
        end
        local itemId = slot.ItemId
        local definition = ItemDefinitions[itemId]
        if not definition then
            return false, "unknown_item"
        end
        if (tonumber(slot.Quantity) or 0) < quantity then
            return false, "insufficient_quantity"
        end
        local added, addReason = InventoryRules.Add(
            storage.Slots,
            storage.Capacity,
            itemId,
            quantity,
            definition.StackLimit or 1
        )
        if not added then
            return false, addReason == "inventory_full" and "storage_full" or addReason
        end
        local removed, removeReason =
            InventoryRules.RemoveAt(inventory.Slots, inventoryIndex, quantity)
        if not removed then
            return false, removeReason
        end
        return true, { ItemId = itemId, Quantity = quantity }
    end)
end

function StorageService.Withdraw(profile, storageIndex, quantity)
    if not StorageService.IsEnabled() then
        return false, "storage_not_enabled"
    end
    if
        type(profile) ~= "table"
        or not validTransferIndex(storageIndex)
        or not validQuantity(quantity)
    then
        return false, "invalid_storage_request"
    end

    return ProfileTransaction.Run(profile, function(workingProfile)
        local inventory = ensureInventory(workingProfile)
        local storage = ensureStorage(workingProfile)
        local slot = storage.Slots[storageIndex]
        if type(slot) ~= "table" then
            return false, "empty_slot"
        end
        local itemId = slot.ItemId
        local definition = ItemDefinitions[itemId]
        if not definition then
            return false, "unknown_item"
        end
        if (tonumber(slot.Quantity) or 0) < quantity then
            return false, "insufficient_quantity"
        end
        local added, addReason = InventoryRules.Add(
            inventory.Slots,
            inventory.Capacity,
            itemId,
            quantity,
            definition.StackLimit or 1
        )
        if not added then
            return false, addReason
        end
        local removed, removeReason = InventoryRules.RemoveAt(storage.Slots, storageIndex, quantity)
        if not removed then
            return false, removeReason
        end
        return true, { ItemId = itemId, Quantity = quantity }
    end)
end

function StorageService.Count(profile, itemId)
    if type(profile) ~= "table" or type(itemId) ~= "string" then
        return 0
    end
    return InventoryRules.Count(ensureStorage(profile).Slots, itemId)
end

return StorageService
