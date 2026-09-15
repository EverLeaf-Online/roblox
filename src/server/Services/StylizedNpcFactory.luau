local StylizedNpcFactory = {}

local function makePart(parent, name, size, cframe, material, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = true
    part.Size = size
    part.CFrame = cframe
    part.Material = material or Enum.Material.SmoothPlastic
    part.Color = color
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function makeBall(parent, name, size, cframe, material, color)
    local part = makePart(parent, name, size, cframe, material, color)
    part.Shape = Enum.PartType.Ball
    return part
end

local function makeWedge(parent, name, size, cframe, material, color)
    local part = Instance.new("WedgePart")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = true
    part.Size = size
    part.CFrame = cframe
    part.Material = material or Enum.Material.SmoothPlastic
    part.Color = color
    part.Parent = parent
    return part
end

local function makeCylinderBetween(parent, name, a, b, radius, material, color)
    local delta = b - a
    local length = delta.Magnitude
    if length <= 0.01 then
        return nil
    end
    local part = makePart(
        parent,
        name,
        Vector3.new(length, radius * 2, radius * 2),
        CFrame.lookAt((a + b) * 0.5, b) * CFrame.Angles(0, math.pi * 0.5, 0),
        material,
        color
    )
    part.Shape = Enum.PartType.Cylinder
    return part
end

local function worldPoint(base, point, scale)
    return (base * CFrame.new(point * scale)).Position
end

local function makeFace(model, base, scale, skin, eyeColor)
    local eyeY = 6.23 * scale
    local eyeZ = -0.88 * scale
    for _, side in { -1, 1 } do
        makeBall(
            model,
            if side < 0 then "LeftEye" else "RightEye",
            Vector3.new(0.17, 0.2, 0.1) * scale,
            base * CFrame.new(side * 0.34 * scale, eyeY, eyeZ),
            Enum.Material.SmoothPlastic,
            eyeColor
        )
        makePart(
            model,
            if side < 0 then "LeftBrow" else "RightBrow",
            Vector3.new(0.32, 0.07, 0.07) * scale,
            base
                * CFrame.new(side * 0.34 * scale, 6.48 * scale, -0.9 * scale)
                * CFrame.Angles(0, 0, math.rad(side * -5)),
            Enum.Material.SmoothPlastic,
            Color3.fromRGB(63, 49, 41)
        )
    end
    makeBall(
        model,
        "Nose",
        Vector3.new(0.16, 0.2, 0.16) * scale,
        base * CFrame.new(0, 6.03 * scale, -0.92 * scale),
        Enum.Material.SmoothPlastic,
        skin
    )
    makePart(
        model,
        "Mouth",
        Vector3.new(0.42, 0.06, 0.06) * scale,
        base * CFrame.new(0, 5.77 * scale, -0.9 * scale),
        Enum.Material.SmoothPlastic,
        Color3.fromRGB(127, 75, 68)
    )
end

local function makeHair(model, base, scale, hairColor, style)
    style = style or "short"
    local crown = makeBall(
        model,
        "HairCrown",
        Vector3.new(1.92, 1.15, 1.86) * scale,
        base * CFrame.new(0, 6.72 * scale, 0.05 * scale),
        Enum.Material.SmoothPlastic,
        hairColor
    )
    crown.CanQuery = false

    for _, side in { -1, 1 } do
        makeWedge(
            model,
            if side < 0 then "HairBangLeft" else "HairBangRight",
            Vector3.new(0.55, 0.9, 0.22) * scale,
            base
                * CFrame.new(side * 0.37 * scale, 6.47 * scale, -0.86 * scale)
                * CFrame.Angles(math.rad(-9), math.rad(side * 6), math.rad(side * 9)),
            Enum.Material.SmoothPlastic,
            hairColor
        )
    end

    if style == "long" then
        for _, side in { -1, 1 } do
            makeWedge(
                model,
                if side < 0 then "LongHairLeft" else "LongHairRight",
                Vector3.new(0.72, 2.7, 0.5) * scale,
                base
                    * CFrame.new(side * 0.58 * scale, 5.55 * scale, 0.72 * scale)
                    * CFrame.Angles(math.rad(-5), 0, math.rad(side * 5)),
                Enum.Material.SmoothPlastic,
                hairColor
            )
        end
    elseif style == "bun" then
        makeBall(
            model,
            "HairBun",
            Vector3.new(0.95, 0.95, 0.95) * scale,
            base * CFrame.new(0, 7.08 * scale, 0.68 * scale),
            Enum.Material.SmoothPlastic,
            hairColor
        )
    elseif style == "ponytail" then
        makeBall(
            model,
            "PonytailTie",
            Vector3.new(0.42, 0.42, 0.42) * scale,
            base * CFrame.new(0, 6.66 * scale, 0.95 * scale),
            Enum.Material.SmoothPlastic,
            Color3.fromRGB(58, 77, 67)
        )
        makeWedge(
            model,
            "Ponytail",
            Vector3.new(0.95, 3.1, 0.7) * scale,
            base
                * CFrame.new(0, 5.55 * scale, 1.25 * scale)
                * CFrame.Angles(math.rad(-8), 0, math.rad(4)),
            Enum.Material.SmoothPlastic,
            hairColor
        )
    end
end

local function makeBody(model, base, scale, palette, build)
    local cloth = palette.Cloth
    local darkCloth = palette.DarkCloth or cloth:Lerp(Color3.new(0, 0, 0), 0.24)
    local skin = palette.Skin or Color3.fromRGB(214, 181, 146)
    local leather = palette.Leather or Color3.fromRGB(84, 58, 39)
    build = build or 1

    local root = makePart(
        model,
        "HumanoidRootPart",
        Vector3.new(2.2, 7.6, 2.0) * scale,
        base * CFrame.new(0, 3.8 * scale, 0),
        Enum.Material.SmoothPlastic,
        Color3.new(0, 0, 0)
    )
    root.Transparency = 1
    root.CanQuery = false

    local hipWidth = 0.5 * build
    local shoulderWidth = 1.27 * build
    for _, side in { -1, 1 } do
        local hip = worldPoint(base, Vector3.new(side * hipWidth, 2.75, 0), scale)
        local knee =
            worldPoint(base, Vector3.new(side * (hipWidth + 0.03), 1.55, side * -0.04), scale)
        local ankle = worldPoint(base, Vector3.new(side * (hipWidth + 0.05), 0.58, -0.03), scale)
        makeCylinderBetween(
            model,
            side < 0 and "LeftUpperLeg" or "RightUpperLeg",
            hip,
            knee,
            0.34 * scale,
            Enum.Material.Fabric,
            darkCloth
        )
        makeCylinderBetween(
            model,
            side < 0 and "LeftLowerLeg" or "RightLowerLeg",
            knee,
            ankle,
            0.3 * scale,
            Enum.Material.Fabric,
            darkCloth
        )
        makeBall(
            model,
            side < 0 and "LeftKnee" or "RightKnee",
            Vector3.new(0.68, 0.62, 0.68) * scale,
            CFrame.new(knee),
            Enum.Material.Fabric,
            darkCloth
        )
        makePart(
            model,
            side < 0 and "LeftBoot" or "RightBoot",
            Vector3.new(0.78, 0.62, 1.14) * scale,
            base * CFrame.new(side * (hipWidth + 0.05) * scale, 0.31 * scale, -0.18 * scale),
            Enum.Material.SmoothPlastic,
            palette.Boots or Color3.fromRGB(54, 42, 34)
        )

        local shoulder = worldPoint(base, Vector3.new(side * shoulderWidth, 4.72, 0), scale)
        local elbow =
            worldPoint(base, Vector3.new(side * (shoulderWidth + 0.16), 3.68, -0.05), scale)
        local hand =
            worldPoint(base, Vector3.new(side * (shoulderWidth + 0.08), 2.72, -0.08), scale)
        makeCylinderBetween(
            model,
            side < 0 and "LeftUpperArm" or "RightUpperArm",
            shoulder,
            elbow,
            0.3 * scale,
            Enum.Material.Fabric,
            cloth
        )
        makeCylinderBetween(
            model,
            side < 0 and "LeftForearm" or "RightForearm",
            elbow,
            hand,
            0.27 * scale,
            Enum.Material.Fabric,
            cloth
        )
        makeBall(
            model,
            side < 0 and "LeftShoulder" or "RightShoulder",
            Vector3.new(0.8, 0.72, 0.82) * scale,
            CFrame.new(shoulder),
            Enum.Material.Fabric,
            darkCloth
        )
        makeBall(
            model,
            side < 0 and "LeftHand" or "RightHand",
            Vector3.new(0.58, 0.58, 0.58) * scale,
            CFrame.new(hand),
            Enum.Material.SmoothPlastic,
            skin
        )
    end

    makePart(
        model,
        "Torso",
        Vector3.new(2.25 * build, 2.05, 1.32) * scale,
        base * CFrame.new(0, 4.0 * scale, 0),
        Enum.Material.Fabric,
        cloth
    )
    makeWedge(
        model,
        "CoatFront",
        Vector3.new(2.42 * build, 1.85, 1.38) * scale,
        base * CFrame.new(0, 2.85 * scale, -0.02 * scale),
        Enum.Material.Fabric,
        darkCloth
    )
    makePart(
        model,
        "Belt",
        Vector3.new(2.48 * build, 0.28, 1.45) * scale,
        base * CFrame.new(0, 3.15 * scale, 0),
        Enum.Material.Fabric,
        leather
    )
    makePart(
        model,
        "Buckle",
        Vector3.new(0.4, 0.38, 0.1) * scale,
        base * CFrame.new(0, 3.14 * scale, -0.77 * scale),
        Enum.Material.Metal,
        palette.Metal or Color3.fromRGB(169, 132, 67)
    )

    local neck = makeBall(
        model,
        "Neck",
        Vector3.new(0.65, 0.55, 0.65) * scale,
        base * CFrame.new(0, 5.16 * scale, 0),
        Enum.Material.SmoothPlastic,
        skin
    )
    neck.CanQuery = false
    local head = makeBall(
        model,
        "Head",
        Vector3.new(1.75, 1.9, 1.7) * scale,
        base * CFrame.new(0, 6.05 * scale, 0),
        Enum.Material.SmoothPlastic,
        skin
    )
    return root, head
end

local function makeStaff(model, base, scale, color, lumenColor, side)
    side = side or 1
    local bottom = worldPoint(base, Vector3.new(side * 1.72, 0.35, 0.2), scale)
    local top = worldPoint(base, Vector3.new(side * 1.72, 6.75, 0.2), scale)
    makeCylinderBetween(model, "Staff", bottom, top, 0.11 * scale, Enum.Material.Wood, color)
    local crystal = makeBall(
        model,
        "StaffLumen",
        Vector3.new(0.78, 0.94, 0.78) * scale,
        CFrame.new(top + Vector3.new(0, 0.3 * scale, 0)),
        Enum.Material.Neon,
        lumenColor
    )
    local light = Instance.new("PointLight")
    light.Color = lumenColor
    light.Brightness = 0.75
    light.Range = 9
    light.Parent = crystal
end

local function addRoleDetails(model, base, scale, spec, palette)
    local role = spec.Role or "Villager"
    local accent = palette.Accent or Color3.fromRGB(101, 155, 119)
    local leather = palette.Leather or Color3.fromRGB(84, 58, 39)
    local dark = palette.DarkCloth or palette.Cloth:Lerp(Color3.new(0, 0, 0), 0.24)
    local lumen = palette.Lumen or Color3.fromRGB(113, 238, 170)

    if role == "Guide" then
        makeWedge(
            model,
            "GuideCape",
            Vector3.new(2.45, 3.25, 0.35) * scale,
            base * CFrame.new(0, 3.75 * scale, 0.86 * scale) * CFrame.Angles(math.rad(-7), 0, 0),
            Enum.Material.Fabric,
            dark
        )
        makePart(
            model,
            "Satchel",
            Vector3.new(1.15, 1.45, 0.55) * scale,
            base * CFrame.new(-1.18 * scale, 3.1 * scale, 0.72 * scale),
            Enum.Material.Fabric,
            leather
        )
        makeStaff(model, base, scale, Color3.fromRGB(74, 52, 34), lumen, 1)
        for _, side in { -1, 1 } do
            makeWedge(
                model,
                side < 0 and "HoodLeft" or "HoodRight",
                Vector3.new(0.45, 1.35, 0.55) * scale,
                base * CFrame.new(side * 0.73 * scale, 6.15 * scale, 0.38 * scale),
                Enum.Material.Fabric,
                dark
            )
        end
    elseif role == "Quartermaster" then
        makePart(
            model,
            "Apron",
            Vector3.new(1.85, 2.65, 0.16) * scale,
            base * CFrame.new(0, 3.55 * scale, -0.75 * scale),
            Enum.Material.Fabric,
            accent
        )
        for _, side in { -1, 1 } do
            makePart(
                model,
                side < 0 and "BeltPouchLeft" or "BeltPouchRight",
                Vector3.new(0.62, 0.72, 0.42) * scale,
                base * CFrame.new(side * 0.88 * scale, 2.95 * scale, -0.62 * scale),
                Enum.Material.Fabric,
                leather
            )
        end
        makePart(
            model,
            "Ledger",
            Vector3.new(1.15, 0.18, 1.5) * scale,
            base
                * CFrame.new(-1.28 * scale, 2.95 * scale, -0.68 * scale)
                * CFrame.Angles(math.rad(14), math.rad(18), math.rad(-9)),
            Enum.Material.Wood,
            Color3.fromRGB(104, 75, 48)
        )
    elseif role == "Scout" then
        makeWedge(
            model,
            "ScoutCloak",
            Vector3.new(2.35, 3.05, 0.34) * scale,
            base * CFrame.new(0, 3.7 * scale, 0.82 * scale) * CFrame.Angles(math.rad(-6), 0, 0),
            Enum.Material.Fabric,
            accent
        )
        makePart(
            model,
            "FieldPack",
            Vector3.new(1.6, 1.8, 0.7) * scale,
            base * CFrame.new(0, 3.55 * scale, 1.02 * scale),
            Enum.Material.Fabric,
            leather
        )
        local spearBottom = worldPoint(base, Vector3.new(1.72, 0.5, 0.4), scale)
        local spearTop = worldPoint(base, Vector3.new(1.72, 6.5, 0.4), scale)
        makeCylinderBetween(
            model,
            "ScoutSpear",
            spearBottom,
            spearTop,
            0.08 * scale,
            Enum.Material.Wood,
            Color3.fromRGB(77, 54, 35)
        )
        makeWedge(
            model,
            "SpearHead",
            Vector3.new(0.42, 0.9, 0.22) * scale,
            CFrame.new(spearTop + Vector3.new(0, 0.38 * scale, 0)),
            Enum.Material.Metal,
            Color3.fromRGB(144, 157, 150)
        )
    elseif role == "Archivist" then
        makeWedge(
            model,
            "ArchiveRobe",
            Vector3.new(2.5, 2.9, 1.25) * scale,
            base * CFrame.new(0, 2.7 * scale, 0.05 * scale),
            Enum.Material.Fabric,
            dark
        )
        makePart(
            model,
            "Book",
            Vector3.new(1.2, 0.32, 1.5) * scale,
            base
                * CFrame.new(1.2 * scale, 2.95 * scale, -0.58 * scale)
                * CFrame.Angles(math.rad(18), math.rad(-12), math.rad(8)),
            Enum.Material.Fabric,
            accent
        )
        for _, side in { -1, 1 } do
            makePart(
                model,
                side < 0 and "GlassesLeft" or "GlassesRight",
                Vector3.new(0.48, 0.32, 0.06) * scale,
                base * CFrame.new(side * 0.34 * scale, 6.23 * scale, -0.94 * scale),
                Enum.Material.Metal,
                Color3.fromRGB(88, 78, 65)
            )
        end
    elseif role == "Mentor" then
        makeWedge(
            model,
            "PathkeeperMantle",
            Vector3.new(2.85, 1.0, 1.7) * scale,
            base * CFrame.new(0, 4.72 * scale, 0.05 * scale),
            Enum.Material.Fabric,
            accent
        )
        makeWedge(
            model,
            "PathkeeperCoatTail",
            Vector3.new(2.35, 3.0, 0.44) * scale,
            base * CFrame.new(0, 2.95 * scale, 0.82 * scale) * CFrame.Angles(math.rad(-5), 0, 0),
            Enum.Material.Fabric,
            dark
        )
        makeStaff(model, base, scale, Color3.fromRGB(82, 58, 38), lumen, 1)
        for index = 1, 3 do
            local angle = index * math.pi * 2 / 3
            local rune = makeBall(
                model,
                "PathRune" .. index,
                Vector3.new(0.25, 0.25, 0.25) * scale,
                base
                    * CFrame.new(
                        math.cos(angle) * 0.78 * scale,
                        4.85 * scale,
                        -0.88 * scale + math.sin(angle) * 0.18 * scale
                    ),
                Enum.Material.Neon,
                lumen
            )
            rune.CanQuery = false
        end
    end
end

function StylizedNpcFactory.Create(parent, spec)
    local model = Instance.new("Model")
    model.Name = spec.Name or spec.NpcId or "EverLeafNpc"
    model.Parent = parent

    local scale = tonumber(spec.Scale) or 1
    local base = CFrame.new(spec.Position) * CFrame.Angles(0, spec.Yaw or 0, 0)
    local palette = spec.Palette or {}
    palette.Cloth = palette.Cloth or Color3.fromRGB(63, 91, 77)
    palette.Accent = palette.Accent or Color3.fromRGB(103, 152, 119)
    palette.Skin = palette.Skin or Color3.fromRGB(214, 181, 146)
    palette.Leather = palette.Leather or Color3.fromRGB(84, 58, 39)
    palette.DarkCloth = palette.DarkCloth or palette.Cloth:Lerp(Color3.new(0, 0, 0), 0.24)

    local root, head = makeBody(model, base, scale, palette, tonumber(spec.Build) or 1)
    makeFace(model, base, scale, palette.Skin, palette.EyeColor or Color3.fromRGB(35, 45, 40))
    makeHair(
        model,
        base,
        scale,
        palette.Hair or Color3.fromRGB(69, 52, 43),
        spec.HairStyle or "short"
    )
    addRoleDetails(model, base, scale, spec, palette)

    model.PrimaryPart = root
    return model, root, head
end

return StylizedNpcFactory
