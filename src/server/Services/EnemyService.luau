local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local EnemyDefinitions = require(script.Parent.Parent.Content.EnemyDefinitions)
local AchievementService = require(script.Parent.AchievementService)
local EnemyAIService = require(script.Parent.EnemyAIService)
local MonsterCombat = require(script.Parent.MonsterCombat)
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
        Dead = false,
    }
    states[enemy] = state
    MonsterCombat.Initialize(enemy, definition.MonsterConfig or definition)
    if definition.MonsterConfig and definition.MonsterConfig.DetectionRange > 0 then
        EnemyAIService.Attach(enemy, definition.MonsterConfig)
    end

    humanoid.Died:Connect(function()
        if state.Dead then
            return
        end
        state.Dead = true

        local winner = chooseWinner(state)
        if winner then
            local profile = PlayerDataService.Get(winner)
            if profile then
                local changed = false
                if definition.Reward then
                    local rewarded = RewardService.Grant(profile, definition.Reward)
                    changed = rewarded or changed
                end
                local questChanged = QuestService.Record(profile, "Defeat", enemyId, 1)
                changed = questChanged or changed
                local achievementChanged = AchievementService.Unlock(profile, "first_victory")
                changed = achievementChanged or changed
                if changed then
                    PlayerDataService.NotifyChanged(winner)
                end
            end
        end

        states[enemy] = nil
        EnemyAIService.Detach(enemy)
        MonsterCombat.PlayDeath(enemy)
        CollectionService:RemoveTag(enemy, "EverLeafEnemy")
        if onDeath then
            task.spawn(onDeath, enemy, definition)
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
    state.DamageByPlayer[player] = (state.DamageByPlayer[player] or 0) + damage
    return true
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
