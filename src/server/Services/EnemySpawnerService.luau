local Workspace = game:GetService("Workspace")

local EnemyDefinitions = require(script.Parent.Parent.Content.EnemyDefinitions)
local MonsterConfig = require(script.Parent.Parent.Content.MonsterConfig)
local EnemyAIService = require(script.Parent.EnemyAIService)
local EnemyService = require(script.Parent.EnemyService)
local MonsterTemplateService = require(script.Parent.MonsterTemplateService)
local WorldGroundingService = require(script.Parent.WorldGroundingService)

local EnemySpawnerService = {}

local function resolveEnemyId(enemyIdOrTemplate)
    return MonsterConfig.GetId(enemyIdOrTemplate)
end

function EnemySpawnerService.Spawn(enemyIdOrTemplate, position, parent, options)
    options = options or {}
    local enemyId = resolveEnemyId(enemyIdOrTemplate)
    local definition = enemyId and EnemyDefinitions[enemyId]
    local template = enemyId and MonsterTemplateService.Get(enemyId)
    if not enemyId or not definition or not template then
        return nil, "unknown_enemy"
    end

    local enemy = template:Clone()
    enemy.Name = definition.MonsterConfig.TemplateName
    enemy:SetAttribute("MonsterEmerging", options.Emerging == true)
    enemy:PivotTo(CFrame.new(position))
    enemy.Parent = parent or Workspace
    local hasGroundInclude = type(options.GroundInclude) == "table" and #options.GroundInclude > 0
    if (options.GroundToTerrain == true or hasGroundInclude) and options.Emerging ~= true then
        local grounded, groundReason = WorldGroundingService.GroundModel(enemy, position, {
            Clearance = options.GroundClearance,
            IncludeInstances = options.GroundInclude,
        })
        if not grounded then
            enemy:Destroy()
            return nil, groundReason
        end
    end

    local root = enemy:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        root.Anchored = enemyId == "training_dummy" or options.Emerging == true
        if not root.Anchored then
            pcall(root.SetNetworkOwner, root, nil)
        end
    end

    local ok, reason = EnemyService.Register(
        enemy,
        enemyId,
        function(deadEnemy, deadDefinition, winner, eligibleUserIds)
            local respawnPosition = deadEnemy:GetPivot().Position
            local respawnParent = deadEnemy.Parent

            if options.OnDeath then
                task.spawn(options.OnDeath, deadEnemy, deadDefinition, winner, eligibleUserIds)
            end

            task.delay(options.DeathLinger or 2.6, function()
                if deadEnemy.Parent then
                    deadEnemy:Destroy()
                end
            end)

            if options.AutoRespawn ~= false then
                task.delay(deadDefinition.RespawnSeconds or 5, function()
                    if respawnParent and respawnParent.Parent then
                        EnemySpawnerService.Spawn(enemyId, respawnPosition, respawnParent, options)
                    end
                end)
            end
        end
    )

    if not ok then
        enemy:Destroy()
        return nil, reason
    end

    return enemy
end

function EnemySpawnerService.SetEmerging(enemy, emerging)
    if not enemy or not enemy:IsA("Model") then
        return false
    end
    enemy:SetAttribute("MonsterEmerging", emerging == true)
    local root = enemy:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        root.Anchored = emerging == true
        if not root.Anchored then
            pcall(root.SetNetworkOwner, root, nil)
            EnemyAIService.SetHomePosition(enemy, root.Position)
        end
    end
    return true
end

function EnemySpawnerService.Init()
    MonsterTemplateService.Init()
end

return EnemySpawnerService
