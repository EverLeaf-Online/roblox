local CombatHitboxService = require(script.Parent.CombatHitboxService)
local DamageService = require(script.Parent.DamageService)
local EnemyService = require(script.Parent.EnemyService)
local MonsterCombat = require(script.Parent.MonsterCombat)
local ProjectileService = require(script.Parent.ProjectileService)
local StatusEffectService = require(script.Parent.StatusEffectService)
local TargetingService = require(script.Parent.TargetingService)

local SkillEffectService = {}

function SkillEffectService.Execute(player, profile, definition)
    local effect = definition.Effect
    if type(effect) ~= "table" then
        return true, { Kind = "NoEffect" }
    end

    if effect.Type == "DamageAttack" then
        local mode = effect.Mode or "Melee"
        local targetSpec = {
            Range = effect.Range or 10,
            VerticalRange = effect.VerticalRange or 8,
            ArcDegrees = effect.ArcDegrees or 140,
            HitboxWidth = effect.HitboxWidth or 7,
            RequireLineOfSight = effect.RequireLineOfSight ~= false,
        }

        local target = if mode == "Melee"
            then CombatHitboxService.FindMeleeTarget(player, targetSpec)
            else TargetingService.FindBestEnemy(player, targetSpec)
        if not target then
            return true, { Kind = "Miss", Reason = "no_target" }
        end

        local targetRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
        local impactPosition = targetRoot and targetRoot.Position or nil
        if mode == "Projectile" then
            local projectileTarget, projectileReason, projectileImpact =
                ProjectileService.TraceToTarget(player, target, {
                    Range = effect.Range or 10,
                    ProjectileSpeed = effect.ProjectileSpeed,
                    ProjectileRadius = effect.ProjectileRadius,
                })
            impactPosition = projectileImpact or impactPosition
            if not projectileTarget then
                return true,
                    {
                        Kind = "Miss",
                        Reason = projectileReason or "projectile_missed",
                        TargetPosition = impactPosition,
                    }
            end
            target = projectileTarget
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
            return true,
                { Kind = "Miss", Reason = "target_unavailable", TargetPosition = impactPosition }
        end
        local hitApplied, hitResult = MonsterCombat.ApplyPlayerHit(
            target,
            targetDefinition.MonsterConfig or targetDefinition,
            damage,
            { Critical = damageMeta and damageMeta.Critical == true }
        )
        if not hitApplied then
            if hitResult == "dodged" then
                return true,
                    {
                        Kind = "Damage",
                        Damage = 0,
                        Dodged = true,
                        TargetPosition = impactPosition,
                    }
            end
            return true, { Kind = "Miss", Reason = hitResult, TargetPosition = impactPosition }
        end
        EnemyService.RecordDamage(target, player, hitResult)
        return true,
            {
                Kind = "Damage",
                Damage = hitResult,
                Critical = damageMeta and damageMeta.Critical == true,
                TargetPosition = impactPosition,
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
