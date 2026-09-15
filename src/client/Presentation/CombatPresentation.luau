local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local WeaponCombatProfiles = require(ReplicatedStorage.Shared.WeaponCombatProfiles)
local CameraImpulse = require(script.Parent.CameraImpulse)

local CombatPresentation = {}
local player = Players.LocalPlayer

local FAMILY_COLORS = table.freeze({
    ironbloom = Color3.fromRGB(121, 244, 183),
    thornrunner = Color3.fromRGB(230, 170, 82),
    lumenweaver = Color3.fromRGB(99, 236, 209),
    veilstrider = Color3.fromRGB(187, 145, 229),
    brasshand = Color3.fromRGB(241, 187, 82),
})

local SKILL_SOUND_CUES = table.freeze({
    slash = table.freeze({
        Id = "rbxasset://sounds/electronicpingshort.wav",
        Volume = 0.18,
        Speed = 1.28,
    }),
    heavy = table.freeze({
        Id = "rbxasset://sounds/electronicpingshort.wav",
        Volume = 0.28,
        Speed = 0.72,
    }),
    shot = table.freeze({
        Id = "rbxasset://sounds/electronicpingshort.wav",
        Volume = 0.18,
        Speed = 1.55,
    }),
    magic = table.freeze({ Id = "rbxasset://sounds/impact_water.mp3", Volume = 0.20, Speed = 1.35 }),
    impact = table.freeze({
        Id = "rbxasset://sounds/electronicpingshort.wav",
        Volume = 0.16,
        Speed = 0.92,
    }),
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

local function playSequence(character, familyId, durationMultiplier)
    local sequence = ATTACK_SEQUENCES[familyId] or ATTACK_SEQUENCES.default
    local duration = sequence.Duration * math.max(0.1, tonumber(durationMultiplier) or 1)
    local resolved = rigJoints(character)
    if not resolved then
        if not playAnimatorFallback(character, familyId, duration) then
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

        local alpha = math.clamp((os.clock() - startedAt) / duration, 0, 1)
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

local function handPosition(character, familyId, weaponType)
    local leftHanded = weaponType == "Bow" or weaponType == nil and familyId == "thornrunner"
    local preferred = if leftHanded then "LeftHand" else "RightHand"
    local hand = character:FindFirstChild(preferred)
        or character:FindFirstChild(if leftHanded then "Left Arm" else "Right Arm")
        or character:FindFirstChild("HumanoidRootPart")
    return hand and hand.Position or character:GetPivot().Position
end

local function projectile(startPosition, targetPosition, color, kind, speed)
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
    elseif kind == "lance" then
        shot.Size = Vector3.new(0.22, 0.22, 2.8)
    else
        shot.Size = Vector3.new(0.12, 0.12, 1.65)
    end
    shot.CFrame = CFrame.lookAt(startPosition, targetPosition)
    shot.Parent = workspace

    if kind == "orb" or kind == "lance" then
        local light = Instance.new("PointLight")
        light.Color = color
        light.Brightness = 1.2
        light.Range = 7
        light.Parent = shot
        local trailHalf = kind == "lance" and 0.9 or 0.2
        local a0 = Instance.new("Attachment")
        a0.Position = Vector3.new(0, 0, -trailHalf)
        a0.Parent = shot
        local a1 = Instance.new("Attachment")
        a1.Position = Vector3.new(0, 0, trailHalf)
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
        TweenInfo.new(
            math.clamp(delta.Magnitude / math.max(1, speed or 110), 0.08, 0.45),
            Enum.EasingStyle.Linear
        ),
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

local function impactParticleBurst(targetPosition, color, heavy)
    local anchor = Instance.new("Part")
    anchor.Name = "EverLeafImpactParticles"
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.CastShadow = false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(0.1, 0.1, 0.1)
    anchor.Position = targetPosition + Vector3.new(0, 1.4, 0)
    anchor.Parent = workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "ImpactSparkBurst"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color = ColorSequence.new(color)
    emitter.LightEmission = 0.7
    emitter.Rate = 0
    emitter.Lifetime = NumberRange.new(0.18, heavy and 0.42 or 0.3)
    emitter.Speed = NumberRange.new(heavy and 8 or 5, heavy and 17 or 11)
    emitter.Drag = 5
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.RotSpeed = NumberRange.new(-180, 180)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, heavy and 0.3 or 0.2),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.08),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = anchor
    emitter:Emit(heavy and 20 or 12)
    Debris:AddItem(anchor, 0.65)
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

