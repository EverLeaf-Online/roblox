local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DerivedStatsMath = require(ReplicatedStorage.Shared.Math.DerivedStatsMath)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local EquipmentService = require(script.Parent.EquipmentService)

local DerivedStatsService = {}

local function totalCoreStat(profile, statName)
    return (tonumber(profile.Stats[statName]) or 0)
        + EquipmentService.GetStatBonus(profile, statName)
end

function DerivedStatsService.Compute(profile)
    return DerivedStatsMath.Compute(
        profile.Level,
        totalCoreStat(profile, "Might"),
        totalCoreStat(profile, "Finesse"),
        totalCoreStat(profile, "Insight"),
        totalCoreStat(profile, "Fortune"),
        GameConfig.DerivedStats,
        {
            Defense = EquipmentService.GetStatBonus(profile, "Defense"),
            CritChance = EquipmentService.GetStatBonus(profile, "CritChance"),
            CritPower = EquipmentService.GetStatBonus(profile, "CritPower"),
        }
    )
end

return DerivedStatsService
