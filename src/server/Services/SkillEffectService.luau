local DamageService = require(script.Parent.DamageService)
local EnemyService = require(script.Parent.EnemyService)
local StatusEffectService = require(script.Parent.StatusEffectService)
local TargetingService = require(script.Parent.TargetingService)

local SkillEffectService = {}

function SkillEffectService.Execute(player, profile, definition)
    local effect = definition.Effect
    if type(effect) ~= "table" then
        return true, { Kind = "NoEffect" }
    end

    if effect.Type == "DamageNearest" then
        local target = TargetingService.FindNearestEnemy(player, {
            Range = effect.Range or 10,
            VerticalRange = effect.VerticalRange or 8,
            DepthRange = effect.DepthRange or 3,
        })
        if not target then
            return false, "no_target"
        end
        local damage, reason = DamageService.RollBasicDamage(profile, {
            PrimaryStat = effect.PrimaryStat or "Might",
            AttackPower = effect.AttackPower or 1,
            StatScale = effect.StatScale or 1,
            Mastery = effect.Mastery,
        })
        if not damage then
            return false, reason
        end
        local humanoid = EnemyService.GetHumanoid(target)
        if not humanoid then
            return false, "target_unavailable"
        end
        EnemyService.RecordDamage(target, player, damage)
        humanoid:TakeDamage(damage)
        return true, { Kind = "Damage", Damage = damage }
    end

    if effect.Type == "SelfStatus" then
        return StatusEffectService.Apply(
            player,
            effect.StatusId,
            effect.Duration or 1,
            effect.Payload
        )
    end

    return false, "unsupported_effect"
end

return SkillEffectService
