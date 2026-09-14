local RunService = game:GetService("RunService")

local MonsterAnimationDefinitions =
    require(script.Parent.Parent.Content.MonsterAnimationDefinitions)

local MonsterAnimationService = {}
local states = {}
local initialized = false

local RIG_BY_MONSTER = table.freeze({
    lumen_mossling = "slime",
    skeleton = "skeleton",
    gravebone_captain = "skeleton",
    slime = "slime",
    royal_glowcap = "slime",
    peco_peco = "bird",
    brambleback = "quadruped",
    mosswarden = "quadruped",
    rivet_scuttler = "quadruped",
    slagmite = "slime",
    gearjaw_hound = "quadruped",
    cindercoil = "wisp",
    pressure_bastion = "quadruped",
    furnace_husk = "skeleton",
    arc_siphon = "wisp",
    railbreaker = "quadruped",
    blueflame_sentry = "wisp",
    foundry_reaver = "skeleton",
    smelter_golem = "slime",
    forge_specter = "wisp",
    ironclad_enforcer = "skeleton",
    molten_drake = "quadruped",
    bellows_titan = "slime",
    belforge_sentinel = "skeleton",
    lumen_wisp = "wisp",
})

local STATE_TO_CLIP = table.freeze({
    Idle = "Idle",
    Emerging = "Idle",
    Pursue = "Walk",
    Returning = "Walk",
    Attack = "Attack",
    Hit = "Hit",
    Dodge = "Dodge",
    Dead = "Dead",
})

local function collectMotors(monster)
    local motors = {}
    for _, descendant in monster:GetDescendants() do
        if descendant:IsA("Motor6D") then
            motors[descendant.Name] = descendant
        end
    end
    return motors
end

local function ensureState(monster)
    local state = states[monster]
    if state then
        return state
    end

    local monsterId = monster:GetAttribute("EnemyId") or monster:GetAttribute("MonsterId")
    local rigName = RIG_BY_MONSTER[monsterId]
    local rig = rigName and MonsterAnimationDefinitions[rigName]
    if not rig then
        return nil
    end

    state = {
        Rig = rig,
        ClipName = "Idle",
        StartedAt = os.clock(),
        Motors = collectMotors(monster),
    }
    states[monster] = state
    monster.Destroying:Once(function()
        states[monster] = nil
    end)
    return state
end

local function applyClip(state, now)
    local clip = state.Rig[state.ClipName]
    if not clip or #clip.Keyframes == 0 then
        return
    end

    local elapsed = math.max(0, now - state.StartedAt)
    if clip.Loop and clip.Duration > 0 then
        elapsed %= clip.Duration
    else
        elapsed = math.min(elapsed, clip.Duration)
    end

    local before = clip.Keyframes[1]
    local after = clip.Keyframes[#clip.Keyframes]
    for index = 1, #clip.Keyframes - 1 do
        local left = clip.Keyframes[index]
        local right = clip.Keyframes[index + 1]
        if elapsed >= left.Time and elapsed <= right.Time then
            before = left
            after = right
            break
        end
    end

    local span = math.max(0.001, after.Time - before.Time)
    local alpha = math.clamp((elapsed - before.Time) / span, 0, 1)
    local names = {}
    for jointName in before.Poses do
        names[jointName] = true
    end
    for jointName in after.Poses do
        names[jointName] = true
    end
    for jointName in names do
        local motor = state.Motors[jointName]
        if motor and motor.Parent then
            local from = before.Poses[jointName] or CFrame.new()
            local to = after.Poses[jointName] or CFrame.new()
            motor.Transform = from:Lerp(to, alpha)
        end
    end
end

function MonsterAnimationService.SetState(monster, aiState)
    local state = ensureState(monster)
    if not state then
        return false
    end
    local clipName = STATE_TO_CLIP[aiState] or "Idle"
    if state.ClipName ~= clipName then
        state.ClipName = clipName
        state.StartedAt = os.clock()
    end
    return true
end

function MonsterAnimationService.Restart(monster, clipName)
    local state = ensureState(monster)
    if not state or not state.Rig[clipName] then
        return false
    end
    state.ClipName = clipName
    state.StartedAt = os.clock()
    return true
end

function MonsterAnimationService.Update(monster, now)
    local state = ensureState(monster)
    if not state then
        return false
    end
    applyClip(state, now or os.clock())
    return true
end

function MonsterAnimationService.PlayOneShot(monster, clipName)
    local state = ensureState(monster)
    if not state or not state.Rig[clipName] then
        return false
    end
    state.ClipName = clipName
    state.StartedAt = os.clock()
    return true
end

function MonsterAnimationService.Detach(monster)
    states[monster] = nil
end

function MonsterAnimationService.Init()
    if initialized then
        return
    end
    initialized = true
    local accumulator = 0
    RunService.Heartbeat:Connect(function(deltaTime)
        accumulator += deltaTime
        if accumulator < 1 / 30 then
            return
        end
        accumulator = 0
        local now = os.clock()
        for monster, state in states do
            if monster.Parent then
                applyClip(state, now)
            else
                states[monster] = nil
            end
        end
    end)
end

return MonsterAnimationService