local function skillPresentation(definition)
    return type(definition) == "table"
            and type(definition.Presentation) == "table"
            and definition.Presentation
        or {}
end

local function skillSequenceKey(familyId, presentation)
    local style = presentation.AnimationStyle or "family"
    if style == "heavy" then
        return familyId == "brasshand" and "brasshand" or "ironbloom"
    end
    if style == "fast" then
        return "veilstrider"
    end
    if style == "shot" then
        return "thornrunner"
    end
    if style == "cast" then
        return "lumenweaver"
    end
    return familyId
end

local function playSkillCue(parent, cueName)
    local cue = SKILL_SOUND_CUES[cueName]
    if not cue or not parent then
        return
    end
    local sound = Instance.new("Sound")
    sound.Name = "EverLeafSkillCue"
    sound.SoundId = cue.Id
    sound.Volume = cue.Volume
    sound.PlaybackSpeed = cue.Speed
    sound.RollOffMode = Enum.RollOffMode.Inverse
    sound.RollOffMinDistance = 5
    sound.RollOffMaxDistance = 55
    sound.Parent = parent
    sound:Play()
    Debris:AddItem(sound, 2)
end

local function playSkillCueAt(position, cueName)
    if typeof(position) ~= "Vector3" or not SKILL_SOUND_CUES[cueName] then
        return
    end
    local anchorPart = Instance.new("Part")
    anchorPart.Name = "EverLeafSkillSoundAnchor"
    anchorPart.Anchored = true
    anchorPart.CanCollide = false
    anchorPart.CanTouch = false
    anchorPart.CanQuery = false
    anchorPart.Transparency = 1
    anchorPart.Size = Vector3.new(0.1, 0.1, 0.1)
    anchorPart.Position = position
    anchorPart.Parent = workspace
    playSkillCue(anchorPart, cueName)
    Debris:AddItem(anchorPart, 2)
end

local function groundPulse(position, color, radius)
    if typeof(position) ~= "Vector3" then
        return
    end
    radius = math.max(2, tonumber(radius) or 5)
    local ring = Instance.new("Part")
    ring.Name = "EverLeafSkillPulse"
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanTouch = false
    ring.CanQuery = false
    ring.CastShadow = false
    ring.Material = Enum.Material.Neon
    ring.Color = color
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.12, 1.2, 1.2)
    ring.CFrame = CFrame.new(position + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
    ring.Transparency = 0.25
    ring.Parent = workspace
    TweenService:Create(ring, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
        Size = Vector3.new(0.08, radius * 2, radius * 2),
        Transparency = 1,
    }):Play()
    Debris:AddItem(ring, 0.28)
end

local function playSkillImpactVisual(familyId, presentation, hit, withCamera)
    if type(hit) ~= "table" or hit.Dodged == true or typeof(hit.TargetPosition) ~= "Vector3" then
        return
    end
    local color = FAMILY_COLORS[familyId] or Color3.fromRGB(188, 216, 201)
    if withCamera then
        local impactWeight = math.max(0, tonumber(presentation.ImpactWeight) or 0.6)
        if hit.Critical == true then
            impactWeight *= 1.2
        end
        CameraImpulse.Punch(impactWeight)
    end
    local heavy = presentation.ImpactStyle == "heavy_burst" or presentation.ImpactStyle == "pulse"
    impactParticleBurst(hit.TargetPosition, color, heavy)
    local style = presentation.ImpactStyle or "burst"
    if style == "slash" then
        slashImpact(hit.TargetPosition, color, false)
    elseif style == "cross" then
        slashImpact(hit.TargetPosition, color, true)
    elseif style == "heavy_burst" then
        burstImpact(hit.TargetPosition, color, true)
    elseif style == "pulse" then
        burstImpact(hit.TargetPosition, color, true)
        groundPulse(hit.TargetPosition, color, 3.5)
    elseif style == "pierce" then
        burstImpact(hit.TargetPosition, color, false)
        slashImpact(hit.TargetPosition, color, false)
    else
        burstImpact(hit.TargetPosition, color, false)
    end
    playSkillCueAt(hit.TargetPosition, presentation.ImpactSound or "none")
end

