local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CombatPresentation = {}
local player = Players.LocalPlayer

local FAMILY_COLORS = table.freeze({
    ironbloom = Color3.fromRGB(121, 244, 183),
    thornrunner = Color3.fromRGB(230, 170, 82),
    lumenweaver = Color3.fromRGB(99, 236, 209),
    veilstrider = Color3.fromRGB(187, 145, 229),
    brasshand = Color3.fromRGB(241, 187, 82),
})

local attackGeneration = 0

local IDENTITY = CFrame.new()

-- Roblox avatars can expose animation-compatible rigs without the shoulder
-- Motor6Ds that the additive pose layer expects. Never fail the attack
-- presentation in that case: fall back to a real Animator track.
local R15_FALLBACK_ANIMATIONS = table.freeze({
    default = "rbxassetid://522635514", -- tool slash
    ironbloom = "rbxassetid://522638767", -- heavier lunge
    thornrunner = "rbxassetid://507770453", -- point / release silhouette
    lumenweaver = "rbxassetid://507770453", -- forward cast silhouette
    veilstrider = "rbxassetid://522635514", -- fast slash
    brasshand = "rbxassetid://522638767", -- heavy lunge
})

local R6_FALLBACK_ANIMATIONS = table.freeze({
    default = "rbxassetid://129967390",
    ironbloom = "rbxassetid://129967478",
    thornrunner = "rbxassetid://128853357",
    lumenweaver = "rbxassetid://128853357",
    veilstrider = "rbxassetid://129967390",
    brasshand = "rbxassetid://129967478",
})

local fallbackTracks = setmetatable({}, { __mode = "k" })

local function findMotor(character, names)
    for _, name in names do
        local joint = character:FindFirstChild(name, true)
        if joint and joint:IsA("Motor6D") then
            return joint
        end
    end
    return nil
end

local function findMotorConnecting(character, partNames)
    for _, descendant in character:GetDescendants() do
        if descendant:IsA("Motor6D") then
            local part0 = descendant.Part0
            local part1 = descendant.Part1
            local part0Name = part0 and part0.Name or ""
            local part1Name = part1 and part1.Name or ""
            for _, name in partNames do
                if part0Name == name or part1Name == name then
                    return descendant
                end
            end
        end
    end
    return nil
end

local function rigJoints(character)
    local right = findMotor(character, { "RightShoulder", "Right Shoulder" })
        or findMotorConnecting(character, { "RightUpperArm", "Right Arm" })
    if not right then
        return nil
    end
    return {
        Right = right,
        Left = findMotor(character, { "LeftShoulder", "Left Shoulder" })
            or findMotorConnecting(character, { "LeftUpperArm", "Left Arm" }),
        RightElbow = findMotor(character, { "RightElbow" })
            or findMotorConnecting(character, { "RightLowerArm" }),
        LeftElbow = findMotor(character, { "LeftElbow" })
            or findMotorConnecting(character, { "LeftLowerArm" }),
        Torso = findMotor(character, { "Waist", "RootJoint", "Root Joint" })
            or findMotorConnecting(character, { "UpperTorso", "Torso" }),
    }
end

local function angles(x, y, z)
    return CFrame.Angles(math.rad(x or 0), math.rad(y or 0), math.rad(z or 0))
end

local function frame(time, pose)
    pose.Time = time
    return pose
end

