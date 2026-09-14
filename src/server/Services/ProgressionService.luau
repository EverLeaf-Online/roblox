local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local ProgressionService = {}

function ProgressionService.ExpToNextLevel(level)
    -- Intentionally simple foundation curve for the prototype. Content tuning
    -- can change this without altering the authority model.
    return math.floor(50 + (level ^ 1.6) * 25)
end

function ProgressionService.GrantExp(profile, amount)
    if type(amount) ~= "number" or amount <= 0 then
        return 0
    end

    amount = math.floor(amount)
    local levelsGained = 0
    profile.Exp += amount

    while profile.Level < GameConfig.LevelCap do
        local needed = ProgressionService.ExpToNextLevel(profile.Level)
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
