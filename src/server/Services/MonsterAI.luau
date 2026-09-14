local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MonsterCombat = require(script.Parent.MonsterCombat)

local MonsterAI = {}
local controllers = {}
local accumulator = 0

local function nearestPlayer(root, range)
    local winner = nil
    local best = range
    for _, player in Players:GetPlayers() do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
        if humanoid and humanoid.Health > 0 and playerRoot then
            local distance = (playerRoot.Position - root.Position).Magnitude
            if distance <= best then
                winner = player
                best = distance
            end
        end
    end
    return winner, best
end

local function setState(monster, controller, nextState)
    if controller.State == nextState then
        return
    end
    controller.State = nextState
    monster:SetAttribute("MonsterAIState", nextState)
end

local function face(root, position)
    local flat = Vector3.new(position.X, root.Position.Y, position.Z)
    if (flat - root.Position).Magnitude > 0.05 then
        root.CFrame = CFrame.lookAt(root.Position, flat)
    end
end

local function animateVisual(monster, controller, now)
    local state = controller.State
    local monsterId = monster:GetAttribute("EnemyId")
    local moving = state == "Pursue" or state == "Returning"
    local speed = if moving then 8 else 2.3
    if monsterId == "peco_peco" and moving then
        speed = 12
    elseif monsterId == "slime" and moving then
        speed = 6
    end

    local phase = now * speed
    local swing = math.sin(phase)
    local amount = if moving then math.rad(24) else math.rad(3)
    if monsterId == "peco_peco" and moving then
        amount = math.rad(34)
    end

    for _, jointName in { "LeftHip", "RightShoulder" } do
        local joint = monster:FindFirstChild(jointName, true)
        if joint and joint:IsA("Motor6D") then
            joint.Transform = CFrame.Angles(swing * amount, 0, 0)
        end
    end
    for _, jointName in { "RightHip", "LeftShoulder" } do
        local joint = monster:FindFirstChild(jointName, true)
        if joint and joint:IsA("Motor6D") then
            joint.Transform = CFrame.Angles(-swing * amount, 0, 0)
        end
    end

    local bodyJoint = monster:FindFirstChild("BodyJoint", true)
    if bodyJoint and bodyJoint:IsA("Motor6D") then
        local bounce = if moving then math.abs(math.sin(phase)) * 0.24 else math.sin(phase) * 0.05
        if monsterId == "slime" then
            bounce = if moving then math.abs(math.sin(phase)) * 0.5 else math.sin(phase) * 0.12
        end
        bodyJoint.Transform = CFrame.new(0, bounce, 0)
            * CFrame.Angles(if moving then math.rad(-3) * math.sin(phase) else 0, 0, 0)
    end

    if monsterId == "slime" then
        local body = monster:FindFirstChild("Body")
        local belly = monster:FindFirstChild("BellyGlow")
        local squish = math.sin(phase) * (if moving then 0.1 else 0.04)
        if body and body:IsA("BasePart") then
            body.Size = Vector3.new(4.6 * (1 + squish), 3.1 * (1 - squish), 4.4 * (1 + squish))
        end
        if belly and belly:IsA("BasePart") then
            belly.Size = Vector3.new(3.1 * (1 + squish), 1.3 * (1 - squish), 3.0 * (1 + squish))
        end
    elseif monsterId == "peco_peco" then
        local tail = monster:FindFirstChild("TailJoint", true)
        if tail and tail:IsA("Motor6D") then
            tail.Transform =
                CFrame.Angles(math.rad(8) * math.sin(phase * 0.7), math.rad(6) * swing, 0)
        end
    end

    if state == "Attack" then
        if monsterId == "skeleton" then
            local shoulder = monster:FindFirstChild("RightShoulder", true)
            if shoulder and shoulder:IsA("Motor6D") then
                shoulder.Transform = CFrame.Angles(math.rad(-72), 0, math.rad(16))
            end
        elseif monsterId == "slime" and bodyJoint and bodyJoint:IsA("Motor6D") then
            bodyJoint.Transform = CFrame.new(0, -0.25, 0) * CFrame.Angles(math.rad(8), 0, 0)
        elseif monsterId == "peco_peco" then
            local headJoint = monster:FindFirstChild("HeadJoint", true)
            if headJoint and headJoint:IsA("Motor6D") then
                headJoint.Transform = CFrame.new(0, -0.2, -0.55) * CFrame.Angles(math.rad(18), 0, 0)
            end
        end
    elseif state == "Dodge" and monsterId == "skeleton" then
        if bodyJoint and bodyJoint:IsA("Motor6D") then
            bodyJoint.Transform = CFrame.Angles(0, 0, math.rad(55) * math.sin(now * 24))
        end
    end
