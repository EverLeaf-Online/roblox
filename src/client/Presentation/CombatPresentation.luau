local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
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

local function findMotor(character, names)
    for _, name in names do
        local joint = character:FindFirstChild(name, true)
        if joint and joint:IsA("Motor6D") then
            return joint
        end
    end
    return nil
end

local function tweenJoint(joint, c0, duration, style, direction)
    if not joint or not joint.Parent then
        return nil
    end
    local tween = TweenService:Create(
        joint,
        TweenInfo.new(
            duration,
            style or Enum.EasingStyle.Quad,
            direction or Enum.EasingDirection.Out
        ),
        { C0 = c0 }
    )
    tween:Play()
    return tween
end

local function joints(character)
    local right = findMotor(character, { "RightShoulder", "Right Shoulder" })
    if not right then
        return nil
    end
    return {
        Right = right,
        Left = findMotor(character, { "LeftShoulder", "Left Shoulder" }),
        Torso = findMotor(character, { "Waist", "RootJoint", "Root Joint" }),
        RightBase = right.C0,
        LeftBase = findMotor(character, { "LeftShoulder", "Left Shoulder" })
                and findMotor(character, { "LeftShoulder", "Left Shoulder" }).C0
            or nil,
        TorsoBase = findMotor(character, { "Waist", "RootJoint", "Root Joint" })
                and findMotor(character, { "Waist", "RootJoint", "Root Joint" }).C0
            or nil,
    }
end

local function restore(state, duration)
    tweenJoint(
        state.Right,
        state.RightBase,
        duration,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.InOut
    )
    if state.Left and state.LeftBase then
        tweenJoint(
            state.Left,
            state.LeftBase,
            duration,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.InOut
        )
    end
    if state.Torso and state.TorsoBase then
        tweenJoint(
            state.Torso,
            state.TorsoBase,
            duration,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.InOut
        )
    end
end

local function meleeSwing(state, heavy)
    local windupDuration = heavy and 0.1 or 0.065
    local strikeDuration = heavy and 0.13 or 0.085
    local windup = tweenJoint(
        state.Right,
        state.RightBase
            * CFrame.Angles(
                math.rad(heavy and 50 or 28),
                math.rad(-12),
                math.rad(heavy and 52 or 36)
            ),
        windupDuration
    )
    if state.Left and state.LeftBase then
        tweenJoint(
            state.Left,
            state.LeftBase * CFrame.Angles(math.rad(-8), 0, math.rad(-12)),
            windupDuration
        )
    end
    if state.Torso and state.TorsoBase then
        tweenJoint(
            state.Torso,
            state.TorsoBase * CFrame.Angles(0, math.rad(heavy and -24 or -16), 0),
            windupDuration
        )
    end
    if windup then
        windup.Completed:Wait()
    end
    local strike = tweenJoint(
        state.Right,
        state.RightBase
            * CFrame.Angles(math.rad(heavy and -112 or -92), math.rad(10), math.rad(-14)),
        strikeDuration,
        Enum.EasingStyle.Quart
    )
    if state.Torso and state.TorsoBase then
        tweenJoint(
            state.Torso,
            state.TorsoBase * CFrame.Angles(0, math.rad(heavy and 30 or 24), 0),
            strikeDuration,
            Enum.EasingStyle.Quart
        )
    end
    if strike then
        strike.Completed:Wait()
    end
    restore(state, heavy and 0.2 or 0.15)
end

local function bowShot(state)
    local left = state.Left
    if not left or not state.LeftBase then
        meleeSwing(state, false)
        return
    end
    local draw = tweenJoint(
        left,
        state.LeftBase * CFrame.Angles(math.rad(-76), math.rad(-6), math.rad(-20)),
        0.09
    )
    tweenJoint(
        state.Right,
        state.RightBase * CFrame.Angles(math.rad(-50), math.rad(24), math.rad(72)),
        0.09
    )
    if state.Torso and state.TorsoBase then
        tweenJoint(state.Torso, state.TorsoBase * CFrame.Angles(0, math.rad(-22), 0), 0.09)
    end
    if draw then
        draw.Completed:Wait()
    end
    tweenJoint(
        state.Right,
        state.RightBase * CFrame.Angles(math.rad(-70), 0, math.rad(10)),
        0.07,
        Enum.EasingStyle.Quart
    )
    task.wait(0.055)
    restore(state, 0.15)
