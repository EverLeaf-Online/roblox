local CollectionService = game:GetService("CollectionService")
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

local function findNearestTarget(playerRoot)
    local nearest = nil
    local nearestDistance = math.huge

    for _, candidate in CollectionService:GetTagged("EverLeafEnemy") do
        if candidate:IsA("Model") and EnemyService.IsValidTarget(candidate) then
            local targetRoot = getRoot(candidate) or candidate.PrimaryPart
            if targetRoot then
                local delta = targetRoot.Position - playerRoot.Position
                local horizontalDistance = math.abs(delta.X)
                local verticalDistance = math.abs(delta.Y)
                local depthDistance = math.abs(delta.Z)
                if
                    horizontalDistance <= GameConfig.Combat.BasicAttackRange
                    and verticalDistance <= GameConfig.Combat.BasicAttackVerticalRange
                    and depthDistance <= GameConfig.Combat.BasicAttackDepthRange
                    and horizontalDistance < nearestDistance
                then
                    nearest = candidate
                    nearestDistance = horizontalDistance
                end
            end
        end
    end

    return nearest
end

function CombatService.BasicAttack(player, profile)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local playerRoot = getRoot(character)
    if not humanoid or humanoid.Health <= 0 or not playerRoot then
        return false, "character_unavailable"
    end

    local target = findNearestTarget(playerRoot)
    if not target then
        return false, "no_target"
    end

    local targetRoot = getRoot(target) or target.PrimaryPart
    if not targetRoot then
        return false, "target_unavailable"
    end

    local now = os.clock()
    local previous = lastAttackAt[player] or 0
    if now - previous < GameConfig.Combat.BasicAttackCooldown then
        return false, "cooldown"
    end

    local delta = targetRoot.Position - playerRoot.Position
    if math.abs(delta.X) > GameConfig.Combat.BasicAttackRange then
        return false, "out_of_range"
    end
    if math.abs(delta.Y) > GameConfig.Combat.BasicAttackVerticalRange then
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