local ATTACK_SEQUENCES = table.freeze({
    default = table.freeze({
        Duration = 0.34,
        Frames = table.freeze({
            frame(0, {}),
            frame(0.18, {
                Right = angles(40, -12, 58),
                Left = angles(-8, 0, -10),
                Torso = angles(0, -18, 0),
                RightElbow = angles(-24, 0, 0),
            }),
            frame(0.52, {
                Right = angles(-112, 12, -24),
                Left = angles(10, 0, 8),
                Torso = angles(0, 30, 0),
                RightElbow = angles(18, 0, 0),
            }),
            frame(1, {}),
        }),
    }),
    ironbloom = table.freeze({
        Duration = 0.43,
        Frames = table.freeze({
            frame(0, {}),
            frame(0.22, {
                Right = angles(62, -15, 66),
                Left = angles(14, 8, -24),
                Torso = angles(-5, -30, 0),
                RightElbow = angles(-38, 0, 0),
            }),
            frame(0.56, {
                Right = angles(-132, 15, -30),
                Left = angles(-18, -5, 16),
                Torso = angles(6, 38, 0),
                RightElbow = angles(12, 0, 0),
            }),
            frame(0.72, {
                Right = angles(-88, 6, -15),
                Torso = angles(3, 20, 0),
            }),
            frame(1, {}),
        }),
    }),
    thornrunner = table.freeze({
        Duration = 0.4,
        Frames = table.freeze({
            frame(0, {}),
            frame(0.22, {
                Left = angles(-82, -8, -18),
                Right = angles(-74, 34, 82),
                LeftElbow = angles(-22, 0, 0),
                RightElbow = angles(-90, 0, 0),
                Torso = angles(0, -24, 0),
            }),
            frame(0.5, {
                Left = angles(-88, -4, -12),
                Right = angles(-86, 3, 8),
                LeftElbow = angles(-14, 0, 0),
                RightElbow = angles(-18, 0, 0),
                Torso = angles(0, -18, 0),
            }),
            frame(0.66, {
                Left = angles(-75, 0, -8),
                Right = angles(-55, 0, 0),
                Torso = angles(0, -10, 0),
            }),
            frame(1, {}),
        }),
    }),
    lumenweaver = table.freeze({
        Duration = 0.42,
        Frames = table.freeze({
            frame(0, {}),
            frame(0.22, {
                Right = angles(-94, -8, 12),
                Left = angles(-48, 12, -32),
                RightElbow = angles(-28, 0, 0),
                LeftElbow = angles(-34, 0, 0),
                Torso = angles(-8, -12, 0),
            }),
            frame(0.55, {
                Right = angles(-118, 3, -4),
                Left = angles(-74, -6, 24),
                RightElbow = angles(4, 0, 0),
                LeftElbow = angles(-14, 0, 0),
                Torso = angles(4, 10, 0),
            }),
            frame(0.7, {
                Right = angles(-72, 0, 0),
                Left = angles(-34, 0, 10),
            }),
            frame(1, {}),
        }),
    }),
    veilstrider = table.freeze({
        Duration = 0.28,
        Frames = table.freeze({
            frame(0, {}),
            frame(0.16, {
                Right = angles(24, -18, 82),
                Left = angles(24, 18, -82),
                RightElbow = angles(-36, 0, 0),
                LeftElbow = angles(-36, 0, 0),
                Torso = angles(0, -16, 0),
            }),
            frame(0.48, {
                Right = angles(-106, 18, -38),
                Left = angles(-106, -18, 38),
                RightElbow = angles(12, 0, 0),
                LeftElbow = angles(12, 0, 0),
                Torso = angles(0, 24, 0),
            }),
            frame(0.68, {
                Right = angles(-70, 6, -18),
                Left = angles(-70, -6, 18),
            }),
            frame(1, {}),
        }),
    }),
    brasshand = table.freeze({
        Duration = 0.46,
        Frames = table.freeze({
            frame(0, {}),
            frame(0.24, {
                Right = angles(58, -8, 28),
                Left = angles(58, 8, -28),
                RightElbow = angles(-72, 0, 0),
                LeftElbow = angles(-72, 0, 0),
                Torso = angles(-12, 0, 0),
            }),
            frame(0.58, {
                Right = angles(-142, 4, 12),
                Left = angles(-126, -4, -12),
                RightElbow = angles(-10, 0, 0),
                LeftElbow = angles(-10, 0, 0),
                Torso = angles(16, 8, 0),
            }),
            frame(0.74, {
                Right = angles(-95, 0, 5),
                Left = angles(-88, 0, -5),
                Torso = angles(8, 4, 0),
            }),
            frame(1, {}),
        }),
    }),
})

local POSE_KEYS = table.freeze({ "Right", "Left", "RightElbow", "LeftElbow", "Torso" })

local function frameOffset(value, key)
    return value[key] or IDENTITY
end

