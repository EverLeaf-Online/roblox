local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DamageMath = require(ReplicatedStorage.Shared.Math.DamageMath)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local DamageService = {}
local random = Random.new()

local validStats = {}
for _, statName in GameConfig.CoreStats do
    validStats[statName] = true
end

function DamageService.RollBasicDamage(profile, definition)
    if type(definition) ~= "table" then
        return nil, "invalid_definition"
    end

    local primaryStat = definition.PrimaryStat
    if not validStats[primaryStat] then
        return nil, "invalid_primary_stat"
    end

    local attackPower = tonumber(definition.AttackPower)
    local statScale = tonumber(definition.StatScale) or 1
    local mastery = tonumber(definition.Mastery) or GameConfig.Combat.DefaultMastery
    if not attackPower or attackPower < 0 or statScale < 0 then
        return nil, "invalid_power"
    end

    mastery =
        math.clamp(mastery, GameConfig.Combat.MinimumMastery, GameConfig.Combat.MaximumMastery)
    local primaryValue = profile.Stats[primaryStat] or 0
    local minimum, maximum =
        DamageMath.CalculateRange(primaryValue, attackPower, statScale, mastery)
    local damage = DamageMath.RollFromUnit(minimum, maximum, random:NextNumber())

    return damage
end

return DamageService
