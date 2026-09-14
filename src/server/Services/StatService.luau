local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local StatService = {}

local allowedStats = {}
for _, statName in GameConfig.CoreStats do
    allowedStats[statName] = true
end

function StatService.Allocate(profile, statName, amount)
    if not allowedStats[statName] then
        return false, "invalid_stat"
    end
    if type(amount) ~= "number" or amount % 1 ~= 0 or amount < 1 then
        return false, "invalid_amount"
    end
    if amount > profile.AP then
        return false, "insufficient_ap"
    end

    profile.AP -= amount
    profile.Stats[statName] += amount
    return true
end

return StatService
