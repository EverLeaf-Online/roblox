local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DerivedStatsMath = require(ReplicatedStorage.Shared.Math.DerivedStatsMath)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local DerivedStatsService = {}

function DerivedStatsService.Compute(profile)
    return DerivedStatsMath.Compute(
        profile.Level,
        profile.Stats.Might,
        profile.Stats.Insight,
        GameConfig.DerivedStats
    )
end

return DerivedStatsService
