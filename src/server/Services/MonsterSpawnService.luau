local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local MonsterConfig = require(script.Parent.Parent.Content.MonsterConfig)
local EnemySpawnerService = require(script.Parent.EnemySpawnerService)

local MonsterSpawnService = {}
local controllers = {}
local accumulator = 0
local rng = Random.new()

local function getConfig(trigger)
    return {
        MonsterType = trigger:GetAttribute("MonsterType") or "Skeleton",
        SpawnAmount = math.max(1, trigger:GetAttribute("SpawnAmount") or 3),
        TriggerRadius = math.max(4, trigger:GetAttribute("TriggerRadius") or 30),
        SpawnRadius = math.max(1, trigger:GetAttribute("SpawnRadius") or 10),
        MaxAliveMonster = math.max(1, trigger:GetAttribute("MaxAliveMonster") or 3),
        SpawnDelay = math.max(0, trigger:GetAttribute("SpawnDelay") or 0.35),
        RespawnTime = math.max(1, trigger:GetAttribute("RespawnTime") or 30),
    }
end

local function anyPlayerInside(trigger, radius)
    for _, player in Players:GetPlayers() do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if humanoid and humanoid.Health > 0 and root then
            local planar = Vector3.new(
                root.Position.X - trigger.Position.X,
                0,
                root.Position.Z - trigger.Position.Z
            )
            if planar.Magnitude <= radius then
                return true, player
            end
        end
    end
    return false, nil
end

local function findGround(trigger, radius, monsterFolder)
    local angle = rng:NextNumber(0, math.pi * 2)
    local distance = math.sqrt(rng:NextNumber()) * radius
    local sample = trigger.Position
        + Vector3.new(math.cos(angle) * distance, 45, math.sin(angle) * distance)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = if monsterFolder
        then { trigger, monsterFolder }
        else { trigger }
    params.IgnoreWater = true
    local hit = Workspace:Raycast(sample, Vector3.new(0, -100, 0), params)
    if hit then
        return hit.Position + Vector3.new(0, 0.2, 0)
    end
    return trigger.Position
end

local function dustBurst(position)
    local anchor = Instance.new("Part")
    anchor.Name = "MonsterSpawnDust"
    anchor.Size = Vector3.new(1, 1, 1)
    anchor.Transparency = 1
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.CFrame = CFrame.new(position)
    anchor.Parent = Workspace

    local dust = Instance.new("ParticleEmitter")
    dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
    dust.Color = ColorSequence.new(Color3.fromRGB(128, 104, 72), Color3.fromRGB(75, 69, 55))
    dust.Lifetime = NumberRange.new(0.45, 0.9)
    dust.Speed = NumberRange.new(7, 14)
    dust.Rate = 0
    dust.SpreadAngle = Vector2.new(180, 65)
    dust.Rotation = NumberRange.new(0, 360)
    dust.RotSpeed = NumberRange.new(-80, 80)
    dust.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.4),
        NumberSequenceKeypoint.new(0.45, 2.4),
        NumberSequenceKeypoint.new(1, 0),
    })
    dust.Parent = anchor
    dust:Emit(22)

    for _ = 1, 5 do
        local debris = Instance.new("Part")
        debris.Size = Vector3.new(0.35, 0.35, 0.35) * rng:NextNumber(0.8, 1.6)
        debris.Color = Color3.fromRGB(91, 76, 55)
        debris.Material = Enum.Material.Ground
        debris.Anchored = false
        debris.CanCollide = false
        debris.CanTouch = false
        debris.CFrame = CFrame.new(
            position + Vector3.new(rng:NextNumber(-1.5, 1.5), 0.4, rng:NextNumber(-1.5, 1.5))
        )
        debris.AssemblyLinearVelocity =
            Vector3.new(rng:NextNumber(-6, 6), rng:NextNumber(7, 13), rng:NextNumber(-6, 6))
        debris.Parent = Workspace
        Debris:AddItem(debris, 1.25)
    end
    Debris:AddItem(anchor, 1.2)
end

local function setState(trigger, controller, state)
    controller.State = state
    trigger:SetAttribute("SpawnState", state)
    trigger:SetAttribute("AliveMonsters", controller.Alive)
end

local function beginCooldown(trigger, controller)
    if controller.State == "Cooldown" then
        return
    end
    controller.CooldownUntil = os.clock() + controller.Config.RespawnTime
    controller.WaitingForExit = true
    setState(trigger, controller, "Cooldown")
end

