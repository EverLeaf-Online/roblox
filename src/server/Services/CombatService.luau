local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DamageService = require(script.Parent.DamageService)
local EnemyService = require(script.Parent.EnemyService)
local MonsterCombat = require(script.Parent.MonsterCombat)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local TargetingService = require(script.Parent.TargetingService)

local CombatService = {}
local lastAttackAt = {}

local function getRoot(model)
    return model and model:FindFirstChild("HumanoidRootPart")
end

function CombatService.BasicAttack(player, profile)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local playerRoot = getRoot(character)
    if not humanoid or humanoid.Health <= 0 or not playerRoot then
        return false, "character_unavailable"
    end

    local target = TargetingService.FindBestEnemy(player, {
        Range = GameConfig.Combat.BasicAttackRange,
        VerticalRange = GameConfig.Combat.BasicAttackVerticalRange,
        ArcDegrees = GameConfig.Combat.BasicAttackArcDegrees,
        RequireLineOfSight = GameConfig.Combat.RequireLineOfSight,
    })
    if not target then
        return false, "no_target"
    end

    local targetRoot = getRoot(target) or target.PrimaryPart
    if not targetRoot then
        return false, "target_unavailable"
    end
    if
        (targetRoot.Position - playerRoot.Position).Magnitude > GameConfig.Combat.BasicAttackRange
    then
        return false, "out_of_range"
    end

    local now = os.clock()
    local previous = lastAttackAt[player] or 0
    if now - previous < GameConfig.Combat.BasicAttackCooldown then
        return false, "cooldown"
    end

    lastAttackAt[player] = now
    local damage, reason = DamageService.RollBasicDamage(profile, {
        PrimaryStat = "Might",
        AttackPower = GameConfig.Combat.BeginnerAttackPower,
        StatScale = GameConfig.Combat.BeginnerStatScale,
        Mastery = GameConfig.Combat.DefaultMastery,
    })
    if not damage then
        return false, reason
    end

    local targetHumanoid = EnemyService.GetHumanoid(target)
    local targetDefinition = EnemyService.GetDefinition(target)
    if not targetHumanoid or not targetDefinition then
        return false, "target_unavailable"
    end

    local hitApplied, hitResult = MonsterCombat.ApplyPlayerHit(
        target,
        targetDefinition.MonsterConfig or targetDefinition,
        damage
    )
    if not hitApplied then
        if hitResult == "dodged" then
            return true,
                {
                    Damage = 0,
                    Dodged = true,
                    TargetHealth = math.max(0, targetHumanoid.Health),
                }
        end
        return false, hitResult
    end

    EnemyService.RecordDamage(target, player, hitResult)
    return true,
        {
            Damage = hitResult,
            TargetHealth = math.max(0, targetHumanoid.Health),
        }
end

Players.PlayerRemoving:Connect(function(player)
    lastAttackAt[player] = nil
end)

return CombatService
