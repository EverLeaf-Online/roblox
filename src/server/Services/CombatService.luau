local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DamageService = require(script.Parent.DamageService)
local EnemyService = require(script.Parent.EnemyService)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local CombatService = {}
local lastAttackAt = {}

local function getRoot(model)
    return model and model:FindFirstChild("HumanoidRootPart")
end

function CombatService.BasicAttack(player, profile, target)
    if typeof(target) ~= "Instance" or not target:IsA("Model") then
        return false, "invalid_target"
    end
    if not EnemyService.IsValidTarget(target) then
        return false, "target_unavailable"
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local playerRoot = getRoot(character)
    local targetRoot = getRoot(target) or target.PrimaryPart
    if not humanoid or humanoid.Health <= 0 or not playerRoot or not targetRoot then
        return false, "character_unavailable"
    end

    local now = os.clock()
    local previous = lastAttackAt[player] or 0
    if now - previous < GameConfig.Combat.BasicAttackCooldown then
        return false, "cooldown"
    end

    local delta = targetRoot.Position - playerRoot.Position
    local planarDistance = Vector2.new(delta.X, delta.Y).Magnitude
    if planarDistance > GameConfig.Combat.BasicAttackRange then
        return false, "out_of_range"
    end
    if math.abs(delta.Z) > GameConfig.Combat.BasicAttackDepthRange then
        return false, "out_of_depth"
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
    if not targetHumanoid then
        return false, "target_unavailable"
    end

    EnemyService.RecordDamage(target, player, damage)
    targetHumanoid:TakeDamage(damage)
    return true,
        {
            Damage = damage,
            TargetHealth = math.max(0, targetHumanoid.Health),
        }
end

Players.PlayerRemoving:Connect(function(player)
    lastAttackAt[player] = nil
end)

return CombatService
