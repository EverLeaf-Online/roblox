local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local EnemyDefinitions = require(script.Parent.Parent.Content.EnemyDefinitions)
local EnemyService = require(script.Parent.EnemyService)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local EnemySpawnerService = {}

local function makePart(name, size, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Anchored = true
    part.CanCollide = true
    return part
end

local function makeTrainingDummy(position)
    local model = Instance.new("Model")
    model.Name = "TrainingDummy"

    local root = makePart("HumanoidRootPart", Vector3.new(2, 3, 1.5), Color3.fromRGB(126, 92, 66))
    root.Transparency = 1
    root.CanCollide = false
    root.CFrame = CFrame.new(position)
    root.Parent = model

    local body = makePart("Body", Vector3.new(2.5, 4, 1.5), Color3.fromRGB(169, 120, 79))
    body.CFrame = CFrame.new(position + Vector3.new(0, 0.5, 0))
    body.Parent = model

    local humanoid = Instance.new("Humanoid")
    humanoid.DisplayName = "Training Dummy"
    humanoid.RequiresNeck = false
    humanoid.Parent = model

    model.PrimaryPart = root
    model.Parent = Workspace
    return model
end

local function spawnStudioDummy(position)
    local definition = EnemyDefinitions.training_dummy
    if not definition then
        return
    end

    local enemy = makeTrainingDummy(position)
    local ok = EnemyService.Register(enemy, "training_dummy", function(deadEnemy)
        local respawnPosition = deadEnemy:GetPivot().Position
        task.delay(definition.RespawnSeconds, function()
            if deadEnemy.Parent then
                deadEnemy:Destroy()
            end
            spawnStudioDummy(respawnPosition)
        end)
    end)

    if not ok then
        enemy:Destroy()
    end
end

function EnemySpawnerService.Init()
    if RunService:IsStudio() and GameConfig.Development.SpawnTrainingDummyInStudio then
        spawnStudioDummy(Vector3.new(8, 4, GameConfig.Movement.DefaultPlaneZ))
    end
end

return EnemySpawnerService
