local DamageService = require(script.Parent.DamageService)
local EnemyService = require(script.Parent.EnemyService)
local MonsterCombat = require(script.Parent.MonsterCombat)
local StatusEffectService = require(script.Parent.StatusEffectService)
local TargetingService = require(script.Parent.TargetingService)

local SkillEffectService = {}

function SkillEffectService.Execute(player, profile, definition)
    local effect = definition.Effect
    if type(effect) ~= "table" then
        return true, { Kind = "NoEffect" }
    end

    if effect.Type == "DamageNearest" then
        local target = TargetingService.FindBestEnemy(player, {
            Range = effect.Range or 10,
            VerticalRange = effect.VerticalRange or 8,
            ArcDegrees = effect.ArcDegrees or 140,
            RequireLineOfSight = effect.RequireLineOfSight ~= false,
        })
        if not target then
            return false, "no_target"
        end
        local damage, damageMeta = DamageService.RollBasicDamage(profile, {
            PrimaryStat = effect.PrimaryStat or "Might",
            AttackPower = effect.AttackPower or 1,
            StatScale = effect.StatScale or 1,
            Mastery = effect.Mastery,
        })
        if not damage then
            return false, damageMeta
        end
        local humanoid = EnemyService.GetHumanoid(target)
        local targetDefinition = EnemyService.GetDefinition(target)
        if not humanoid or not targetDefinition then
            return false, "target_unavailable"
        end
        local hitApplied, hitResult = MonsterCombat.ApplyPlayerHit(
            target,
            targetDefinition.MonsterConfig or targetDefinition,
            damage,
            { Critical = damageMeta and damageMeta.Critical == true }
        )
        if not hitApplied then
            if hitResult == "dodged" then
                return true, { Kind = "Damage", Damage = 0, Dodged = true }
            end
            return false, hitResult
        end
        EnemyService.RecordDamage(target, player, hitResult)
        return true,
            {
                Kind = "Damage",
                Damage = hitResult,
                Critical = damageMeta and damageMeta.Critical == true,
            }
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
