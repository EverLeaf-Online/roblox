local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatRewardRules = require(ReplicatedStorage.Shared.Logic.CombatRewardRules)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local EnemyDefinitions = require(script.Parent.Parent.Content.EnemyDefinitions)
local AchievementService = require(script.Parent.AchievementService)
local EnemyAIService = require(script.Parent.EnemyAIService)
local LootDropService = require(script.Parent.LootDropService)
local MonsterCombat = require(script.Parent.MonsterCombat)
local MonsterThreatService = require(script.Parent.MonsterThreatService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local QuestService = require(script.Parent.QuestService)
local RewardService = require(script.Parent.RewardService)

local EnemyService = {}
local states = {}

local function getHumanoid(enemy)
    if typeof(enemy) ~= "Instance" or not enemy:IsA("Model") then
        return nil
    end
    return enemy:FindFirstChildOfClass("Humanoid")
end

local function chooseWinner(state)
    local winner = nil
    local mostDamage = 0
    for player, damage in state.DamageByPlayer do
        if player.Parent == Players and damage > mostDamage then
            winner = player
            mostDamage = damage
        end
    end
    return winner
end

local function buildRewardPlan(state, humanoid)
    local contributors = {}
    local playerByUserId = {}
    for player, damage in state.DamageByPlayer do
        if player.Parent == Players and damage > 0 then
            table.insert(contributors, { UserId = player.UserId, Damage = damage })
            playerByUserId[player.UserId] = player
        end
    end

    local config = state.Definition.MonsterConfig or state.Definition
    local plan = CombatRewardRules.BuildPlan(
        contributors,
        humanoid.MaxHealth,
        config,
        state.Definition.Reward,
        GameConfig.Combat
    )
    return plan, playerByUserId
end

function EnemyService.Register(enemy, enemyId, onDeath)
    local definition = EnemyDefinitions[enemyId]
    local humanoid = getHumanoid(enemy)
    if not definition or not humanoid then
        return false, "invalid_enemy"
    end

    humanoid.MaxHealth = definition.MaxHealth
    humanoid.Health = definition.MaxHealth
    enemy:SetAttribute("EnemyId", enemyId)
    CollectionService:AddTag(enemy, "EverLeafEnemy")

    local state = {
        Definition = definition,
        DamageByPlayer = {},
        TotalCreditedDamage = 0,
        Dead = false,
    }
    states[enemy] = state
    MonsterCombat.Initialize(enemy, definition.MonsterConfig or definition)
    if definition.MonsterConfig and definition.MonsterConfig.DetectionRange > 0 then
        EnemyAIService.Attach(enemy, definition.MonsterConfig)
    end

    enemy.Destroying:Once(function()
        if states[enemy] ~= state then
            return
        end
        states[enemy] = nil
        EnemyAIService.Detach(enemy)
        MonsterThreatService.Clear(enemy)
        CollectionService:RemoveTag(enemy, "EverLeafEnemy")
    end)

    humanoid.Died:Connect(function()
        if state.Dead then
            return
        end
        state.Dead = true

        local winner = chooseWinner(state)
        local rewardPlan, playerByUserId = buildRewardPlan(state, humanoid)
        local lootUsers = {}
        for _, userId in rewardPlan.LootUserIds do
            lootUsers[userId] = true
        end

        for _, contributor in rewardPlan.Eligible do
            local recipient = playerByUserId[contributor.UserId]
            local profile = recipient and PlayerDataService.Get(recipient)
            if recipient and profile then
                local changed = false
                local rewardShare = rewardPlan.RewardByUserId[contributor.UserId]
                if CombatRewardRules.HasReward(rewardShare) then
                    local rewarded = RewardService.Grant(profile, rewardShare)
                    changed = rewarded or changed
                end
                local questChanged = QuestService.Record(profile, "Defeat", enemyId, 1)
                changed = questChanged or changed
                local achievementChanged =
                    AchievementService.UnlockAndAward(recipient, profile, "first_victory")
                local levelChanged = AchievementService.SyncProgression(recipient, profile)
                changed = levelChanged or changed
                changed = achievementChanged or changed
                if changed then
                    PlayerDataService.NotifyChanged(recipient)
                end
                if lootUsers[contributor.UserId] then
                    LootDropService.RollAndSpawn(enemyId, enemy:GetPivot().Position, recipient)
                end
            end
        end

        states[enemy] = nil
        EnemyAIService.Detach(enemy)
        MonsterThreatService.Clear(enemy)
        MonsterCombat.PlayDeath(enemy)
        CollectionService:RemoveTag(enemy, "EverLeafEnemy")
        if onDeath then
            task.spawn(onDeath, enemy, definition, winner)
        end
    end)

    return true
end

function EnemyService.IsValidTarget(enemy)
    local state = states[enemy]
    local humanoid = getHumanoid(enemy)
    return state ~= nil and not state.Dead and humanoid ~= nil and humanoid.Health > 0
end

function EnemyService.RecordDamage(enemy, player, damage)
    local state = states[enemy]
    if not state or state.Dead or type(damage) ~= "number" or damage <= 0 then
        return false
    end
    local humanoid = getHumanoid(enemy)
    local maxHealth = humanoid and humanoid.MaxHealth or state.Definition.MaxHealth or 1
    local credited = CombatRewardRules.CreditDamage(state.TotalCreditedDamage, maxHealth, damage)
    if credited <= 0 then
        return false
    end
    state.TotalCreditedDamage += credited
    state.DamageByPlayer[player] = (state.DamageByPlayer[player] or 0) + credited
    MonsterThreatService.Add(enemy, player, credited)
    return true, credited
end

function EnemyService.GetHumanoid(enemy)
    return getHumanoid(enemy)
end

function EnemyService.GetDefinition(enemy)
    local state = states[enemy]
    return state and state.Definition or nil
end

function EnemyService.GetActiveEnemies()
    local active = {}
    for enemy, state in states do
        local humanoid = getHumanoid(enemy)
        if enemy.Parent and not state.Dead and humanoid and humanoid.Health > 0 then
            table.insert(active, enemy)
        end
    end
    return active
end

return EnemyService
