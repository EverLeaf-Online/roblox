local DamageService = require(script.Parent.DamageService)
local EnemyService = require(script.Parent.EnemyService)
local MonsterCombat = require(script.Parent.MonsterCombat)
local ProjectileService = require(script.Parent.ProjectileService)
local SkillTargetingService = require(script.Parent.SkillTargetingService)
local StatusEffectService = require(script.Parent.StatusEffectService)

local SkillEffectService = {}

local function targetPosition(target)
    local root = target and (target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart)
    return root and root.Position or nil
end

local function applyDamageTarget(player, profile, effect, target, sourcePosition, impactPosition)
    local humanoid = EnemyService.GetHumanoid(target)
    local targetDefinition = EnemyService.GetDefinition(target)
    if not humanoid or not targetDefinition then
        return nil, "target_unavailable"
    end

    local damage, damageMeta = DamageService.RollBasicDamage(profile, {
        PrimaryStat = effect.PrimaryStat or "Might",
        AttackPower = effect.AttackPower or 1,
        StatScale = effect.StatScale or 1,
        Mastery = effect.Mastery,
    })
    if not damage then
        return nil, damageMeta
    end

    local hitApplied, hitResult = MonsterCombat.ApplyPlayerHit(
        target,
        targetDefinition.MonsterConfig or targetDefinition,
        damage,
        {
            Critical = damageMeta and damageMeta.Critical == true,
            SourcePosition = sourcePosition,
            Knockback = effect.Knockback or 0,
            Knockup = effect.Knockup or 0,
            Stagger = effect.Stagger,
        }
    )
    if not hitApplied then
        if hitResult == "dodged" then
            return {
                Damage = 0,
                Dodged = true,
                Critical = false,
                TargetPosition = impactPosition,
            }
        end
        return nil, hitResult
    end

    EnemyService.RecordDamage(target, player, hitResult)
    return {
        Damage = hitResult,
        Dodged = false,
        Critical = damageMeta and damageMeta.Critical == true,
        TargetPosition = impactPosition,
    }
end

function SkillEffectService.Execute(player, profile, definition)
    local effect = definition.Effect
    if type(effect) ~= "table" then
        return true, { Kind = "NoEffect" }
    end

    if effect.Type == "DamageAttack" then
        local character = player.Character
        local sourceRoot = character and character:FindFirstChild("HumanoidRootPart")
        if not sourceRoot then
            return false, "character_unavailable"
        end

        local targets = SkillTargetingService.FindTargets(player, effect)
        if #targets == 0 then
            return true, { Kind = "Miss", Reason = "no_target" }
        end

        if effect.Mode == "Projectile" then
            local target = targets[1]
            local initialImpact = targetPosition(target)
            local projectileTarget, projectileReason, projectileImpact =
                ProjectileService.TraceToTarget(player, target, {
                    Range = effect.Range or 10,
                    ProjectileSpeed = effect.ProjectileSpeed,
                    ProjectileRadius = effect.ProjectileRadius,
                })
            local impactPosition = projectileImpact or initialImpact
            if not projectileTarget then
                return true,
                    {
                        Kind = "Miss",
                        Reason = projectileReason or "projectile_missed",
                        TargetPosition = impactPosition,
                    }
            end
            local hit, reason = applyDamageTarget(
                player,
                profile,
                effect,
                projectileTarget,
                sourceRoot.Position,
                targetPosition(projectileTarget) or impactPosition
            )
            if not hit then
                return true, { Kind = "Miss", Reason = reason, TargetPosition = impactPosition }
            end
            return true,
                {
                    Kind = "Damage",
                    Damage = hit.Damage,
                    Dodged = hit.Dodged,
                    Critical = hit.Critical,
                    TargetPosition = hit.TargetPosition,
                    HitCount = hit.Damage > 0 and 1 or 0,
                    TargetCount = 1,
                    TotalDamage = hit.Damage,
                    Hits = { hit },
                }
        end

        local hits = {}
        local totalDamage = 0
        local hitCount = 0
        local lastReason = "target_unavailable"
        for _, target in targets do
            local hit, reason = applyDamageTarget(
                player,
                profile,
                effect,
                target,
                sourceRoot.Position,
                targetPosition(target)
            )
            if hit then
                table.insert(hits, hit)
                totalDamage += hit.Damage
                if hit.Damage > 0 then
                    hitCount += 1
                end
            elseif reason then
                lastReason = reason
            end
        end

        if #hits == 0 then
            return true, { Kind = "Miss", Reason = lastReason }
        end
        local primary = hits[1]
        return true,
            {
                Kind = "Damage",
                Damage = primary.Damage,
                Dodged = primary.Dodged,
                Critical = primary.Critical,
                TargetPosition = primary.TargetPosition,
                HitCount = hitCount,
                TargetCount = #targets,
                TotalDamage = totalDamage,
                Hits = hits,
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
