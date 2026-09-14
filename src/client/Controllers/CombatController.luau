local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)

local CombatController = {}
local player = Players.LocalPlayer

local function findNearestEnemy()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil
    end

    local nearest = nil
    local nearestDistance = math.huge
    for _, enemy in CollectionService:GetTagged("EverLeafEnemy") do
        if enemy:IsA("Model") then
            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
            if enemyRoot then
                local delta = enemyRoot.Position - root.Position
                local distance = Vector2.new(delta.X, delta.Y).Magnitude
                if
                    distance < nearestDistance
                    and distance <= GameConfig.Combat.BasicAttackRange * 1.25
                then
                    nearest = enemy
                    nearestDistance = distance
                end
            end
        end
    end
    return nearest
end

function CombatController.Start()
    local remotes = ReplicatedStorage:WaitForChild(Net.RemoteFolderName)
    local basicAttack = remotes:WaitForChild(Net.Functions.BasicAttack)

    ContextActionService:BindAction("EverLeafBasicAttack", function(_, inputState)
        if inputState ~= Enum.UserInputState.Begin then
            return Enum.ContextActionResult.Sink
        end

        local target = findNearestEnemy()
        if target then
            task.spawn(function()
                basicAttack:InvokeServer(target)
            end)
        end
        return Enum.ContextActionResult.Sink
    end, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.F, Enum.KeyCode.ButtonR2)

    ContextActionService:SetTitle("EverLeafBasicAttack", "Attack")
    ContextActionService:SetPosition("EverLeafBasicAttack", UDim2.fromScale(0.78, 0.78))
end

return CombatController