end

local function lumenCast(state)
    local cast = tweenJoint(
        state.Right,
        state.RightBase * CFrame.Angles(math.rad(-82), math.rad(-4), math.rad(4)),
        0.1
    )
    if state.Left and state.LeftBase then
        tweenJoint(
            state.Left,
            state.LeftBase * CFrame.Angles(math.rad(-42), math.rad(8), math.rad(-26)),
            0.1
        )
    end
    if state.Torso and state.TorsoBase then
        tweenJoint(state.Torso, state.TorsoBase * CFrame.Angles(math.rad(-4), math.rad(-8), 0), 0.1)
    end
    if cast then
        cast.Completed:Wait()
    end
    task.wait(0.065)
    restore(state, 0.18)
end

local function crosscut(state)
    local left = state.Left
    if not left or not state.LeftBase then
        meleeSwing(state, false)
        return
    end
    local windup = tweenJoint(
        state.Right,
        state.RightBase * CFrame.Angles(math.rad(20), math.rad(-15), math.rad(70)),
        0.05
    )
    tweenJoint(
        left,
        state.LeftBase * CFrame.Angles(math.rad(20), math.rad(15), math.rad(-70)),
        0.05
    )
    if windup then
        windup.Completed:Wait()
    end
    tweenJoint(
        state.Right,
        state.RightBase * CFrame.Angles(math.rad(-82), math.rad(16), math.rad(-30)),
        0.065,
        Enum.EasingStyle.Quart
    )
    tweenJoint(
        left,
        state.LeftBase * CFrame.Angles(math.rad(-82), math.rad(-16), math.rad(30)),
        0.065,
        Enum.EasingStyle.Quart
    )
    task.wait(0.06)
    restore(state, 0.12)
end

local function maulSwing(state)
    local left = state.Left
    local windup = tweenJoint(
        state.Right,
        state.RightBase * CFrame.Angles(math.rad(42), 0, math.rad(24)),
        0.12
    )
    if left and state.LeftBase then
        tweenJoint(left, state.LeftBase * CFrame.Angles(math.rad(42), 0, math.rad(-24)), 0.12)
    end
    if state.Torso and state.TorsoBase then
        tweenJoint(state.Torso, state.TorsoBase * CFrame.Angles(math.rad(-7), 0, 0), 0.12)
    end
    if windup then
        windup.Completed:Wait()
    end
    tweenJoint(
        state.Right,
        state.RightBase * CFrame.Angles(math.rad(-120), 0, math.rad(8)),
        0.12,
        Enum.EasingStyle.Quint
    )
    if left and state.LeftBase then
        tweenJoint(
            left,
            state.LeftBase * CFrame.Angles(math.rad(-100), 0, math.rad(-8)),
            0.12,
            Enum.EasingStyle.Quint
        )
    end
    task.wait(0.1)
    restore(state, 0.22)
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

function CombatPresentation.PlayBasicAttack(familyId)
    local character = player.Character
    if not character then
        return
    end
    local state = joints(character)
    if not state then
        return
    end
    task.spawn(function()
        if familyId == "thornrunner" then
            bowShot(state)
        elseif familyId == "lumenweaver" then
            lumenCast(state)
        elseif familyId == "veilstrider" then
            crosscut(state)
        elseif familyId == "brasshand" then
            maulSwing(state)
        elseif familyId == "ironbloom" then
            meleeSwing(state, true)
        else
            meleeSwing(state, false)
        end
    end)
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
