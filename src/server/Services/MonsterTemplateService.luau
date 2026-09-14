local ServerStorage = game:GetService("ServerStorage")

local MonsterConfig = require(script.Parent.Parent.Content.MonsterConfig)

local MonsterTemplateService = {}

local function makePart(model, name, size, color, material, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Shape = shape or Enum.PartType.Block
    part.Anchored = false
    part.CanCollide = false
    part.CanTouch = false
    part.Massless = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = model
    return part
end

local function makeMotor(root, part, name, offset, rotation)
    part.CFrame = root.CFrame * CFrame.new(offset) * (rotation or CFrame.new())
    local motor = Instance.new("Motor6D")
    motor.Name = name
    motor.Part0 = root
    motor.Part1 = part
    motor.C0 = CFrame.new(offset) * (rotation or CFrame.new())
    motor.Parent = root
    return motor
end

local function makeBase(templateName, displayName, rootSize, hipHeight)
    local model = Instance.new("Model")
    model.Name = templateName

    local root = makePart(
        model,
        "HumanoidRootPart",
        rootSize,
        Color3.new(0, 0, 0),
        Enum.Material.SmoothPlastic
    )
    root.Transparency = 1
    root.CanCollide = true
    root.CanTouch = true
    root.Massless = false
    root.Anchored = true
    root.CFrame = CFrame.new(0, 5, 0)

    local humanoid = Instance.new("Humanoid")
    humanoid.DisplayName = displayName
    humanoid.RequiresNeck = false
    humanoid.HipHeight = hipHeight
    humanoid.AutoRotate = false
    humanoid.BreakJointsOnDeath = false
    humanoid.Parent = model

    model.PrimaryPart = root
    return model, root, humanoid
end

local function buildTrainingDummy()
    local definition = MonsterConfig.Get("training_dummy")
    local model, root =
        makeBase(definition.TemplateName, definition.DisplayName, Vector3.new(2, 3, 1.5), 0)
    local body = makePart(
        model,
        "Body",
        Vector3.new(2.5, 4, 1.5),
        Color3.fromRGB(169, 120, 79),
        Enum.Material.Wood
    )
    makeMotor(root, body, "BodyJoint", Vector3.new(0, 0.5, 0))
    return model
end

local function buildMossling()
    local definition = MonsterConfig.Get("lumen_mossling")
    local model, root =
        makeBase(definition.TemplateName, definition.DisplayName, Vector3.new(2.5, 2.5, 2.5), 1.1)
    model:SetAttribute("AgentRadius", 2)
    model:SetAttribute("AgentHeight", 4)

    local body = makePart(
        model,
        "Body",
        Vector3.new(3.8, 2.8, 3.5),
        Color3.fromRGB(74, 126, 70),
        Enum.Material.Grass,
        Enum.PartType.Ball
    )
    makeMotor(root, body, "BodyJoint", Vector3.new(0, 0.3, 0))
    local head = makePart(
        model,
        "Head",
        Vector3.new(2.8, 1.35, 2.8),
        Color3.fromRGB(101, 154, 78),
        Enum.Material.Grass,
        Enum.PartType.Ball
    )
    makeMotor(root, head, "HeadJoint", Vector3.new(0, 1.65, 0))

    for _, x in { -0.65, 0.65 } do
        local eye = makePart(
            model,
            if x < 0 then "EyeLeft" else "EyeRight",
            Vector3.new(0.34, 0.34, 0.2),
            Color3.fromRGB(176, 255, 218),
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
        makeMotor(
            root,
            eye,
            if x < 0 then "EyeLeftJoint" else "EyeRightJoint",
            Vector3.new(x, 0.65, -1.55)
        )
    end
    return model
end

local function buildSkeleton()
    local definition = MonsterConfig.Get("skeleton")
    local model, root =
        makeBase(definition.TemplateName, definition.DisplayName, Vector3.new(2.2, 4.8, 1.8), 1.7)
    model:SetAttribute("AgentRadius", 2)
    model:SetAttribute("AgentHeight", 6)
    local bone = Color3.fromRGB(221, 216, 188)
    local darkBone = Color3.fromRGB(174, 169, 145)

    local torso =
        makePart(model, "Torso", Vector3.new(2.2, 2.2, 0.9), darkBone, Enum.Material.SmoothPlastic)
    makeMotor(root, torso, "BodyJoint", Vector3.new(0, 0.5, 0))
    for rib = -1, 1 do
        local ribPart = makePart(model, "Rib", Vector3.new(2.7, 0.18, 0.35), bone)
        makeMotor(
            root,
            ribPart,
            "RibJoint" .. tostring(rib + 2),
            Vector3.new(0, 0.55 + rib * 0.48, -0.15)
        )
    end
    local spine = makePart(model, "Spine", Vector3.new(0.32, 2.7, 0.32), bone)
    makeMotor(root, spine, "SpineJoint", Vector3.new(0, 0.35, 0.2))
    local head = makePart(
        model,
        "Head",
        Vector3.new(1.65, 1.6, 1.55),
        bone,
        Enum.Material.SmoothPlastic,
        Enum.PartType.Ball
    )
    makeMotor(root, head, "HeadJoint", Vector3.new(0, 2.2, 0))

    for _, side in { -1, 1 } do
        local arm = makePart(
            model,
            side < 0 and "LeftArm" or "RightArm",
            Vector3.new(0.45, 2.5, 0.45),
            bone
        )
        makeMotor(
            root,
            arm,
            side < 0 and "LeftShoulder" or "RightShoulder",
            Vector3.new(side * 1.55, 0.55, 0)
        )
        local leg = makePart(
            model,
            side < 0 and "LeftLeg" or "RightLeg",
            Vector3.new(0.55, 2.9, 0.58),
            bone
        )
        makeMotor(
            root,
            leg,
            side < 0 and "LeftHip" or "RightHip",
            Vector3.new(side * 0.65, -2.0, 0)
        )
    end

    local blade = makePart(
        model,
        "Rustblade",
        Vector3.new(0.28, 3.4, 0.55),
        Color3.fromRGB(113, 116, 108),
        Enum.Material.Metal
    )
    makeMotor(
        root,
        blade,
        "WeaponJoint",
        Vector3.new(2.0, -0.5, -0.15),
        CFrame.Angles(0, 0, math.rad(-18))
    )

    local jaw = makePart(model, "Jaw", Vector3.new(1.25, 0.35, 1.05), darkBone)
    makeMotor(root, jaw, "JawJoint", Vector3.new(0, 1.62, -0.18), CFrame.Angles(math.rad(8), 0, 0))
    local pelvis = makePart(model, "Pelvis", Vector3.new(1.8, 0.55, 0.72), darkBone)
    makeMotor(root, pelvis, "PelvisJoint", Vector3.new(0, -0.95, 0))
    for _, side in { -1, 1 } do
        local eye = makePart(
            model,
            side < 0 and "LeftEyeGlow" or "RightEyeGlow",
            Vector3.new(0.26, 0.22, 0.12),
            Color3.fromRGB(115, 224, 189),
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
        makeMotor(
            root,
            eye,
            side < 0 and "LeftEyeGlowJoint" or "RightEyeGlowJoint",
            Vector3.new(side * 0.38, 2.3, -0.75)
        )
        local shoulderGuard = makePart(
            model,
            side < 0 and "LeftShoulderGuard" or "RightShoulderGuard",
            Vector3.new(0.9, 0.55, 0.9),
            Color3.fromRGB(73, 91, 82),
            Enum.Material.Metal,
            Enum.PartType.Ball
        )
        makeMotor(
            root,
            shoulderGuard,
            side < 0 and "LeftGuardJoint" or "RightGuardJoint",
            Vector3.new(side * 1.55, 1.15, 0.02)
        )
    end
    return model
end

local function buildSlime()
    local definition = MonsterConfig.Get("slime")
    local model, root =
        makeBase(definition.TemplateName, definition.DisplayName, Vector3.new(3.2, 2.1, 3.2), 0.9)
    model:SetAttribute("AgentRadius", 2.2)
    model:SetAttribute("AgentHeight", 3.5)

    local body = makePart(
        model,
        "Body",
        Vector3.new(4.6, 3.1, 4.4),
        Color3.fromRGB(89, 190, 126),
        Enum.Material.Glass,
        Enum.PartType.Ball
    )
    body.Transparency = 0.12
    makeMotor(root, body, "BodyJoint", Vector3.new(0, 0.25, 0))
    local belly = makePart(
        model,
        "BellyGlow",
        Vector3.new(3.1, 1.3, 3.0),
        Color3.fromRGB(123, 238, 167),
        Enum.Material.Neon,
        Enum.PartType.Ball
    )
    belly.Transparency = 0.28
    makeMotor(root, belly, "BellyJoint", Vector3.new(0, -0.2, 0))
    for _, x in { -0.72, 0.72 } do
        local eye = makePart(
            model,
            x < 0 and "EyeLeft" or "EyeRight",
            Vector3.new(0.42, 0.52, 0.25),
            Color3.fromRGB(28, 52, 44),
            Enum.Material.SmoothPlastic,
            Enum.PartType.Ball
        )
        makeMotor(
            root,
            eye,
            x < 0 and "EyeLeftJoint" or "EyeRightJoint",
            Vector3.new(x, 0.55, -2.03)
        )
    end

    local mouth = makePart(
        model,
        "Mouth",
        Vector3.new(0.9, 0.18, 0.16),
        Color3.fromRGB(45, 82, 61),
        Enum.Material.SmoothPlastic
    )
    makeMotor(root, mouth, "MouthJoint", Vector3.new(0, -0.1, -2.08))
    for index, offset in
        {
            Vector3.new(-1.05, 1.55, -0.2),
            Vector3.new(0.15, 1.95, 0.35),
            Vector3.new(1.0, 1.5, -0.1),
        }
    do
        local cap = makePart(
            model,
            "Glowcap" .. index,
            Vector3.new(0.9, 0.38, 0.9),
            if index == 2 then Color3.fromRGB(166, 118, 196) else Color3.fromRGB(126, 201, 142),
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
        cap.Transparency = 0.06
        makeMotor(root, cap, "GlowcapJoint" .. index, offset)
    end
    return model
end

local function buildPecoPeco()
    local definition = MonsterConfig.Get("peco_peco")
    local model, root =
        makeBase(definition.TemplateName, definition.DisplayName, Vector3.new(3.2, 4.4, 4.2), 1.8)
    model:SetAttribute("AgentRadius", 2.4)
    model:SetAttribute("AgentHeight", 6)
    local feather = Color3.fromRGB(201, 126, 57)
    local featherDark = Color3.fromRGB(137, 79, 43)
    local cream = Color3.fromRGB(232, 205, 139)

    local body = makePart(
        model,
        "Body",
        Vector3.new(4.8, 3.7, 5.2),
        feather,
        Enum.Material.SmoothPlastic,
        Enum.PartType.Ball
    )
    makeMotor(root, body, "BodyJoint", Vector3.new(0, 0.45, 0.2))
    local neck = makePart(
        model,
        "Neck",
        Vector3.new(1.8, 3.4, 1.8),
        featherDark,
        Enum.Material.SmoothPlastic
    )
    makeMotor(
        root,
        neck,
        "NeckJoint",
        Vector3.new(0, 2.4, -1.05),
        CFrame.Angles(math.rad(-16), 0, 0)
    )
    local head = makePart(
        model,
        "Head",
        Vector3.new(2.5, 2.2, 2.7),
        cream,
        Enum.Material.SmoothPlastic,
        Enum.PartType.Ball
    )
    makeMotor(root, head, "HeadJoint", Vector3.new(0, 4.1, -2.0))
    local beak = makePart(
        model,
        "Beak",
        Vector3.new(1.0, 0.85, 2.2),
        Color3.fromRGB(224, 174, 64),
        Enum.Material.SmoothPlastic
    )
    makeMotor(root, beak, "BeakJoint", Vector3.new(0, 3.9, -3.6), CFrame.Angles(math.rad(-5), 0, 0))

    for _, side in { -1, 1 } do
        local wing = makePart(
            model,
            side < 0 and "LeftWing" or "RightWing",
            Vector3.new(1.0, 2.7, 3.8),
            featherDark,
            Enum.Material.SmoothPlastic
        )
        makeMotor(
            root,
            wing,
            side < 0 and "LeftShoulder" or "RightShoulder",
            Vector3.new(side * 2.35, 0.6, 0.3),
            CFrame.Angles(0, 0, math.rad(side * 18))
        )
        local leg = makePart(
            model,
            side < 0 and "LeftLeg" or "RightLeg",
            Vector3.new(0.65, 3.3, 0.7),
            cream,
            Enum.Material.SmoothPlastic
        )
        makeMotor(
            root,
            leg,
            side < 0 and "LeftHip" or "RightHip",
            Vector3.new(side * 1.05, -2.5, 0.45)
        )
        local foot = makePart(
            model,
            side < 0 and "LeftFoot" or "RightFoot",
            Vector3.new(1.1, 0.45, 1.8),
            Color3.fromRGB(194, 145, 52),
            Enum.Material.SmoothPlastic
        )
        makeMotor(
            root,
            foot,
            side < 0 and "LeftFootJoint" or "RightFootJoint",
            Vector3.new(side * 1.05, -4.0, -0.2)
        )
    end

    local tail = makePart(
        model,
        "Tail",
        Vector3.new(2.4, 1.4, 4.0),
        featherDark,
        Enum.Material.SmoothPlastic
    )
    makeMotor(root, tail, "TailJoint", Vector3.new(0, 0.8, 3.4), CFrame.Angles(math.rad(18), 0, 0))

    for _, side in { -1, 1 } do
        local eye = makePart(
            model,
            side < 0 and "LeftEye" or "RightEye",
            Vector3.new(0.28, 0.32, 0.18),
            Color3.fromRGB(35, 40, 35),
            Enum.Material.SmoothPlastic,
            Enum.PartType.Ball
        )
        makeMotor(
            root,
            eye,
            side < 0 and "LeftEyeJoint" or "RightEyeJoint",
            Vector3.new(side * 0.62, 4.35, -3.05)
        )
        local talon = makePart(
            model,
            side < 0 and "LeftTalon" or "RightTalon",
            Vector3.new(0.22, 0.28, 1.0),
            Color3.fromRGB(92, 77, 48),
            Enum.Material.SmoothPlastic
        )
        makeMotor(
            root,
            talon,
            side < 0 and "LeftTalonJoint" or "RightTalonJoint",
            Vector3.new(side * 1.05, -4.05, -1.05),
            CFrame.Angles(0, 0, math.rad(side * 5))
        )
        for featherIndex = 1, 2 do
            local layer = makePart(
                model,
                string.format("%sWingFeather%d", side < 0 and "Left" or "Right", featherIndex),
                Vector3.new(0.42, 1.2 + featherIndex * 0.25, 3.1),
                if featherIndex == 1 then featherDark else feather,
                Enum.Material.SmoothPlastic
            )
            makeMotor(
                root,
                layer,
                string.format("%sWingFeatherJoint%d", side < 0 and "Left" or "Right", featherIndex),
                Vector3.new(side * (2.55 + featherIndex * 0.18), 0.35 - featherIndex * 0.25, 0.55),
                CFrame.Angles(
                    math.rad(featherIndex * 5),
                    0,
                    math.rad(side * (22 + featherIndex * 7))
                )
            )
        end
    end

    for crestIndex = 1, 3 do
        local crest = makePart(
            model,
            "Crest" .. crestIndex,
            Vector3.new(0.3, 1.3 + crestIndex * 0.22, 0.5),
            Color3.fromRGB(151, 66 + crestIndex * 12, 48),
            Enum.Material.SmoothPlastic
        )
        makeMotor(
            root,
            crest,
            "CrestJoint" .. crestIndex,
            Vector3.new(
                (crestIndex - 2) * 0.42,
                5.35 + math.abs(crestIndex - 2) * 0.1,
                -2.0 + crestIndex * 0.12
            ),
            CFrame.Angles(math.rad(-22), 0, math.rad((crestIndex - 2) * 8))
        )
    end
    return model
end

local function buildBrambleback()
    local definition = MonsterConfig.Get("brambleback")
    local model, root =
        makeBase(definition.TemplateName, definition.DisplayName, Vector3.new(3.5, 3.5, 5.2), 1.2)
    model:SetAttribute("AgentRadius", 2.5)
    model:SetAttribute("AgentHeight", 4.5)
    local bark = Color3.fromRGB(92, 70, 48)
    local moss = Color3.fromRGB(72, 118, 69)
    local thorn = Color3.fromRGB(119, 96, 62)

    local body = makePart(
        model,
        "Body",
        Vector3.new(5.4, 3.4, 6.1),
        bark,
        Enum.Material.Wood,
        Enum.PartType.Ball
    )
    makeMotor(root, body, "BodyJoint", Vector3.new(0, 0.25, 0))
    local head = makePart(
        model,
        "Head",
        Vector3.new(3.3, 2.7, 3.4),
        moss,
        Enum.Material.Grass,
        Enum.PartType.Ball
    )
    makeMotor(root, head, "HeadJoint", Vector3.new(0, 0.65, -3.45))

    for _, spec in
        {
            { "FrontLeft", -1.6, -1.55 },
            { "FrontRight", 1.6, -1.55 },
            { "BackLeft", -1.6, 1.75 },
            { "BackRight", 1.6, 1.75 },
        }
    do
        local leg =
            makePart(model, spec[1] .. "Leg", Vector3.new(0.8, 2.4, 0.9), bark, Enum.Material.Wood)
        makeMotor(root, leg, spec[1] .. "Hip", Vector3.new(spec[2], -1.95, spec[3]))
    end

    for index = 1, 5 do
        local spine = makePart(
            model,
            "Thorn" .. index,
            Vector3.new(0.45, 2.2, 0.45),
            thorn,
            Enum.Material.Wood
        )
        makeMotor(
            root,
            spine,
            "ThornJoint" .. index,
            Vector3.new(0, 2.0, -1.5 + index * 0.75),
            CFrame.Angles(math.rad(-12 + index * 5), 0, math.rad((index % 2 == 0 and 1 or -1) * 6))
        )
    end
    return model
end

local function buildWisp()
    local definition = MonsterConfig.Get("lumen_wisp")
    local model, root =
        makeBase(definition.TemplateName, definition.DisplayName, Vector3.new(2.2, 2.2, 2.2), 2.6)
    model:SetAttribute("AgentRadius", 1.6)
    model:SetAttribute("AgentHeight", 4)
    local body = makePart(
        model,
        "Body",
        Vector3.new(3.1, 3.1, 3.1),
        Color3.fromRGB(104, 234, 210),
        Enum.Material.Neon,
        Enum.PartType.Ball
    )
    body.Transparency = 0.12
    makeMotor(root, body, "BodyJoint", Vector3.new(0, 0.5, 0))
    for index = 1, 3 do
        local tail = makePart(
            model,
            "WispTail" .. index,
            Vector3.new(0.5, 0.5, 2.3 + index * 0.4),
            Color3.fromRGB(76, 185, 181),
            Enum.Material.Neon
        )
        tail.Transparency = 0.22
        makeMotor(
            root,
            tail,
            "TailJoint" .. index,
            Vector3.new((index - 2) * 0.7, -0.5, 1.8 + index * 0.45),
            CFrame.Angles(math.rad(12 + index * 5), 0, math.rad((index - 2) * 8))
        )
    end
    local light = Instance.new("PointLight")
    light.Color = body.Color
    light.Brightness = 1.1
    light.Range = 10
    light.Parent = body
    return model
end

local function buildGraveboneCaptain()
    local definition = MonsterConfig.Get("gravebone_captain")
    local model = buildSkeleton()
    model.Name = definition.TemplateName
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayName = definition.DisplayName
    end
    model:ScaleTo(1.16)
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        local helm = makePart(
            model,
            "CaptainHelm",
            Vector3.new(2.0, 0.8, 1.9),
            Color3.fromRGB(77, 82, 78),
            Enum.Material.Metal
        )
        makeMotor(root, helm, "CaptainHelmJoint", Vector3.new(0, 3.0, 0))
        local plume = makePart(
            model,
            "CaptainPlume",
            Vector3.new(0.35, 1.5, 0.7),
            Color3.fromRGB(130, 52, 43),
            Enum.Material.Fabric
        )
        makeMotor(
            root,
            plume,
            "CaptainPlumeJoint",
            Vector3.new(0, 3.95, 0.2),
            CFrame.Angles(math.rad(-10), 0, 0)
        )
    end
    return model
end

local function buildRoyalGlowcap()
    local definition = MonsterConfig.Get("royal_glowcap")
    local model = buildSlime()
    model.Name = definition.TemplateName
    model:ScaleTo(1.32)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayName = definition.DisplayName
    end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        local crown = makePart(
            model,
            "RoyalCap",
            Vector3.new(2.8, 0.7, 2.8),
            Color3.fromRGB(184, 112, 205),
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
        crown.Transparency = 0.1
        makeMotor(root, crown, "RoyalCapJoint", Vector3.new(0, 2.35, 0))
    end
    return model
end

local function buildMosswarden()
    local definition = MonsterConfig.Get("mosswarden")
    local model = buildBrambleback()
    model.Name = definition.TemplateName
    model:ScaleTo(1.72)
    model:SetAttribute("AgentRadius", 3.8)
    model:SetAttribute("AgentHeight", 8)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayName = definition.DisplayName
    end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        for _, side in { -1, 1 } do
            local antler = makePart(
                model,
                side < 0 and "LeftAntler" or "RightAntler",
                Vector3.new(0.5, 4.2, 0.5),
                Color3.fromRGB(113, 86, 54),
                Enum.Material.Wood
            )
            makeMotor(
                root,
                antler,
                side < 0 and "LeftAntlerJoint" or "RightAntlerJoint",
                Vector3.new(side * 1.9, 2.4, -4.2),
                CFrame.Angles(math.rad(-18), 0, math.rad(side * 28))
            )
        end
        local core = makePart(
            model,
            "LumenCore",
            Vector3.new(1.25, 1.25, 1.25),
            Color3.fromRGB(92, 244, 197),
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
        makeMotor(root, core, "LumenCoreJoint", Vector3.new(0, 1.0, -3.4))
        local light = Instance.new("PointLight")
        light.Color = core.Color
        light.Brightness = 1.6
        light.Range = 14
        light.Parent = core
    end
    return model
end

local builders = {
    training_dummy = buildTrainingDummy,
    lumen_mossling = buildMossling,
    skeleton = buildSkeleton,
    slime = buildSlime,
    peco_peco = buildPecoPeco,
    brambleback = buildBrambleback,
    lumen_wisp = buildWisp,
    gravebone_captain = buildGraveboneCaptain,
    royal_glowcap = buildRoyalGlowcap,
    mosswarden = buildMosswarden,
}

function MonsterTemplateService.Init()
    local folder = ServerStorage:FindFirstChild("Monsters")
    if folder then
        folder:Destroy()
    end
    folder = Instance.new("Folder")
    folder.Name = "Monsters"
    folder.Parent = ServerStorage

    for monsterId, builder in builders do
        local model = builder()
        model:SetAttribute("MonsterId", monsterId)
        model.Parent = folder
    end
end

function MonsterTemplateService.Get(monsterId)
    local definition = MonsterConfig.Get(monsterId)
    local folder = ServerStorage:FindFirstChild("Monsters")
    if not definition or not folder then
        return nil
    end
    return folder:FindFirstChild(definition.TemplateName)
end

return MonsterTemplateService
