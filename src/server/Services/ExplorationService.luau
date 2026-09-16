local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerDataService = require(script.Parent.PlayerDataService)
local QuestObjectiveService = require(script.Parent.QuestObjectiveService)

local ExplorationService = {}
local triggers = {}
local inside = {}
local accumulator = 0

local function register(trigger)
    if not trigger:IsA("BasePart") or triggers[trigger] then
        return
    end
    local landmarkId = trigger:GetAttribute("LandmarkId")
    if type(landmarkId) ~= "string" or landmarkId == "" then
        return
    end
    triggers[trigger] = true
    trigger.Destroying:Once(function()
        triggers[trigger] = nil
        for _, playerState in inside do
            playerState[trigger] = nil
        end
    end)
end

local function processTrigger(player, trigger)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root then
        return
    end

    local radius = trigger:GetAttribute("TriggerRadius") or 14
    local delta =
        Vector3.new(root.Position.X - trigger.Position.X, 0, root.Position.Z - trigger.Position.Z)
    local isInside = delta.Magnitude <= radius
    local playerState = inside[player]
    if not playerState then
        playerState = {}
        inside[player] = playerState
    end
    local wasInside = playerState[trigger] == true
    playerState[trigger] = isInside

    if isInside and not wasInside then
        local profile = PlayerDataService.Get(player)
        if profile then
            local landmarkId = trigger:GetAttribute("LandmarkId")
            local changed = QuestObjectiveService.Record(profile, "Explore", landmarkId, 1)
            if changed then
                PlayerDataService.NotifyChanged(player)
            end
        end
    end
end

function ExplorationService.Init()
    for _, instance in CollectionService:GetTagged("ExplorationTrigger") do
        register(instance)
    end
    CollectionService:GetInstanceAddedSignal("ExplorationTrigger"):Connect(register)
    CollectionService:GetInstanceRemovedSignal("ExplorationTrigger"):Connect(function(instance)
        triggers[instance] = nil
    end)
    Players.PlayerRemoving:Connect(function(player)
        inside[player] = nil
    end)

    RunService.Heartbeat:Connect(function(deltaTime)
        accumulator += deltaTime
        if accumulator < 0.3 then
            return
        end
        accumulator = 0
        for _, player in Players:GetPlayers() do
            for trigger in triggers do
                if trigger.Parent then
                    processTrigger(player, trigger)
                end
            end
        end
    end)
end

return ExplorationService
