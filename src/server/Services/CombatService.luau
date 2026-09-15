local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassFamilyDefinitions = require(script.Parent.Parent.Content.ClassFamilyDefinitions)
local DamageService = require(script.Parent.DamageService)
local EnemyService = require(script.Parent.EnemyService)
local MonsterCombat = require(script.Parent.MonsterCombat)
local ResourceService = require(script.Parent.ResourceService)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local TargetingService = require(script.Parent.TargetingService)

local CombatService = {}
local lastAttackAt = {}

local function getRoot(model)
    return model and model:FindFirstChild("HumanoidRootPart")
end

local function basicAttackDefinition(profile)
    local family = type(profile.FamilyId) == "string" and ClassFamilyDefinitions[profile.FamilyId]
        or nil
    local attack = family and family.BasicAttack or nil
    return {
        PrimaryStat = family and family.PrimaryStat or "Might",
        Range = attack and attack.Range or GameConfig.Combat.BasicAttackRange,
        VerticalRange = attack and attack.VerticalRange
            or GameConfig.Combat.BasicAttackVerticalRange,
        ArcDegrees = attack and attack.ArcDegrees or GameConfig.Combat.BasicAttackArcDegrees,
        Cooldown = attack and attack.Cooldown or GameConfig.Combat.BasicAttackCooldown,
        AttackPower = attack and attack.AttackPower or GameConfig.Combat.BeginnerAttackPower,
        StatScale = attack and attack.StatScale or GameConfig.Combat.BeginnerStatScale,
        Mastery = attack and attack.Mastery or GameConfig.Combat.DefaultMastery,
    }
end

function CombatService.BasicAttack(player, profile)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local playerRoot = getRoot(character)
    if not humanoid or humanoid.Health <= 0 or not playerRoot then
        return false, "character_unavailable"
    end

    local attack = basicAttackDefinition(profile)
    local target = TargetingService.FindBestEnemy(player, {
        Range = attack.Range,
        VerticalRange = attack.VerticalRange,
        ArcDegrees = attack.ArcDegrees,
        RequireLineOfSight = GameConfig.Combat.RequireLineOfSight,
    })
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

    local now = os.clock()
    local previous = lastAttackAt[player] or 0
    if now - previous < attack.Cooldown then
        return false, "cooldown"
    end

    lastAttackAt[player] = now
    ResourceService.MarkCombat(player, profile)
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
        { Critical = damageMeta and damageMeta.Critical == true }
    )
    if not hitApplied then
        if hitResult == "dodged" then
            return true,
                {
                    Damage = 0,
                    Dodged = true,
                    TargetHealth = math.max(0, targetHumanoid.Health),
                    TargetPosition = targetRoot.Position,
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
            TargetPosition = targetRoot.Position,
        }
end

Players.PlayerRemoving:Connect(function(player)
    lastAttackAt[player] = nil
end)

return CombatService
