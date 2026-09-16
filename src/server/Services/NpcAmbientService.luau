local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local NpcAmbientService = {}

local WALK_ANIMATION_ID = "rbxassetid://507777826"
local DEFAULT_SPEED = 4.5
local DEFAULT_RADIUS = 13
local MIN_IDLE = 4.5
local MAX_IDLE = 11
local MAX_PATH_WAYPOINTS = 9
local controllers = {}
local initialized = false
local rng = Random.new()

local function rootPart(model)
    local root = model:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root else nil
end

local function getAnimator(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil
    end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    return animator
end

local function loadWalkTrack(model)
    local animator = getAnimator(model)
    if not animator then
        return nil
    end
    local animation = Instance.new("Animation")
    animation.Name = "EverLeafAmbientWalk"
    animation.AnimationId = WALK_ANIMATION_ID
    local ok, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)
    animation:Destroy()
    if not ok then
        return nil
    end
    track.Priority = Enum.AnimationPriority.Movement
    track.Looped = true
    return track
end

local function sampleGround(model, point)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { model }
    params.IgnoreWater = true
    local hit = Workspace:Raycast(point + Vector3.new(0, 35, 0), Vector3.new(0, -80, 0), params)
    return hit and hit.Position or nil
end

local function chooseDestination(controller)
    local angle = rng:NextNumber(0, math.pi * 2)
    local distance = rng:NextNumber(controller.Radius * 0.35, controller.Radius)
    local targetPlanar = controller.Home
        + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
    local ground = sampleGround(controller.Model, targetPlanar)
    if not ground then
        return nil
    end
    if math.abs(ground.Y - controller.GroundY) > 4.5 then
        return nil
    end
    return ground + Vector3.new(0, controller.RootClearance, 0)
end

local function pathTo(controller, destination)
    local path = PathfindingService:CreatePath({
        AgentRadius = 1.35,
        AgentHeight = 5.4,
        AgentCanJump = false,
        AgentCanClimb = false,
        WaypointSpacing = 4,
    })
    local ok = pcall(path.ComputeAsync, path, controller.Root.Position, destination)
    if not ok or path.Status ~= Enum.PathStatus.Success then
        return nil
    end
    local result = {}
    for _, waypoint in path:GetWaypoints() do
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            return nil
        end
        table.insert(result, waypoint.Position + Vector3.new(0, controller.RootClearance, 0))
        if #result >= MAX_PATH_WAYPOINTS then
            break
        end
    end
    return if #result >= 2 then result else nil
end

local function stopWalk(controller)
    if controller.WalkTrack and controller.WalkTrack.IsPlaying then
        controller.WalkTrack:Stop(0.18)
    end
    controller.Model:SetAttribute("AmbientActivityState", "Idle")
end

local function moveRoute(controller, waypoints)
    local root = controller.Root
    local model = controller.Model
    if not root.Parent or not model.Parent then
        return false
    end
    if controller.WalkTrack then
        controller.WalkTrack:Play(0.18, 1, 0.82)
    end
    model:SetAttribute("AmbientActivityState", "Walking")

    for index = 2, #waypoints do
        if not root.Parent or not model.Parent then
            return false
        end
        local target = waypoints[index]
        local delta = target - root.Position
        local planar = Vector3.new(delta.X, 0, delta.Z)
        if planar.Magnitude > 0.2 then
            local duration = math.clamp(planar.Magnitude / controller.Speed, 0.2, 2.6)
            local facing = CFrame.lookAt(target, target + planar.Unit)
            local tween = TweenService:Create(
                root,
                TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
                { CFrame = facing }
            )
            tween:Play()
            tween.Completed:Wait()
        end
    end
    stopWalk(controller)
    return true
end

local function runController(controller)
    task.spawn(function()
        task.wait(rng:NextNumber(1, 6))
        while controller.Model.Parent and controller.Root.Parent do
            stopWalk(controller)
            task.wait(rng:NextNumber(MIN_IDLE, MAX_IDLE))
            if not controller.Model.Parent or not controller.Root.Parent then
                break
            end
            local destination = chooseDestination(controller)
            if destination then
                local waypoints = pathTo(controller, destination)
                if waypoints then
                    moveRoute(controller, waypoints)
                end
            end
        end
        controllers[controller.Model] = nil
    end)
end

local function register(model)
    if
        not model:IsA("Model")
        or model:GetAttribute("AmbientResident") ~= true
        or controllers[model]
    then
        return false
    end
    local root = rootPart(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then
        return false
    end

    -- Ambient actors remain server-controlled and anchored. The service moves the
    -- authoritative R15 root along a navigation path, so crowds never acquire
    -- network ownership or introduce player-push collision exploits.
    root.Anchored = true
    root.CanCollide = false
    root.CanTouch = false
    root.CanQuery = true

    local ground = sampleGround(model, root.Position) or root.Position
    local controller = {
        Model = model,
        Root = root,
        Home = Vector3.new(root.Position.X, ground.Y, root.Position.Z),
        GroundY = ground.Y,
        RootClearance = math.max(2.4, root.Position.Y - ground.Y),
        Radius = tonumber(model:GetAttribute("AmbientMotionRadius")) or DEFAULT_RADIUS,
        Speed = tonumber(model:GetAttribute("AmbientWalkSpeed")) or DEFAULT_SPEED,
        WalkTrack = loadWalkTrack(model),
    }
    controller.Radius = math.clamp(controller.Radius, 5, 22)
    controller.Speed = math.clamp(controller.Speed, 2.5, 7)
    controllers[model] = controller
    model:SetAttribute("AmbientActivityEnabled", true)
    model:SetAttribute("AmbientActivityState", "Idle")
    runController(controller)
    return true
end

function NpcAmbientService.Init()
    if initialized then
        return
    end
    initialized = true
    for _, descendant in Workspace:GetDescendants() do
        if descendant:IsA("Model") and descendant:GetAttribute("AmbientResident") == true then
            register(descendant)
        end
    end
    Workspace.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Model") and descendant:GetAttribute("AmbientResident") == true then
            task.defer(register, descendant)
        end
    end)
end

return NpcAmbientService
