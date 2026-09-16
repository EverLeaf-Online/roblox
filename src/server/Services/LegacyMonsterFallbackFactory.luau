local MonsterConfig = require(script.Parent.Parent.Content.MonsterConfig)

local LegacyMonsterFallbackFactory = {}

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
        makeBase(definition.TemplateName, definition.DisplayName, Vector3.new(2, 3, 2), 0)

    local wood = Color3.fromRGB(112, 78, 48)
    local darkWood = Color3.fromRGB(78, 52, 34)
    local rope = Color3.fromRGB(172, 145, 101)
    local cloth = Color3.fromRGB(134, 119, 86)
    local target = Color3.fromRGB(177, 74, 59)

    local base =
        makePart(model, "WeightedBase", Vector3.new(4.2, 0.85, 3.6), darkWood, Enum.Material.Wood)
    makeMotor(root, base, "BaseJoint", Vector3.new(0, -3.55, 0))

    local post = makePart(
        model,
        "TrainingPost",
        Vector3.new(5.8, 0.85, 0.85),
        wood,
        Enum.Material.Wood,
        Enum.PartType.Cylinder
    )
    makeMotor(root, post, "PostJoint", Vector3.new(0, -0.45, 0), CFrame.Angles(0, 0, math.rad(90)))

    local crossbar = makePart(
        model,
        "Crossbar",
        Vector3.new(5.2, 0.68, 0.68),
        wood,
        Enum.Material.Wood,
        Enum.PartType.Cylinder
    )
    makeMotor(root, crossbar, "CrossbarJoint", Vector3.new(0, 0.65, 0), CFrame.Angles(0, 0, 0))

    for index, y in { -1.35, 0.72 } do
        local binding = makePart(
            model,
            "RopeBinding" .. index,
            Vector3.new(0.32, 1.05, 1.05),
            rope,
            Enum.Material.Fabric,
            Enum.PartType.Cylinder
        )
        makeMotor(root, binding, "RopeJoint" .. index, Vector3.new(0, y, 0), CFrame.new())
    end

    local head = makePart(
        model,
        "WrappedHead",
        Vector3.new(2.0, 1.75, 1.55),
        cloth,
        Enum.Material.Fabric,
        Enum.PartType.Ball
    )
    makeMotor(root, head, "HeadJoint", Vector3.new(0, 2.15, 0))

    local plate = makePart(
        model,
        "TargetPlate",
        Vector3.new(0.28, 2.25, 2.25),
        Color3.fromRGB(194, 170, 117),
        Enum.Material.Wood,
        Enum.PartType.Cylinder
    )
    makeMotor(
        root,
        plate,
        "TargetPlateJoint",
        Vector3.new(0, 0.05, -0.58),
        CFrame.Angles(0, math.rad(90), 0)
    )

    local bullseye = makePart(
        model,
        "Bullseye",
        Vector3.new(0.12, 0.92, 0.92),
        target,
        Enum.Material.SmoothPlastic,
        Enum.PartType.Cylinder
    )
    makeMotor(
        root,
        bullseye,
        "BullseyeJoint",
        Vector3.new(0, 0.05, -0.76),
        CFrame.Angles(0, math.rad(90), 0)
    )

    local stakeLeft = makePart(
        model,
        "LeftBrace",
        Vector3.new(3.0, 0.42, 0.42),
        darkWood,
        Enum.Material.Wood,
        Enum.PartType.Cylinder
    )
    makeMotor(
        root,
        stakeLeft,
        "LeftBraceJoint",
        Vector3.new(-1.1, -2.35, 0),
        CFrame.Angles(0, 0, math.rad(64))
    )
    local stakeRight = makePart(
        model,
        "RightBrace",
        Vector3.new(3.0, 0.42, 0.42),
        darkWood,
        Enum.Material.Wood,
        Enum.PartType.Cylinder
    )
    makeMotor(
        root,
        stakeRight,
        "RightBraceJoint",
        Vector3.new(1.1, -2.35, 0),
        CFrame.Angles(0, 0, math.rad(-64))
    )

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