local function launchRangedBasic(character, familyId, weaponType)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local profile = type(weaponType) == "string" and WeaponCombatProfiles[weaponType] or nil
    local isLegacyFamilyProjectile = profile == nil
        and (familyId == "thornrunner" or familyId == "lumenweaver")
    if
        profile and profile.AttackMode ~= "Projectile"
        or not profile and not isLegacyFamilyProjectile
    then
        return
    end

    local range = profile and profile.Range or if familyId == "thornrunner" then 23 else 21
    local speed = profile and profile.ProjectileSpeed
        or if familyId == "lumenweaver" then 68 else 88
    local kind = profile and profile.ProjectileKind
        or if familyId == "lumenweaver" then "orb" else "arrow"
    local startPosition = handPosition(character, familyId, weaponType)
    projectile(
        startPosition,
        startPosition + root.CFrame.LookVector * range,
        FAMILY_COLORS[familyId] or Color3.fromRGB(188, 216, 201),
        kind,
        speed
    )
end

function CombatPresentation.GetBasicAttackDuration(familyId, weaponType)
    local sequence = ATTACK_SEQUENCES[familyId] or ATTACK_SEQUENCES.default
    local profile = type(weaponType) == "string" and WeaponCombatProfiles[weaponType] or nil
    return sequence.Duration * math.max(0.1, profile and profile.AnimationDurationMultiplier or 1)
end

function CombatPresentation.PlayBasicAttack(familyId, weaponType)
    local character = player.Character
    if not character then
        return
    end
    local profile = type(weaponType) == "string" and WeaponCombatProfiles[weaponType] or nil
    playSequence(character, familyId, profile and profile.AnimationDurationMultiplier or 1)
    launchRangedBasic(character, familyId, weaponType)
end

function CombatPresentation.GetSkillCastDuration(familyId, definition)
    local presentation = skillPresentation(definition)
    local sequenceKey = skillSequenceKey(familyId, presentation)
    local sequence = ATTACK_SEQUENCES[sequenceKey] or ATTACK_SEQUENCES.default
    return sequence.Duration * math.max(0.5, tonumber(presentation.CastDurationMultiplier) or 1)
end

function CombatPresentation.PlaySkillCast(familyId, definition)
    local character = player.Character
    if not character then
        return
    end
    local presentation = skillPresentation(definition)
    local sequenceKey = skillSequenceKey(familyId, presentation)
    local durationMultiplier = math.max(0.5, tonumber(presentation.CastDurationMultiplier) or 1)
    playSequence(character, sequenceKey, durationMultiplier)

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return
    end
    local color = FAMILY_COLORS[familyId] or Color3.fromRGB(188, 216, 201)
    playSkillCue(root, presentation.CastSound or "none")
    if presentation.CastVFX == "pulse" then
        local effect = definition and definition.Effect or {}
        groundPulse(root.Position, color, effect.TargetRadius or 4.5)
    end

    local effect = definition and definition.Effect
    if type(effect) ~= "table" or effect.Mode ~= "Projectile" then
        return
    end
    local startPosition = handPosition(character, familyId, nil)
    local range = math.max(1, tonumber(effect.Range) or 20)
    local speed = math.max(1, tonumber(effect.ProjectileSpeed) or 80)
    local kind = presentation.ProjectileKind or (familyId == "lumenweaver" and "orb" or "arrow")
    projectile(startPosition, startPosition + root.CFrame.LookVector * range, color, kind, speed)
end

function CombatPresentation.PlaySkillResult(familyId, definition, result)
    if type(result) ~= "table" then
        return
    end
    local presentation = skillPresentation(definition)
    if result.Kind == "Damage" then
        local hits = type(result.Hits) == "table" and result.Hits or nil
        if hits and #hits > 0 then
            for index, hit in hits do
                playSkillImpactVisual(familyId, presentation, hit, index == 1)
            end
        else
            playSkillImpactVisual(familyId, presentation, {
                TargetPosition = result.TargetPosition,
                Dodged = result.Dodged,
                Critical = result.Critical,
            }, true)
        end
    elseif result.Kind == "Miss" and typeof(result.TargetPosition) == "Vector3" then
        if result.Reason == "projectile_blocked" then
            local color = FAMILY_COLORS[familyId] or Color3.fromRGB(188, 216, 201)
            burstImpact(result.TargetPosition, color, false)
            playSkillCueAt(result.TargetPosition, presentation.ImpactSound or "impact")
        end
    end
end

function CombatPresentation.PlayHit(familyId, targetPosition, dodged, critical)
    if typeof(targetPosition) ~= "Vector3" or dodged then
        return
    end
    local character = player.Character
    if not character then
        return
    end
    local color = FAMILY_COLORS[familyId] or Color3.fromRGB(188, 216, 201)
    local impactStrength = if critical
        then 1.1
        else if familyId == "brasshand"
            then 0.85
            else if familyId == "ironbloom" then 0.72 else 0.5
    CameraImpulse.Punch(impactStrength)
    if familyId == "veilstrider" then
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
