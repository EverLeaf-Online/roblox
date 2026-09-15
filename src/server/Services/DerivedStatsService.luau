local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DerivedStatsMath = require(ReplicatedStorage.Shared.Math.DerivedStatsMath)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local EquipmentService = require(script.Parent.EquipmentService)
local SkillBonusService = require(script.Parent.SkillBonusService)

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
            MaxHP = SkillBonusService.GetStatBonus(profile, "MaxHP"),
            MaxMP = SkillBonusService.GetStatBonus(profile, "MaxMP"),
            Defense = EquipmentService.GetStatBonus(profile, "Defense")
                + SkillBonusService.GetStatBonus(profile, "Defense"),
            CritChance = EquipmentService.GetStatBonus(profile, "CritChance")
                + SkillBonusService.GetStatBonus(profile, "CritChance"),
            CritPower = EquipmentService.GetStatBonus(profile, "CritPower")
                + SkillBonusService.GetStatBonus(profile, "CritPower"),
        }
    )
end

return DerivedStatsService
