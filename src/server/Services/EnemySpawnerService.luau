local Workspace = game:GetService("Workspace")

local EnemyDefinitions = require(script.Parent.Parent.Content.EnemyDefinitions)
local EnemyService = require(script.Parent.EnemyService)

local EnemySpawnerService = {}

local function makePart(name, size, color, anchored)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Anchored = anchored
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    return part
end

local function makeTrainingDummy(position)
    local model = Instance.new("Model")
    model.Name = "TrainingDummy"

    local root =
        makePart("HumanoidRootPart", Vector3.new(2, 3, 1.5), Color3.fromRGB(126, 92, 66), true)
    root.Transparency = 1
    root.CanCollide = false
    root.CFrame = CFrame.new(position)
    root.Parent = model

    local body = makePart("Body", Vector3.new(2.5, 4, 1.5), Color3.fromRGB(169, 120, 79), true)
    body.Material = Enum.Material.Wood
    body.CFrame = CFrame.new(position + Vector3.new(0, 0.5, 0))
    body.Parent = model

    local humanoid = Instance.new("Humanoid")
    humanoid.DisplayName = "Training Dummy"
    humanoid.RequiresNeck = false
    humanoid.Parent = model

    model.PrimaryPart = root
    return model
end

local function weld(root, part)
    local joint = Instance.new("WeldConstraint")
    joint.Part0 = root
    joint.Part1 = part
    joint.Parent = part
end

local function makeMossling(position)
    local model = Instance.new("Model")
    model.Name = "LumenMossling"

    local root =
        makePart("HumanoidRootPart", Vector3.new(2.4, 2.4, 2.4), Color3.fromRGB(65, 103, 55), false)
    root.Transparency = 1
    root.CanCollide = true
    root.Material = Enum.Material.SmoothPlastic
    root.CFrame = CFrame.new(position)
    root.Parent = model

    local body = makePart("Body", Vector3.new(3.6, 2.7, 3.4), Color3.fromRGB(74, 126, 70), false)
    body.Shape = Enum.PartType.Ball
    body.Material = Enum.Material.Grass
    body.CanCollide = false
    body.Massless = true
    body.CFrame = CFrame.new(position + Vector3.new(0, 0.35, 0))
    body.Parent = model
    weld(root, body)

    local crown = makePart("Head", Vector3.new(2.8, 1.25, 2.8), Color3.fromRGB(101, 154, 78), false)
    crown.Shape = Enum.PartType.Ball
    crown.Material = Enum.Material.Grass
    crown.CanCollide = false
    crown.Massless = true
    crown.CFrame = CFrame.new(position + Vector3.new(0, 1.65, 0))
    crown.Parent = model
    weld(root, crown)

    local eyeLeft =
        makePart("EyeLeft", Vector3.new(0.35, 0.35, 0.25), Color3.fromRGB(176, 255, 218), false)
    eyeLeft.Shape = Enum.PartType.Ball
    eyeLeft.Material = Enum.Material.Neon
    eyeLeft.CanCollide = false
    eyeLeft.Massless = true
    eyeLeft.CFrame = CFrame.new(position + Vector3.new(-0.65, 0.65, -1.5))
    eyeLeft.Parent = model

    local eyeRight =
        makePart("EyeRight", Vector3.new(0.35, 0.35, 0.25), Color3.fromRGB(176, 255, 218), false)
    eyeRight.Shape = Enum.PartType.Ball
    eyeRight.Material = Enum.Material.Neon
    eyeRight.CanCollide = false
    eyeRight.Massless = true
    eyeRight.CFrame = CFrame.new(position + Vector3.new(0.65, 0.65, -1.5))
    eyeRight.Parent = model

    weld(root, eyeLeft)
    weld(root, eyeRight)

    local humanoid = Instance.new("Humanoid")
    humanoid.DisplayName = "Lumen Mossling"
    humanoid.RequiresNeck = false
    humanoid.HipHeight = 1.1
    humanoid.WalkSpeed = 9
    humanoid.AutoRotate = true
    humanoid.Parent = model

    model.PrimaryPart = root
    return model
end

local builders = {
    training_dummy = makeTrainingDummy,
    lumen_mossling = makeMossling,
}

function EnemySpawnerService.Spawn(enemyId, position, parent)
    local definition = EnemyDefinitions[enemyId]
    local builder = builders[enemyId]
    if not definition or not builder then
        return nil, "unknown_enemy"
    end

    local enemy = builder(position)
    enemy.Parent = parent or Workspace

    local root = enemy:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") and not root.Anchored then
        pcall(root.SetNetworkOwner, root, nil)
    end

    local ok, reason = EnemyService.Register(enemy, enemyId, function(deadEnemy, deadDefinition)
        local respawnPosition = deadEnemy:GetPivot().Position
        local respawnParent = deadEnemy.Parent
        task.delay(0.8, function()
            if deadEnemy.Parent then
                deadEnemy:Destroy()
            end
        end)
        task.delay(deadDefinition.RespawnSeconds or 5, function()
            if respawnParent and respawnParent.Parent then
                EnemySpawnerService.Spawn(enemyId, respawnPosition, respawnParent)
            end
        end)
    end)

    if not ok then
        enemy:Destroy()
        return nil, reason
    end

    return enemy
end

function EnemySpawnerService.Init()
    -- World services own placement. This service only owns construction and respawn.
end

return EnemySpawnerService
