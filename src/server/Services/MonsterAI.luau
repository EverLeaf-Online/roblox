local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MonsterAnimationService = require(script.Parent.MonsterAnimationService)
local MonsterAttackHitboxService = require(script.Parent.MonsterAttackHitboxService)
local MonsterCombat = require(script.Parent.MonsterCombat)
local MonsterThreatService = require(script.Parent.MonsterThreatService)

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
    MonsterAnimationService.SetState(monster, nextState)
end

local function face(root, position)
    local flat = Vector3.new(position.X, root.Position.Y, position.Z)
    if (flat - root.Position).Magnitude > 0.05 then
        root.CFrame = CFrame.lookAt(root.Position, flat)
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
    if controller.State == "Attack" and now < controller.AttackStateUntil then
        return
    end
    if now < controller.NextAttackAt then
        setState(monster, controller, "Idle")
        face(controller.Root, targetRoot.Position)
        controller.Humanoid:Move(Vector3.zero, false)
        return
    end

    local attackWindup = controller.Definition.AttackWindup or 0.4
    controller.NextAttackAt = now + (controller.Definition.AttackCooldown or 1.5)
    controller.AttackStateUntil = now + math.max(0.55, attackWindup + 0.28)
    controller.AttackToken += 1
    local token = controller.AttackToken
    setState(monster, controller, "Attack")
    face(controller.Root, targetRoot.Position)
    controller.Humanoid:Move(Vector3.zero, false)

    MonsterAnimationService.Restart(monster, "Attack")
    local monsterId = controller.Definition.Id
    local direction = targetRoot.Position - controller.Root.Position
    local planar = Vector3.new(direction.X, 0, direction.Z)
    if planar.Magnitude > 0.05 then
        planar = planar.Unit
        if monsterId == "slime" or monsterId == "royal_glowcap" then
            controller.Root.AssemblyLinearVelocity = Vector3.new(planar.X * 9, 15, planar.Z * 9)
        elseif monsterId == "peco_peco" then
            controller.Root.AssemblyLinearVelocity = Vector3.new(planar.X * 17, 5, planar.Z * 17)
        elseif monsterId == "brambleback" then
            controller.Root.AssemblyLinearVelocity = Vector3.new(planar.X * 14, 3, planar.Z * 14)
        elseif monsterId == "mosswarden" then
            controller.Root.AssemblyLinearVelocity = Vector3.new(planar.X * 11, 2, planar.Z * 11)
        end
    end

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
        local canHit =
            MonsterAttackHitboxService.CanHitPlayer(monster, target, controller.Definition)
        if canHit then
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
        AttackStateUntil = 0,
        NextPathAt = 0,
        Waypoints = nil,
        WaypointIndex = 0,
        AttackToken = 0,
        AgentRadius = monster:GetAttribute("AgentRadius") or 2,
        AgentHeight = monster:GetAttribute("AgentHeight") or 5,
    }
    controllers[monster] = controller
    monster:SetAttribute("MonsterAIState", "Idle")
    MonsterAnimationService.SetState(monster, "Idle")
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
    MonsterThreatService.Clear(monster)
    MonsterAnimationService.Detach(monster)
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
        local frameNow = os.clock()
        for monster in controllers do
            if monster.Parent then
                MonsterAnimationService.Update(monster, frameNow)
            end
        end

        accumulator += deltaTime
        if accumulator < 0.12 then
            return
        end
        accumulator = 0
        local now = frameNow

        for monster, controller in controllers do
            local root = controller.Root
            local humanoid = controller.Humanoid
            if not monster.Parent or not root.Parent or humanoid.Health <= 0 then
                controllers[monster] = nil
                continue
            end

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
            local detectionRange = definition.DetectionRange or 30
            local target, distance = MonsterThreatService.SelectTarget(
                monster,
                controller.Target,
                root.Position,
                detectionRange
            )
            if not target then
                target, distance = nearestPlayer(root, detectionRange)
            end

            local leashDistance = (root.Position - controller.SpawnPosition).Magnitude
            if leashDistance > (definition.LeashRange or 60) then
                target = nil
                MonsterThreatService.Clear(monster)
            end

            controller.Target = target
            if not target then
                if (root.Position - controller.SpawnPosition).Magnitude > 4 then
                    setState(monster, controller, "Returning")
                    humanoid.WalkSpeed = definition.WalkSpeed or 10
                    moveWithPath(controller, humanoid, root, controller.SpawnPosition, now)
                else
                    MonsterThreatService.Clear(monster)
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
