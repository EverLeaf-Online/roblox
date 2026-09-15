local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SkillBonusMath = require(ReplicatedStorage.Shared.Math.SkillBonusMath)
local SkillDefinitions = require(script.Parent.Parent.Content.SkillDefinitions)

local SkillBonusService = {}

function SkillBonusService.GetStatBonus(profile, statName)
    local learned = type(profile) == "table" and profile.Skills and profile.Skills.Learned or {}
    return SkillBonusMath.Compute(learned, SkillDefinitions, statName)
end

return SkillBonusService
