local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassFamilyDefinitions = require(script.Parent.Parent.Content.ClassFamilyDefinitions)
local ItemDefinitions = require(script.Parent.Parent.Content.ItemDefinitions)
local AttackCadenceMath = require(ReplicatedStorage.Shared.Math.AttackCadenceMath)
local WeaponCombatProfiles = require(ReplicatedStorage.Shared.WeaponCombatProfiles)
local WeaponCombatRules = require(ReplicatedStorage.Shared.Logic.WeaponCombatRules)
local DamageService = require(script.Parent.DamageService)
local CombatHitboxService = require(script.Parent.CombatHitboxService)
local EnemyService = require(script.Parent.EnemyService)
local EquipmentService = require(script.Parent.EquipmentService)
local MonsterCombat = require(script.Parent.MonsterCombat)
local ProjectileService = require(script.Parent.ProjectileService)
local ResourceService = require(script.Parent.ResourceService)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local SkillBonusService = require(script.Parent.SkillBonusService)
local TargetingService = require(script.Parent.TargetingService)

local CombatService = {}
local lastAttackAt = {}

local function getRoot(model)
    return model and model:FindFirstChild("HumanoidRootPart")
end

local function equippedWeaponType(profile)
    local itemId = profile.Equipment and profile.Equipment.Weapon
    local definition = type(itemId) == "string" and ItemDefinitions[itemId] or nil
    if not definition or definition.EquipmentSlot ~= "Weapon" then
        return nil
    end
    return definition.WeaponType
end

local function basicAttackDefinition(profile)
    local family = type(profile.FamilyId) == "string" and ClassFamilyDefinitions[profile.FamilyId]
        or nil
    local baseAttack = family and family.BasicAttack or {}
    local attackSpeedBonus = EquipmentService.GetStatBonus(profile, "AttackSpeed")
        + SkillBonusService.GetStatBonus(profile, "AttackSpeed")
    local weaponType = equippedWeaponType(profile)
    local resolved = WeaponCombatRules.Resolve(
        baseAttack,
        weaponType,
        weaponType and WeaponCombatProfiles[weaponType] or nil,
        GameConfig.Combat
    )
    resolved.Cooldown, resolved.AttackSpeed = AttackCadenceMath.ResolveCooldown(
        resolved.BaseCooldown,
        attackSpeedBonus,
        GameConfig.Combat
    )
    resolved.PrimaryStat = family and family.PrimaryStat or "Might"
    return resolved
end

function CombatService.BasicAttack(player, profile)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local playerRoot = getRoot(character)
    if not humanoid or humanoid.Health <= 0 or not playerRoot then
        return false, "character_unavailable"
    end

    local attack = basicAttackDefinition(profile)
    local now = os.clock()
    local previous = lastAttackAt[player] or 0
    if now - previous < attack.Cooldown then
        return false, "cooldown"
    end
    -- A swing/shot consumes cadence even when it misses. This prevents clients
    -- from probing the server hitbox at a rate higher than the actual weapon.
    lastAttackAt[player] = now

    local targetSpec = {
        Range = attack.Range,
        VerticalRange = attack.VerticalRange,
        ArcDegrees = attack.ArcDegrees,
        HitboxWidth = attack.HitboxWidth,
        RequireLineOfSight = GameConfig.Combat.RequireLineOfSight,
    }
    local target = if attack.AttackMode == "Melee"
        then CombatHitboxService.FindMeleeTarget(player, targetSpec)
        else TargetingService.FindBestEnemy(player, targetSpec)
    if not target then
        return false, "no_target"
    end

    local targetRoot = getRoot(target) or target.PrimaryPart
    if not targetRoot then
        return false, "target_unavailable"
    end
    if (targetRoot.Position - playerRoot.Position).Magnitude > attack.Range then
        return false, "out_of_range"
    end

    ResourceService.MarkCombat(player, profile)
    local impactPosition = targetRoot.Position
    if attack.AttackMode == "Projectile" then
        local projectileTarget, projectileReason, projectileImpact =
            ProjectileService.TraceToTarget(player, target, {
                Range = attack.Range,
                ProjectileSpeed = attack.ProjectileSpeed,
                ProjectileRadius = attack.ProjectileRadius,
            })
        impactPosition = projectileImpact or impactPosition
        if not projectileTarget then
            return false, projectileReason or "projectile_missed"
        end
        target = projectileTarget
        targetRoot = getRoot(target) or target.PrimaryPart
        if not targetRoot then
            return false, "target_unavailable"
        end
    end

    local damage, damageMeta = DamageService.RollBasicDamage(profile, {
        PrimaryStat = attack.PrimaryStat,
        AttackPower = attack.AttackPower,
        StatScale = attack.StatScale,
        Mastery = attack.Mastery,
    })
    if not damage then
        return false, damageMeta
    end

    local targetHumanoid = EnemyService.GetHumanoid(target)
    local targetDefinition = EnemyService.GetDefinition(target)
    if not targetHumanoid or not targetDefinition then
        return false, "target_unavailable"
    end

    local hitApplied, hitResult = MonsterCombat.ApplyPlayerHit(
        target,
        targetDefinition.MonsterConfig or targetDefinition,
        damage,
        {
            Critical = damageMeta and damageMeta.Critical == true,
            SourcePosition = playerRoot.Position,
            Knockback = attack.Knockback,
            Knockup = attack.Knockup,
            Stagger = attack.Stagger,
        }
    )
    if not hitApplied then
        if hitResult == "dodged" then
            return true,
                {
                    Damage = 0,
                    Dodged = true,
                    TargetHealth = math.max(0, targetHumanoid.Health),
                    TargetPosition = impactPosition,
                }
        end
        return false, hitResult
    end

    EnemyService.RecordDamage(target, player, hitResult)
    return true,
        {
            Damage = hitResult,
            Critical = damageMeta and damageMeta.Critical == true,
            TargetHealth = math.max(0, targetHumanoid.Health),
            TargetPosition = impactPosition,
        }
end

Players.PlayerRemoving:Connect(function(player)
    lastAttackAt[player] = nil
end)

return CombatService
