local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ProgressionMath = require(ReplicatedStorage.Shared.Math.ProgressionMath)

local ProgressionService = {}

ProgressionService.ExpToNextLevel = ProgressionMath.ExpToNextLevel

function ProgressionService.GrantExp(profile, amount)
    if type(amount) ~= "number" or amount <= 0 then
        return 0
    end

    amount = math.floor(amount)
    local levelsGained = 0
    profile.Exp += amount

    while profile.Level < GameConfig.LevelCap do
        local needed = ProgressionMath.ExpToNextLevel(profile.Level)
        if profile.Exp < needed then
            break
        end

        profile.Exp -= needed
        profile.Level += 1
        profile.AP += GameConfig.Progression.APPerLevel
        if profile.AdvancementTier >= 1 then
            profile.SP += GameConfig.Progression.SPPerLevelAfterFirstAdvancement
        end
        levelsGained += 1
    end

    if profile.Level >= GameConfig.LevelCap then
        profile.Level = GameConfig.LevelCap
        profile.Exp = 0
    end

    return levelsGained
end

function ProgressionService.CanFirstAdvance(profile)
    if profile.AdvancementTier ~= 0 then
        return false
    end

    for _, level in GameConfig.Progression.FirstAdvancementLevels do
        if profile.Level >= level then
            return true
        end
    end

    return false
end

return ProgressionService
