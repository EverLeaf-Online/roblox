local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SkillTargetingRules = require(ReplicatedStorage.Shared.Logic.SkillTargetingRules)
local CombatHitboxService = require(script.Parent.CombatHitboxService)
local TargetingService = require(script.Parent.TargetingService)

local SkillTargetingService = {}

function SkillTargetingService.FindTargets(player, effect)
    local shape = SkillTargetingRules.ResolveShape(effect)
    local maxTargets = SkillTargetingRules.ResolveMaxTargets(effect)
    local range = SkillTargetingRules.ResolveRange(effect)
    local spec = {
        Range = range,
        VerticalRange = effect.VerticalRange or range,
        ArcDegrees = effect.ArcDegrees or 360,
        HitboxWidth = effect.HitboxWidth or 7,
        RequireLineOfSight = effect.RequireLineOfSight ~= false,
        MaxTargets = maxTargets,
    }

    if shape == "Projectile" then
        local target = TargetingService.FindBestEnemy(player, spec)
        return target and { target } or {}
    end
    if shape == "Box" then
        return CombatHitboxService.FindMeleeTargets(player, spec)
    end
    if shape == "Radius" then
        spec.ArcDegrees = 360
        return TargetingService.FindEnemies(player, spec)
    end
    if shape == "Cone" then
        return TargetingService.FindEnemies(player, spec)
    end

    spec.MaxTargets = 1
    local target = CombatHitboxService.FindMeleeTarget(player, spec)
    return target and { target } or {}
end

return SkillTargetingService