local function spawnOne(trigger, controller)
    if controller.Alive >= controller.Config.MaxAliveMonster then
        return false
    end
    local monsterId = MonsterConfig.GetId(controller.Config.MonsterType)
    if not monsterId then
        warn(
            string.format(
                "[MonsterSpawnService] Unknown MonsterType %s",
                tostring(controller.Config.MonsterType)
            )
        )
        return false
    end

    local definition = MonsterConfig.Get(monsterId)
    local groundPosition = findGround(trigger, controller.Config.SpawnRadius, controller.Folder)
    local rootGroundPosition = groundPosition + Vector3.new(0, definition.GroundOffset or 2, 0)
    dustBurst(groundPosition)
    local emergeDepth = rng:NextNumber(5, 8)
    local spawnPosition = rootGroundPosition - Vector3.new(0, emergeDepth, 0)
    controller.Alive += 1
    trigger:SetAttribute("AliveMonsters", controller.Alive)

    local monster, reason = EnemySpawnerService.Spawn(monsterId, spawnPosition, controller.Folder, {
        AutoRespawn = false,
        Emerging = true,
        DeathLinger = 2.8,
        OnDeath = function()
            controller.Alive = math.max(0, controller.Alive - 1)
            trigger:SetAttribute("AliveMonsters", controller.Alive)
            if controller.Alive == 0 and controller.State == "Active" then
                beginCooldown(trigger, controller)
            end
        end,
    })
    if not monster then
        controller.Alive = math.max(0, controller.Alive - 1)
        trigger:SetAttribute("AliveMonsters", controller.Alive)
        warn(string.format("[MonsterSpawnService] Spawn failed: %s", tostring(reason)))
        return false
    end

    local root = monster:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        monster:Destroy()
        controller.Alive = math.max(0, controller.Alive - 1)
        return false
    end

    local tween = TweenService:Create(
        root,
        TweenInfo.new(1.05, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { CFrame = CFrame.new(rootGroundPosition) }
    )
    tween:Play()
    tween.Completed:Once(function()
        if monster.Parent then
            EnemySpawnerService.SetEmerging(monster, false)
            dustBurst(groundPosition)
        end
    end)
    return true
end

local function beginWave(trigger, controller)
    if controller.State ~= "Idle" then
        return
    end
    setState(trigger, controller, "Triggered")
    task.spawn(function()
        if not trigger.Parent then
            return
        end
        setState(trigger, controller, "Spawning")
        local amount = math.min(controller.Config.SpawnAmount, controller.Config.MaxAliveMonster)
        for index = 1, amount do
            if not trigger.Parent then
                return
            end
            spawnOne(trigger, controller)
            if controller.Config.SpawnDelay > 0 and index < amount then
                task.wait(controller.Config.SpawnDelay)
            end
        end
        if trigger.Parent then
            setState(trigger, controller, "Active")
            if controller.Alive == 0 then
                beginCooldown(trigger, controller)
            end
        end
    end)
end

function MonsterSpawnService.Register(trigger)
    if controllers[trigger] or not trigger:IsA("BasePart") then
        return
    end
    trigger.Name = "MonsterSpawnTrigger"
    trigger.Anchored = true
    trigger.CanCollide = false
    trigger.CanTouch = false
    trigger.Transparency = 1

    local folder = Instance.new("Folder")
    folder.Name = "SpawnedMonsters_" .. tostring(trigger:GetAttribute("TriggerName") or "Trigger")
    folder.Parent = trigger.Parent

    local controller = {
        Config = getConfig(trigger),
        State = "Idle",
        Alive = 0,
        CooldownUntil = 0,
        WaitingForExit = false,
        Folder = folder,
    }
    controllers[trigger] = controller
    setState(trigger, controller, "Idle")
    trigger.Destroying:Once(function()
        controllers[trigger] = nil
        if folder.Parent then
            folder:Destroy()
        end
    end)
end

function MonsterSpawnService.Init()
    for _, descendant in Workspace:GetDescendants() do
        if descendant:IsA("BasePart") and descendant.Name == "MonsterSpawnTrigger" then
            MonsterSpawnService.Register(descendant)
        end
    end
    CollectionService:GetInstanceAddedSignal("MonsterSpawnTrigger"):Connect(function(instance)
        if instance:IsA("BasePart") then
            MonsterSpawnService.Register(instance)
        end
    end)

    RunService.Heartbeat:Connect(function(deltaTime)
        accumulator += deltaTime
        if accumulator < 0.25 then
            return
        end
        accumulator = 0
        local now = os.clock()
        for trigger, controller in controllers do
            if not trigger.Parent then
                controllers[trigger] = nil
                continue
            end
            controller.Config = getConfig(trigger)
            local inside = anyPlayerInside(trigger, controller.Config.TriggerRadius)
            if controller.State == "Idle" then
                if inside then
                    beginWave(trigger, controller)
                end
            elseif controller.State == "Cooldown" and now >= controller.CooldownUntil then
                if inside then
                    controller.WaitingForExit = true
                elseif controller.WaitingForExit then
                    controller.WaitingForExit = false
                    setState(trigger, controller, "Idle")
                end
            end
        end
    end)
end

return MonsterSpawnService