local function sampleSequence(sequence, alpha)
    local frames = sequence.Frames
    if alpha <= 0 then
        return frames[1]
    end
    for index = 1, #frames - 1 do
        local a = frames[index]
        local b = frames[index + 1]
        if alpha <= b.Time then
            local span = math.max(0.0001, b.Time - a.Time)
            local t = math.clamp((alpha - a.Time) / span, 0, 1)
            local result = {}
            for _, key in POSE_KEYS do
                result[key] = frameOffset(a, key):Lerp(frameOffset(b, key), t)
            end
            return result
        end
    end
    return frames[#frames]
end

local function fallbackAnimationId(humanoid, familyId)
    local animations = if humanoid.RigType == Enum.HumanoidRigType.R6
        then R6_FALLBACK_ANIMATIONS
        else R15_FALLBACK_ANIMATIONS
    return animations[familyId] or animations.default
end

local function playAnimatorFallback(character, familyId, duration)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        return false
    end

    local animationId = fallbackAnimationId(humanoid, familyId)
    local perAnimator = fallbackTracks[animator]
    if not perAnimator then
        perAnimator = {}
        fallbackTracks[animator] = perAnimator
    end

    local track = perAnimator[animationId]
    if not track then
        local animation = Instance.new("Animation")
        animation.Name = "EverLeafAttackFallback"
        animation.AnimationId = animationId
        local ok, loaded = pcall(function()
            return animator:LoadAnimation(animation)
        end)
        animation:Destroy()
        if not ok or not loaded then
            return false
        end
        track = loaded
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = false
        perAnimator[animationId] = track
    end

    if track.IsPlaying then
        track:Stop(0.02)
    end
    track:Play(0.035, 1, 1)
    if track.Length > 0 and duration > 0 then
        track:AdjustSpeed(math.max(0.1, track.Length / duration))
    end
    return true
end

local function playSequence(character, familyId)
    local sequence = ATTACK_SEQUENCES[familyId] or ATTACK_SEQUENCES.default
    local resolved = rigJoints(character)
    if not resolved then
        if not playAnimatorFallback(character, familyId, sequence.Duration) then
            warn("[CombatPresentation] Player rig has no usable attack animation path")
        end
        return
    end

    attackGeneration += 1
    local generation = attackGeneration
    local startedAt = os.clock()
    local base = {}
    for _, key in POSE_KEYS do
        local joint = resolved[key]
        if joint then
            base[key] = joint.Transform
        end
    end

    local connection
    connection = RunService.PreSimulation:Connect(function()
        if generation ~= attackGeneration or not character.Parent then
            connection:Disconnect()
            return
        end

        local alpha = math.clamp((os.clock() - startedAt) / sequence.Duration, 0, 1)
        local pose = sampleSequence(sequence, alpha)
        for _, key in POSE_KEYS do
            local joint = resolved[key]
            if joint and joint.Parent then
                joint.Transform = (base[key] or IDENTITY) * frameOffset(pose, key)
            end
        end

        if alpha >= 1 then
            connection:Disconnect()
        end
    end)
end

local function handPosition(character, familyId)
    local preferred = if familyId == "thornrunner" then "LeftHand" else "RightHand"
    local hand = character:FindFirstChild(preferred)
        or character:FindFirstChild(if familyId == "thornrunner" then "Left Arm" else "Right Arm")
        or character:FindFirstChild("HumanoidRootPart")
    return hand and hand.Position or character:GetPivot().Position
end

local function projectile(startPosition, targetPosition, color, kind)
    local delta = targetPosition - startPosition
    if delta.Magnitude < 0.1 then
        return
    end
    local shot = Instance.new("Part")
    shot.Name = "EverLeafAttackVFX"
    shot.Anchored = true
    shot.CanCollide = false
    shot.CanTouch = false
    shot.CanQuery = false
    shot.CastShadow = false
    shot.Material = Enum.Material.Neon
    shot.Color = color
    shot.Transparency = 0.05
    if kind == "orb" then
        shot.Shape = Enum.PartType.Ball
        shot.Size = Vector3.new(0.65, 0.65, 0.65)
    else
        shot.Size = Vector3.new(0.12, 0.12, 1.65)
    end
    shot.CFrame = CFrame.lookAt(startPosition, targetPosition)
    shot.Parent = workspace

    if kind == "orb" then
        local light = Instance.new("PointLight")
        light.Color = color
        light.Brightness = 1.2
        light.Range = 7
        light.Parent = shot
        local a0 = Instance.new("Attachment")
        a0.Position = Vector3.new(0, 0, -0.2)
        a0.Parent = shot
        local a1 = Instance.new("Attachment")
        a1.Position = Vector3.new(0, 0, 0.2)
        a1.Parent = shot
        local trail = Instance.new("Trail")
        trail.Attachment0 = a0
        trail.Attachment1 = a1
        trail.Color = ColorSequence.new(color)
        trail.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.15),
            NumberSequenceKeypoint.new(1, 1),
        })
        trail.Lifetime = 0.14
        trail.Parent = shot
    end

    local targetCFrame = CFrame.lookAt(targetPosition, targetPosition + delta.Unit)
    local tween = TweenService:Create(
        shot,
        TweenInfo.new(math.clamp(delta.Magnitude / 110, 0.08, 0.2), Enum.EasingStyle.Linear),
        { CFrame = targetCFrame }
    )
    tween:Play()
    tween.Completed:Once(function()
        if shot.Parent then
            TweenService:Create(shot, TweenInfo.new(0.08), {
                Transparency = 1,
                Size = kind == "orb" and Vector3.new(1.4, 1.4, 1.4) or shot.Size,
            }):Play()
        end
    end)
    Debris:AddItem(shot, 0.45)