local function buildRivetScuttler()
    local definition = MonsterConfig.Get("rivet_scuttler")
    local model, root =
        makeBase(definition.TemplateName, definition.DisplayName, Vector3.new(3.1, 2.3, 4.4), 0.9)
    model:SetAttribute("AgentRadius", 2.2)
    model:SetAttribute("AgentHeight", 3.8)

    local iron = Color3.fromRGB(73, 72, 68)
    local brass = Color3.fromRGB(151, 103, 48)
    local hot = Color3.fromRGB(241, 135, 59)

    local body =
        makePart(model, "Body", Vector3.new(4.7, 2.0, 5.0), iron, Enum.Material.DiamondPlate)
    makeMotor(root, body, "BodyJoint", Vector3.new(0, 0.2, 0))

    local shell = makePart(
        model,
        "Shell",
        Vector3.new(3.9, 1.1, 3.8),
        brass,
        Enum.Material.Metal,
        Enum.PartType.Ball
    )
    makeMotor(root, shell, "ShellJoint", Vector3.new(0, 1.0, 0.25))

    local head = makePart(model, "Head", Vector3.new(2.4, 1.3, 2.2), iron, Enum.Material.Metal)
    makeMotor(root, head, "HeadJoint", Vector3.new(0, 0.25, -3.0))

    for _, spec in
        {
            { "FrontLeft", -1.55, -1.55 },
            { "FrontRight", 1.55, -1.55 },
            { "BackLeft", -1.55, 1.6 },
            { "BackRight", 1.55, 1.6 },
        }
    do
        local leg = makePart(
            model,
            spec[1] .. "Leg",
            Vector3.new(0.48, 2.0, 0.55),
            brass,
            Enum.Material.Metal
        )
        makeMotor(root, leg, spec[1] .. "Hip", Vector3.new(spec[2], -1.35, spec[3]))
        local foot = makePart(
            model,
            spec[1] .. "Foot",
            Vector3.new(0.9, 0.35, 1.0),
            iron,
            Enum.Material.DiamondPlate
        )
        makeMotor(root, foot, spec[1] .. "FootJoint", Vector3.new(spec[2], -2.15, spec[3] - 0.15))
    end

    for _, side in { -1, 1 } do
        local eye = makePart(
            model,
            side < 0 and "LeftEye" or "RightEye",
            Vector3.new(0.28, 0.28, 0.15),
            hot,
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
        makeMotor(
            root,
            eye,
            side < 0 and "LeftEyeJoint" or "RightEyeJoint",
            Vector3.new(side * 0.52, 0.45, -4.08)
        )
    end

    local cutter = makePart(
        model,
        "RivetCutter",
        Vector3.new(0.38, 0.38, 2.3),
        Color3.fromRGB(112, 112, 106),
        Enum.Material.Metal
    )
    makeMotor(
        root,
        cutter,
        "WeaponJoint",
        Vector3.new(0, -0.25, -4.0),
        CFrame.Angles(math.rad(90), 0, 0)
    )
    return model
end

local function buildSlagmite()
    local definition = MonsterConfig.Get("slagmite")
    local model, root =
        makeBase(definition.TemplateName, definition.DisplayName, Vector3.new(3.0, 2.8, 3.0), 1.1)
    model:SetAttribute("AgentRadius", 2.3)
    model:SetAttribute("AgentHeight", 4.5)

    local crust = Color3.fromRGB(61, 58, 54)
    local slag = Color3.fromRGB(103, 73, 48)
    local molten = Color3.fromRGB(255, 121, 43)

    local body = makePart(
        model,
        "Body",
        Vector3.new(4.8, 3.6, 4.5),
        slag,
        Enum.Material.Basalt,
        Enum.PartType.Ball
    )
    makeMotor(root, body, "BodyJoint", Vector3.new(0, 0.3, 0))

    for index, offset in
        {
            Vector3.new(-1.1, 0.7, -1.65),
            Vector3.new(1.0, 0.15, -1.9),
            Vector3.new(-0.4, 1.15, 1.8),
            Vector3.new(1.35, -0.35, 1.2),
        }
    do
        local plate = makePart(
            model,
            "CrustPlate" .. tostring(index),
            Vector3.new(1.5, 0.55, 1.15),
            crust,
            Enum.Material.Basalt
        )
        makeMotor(
            root,
            plate,
            "CrustJoint" .. tostring(index),
            offset,
            CFrame.Angles(math.rad(index * 11), math.rad(index * 37), math.rad(index * 7))
        )
    end

    local core = makePart(
        model,
        "MoltenCore",
        Vector3.new(1.45, 1.45, 1.45),
        molten,
        Enum.Material.Neon,
        Enum.PartType.Ball
    )
    core.Transparency = 0.05
    makeMotor(root, core, "CoreJoint", Vector3.new(0, 0.35, -2.05))
    local light = Instance.new("PointLight")
    light.Color = molten
    light.Brightness = 1.25
    light.Range = 10
    light.Parent = core

    for _, side in { -1, 1 } do
        local eye = makePart(
            model,
            side < 0 and "LeftEye" or "RightEye",
            Vector3.new(0.24, 0.24, 0.14),
            Color3.fromRGB(255, 203, 102),
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
        makeMotor(
            root,
            eye,
            side < 0 and "LeftEyeJoint" or "RightEyeJoint",
            Vector3.new(side * 0.48, 0.7, -2.43)
        )
    end
    return model
end

local function buildGearjawHound()
    local definition = MonsterConfig.Get("gearjaw_hound")
    local model, root =
        makeBase(definition.TemplateName, definition.DisplayName, Vector3.new(3.2, 2.8, 5.2), 1.0)
    model:SetAttribute("AgentRadius", 2.3)
    model:SetAttribute("AgentHeight", 4.2)

    local iron = Color3.fromRGB(67, 67, 64)
    local brass = Color3.fromRGB(150, 101, 48)
    local tooth = Color3.fromRGB(181, 181, 169)
    local ember = Color3.fromRGB(242, 124, 54)

    local body =
        makePart(model, "Body", Vector3.new(4.9, 2.6, 6.0), iron, Enum.Material.DiamondPlate)
    makeMotor(root, body, "BodyJoint", Vector3.new(0, 0.3, 0))

    local shoulderShell = makePart(
        model,
        "ShoulderShell",
        Vector3.new(4.3, 1.4, 3.4),
        brass,
        Enum.Material.Metal,
        Enum.PartType.Ball
    )
    makeMotor(root, shoulderShell, "ShoulderShellJoint", Vector3.new(0, 1.25, -0.55))

    local head = makePart(model, "Head", Vector3.new(2.8, 1.8, 2.8), iron, Enum.Material.Metal)
    makeMotor(root, head, "HeadJoint", Vector3.new(0, 0.6, -3.9))

    local muzzle =
        makePart(model, "Muzzle", Vector3.new(2.2, 1.0, 1.45), brass, Enum.Material.Metal)
    makeMotor(root, muzzle, "MuzzleJoint", Vector3.new(0, 0.2, -5.0))

    for index, side in { -1, 1 } do
        local eye = makePart(
            model,
            side < 0 and "LeftEye" or "RightEye",
            Vector3.new(0.28, 0.28, 0.15),
            ember,
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
        makeMotor(
            root,
            eye,
            side < 0 and "LeftEyeJoint" or "RightEyeJoint",
            Vector3.new(side * 0.58, 0.83, -5.0)
        )
        for toothIndex = 1, 3 do
            local jawTooth = makePart(
                model,
                string.format("JawTooth%d_%d", index, toothIndex),
                Vector3.new(0.22, 0.6, 0.22),
                tooth,
                Enum.Material.Metal
            )
            makeMotor(
                root,
                jawTooth,
                string.format("JawToothJoint%d_%d", index, toothIndex),
                Vector3.new(side * (0.34 + toothIndex * 0.19), -0.35, -5.72),
                CFrame.Angles(math.rad(-16), 0, math.rad(side * 9))
            )
        end
    end

    for _, spec in
        {
            { "FrontLeft", -1.65, -1.65 },
            { "FrontRight", 1.65, -1.65 },
            { "BackLeft", -1.65, 1.8 },
            { "BackRight", 1.65, 1.8 },
        }
    do
        local leg = makePart(
            model,
            spec[1] .. "Leg",
            Vector3.new(0.58, 2.25, 0.62),
            brass,
            Enum.Material.Metal
        )
        makeMotor(root, leg, spec[1] .. "Hip", Vector3.new(spec[2], -1.55, spec[3]))
    end

    local tail = makePart(model, "Tail", Vector3.new(0.46, 0.46, 3.2), brass, Enum.Material.Metal)
    makeMotor(root, tail, "TailJoint", Vector3.new(0, 0.7, 3.9), CFrame.Angles(math.rad(-18), 0, 0))
    return model
end

local function buildCindercoil()
    local definition = MonsterConfig.Get("cindercoil")
    local model, root =
        makeBase(definition.TemplateName, definition.DisplayName, Vector3.new(2.3, 2.3, 2.3), 2.9)
    model:SetAttribute("AgentRadius", 1.7)
    model:SetAttribute("AgentHeight", 4.2)

    local copper = Color3.fromRGB(164, 91, 47)
    local dark = Color3.fromRGB(68, 59, 53)
    local ember = Color3.fromRGB(255, 116, 45)

    local body = makePart(
        model,
        "Body",
        Vector3.new(3.2, 3.2, 3.2),
        dark,
        Enum.Material.Metal,
        Enum.PartType.Ball
    )
    makeMotor(root, body, "BodyJoint", Vector3.new(0, 0.55, 0))

    local core = makePart(
        model,
        "EmberCore",
        Vector3.new(1.6, 1.6, 1.6),
        ember,
        Enum.Material.Neon,
        Enum.PartType.Ball
    )
    core.Transparency = 0.06
    makeMotor(root, core, "CoreJoint", Vector3.new(0, 0.55, -1.5))

    for index = 1, 4 do
        local ring = makePart(
            model,
            "CoilRing" .. tostring(index),
            Vector3.new(0.35, 3.8 + index * 0.15, 3.8 + index * 0.15),
            copper,
            Enum.Material.Metal
        )
        ring.Shape = Enum.PartType.Cylinder
        makeMotor(
            root,
            ring,
            "CoilRingJoint" .. tostring(index),
            Vector3.new(0, 0.5, 0.15 + index * 0.08),
            CFrame.Angles(0, 0, math.rad(90 + index * 13))
        )
    end

    for index = 1, 3 do
        local tail = makePart(
            model,
            "WispTail" .. index,
            Vector3.new(0.45, 0.45, 2.4 + index * 0.55),
            copper,
            Enum.Material.Metal
        )
        makeMotor(
            root,
            tail,
            "TailJoint" .. index,
            Vector3.new((index - 2) * 0.65, -0.45, 2.0 + index * 0.5),
            CFrame.Angles(math.rad(16 + index * 6), 0, math.rad((index - 2) * 11))
        )
    end

    local light = Instance.new("PointLight")
    light.Color = ember
    light.Brightness = 1.5
    light.Range = 12
    light.Parent = core
    return model
end

local function buildPressureBastion()
    local definition = MonsterConfig.Get("pressure_bastion")
    local model = buildRivetScuttler()
    model.Name = definition.TemplateName
    model:ScaleTo(1.48)
    model:SetAttribute("AgentRadius", 3.1)
    model:SetAttribute("AgentHeight", 5.5)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayName = definition.DisplayName
    end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        local tank = makePart(
            model,
            "PressureTank",
            Vector3.new(2.3, 3.8, 2.3),
            Color3.fromRGB(92, 84, 72),
            Enum.Material.Metal,
            Enum.PartType.Cylinder
        )
        makeMotor(
            root,
            tank,
            "PressureTankJoint",
            Vector3.new(0, 2.0, 0.8),
            CFrame.Angles(0, 0, math.rad(90))
        )
        local gauge = makePart(
            model,
            "PressureGauge",
            Vector3.new(1.3, 1.3, 0.28),
            Color3.fromRGB(227, 195, 125),
            Enum.Material.Metal,
            Enum.PartType.Cylinder
        )
        makeMotor(
            root,
            gauge,
            "GaugeJoint",
            Vector3.new(0, 2.1, -1.35),
            CFrame.Angles(0, math.rad(90), 0)
        )
        local warning = makePart(
            model,
            "WarningCore",
            Vector3.new(0.8, 0.8, 0.8),
            Color3.fromRGB(255, 83, 42),
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
        makeMotor(root, warning, "WarningCoreJoint", Vector3.new(0, 0.8, -3.9))
        local light = Instance.new("PointLight")
        light.Color = warning.Color
        light.Brightness = 1.7
        light.Range = 14
        light.Parent = warning
    end
    return model
end

local function buildFurnaceHusk()
    local definition = MonsterConfig.Get("furnace_husk")
    local model, root =
        makeBase(definition.TemplateName, definition.DisplayName, Vector3.new(2.4, 4.8, 2.0), 1.75)
    model:SetAttribute("AgentRadius", 2.1)
    model:SetAttribute("AgentHeight", 6.2)

    local iron = Color3.fromRGB(70, 67, 62)
    local brass = Color3.fromRGB(143, 97, 49)
    local ember = Color3.fromRGB(248, 116, 45)

    local torso =
        makePart(model, "Torso", Vector3.new(2.7, 2.7, 1.5), iron, Enum.Material.DiamondPlate)
    makeMotor(root, torso, "BodyJoint", Vector3.new(0, 0.55, 0))
    local furnace =
        makePart(model, "ChestFurnace", Vector3.new(1.55, 1.4, 0.35), ember, Enum.Material.Neon)
    makeMotor(root, furnace, "ChestFurnaceJoint", Vector3.new(0, 0.65, -0.93))
    local head = makePart(model, "Head", Vector3.new(1.7, 1.55, 1.55), iron, Enum.Material.Metal)
    makeMotor(root, head, "HeadJoint", Vector3.new(0, 2.45, 0))

    for _, side in { -1, 1 } do
        local arm = makePart(
            model,
            side < 0 and "LeftArm" or "RightArm",
            Vector3.new(0.62, 2.8, 0.72),
            brass,
            Enum.Material.Metal
        )
        makeMotor(
            root,
            arm,
            side < 0 and "LeftShoulder" or "RightShoulder",
            Vector3.new(side * 1.7, 0.55, 0)
        )
        local leg = makePart(
            model,
            side < 0 and "LeftLeg" or "RightLeg",
            Vector3.new(0.72, 3.0, 0.82),
            iron,
            Enum.Material.Metal
        )
        makeMotor(root, leg, side < 0 and "LeftHip" or "RightHip", Vector3.new(side * 0.7, -2.0, 0))
        local eye = makePart(
            model,
            side < 0 and "LeftEye" or "RightEye",
            Vector3.new(0.22, 0.22, 0.12),
            ember,
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
        makeMotor(
            root,
            eye,
            side < 0 and "LeftEyeJoint" or "RightEyeJoint",
            Vector3.new(side * 0.38, 2.62, -0.79)
        )
    end

    local smokestack =
        makePart(model, "Smokestack", Vector3.new(0.72, 2.6, 0.72), iron, Enum.Material.Metal)
    makeMotor(root, smokestack, "SmokestackJoint", Vector3.new(0.9, 2.35, 0.35))
    local smoke = Instance.new("Smoke")
    smoke.Color = Color3.fromRGB(89, 83, 77)
    smoke.Opacity = 0.16
    smoke.RiseVelocity = 2.5
    smoke.Size = 2.2
    smoke.Parent = smokestack
    return model
end

local function buildArcSiphon()
    local definition = MonsterConfig.Get("arc_siphon")
    local model, root =
        makeBase(definition.TemplateName, definition.DisplayName, Vector3.new(2.4, 2.4, 2.4), 3.0)
    model:SetAttribute("AgentRadius", 1.7)
    model:SetAttribute("AgentHeight", 4.3)

    local steel = Color3.fromRGB(75, 82, 87)
    local copper = Color3.fromRGB(154, 98, 53)
    local arc = Color3.fromRGB(103, 208, 255)

    local body = makePart(
        model,
        "Body",
        Vector3.new(3.4, 3.4, 3.4),
        steel,
        Enum.Material.Metal,
        Enum.PartType.Ball
    )
    makeMotor(root, body, "BodyJoint", Vector3.new(0, 0.55, 0))
    local core = makePart(
        model,
        "ArcCore",
        Vector3.new(1.55, 1.55, 1.55),
        arc,
        Enum.Material.Neon,
        Enum.PartType.Ball
    )
    core.Transparency = 0.04
    makeMotor(root, core, "CoreJoint", Vector3.new(0, 0.55, -1.65))

    for index = 1, 3 do
        local tail = makePart(
            model,
            "WispTail" .. index,
            Vector3.new(0.44, 0.44, 2.8 + index * 0.55),
            copper,
            Enum.Material.Metal
        )
        makeMotor(
            root,
            tail,
            "TailJoint" .. index,
            Vector3.new((index - 2) * 0.7, -0.45, 2.15 + index * 0.55),
            CFrame.Angles(math.rad(14 + index * 6), 0, math.rad((index - 2) * 13))
        )
    end

    for index = 1, 4 do
        local prong = makePart(
            model,
            "SiphonProng" .. tostring(index),
            Vector3.new(0.28, 2.1, 0.28),
            copper,
            Enum.Material.Metal
        )
        local angle = (index - 1) * math.pi / 2
        makeMotor(
            root,
            prong,
            "SiphonProngJoint" .. tostring(index),
            Vector3.new(math.cos(angle) * 1.75, 0.65, math.sin(angle) * 1.75),
            CFrame.Angles(math.rad(22), 0, -angle)
        )
    end

    local light = Instance.new("PointLight")
    light.Color = arc
    light.Brightness = 1.7
    light.Range = 13
    light.Parent = core
    return model
end

local function buildRailbreaker()
    local definition = MonsterConfig.Get("railbreaker")
    local model = buildGearjawHound()
    model.Name = definition.TemplateName
    model:ScaleTo(1.55)
    model:SetAttribute("AgentRadius", 3.3)
    model:SetAttribute("AgentHeight", 6.0)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayName = definition.DisplayName
    end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        local plow = makePart(
            model,
            "RailPlow",
            Vector3.new(6.8, 2.4, 1.0),
            Color3.fromRGB(85, 82, 76),
            Enum.Material.DiamondPlate
        )
        makeMotor(
            root,
            plow,
            "RailPlowJoint",
            Vector3.new(0, -0.25, -5.9),
            CFrame.Angles(math.rad(-10), 0, 0)
        )
        for _, side in { -1, 1 } do
            local lamp = makePart(
                model,
                side < 0 and "LeftWarningLamp" or "RightWarningLamp",
                Vector3.new(0.7, 0.7, 0.5),
                Color3.fromRGB(255, 85, 42),
                Enum.Material.Neon,
                Enum.PartType.Ball
            )
            makeMotor(
                root,
                lamp,
                side < 0 and "LeftWarningLampJoint" or "RightWarningLampJoint",
                Vector3.new(side * 2.15, 1.45, -4.8)
            )
        end
        local authority = makePart(
            model,
            "AuthorityPlate",
            Vector3.new(2.8, 1.5, 0.25),
            Color3.fromRGB(187, 134, 65),
            Enum.Material.Metal
        )
        makeMotor(root, authority, "AuthorityPlateJoint", Vector3.new(0, 2.2, -3.6))
    end
    return model
end

local function buildBlueflameSentry()
    local definition = MonsterConfig.Get("blueflame_sentry")
    local model = buildArcSiphon()
    model.Name = definition.TemplateName
    model:ScaleTo(1.08)
    model:SetAttribute("AgentRadius", 1.8)
    model:SetAttribute("AgentHeight", 4.5)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayName = definition.DisplayName
    end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        local lens = makePart(
            model,
            "FluxLens",
            Vector3.new(1.35, 1.35, 0.24),
            Color3.fromRGB(96, 211, 255),
            Enum.Material.Glass,
            Enum.PartType.Cylinder
        )
        lens.Transparency = 0.18
        makeMotor(
            root,
            lens,
            "FluxLensJoint",
            Vector3.new(0, 0.55, -2.25),
            CFrame.Angles(0, math.rad(90), 0)
        )
        for _, side in { -1, 1 } do
            local fin = makePart(
                model,
                side < 0 and "LeftFin" or "RightFin",
                Vector3.new(0.3, 2.6, 1.4),
                Color3.fromRGB(88, 103, 111),
                Enum.Material.Metal
            )
            makeMotor(
                root,
                fin,
                side < 0 and "LeftFinJoint" or "RightFinJoint",
                Vector3.new(side * 2.0, 0.35, 0.2),
                CFrame.Angles(math.rad(12), 0, math.rad(side * 24))
            )
        end
    end
    return model
end

local function buildFoundryReaver()
    local definition = MonsterConfig.Get("foundry_reaver")
    local model, root =
        makeBase(definition.TemplateName, definition.DisplayName, Vector3.new(2.5, 5.0, 2.0), 1.8)
    model:SetAttribute("AgentRadius", 2.2)
    model:SetAttribute("AgentHeight", 6.4)

    local iron = Color3.fromRGB(65, 64, 61)
    local brass = Color3.fromRGB(153, 102, 49)
    local blue = Color3.fromRGB(91, 183, 224)

    local torso =
        makePart(model, "Torso", Vector3.new(2.9, 3.0, 1.7), iron, Enum.Material.DiamondPlate)
    makeMotor(root, torso, "BodyJoint", Vector3.new(0, 0.55, 0))
    local chest =
        makePart(model, "ChestMark", Vector3.new(1.5, 1.2, 0.22), blue, Enum.Material.Neon)
    makeMotor(root, chest, "ChestMarkJoint", Vector3.new(0, 0.65, -1.0))
    local head = makePart(model, "Head", Vector3.new(1.75, 1.65, 1.65), iron, Enum.Material.Metal)
    makeMotor(root, head, "HeadJoint", Vector3.new(0, 2.55, 0))

    for _, side in { -1, 1 } do
        local arm = makePart(
            model,
            side < 0 and "LeftArm" or "RightArm",
            Vector3.new(0.7, 3.0, 0.8),
            brass,
            Enum.Material.Metal
        )
        makeMotor(
            root,
            arm,
            side < 0 and "LeftShoulder" or "RightShoulder",
            Vector3.new(side * 1.8, 0.55, 0)
        )
        local leg = makePart(
            model,
            side < 0 and "LeftLeg" or "RightLeg",
            Vector3.new(0.8, 3.15, 0.9),
            iron,
            Enum.Material.Metal
        )
        makeMotor(
            root,
            leg,
            side < 0 and "LeftHip" or "RightHip",
            Vector3.new(side * 0.72, -2.1, 0)
        )
        local eye = makePart(
            model,
            side < 0 and "LeftEye" or "RightEye",
            Vector3.new(0.23, 0.23, 0.12),
            blue,
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
        makeMotor(
            root,
            eye,
            side < 0 and "LeftEyeJoint" or "RightEyeJoint",
            Vector3.new(side * 0.4, 2.72, -0.84)
        )
    end

    local blade = makePart(
        model,
        "ReaverBlade",
        Vector3.new(0.34, 3.9, 0.72),
        Color3.fromRGB(112, 112, 106),
        Enum.Material.Metal
    )
    makeMotor(
        root,
        blade,
        "WeaponJoint",
        Vector3.new(2.15, -0.35, -0.2),
        CFrame.Angles(0, 0, math.rad(-16))
    )
    return model
end

local function buildSmelterGolem()
    local definition = MonsterConfig.Get("smelter_golem")
    local model = buildSlagmite()
    model.Name = definition.TemplateName
    model:ScaleTo(1.9)
    model:SetAttribute("AgentRadius", 3.5)
    model:SetAttribute("AgentHeight", 6.6)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayName = definition.DisplayName
    end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        for _, side in { -1, 1 } do
            local shoulder = makePart(
                model,
                side < 0 and "LeftSmelterPlate" or "RightSmelterPlate",
                Vector3.new(2.6, 1.2, 2.3),
                Color3.fromRGB(72, 68, 62),
                Enum.Material.DiamondPlate
            )
            makeMotor(
                root,
                shoulder,
                side < 0 and "LeftSmelterPlateJoint" or "RightSmelterPlateJoint",
                Vector3.new(side * 2.55, 1.65, -0.2),
                CFrame.Angles(0, 0, math.rad(side * 12))
            )
            local stack = makePart(
                model,
                side < 0 and "LeftStack" or "RightStack",
                Vector3.new(0.85, 3.3, 0.85),
                Color3.fromRGB(62, 61, 58),
                Enum.Material.Metal
            )
            makeMotor(
                root,
                stack,
                side < 0 and "LeftStackJoint" or "RightStackJoint",
                Vector3.new(side * 1.55, 2.9, 0.65)
            )
            local smoke = Instance.new("Smoke")
            smoke.Color = Color3.fromRGB(95, 80, 70)
            smoke.Opacity = 0.2
            smoke.RiseVelocity = 4
            smoke.Size = 4
            smoke.Parent = stack
        end
        local core = model:FindFirstChild("MoltenCore")
        if core and core:IsA("BasePart") then
            core.Color = Color3.fromRGB(255, 91, 35)
            local light = core:FindFirstChildOfClass("PointLight")
            if light then
                light.Color = core.Color
                light.Brightness = 2.0
                light.Range = 16
            end
        end
    end
    return model
end

local function buildForgeSpecter()
    local definition = MonsterConfig.Get("forge_specter")
    local model = buildBlueflameSentry()
    model.Name = definition.TemplateName
    model:ScaleTo(1.1)
    model:SetAttribute("AgentRadius", 1.9)
    model:SetAttribute("AgentHeight", 4.7)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayName = definition.DisplayName
    end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        local halo = makePart(
            model,
            "FluxHalo",
            Vector3.new(0.3, 4.6, 4.6),
            Color3.fromRGB(193, 102, 238),
            Enum.Material.Neon,
            Enum.PartType.Cylinder
        )
        halo.Transparency = 0.18
        makeMotor(
            root,
            halo,
            "FluxHaloJoint",
            Vector3.new(0, 0.65, 0.2),
            CFrame.Angles(0, 0, math.rad(90))
        )
        local core = model:FindFirstChild("ArcCore")
        if core and core:IsA("BasePart") then
            core.Color = Color3.fromRGB(198, 102, 244)
            local light = core:FindFirstChildOfClass("PointLight")
            if light then
                light.Color = core.Color
            end
        end
    end
    return model
end

local function buildIroncladEnforcer()
    local definition = MonsterConfig.Get("ironclad_enforcer")
    local model = buildFoundryReaver()
    model.Name = definition.TemplateName
    model:ScaleTo(1.16)
    model:SetAttribute("AgentRadius", 2.4)
    model:SetAttribute("AgentHeight", 6.8)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayName = definition.DisplayName
    end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        local helm = makePart(
            model,
            "EnforcerHelm",
            Vector3.new(2.2, 0.9, 2.0),
            Color3.fromRGB(59, 61, 60),
            Enum.Material.Metal
        )
        makeMotor(root, helm, "EnforcerHelmJoint", Vector3.new(0, 3.2, 0))
        local shield = makePart(
            model,
            "AuthorityShield",
            Vector3.new(2.6, 3.8, 0.42),
            Color3.fromRGB(147, 98, 50),
            Enum.Material.DiamondPlate
        )
        makeMotor(
            root,
            shield,
            "AuthorityShieldJoint",
            Vector3.new(-2.25, 0.0, -0.15),
            CFrame.Angles(0, math.rad(12), math.rad(6))
        )
        local badge = makePart(
            model,
            "EnforcerBadge",
            Vector3.new(0.7, 0.7, 0.12),
            Color3.fromRGB(222, 187, 104),
            Enum.Material.Metal
        )
        makeMotor(root, badge, "EnforcerBadgeJoint", Vector3.new(0.72, 0.9, -1.18))
    end
    return model
end

local function buildMoltenDrake()
    local definition = MonsterConfig.Get("molten_drake")
    local model, root =
        makeBase(definition.TemplateName, definition.DisplayName, Vector3.new(3.6, 3.2, 5.8), 1.15)
    model:SetAttribute("AgentRadius", 2.8)
    model:SetAttribute("AgentHeight", 5.0)

    local dark = Color3.fromRGB(57, 56, 53)
    local plate = Color3.fromRGB(101, 67, 45)
    local molten = Color3.fromRGB(255, 95, 36)

    local body = makePart(
        model,
        "Body",
        Vector3.new(5.5, 3.3, 6.6),
        dark,
        Enum.Material.Basalt,
        Enum.PartType.Ball
    )
    makeMotor(root, body, "BodyJoint", Vector3.new(0, 0.3, 0))
    local head = makePart(
        model,
        "Head",
        Vector3.new(3.5, 2.4, 3.7),
        plate,
        Enum.Material.Metal,
        Enum.PartType.Ball
    )
    makeMotor(root, head, "HeadJoint", Vector3.new(0, 0.75, -3.8))

    for _, spec in
        {
            { "FrontLeft", -1.75, -1.7 },
            { "FrontRight", 1.75, -1.7 },
            { "BackLeft", -1.75, 1.95 },
            { "BackRight", 1.75, 1.95 },
        }
    do
        local leg = makePart(
            model,
            spec[1] .. "Leg",
            Vector3.new(0.78, 2.6, 0.88),
            plate,
            Enum.Material.Metal
        )
        makeMotor(root, leg, spec[1] .. "Hip", Vector3.new(spec[2], -1.95, spec[3]))
    end

    for index = 1, 5 do
        local spine = makePart(
            model,
            "HeatSpine" .. tostring(index),
            Vector3.new(0.48, 2.0, 0.48),
            molten,
            Enum.Material.Neon
        )
        makeMotor(
            root,
            spine,
            "HeatSpineJoint" .. tostring(index),
            Vector3.new(0, 2.0, -1.6 + index * 0.85),
            CFrame.Angles(math.rad(-18 + index * 5), 0, math.rad((index % 2 == 0 and 1 or -1) * 7))
        )
    end

    local tail = makePart(model, "Tail", Vector3.new(0.7, 0.7, 4.8), plate, Enum.Material.Metal)
    makeMotor(
        root,
        tail,
        "TailJoint",
        Vector3.new(0, 0.55, 4.6),
        CFrame.Angles(math.rad(-10), 0, 0)
    )
    local core =
        makePart(model, "MoltenChest", Vector3.new(1.25, 1.25, 0.35), molten, Enum.Material.Neon)
    makeMotor(root, core, "MoltenChestJoint", Vector3.new(0, 0.75, -3.15))
    local light = Instance.new("PointLight")
    light.Color = molten
    light.Brightness = 1.5
    light.Range = 12
    light.Parent = core
    return model
end

local function buildBellowsTitan()
    local definition = MonsterConfig.Get("bellows_titan")
    local model = buildSmelterGolem()
    model.Name = definition.TemplateName
    model:ScaleTo(1.28)
    model:SetAttribute("AgentRadius", 4.1)
    model:SetAttribute("AgentHeight", 8.0)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayName = definition.DisplayName
    end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        for _, side in { -1, 1 } do
            local bellows = makePart(
                model,
                side < 0 and "LeftBellows" or "RightBellows",
                Vector3.new(2.6, 3.4, 1.5),
                Color3.fromRGB(101, 70, 48),
                Enum.Material.Fabric
            )
            makeMotor(
                root,
                bellows,
                side < 0 and "LeftBellowsJoint" or "RightBellowsJoint",
                Vector3.new(side * 2.6, 0.8, 1.0),
                CFrame.Angles(math.rad(-8), 0, math.rad(side * 10))
            )
        end
        local crown = makePart(
            model,
            "TitanCrown",
            Vector3.new(4.2, 1.0, 3.0),
            Color3.fromRGB(142, 94, 45),
            Enum.Material.Metal
        )
        makeMotor(root, crown, "TitanCrownJoint", Vector3.new(0, 3.6, -0.2))
    end
    return model
end

local function buildBelforgeSentinel()
    local definition = MonsterConfig.Get("belforge_sentinel")
    local model = buildFoundryReaver()
    model.Name = definition.TemplateName
    model:ScaleTo(1.48)
    model:SetAttribute("AgentRadius", 3.2)
    model:SetAttribute("AgentHeight", 8.0)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayName = definition.DisplayName
    end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        local helm = makePart(
            model,
            "SentinelHelm",
            Vector3.new(2.6, 1.2, 2.4),
            Color3.fromRGB(55, 57, 56),
            Enum.Material.DiamondPlate
        )
        makeMotor(root, helm, "SentinelHelmJoint", Vector3.new(0, 3.55, 0))
        local crest = makePart(
            model,
            "SentinelCrest",
            Vector3.new(0.45, 2.3, 1.0),
            Color3.fromRGB(184, 119, 53),
            Enum.Material.Metal
        )
        makeMotor(root, crest, "SentinelCrestJoint", Vector3.new(0, 4.8, 0.15))
        local shield = makePart(
            model,
            "GateShield",
            Vector3.new(3.4, 4.8, 0.5),
            Color3.fromRGB(72, 70, 66),
            Enum.Material.DiamondPlate
        )
        makeMotor(
            root,
            shield,
            "GateShieldJoint",
            Vector3.new(-2.7, -0.1, -0.15),
            CFrame.Angles(0, math.rad(10), math.rad(5))
        )
        local key = makePart(
            model,
            "GateKey",
            Vector3.new(0.5, 2.4, 0.5),
            Color3.fromRGB(223, 171, 74),
            Enum.Material.Metal
        )
        makeMotor(
            root,
            key,
            "GateKeyJoint",
            Vector3.new(1.6, 1.1, 0.95),
            CFrame.Angles(0, 0, math.rad(22))
        )
    end
    return model
end

local function buildBelforgeColossus()
    local definition = MonsterConfig.Get("belforge_colossus")
    local model = buildFoundryReaver()
    model.Name = definition.TemplateName
    model:ScaleTo(2.05)
    model:SetAttribute("AgentRadius", 4.5)
    model:SetAttribute("AgentHeight", 10)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayName = definition.DisplayName
    end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        local oldBlade = model:FindFirstChild("ReaverBlade")
        if oldBlade then
            oldBlade:Destroy()
        end
        local oldWeaponJoint = root:FindFirstChild("WeaponJoint")
        if oldWeaponJoint then
            oldWeaponJoint:Destroy()
        end

        local furnace = makePart(
            model,
            "ColossusFurnace",
            Vector3.new(4.4, 4.6, 1.2),
            Color3.fromRGB(255, 82, 30),
            Enum.Material.Neon
        )
        makeMotor(root, furnace, "ColossusFurnaceJoint", Vector3.new(0, 1.25, -3.0))
        local furnaceLight = Instance.new("PointLight")
        furnaceLight.Color = furnace.Color
        furnaceLight.Brightness = 2.3
        furnaceLight.Range = 22
        furnaceLight.Parent = furnace

        for _, side in { -1, 1 } do
            local shoulder = makePart(
                model,
                side < 0 and "LeftPistonShoulder" or "RightPistonShoulder",
                Vector3.new(3.0, 2.5, 3.1),
                Color3.fromRGB(68, 66, 62),
                Enum.Material.DiamondPlate
            )
            makeMotor(
                root,
                shoulder,
                side < 0 and "LeftPistonShoulderJoint" or "RightPistonShoulderJoint",
                Vector3.new(side * 4.0, 1.4, 0)
            )
            local stack = makePart(
                model,
                side < 0 and "LeftExhaust" or "RightExhaust",
                Vector3.new(1.2, 5.2, 1.2),
                Color3.fromRGB(61, 59, 56),
                Enum.Material.Metal
            )
            makeMotor(
                root,
                stack,
                side < 0 and "LeftExhaustJoint" or "RightExhaustJoint",
                Vector3.new(side * 2.65, 4.15, 1.0)
            )
            local smoke = Instance.new("Smoke")
            smoke.Color = Color3.fromRGB(91, 78, 69)
            smoke.Opacity = 0.22
            smoke.RiseVelocity = 5
            smoke.Size = 5
            smoke.Parent = stack
        end

        local hammer = makePart(
            model,
            "ColossusHammer",
            Vector3.new(1.5, 8.0, 1.5),
            Color3.fromRGB(91, 76, 61),
            Enum.Material.Metal
        )
        makeMotor(
            root,
            hammer,
            "WeaponJoint",
            Vector3.new(4.6, -0.4, -0.2),
            CFrame.Angles(0, 0, math.rad(-10))
        )
        local hammerHead = makePart(
            model,
            "HammerHead",
            Vector3.new(5.2, 2.8, 2.8),
            Color3.fromRGB(58, 58, 56),
            Enum.Material.DiamondPlate
        )
        makeMotor(
            root,
            hammerHead,
            "HammerHeadJoint",
            Vector3.new(5.25, 3.45, -0.2),
            CFrame.Angles(0, 0, math.rad(-10))
        )
        local hammerGlow = makePart(
            model,
            "HammerHeat",
            Vector3.new(4.6, 0.5, 2.3),
            Color3.fromRGB(245, 102, 39),
            Enum.Material.Neon
        )
        makeMotor(
            root,
            hammerGlow,
            "HammerHeatJoint",
            Vector3.new(5.35, 3.5, -0.25),
            CFrame.Angles(0, 0, math.rad(-10))
        )

        local helm = makePart(
            model,
            "ColossusHelm",
            Vector3.new(3.6, 1.6, 3.3),
            Color3.fromRGB(53, 55, 54),
            Enum.Material.DiamondPlate
        )
        makeMotor(root, helm, "ColossusHelmJoint", Vector3.new(0, 5.0, 0))
        local crest = makePart(
            model,
            "ColossusCrest",
            Vector3.new(0.7, 3.2, 1.3),
            Color3.fromRGB(178, 111, 48),
            Enum.Material.Metal
        )
        makeMotor(root, crest, "ColossusCrestJoint", Vector3.new(0, 7.0, 0.3))
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
    rivet_scuttler = buildRivetScuttler,
    slagmite = buildSlagmite,
    gearjaw_hound = buildGearjawHound,
    cindercoil = buildCindercoil,
    pressure_bastion = buildPressureBastion,
    furnace_husk = buildFurnaceHusk,
    arc_siphon = buildArcSiphon,
    railbreaker = buildRailbreaker,
    blueflame_sentry = buildBlueflameSentry,
    foundry_reaver = buildFoundryReaver,
    smelter_golem = buildSmelterGolem,
    forge_specter = buildForgeSpecter,
    ironclad_enforcer = buildIroncladEnforcer,
    molten_drake = buildMoltenDrake,
    bellows_titan = buildBellowsTitan,
    belforge_sentinel = buildBelforgeSentinel,
    belforge_colossus = buildBelforgeColossus,
    mosswarden = buildMosswarden,
}

function LegacyMonsterFallbackFactory.Build(monsterId)
    local builder = builders[monsterId]
    if not builder then
        return nil, "unknown_monster_fallback"
    end
    return builder()
end

function LegacyMonsterFallbackFactory.Supports(monsterId)
    return builders[monsterId] ~= nil
end

return LegacyMonsterFallbackFactory