end

local function computePath(controller, root, destination)
    local path = PathfindingService:CreatePath({
        AgentRadius = controller.AgentRadius or 2,
        AgentHeight = controller.AgentHeight or 5,
        AgentCanJump = true,
        WaypointSpacing = 5,
    })
    local ok = pcall(path.ComputeAsync, path, root.Position, destination)
    if not ok or path.Status ~= Enum.PathStatus.Success then
        controller.Waypoints = nil
        controller.WaypointIndex = 0
        return
    end
    controller.Waypoints = path:GetWaypoints()
    controller.WaypointIndex = math.min(2, #controller.Waypoints)
end

local function moveWithPath(controller, humanoid, root, destination, now)
    if now >= controller.NextPathAt then
        controller.NextPathAt = now + 0.75
        computePath(controller, root, destination)
    end

    local waypoints = controller.Waypoints
    local index = controller.WaypointIndex
    local waypoint = waypoints and waypoints[index]
    if waypoint then
        if (waypoint.Position - root.Position).Magnitude <= 3 then
            controller.WaypointIndex += 1
            waypoint = waypoints[controller.WaypointIndex]
        end
        if waypoint then
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            humanoid:MoveTo(waypoint.Position)
            return
        end
    end
    humanoid:MoveTo(destination)
end

local function beginAttack(monster, controller, target, targetRoot, now)
    if now < controller.NextAttackAt then
        return
    end
    controller.NextAttackAt = now + (controller.Definition.AttackCooldown or 1.5)
    controller.AttackToken += 1
    local token = controller.AttackToken
    setState(monster, controller, "Attack")
    face(controller.Root, targetRoot.Position)
    controller.Humanoid:Move(Vector3.zero, false)

    local monsterId = controller.Definition.Id
    local rightShoulder = monster:FindFirstChild("RightShoulder", true)
    if monsterId == "skeleton" and rightShoulder and rightShoulder:IsA("Motor6D") then
        rightShoulder.Transform = CFrame.Angles(math.rad(-65), 0, math.rad(12))
    elseif monsterId == "slime" then
        local direction = targetRoot.Position - controller.Root.Position
        local planar = Vector3.new(direction.X, 0, direction.Z)
        if planar.Magnitude > 0.05 then
            planar = planar.Unit
            controller.Root.AssemblyLinearVelocity = Vector3.new(planar.X * 9, 15, planar.Z * 9)
        end
    elseif monsterId == "peco_peco" then
        local direction = targetRoot.Position - controller.Root.Position
        local planar = Vector3.new(direction.X, 0, direction.Z)
        if planar.Magnitude > 0.05 then
            planar = planar.Unit
            controller.Root.AssemblyLinearVelocity = Vector3.new(planar.X * 17, 5, planar.Z * 17)
        end
    end

    local attackWindup = controller.Definition.AttackWindup or 0.4
    task.delay(attackWindup, function()
        if not monster.Parent or controller.AttackToken ~= token then
            return
        end
        if
            monster:GetAttribute("MonsterReaction") ~= ""
            or monster:GetAttribute("MonsterEmerging") == true
        then
            return
        end
        local character = target.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local currentRoot = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or humanoid.Health <= 0 or not currentRoot then
            return
        end
        if
            (currentRoot.Position - controller.Root.Position).Magnitude
            <= (controller.Definition.AttackRange or 5) + 1
        then
            MonsterCombat.DamagePlayer(monster, target, controller.Definition)
        end
    end)
end

function MonsterAI.Attach(monster, definition)
    local root = monster:FindFirstChild("HumanoidRootPart")
    local humanoid = monster:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or type(definition) ~= "table" then
        return false, "invalid_monster"
    end

    humanoid.WalkSpeed = definition.WalkSpeed or 10
    humanoid.AutoRotate = false
    local controller = {
        Definition = definition,
        Root = root,
        Humanoid = humanoid,
        SpawnPosition = root.Position,
        Target = nil,
        State = "Idle",
        NextAttackAt = 0,
        NextPathAt = 0,
        Waypoints = nil,
        WaypointIndex = 0,
        AttackToken = 0,
        AgentRadius = monster:GetAttribute("AgentRadius") or 2,
        AgentHeight = monster:GetAttribute("AgentHeight") or 5,
    }
    controllers[monster] = controller
    monster:SetAttribute("MonsterAIState", "Idle")
    monster.Destroying:Once(function()
        controllers[monster] = nil
    end)
    return true
end

function MonsterAI.Detach(monster)
    local controller = controllers[monster]
    if controller then
        controller.AttackToken += 1
    end
    controllers[monster] = nil
end

function MonsterAI.GetState(monster)
    local controller = controllers[monster]
    return controller and controller.State or nil
end

function MonsterAI.SetHomePosition(monster, position)
    local controller = controllers[monster]
    if not controller or typeof(position) ~= "Vector3" then
        return false
    end
    controller.SpawnPosition = position
    controller.Waypoints = nil
    controller.WaypointIndex = 0
    return true
end

function MonsterAI.Init()
    RunService.Heartbeat:Connect(function(deltaTime)
        accumulator += deltaTime
        if accumulator < 0.12 then
            return
        end
        accumulator = 0
        local now = os.clock()

        for monster, controller in controllers do
            local root = controller.Root
            local humanoid = controller.Humanoid
            if not monster.Parent or not root.Parent or humanoid.Health <= 0 then
                controllers[monster] = nil
                continue
            end

            animateVisual(monster, controller, now)

            if monster:GetAttribute("MonsterEmerging") == true then
                setState(monster, controller, "Emerging")
                humanoid:Move(Vector3.zero, false)
                continue
            end

            local reaction = monster:GetAttribute("MonsterReaction")
            local reactionUntil = monster:GetAttribute("MonsterReactionUntil") or 0
            if reaction and reaction ~= "" and now < reactionUntil then
                setState(monster, controller, reaction)
                humanoid:Move(Vector3.zero, false)
                continue
            elseif reaction and reaction ~= "" and reaction ~= "Dead" then
                monster:SetAttribute("MonsterReaction", "")
            end

            local definition = controller.Definition
            local target, distance = nearestPlayer(root, definition.DetectionRange or 30)
            local leashDistance = (root.Position - controller.SpawnPosition).Magnitude
            if leashDistance > (definition.LeashRange or 60) then
                target = nil
            end

            controller.Target = target
            if not target then
                if (root.Position - controller.SpawnPosition).Magnitude > 4 then
                    setState(monster, controller, "Returning")
                    humanoid.WalkSpeed = definition.WalkSpeed or 10
                    moveWithPath(controller, humanoid, root, controller.SpawnPosition, now)
                else
                    setState(monster, controller, "Idle")
                    humanoid:Move(Vector3.zero, false)
                end
                continue
            end

            local targetRoot = target.Character
                and target.Character:FindFirstChild("HumanoidRootPart")
            if not targetRoot then
                continue
            end

            if distance <= (definition.AttackRange or 5) then
                beginAttack(monster, controller, target, targetRoot, now)
            else
                setState(monster, controller, "Pursue")
                humanoid.WalkSpeed = definition.WalkSpeed or 10
                moveWithPath(controller, humanoid, root, targetRoot.Position, now)
                face(root, targetRoot.Position)
            end
        end
    end)
end

return MonsterAI