end

local function slashImpact(targetPosition, color, dual)
    local count = dual and 2 or 1
    for index = 1, count do
        local slash = Instance.new("Part")
        slash.Name = "EverLeafSlashVFX"
        slash.Anchored = true
        slash.CanCollide = false
        slash.CanTouch = false
        slash.CanQuery = false
        slash.CastShadow = false
        slash.Material = Enum.Material.Neon
        slash.Color = color
        slash.Size = Vector3.new(0.12, 4.2, 0.45)
        slash.CFrame = CFrame.new(targetPosition + Vector3.new(0, 2.1, 0))
            * CFrame.Angles(0, 0, math.rad(dual and (index == 1 and 48 or -48) or -35))
        slash.Parent = workspace
        TweenService:Create(slash, TweenInfo.new(0.14), {
            Transparency = 1,
            Size = Vector3.new(0.08, 5.2, 0.25),
        }):Play()
        Debris:AddItem(slash, 0.18)
    end
end

local function burstImpact(targetPosition, color, heavy)
    local core = Instance.new("Part")
    core.Name = "EverLeafImpactVFX"
    core.Anchored = true
    core.CanCollide = false
    core.CanTouch = false
    core.CanQuery = false
    core.CastShadow = false
    core.Material = Enum.Material.Neon
    core.Color = color
    core.Shape = Enum.PartType.Ball
    core.Size = Vector3.new(0.5, 0.5, 0.5)
    core.CFrame = CFrame.new(targetPosition + Vector3.new(0, 1.5, 0))
    core.Parent = workspace
    TweenService:Create(core, TweenInfo.new(heavy and 0.18 or 0.12), {
        Size = Vector3.new(heavy and 5 or 3, heavy and 5 or 3, heavy and 5 or 3),
        Transparency = 1,
    }):Play()
    Debris:AddItem(core, 0.22)
end

function CombatPresentation.GetBasicAttackDuration(familyId)
    local sequence = ATTACK_SEQUENCES[familyId] or ATTACK_SEQUENCES.default
    return sequence.Duration
end

function CombatPresentation.PlayBasicAttack(familyId)
    local character = player.Character
    if not character then
        return
    end
    playSequence(character, familyId)
end

function CombatPresentation.PlayHit(familyId, targetPosition, dodged)
    if typeof(targetPosition) ~= "Vector3" or dodged then
        return
    end
    local character = player.Character
    if not character then
        return
    end
    local color = FAMILY_COLORS[familyId] or Color3.fromRGB(188, 216, 201)
    if familyId == "thornrunner" then
        projectile(
            handPosition(character, familyId),
            targetPosition + Vector3.new(0, 1.4, 0),
            color,
            "arrow"
        )
    elseif familyId == "lumenweaver" then
        projectile(
            handPosition(character, familyId),
            targetPosition + Vector3.new(0, 1.5, 0),
            color,
            "orb"
        )
    elseif familyId == "veilstrider" then
        slashImpact(targetPosition, color, true)
    elseif familyId == "brasshand" then
        burstImpact(targetPosition, color, true)
    elseif familyId == "ironbloom" then
        slashImpact(targetPosition, color, false)
    else
        burstImpact(targetPosition, color, false)
    end
end

return CombatPresentation
