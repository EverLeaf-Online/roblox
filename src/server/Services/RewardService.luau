local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileTransaction = require(ReplicatedStorage.Shared.Logic.ProfileTransaction)
local RewardRules = require(ReplicatedStorage.Shared.Logic.RewardRules)
local CurrencyService = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)
local RegionService = require(script.Parent.RegionService)

local RewardService = {}

function RewardService.Apply(profile, reward)
    local valid, validationReason = RewardRules.Validate(reward)
    if not valid then
        return false, validationReason
    end

    local result = { LevelsGained = 0, Currencies = {}, Items = {}, UnlockedRegions = {} }

    if reward.Exp then
        result.LevelsGained = ProgressionService.GrantExp(profile, reward.Exp)
    end
    if reward.Currencies then
        for currencyName, amount in reward.Currencies do
            local ok, balanceOrReason = CurrencyService.Add(profile, currencyName, amount)
            if not ok then
                return false, balanceOrReason
            end
            result.Currencies[currencyName] = balanceOrReason
        end
    end
    if reward.Items then
        for itemId, quantity in reward.Items do
            local ok, reason = InventoryService.Add(profile, itemId, quantity)
            if not ok then
                return false, reason
            end
            result.Items[itemId] = quantity
        end
    end
    if reward.UnlockRegions then
        for _, regionId in reward.UnlockRegions do
            local ok, reason = RegionService.Unlock(profile, regionId)
            if not ok then
                return false, reason
            end
            result.UnlockedRegions[regionId] = true
        end
    end
    return true, result
end

function RewardService.Grant(profile, reward)
    return ProfileTransaction.Run(profile, function(workingProfile)
        return RewardService.Apply(workingProfile, reward)
    end)
end

return RewardService
