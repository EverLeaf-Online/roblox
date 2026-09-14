local Players = game:GetService("Players")

local WeaponVisualDefinitions = require(script.Parent.Parent.Content.WeaponVisualDefinitions)

local EquipmentVisualService = {}
local applied = {}

local VISUAL_FOLDER = "EverLeafEquipmentVisuals"

local THEMES = table.freeze({
    Training = table.freeze({
        Metal = Color3.fromRGB(156, 163, 158),
        Dark = Color3.fromRGB(77, 68, 58),
        Accent = Color3.fromRGB(192, 202, 195),
    }),
    Scout = table.freeze({
        Metal = Color3.fromRGB(130, 153, 137),
        Dark = Color3.fromRGB(74, 56, 38),
        Accent = Color3.fromRGB(111, 214, 158),
    }),
    Ironbloom = table.freeze({
        Metal = Color3.fromRGB(105, 132, 112),
        Dark = Color3.fromRGB(45, 63, 53),
        Accent = Color3.fromRGB(121, 244, 183),
    }),
    Thornrunner = table.freeze({
        Metal = Color3.fromRGB(134, 92, 48),
        Dark = Color3.fromRGB(66, 49, 32),
        Accent = Color3.fromRGB(226, 164, 79),
    }),
    Lumenweaver = table.freeze({
        Metal = Color3.fromRGB(65, 111, 101),
        Dark = Color3.fromRGB(31, 54, 52),
        Accent = Color3.fromRGB(101, 235, 207),
    }),
    Veilstrider = table.freeze({
        Metal = Color3.fromRGB(114, 104, 136),
        Dark = Color3.fromRGB(49, 39, 61),
        Accent = Color3.fromRGB(185, 144, 229),
    }),
    Brasshand = table.freeze({
        Metal = Color3.fromRGB(161, 111, 56),
        Dark = Color3.fromRGB(69, 61, 52),
        Accent = Color3.fromRGB(242, 193, 92),
    }),
})

local function clear(character)
    local existing = character and character:FindFirstChild(VISUAL_FOLDER)
    if existing then
        existing:Destroy()
    end
end

local function part(parent, name, size, localCFrame, material, color, shape)
    local value = Instance.new("Part")
    value.Name = name
    value.Size = size
    value.CFrame = localCFrame
    value.Material = material
    value.Color = color
    value.Shape = shape or Enum.PartType.Block
    value.Anchored = false
    value.CanCollide = false
    value.CanTouch = false
    value.CanQuery = false
    value.Massless = true
    value.CastShadow = true
    value.TopSurface = Enum.SurfaceType.Smooth
    value.BottomSurface = Enum.SurfaceType.Smooth
    value.Parent = parent
    return value
end

local function wedge(parent, name, size, localCFrame, material, color)
    local value = Instance.new("WedgePart")
    value.Name = name
    value.Size = size
    value.CFrame = localCFrame
    value.Material = material
    value.Color = color
    value.Anchored = false
    value.CanCollide = false
    value.CanTouch = false
    value.CanQuery = false
    value.Massless = true
    value.CastShadow = true
    value.Parent = parent
    return value
end

local function weldTo(root, child)
    if child == root then
        return
    end
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = child
    weld.Parent = child
end

local function modelPart(model, root, name, size, offset, material, color, shape)
    local child = part(model, name, size, root.CFrame * offset, material, color, shape)
    weldTo(root, child)
    return child
end

local function modelWedge(model, root, name, size, offset, material, color)
    local child = wedge(model, name, size, root.CFrame * offset, material, color)
    weldTo(root, child)
    return child
end

local function themeFor(name)
    return THEMES[name] or THEMES.Training
end

local function blade(model, themeName)
    local theme = themeFor(themeName)
    local root = part(
        model,
        "Grip",
        Vector3.new(0.28, 1.1, 0.28),
        CFrame.new(),
        Enum.Material.Wood,
        theme.Dark
    )
    modelPart(
        model,
        root,
        "Pommel",
        Vector3.new(0.5, 0.28, 0.5),
        CFrame.new(0, -0.66, 0),
        Enum.Material.Metal,
        theme.Accent
    )
    modelPart(
        model,
        root,
        "Guard",
        Vector3.new(1.55, 0.22, 0.34),
        CFrame.new(0, 0.62, 0),
        Enum.Material.Metal,
        theme.Dark
    )

    local bladeWidth = if themeName == "Ironbloom" then 0.72 else 0.48
    local bladeLength = if themeName == "Ironbloom" then 3.25 else 2.65
    local main = modelPart(
        model,
        root,
        "Blade",
        Vector3.new(bladeWidth, bladeLength, 0.16),
        CFrame.new(0, 0.64 + bladeLength / 2, 0),
        Enum.Material.Metal,
        theme.Metal
    )
    main.Reflectance = 0.04
    modelWedge(
        model,
        root,
        "BladeTip",
        Vector3.new(bladeWidth, 0.75, 0.16),
        CFrame.new(0, 0.64 + bladeLength + 0.36, 0) * CFrame.Angles(0, 0, math.rad(180)),
        Enum.Material.Metal,
        theme.Metal
    )
    local vein = modelPart(
        model,
        root,
        "LumenVein",
        Vector3.new(0.1, bladeLength * 0.78, 0.19),
        CFrame.new(0, 0.8 + bladeLength / 2, -0.01),
        Enum.Material.Neon,
        theme.Accent
    )
    vein.CastShadow = false
    if themeName == "Ironbloom" then
        modelPart(
            model,
            root,
            "RootGuardLeft",
            Vector3.new(0.18, 0.78, 0.18),
            CFrame.new(-0.62, 0.73, 0) * CFrame.Angles(0, 0, math.rad(-38)),
            Enum.Material.Wood,
            theme.Dark
        )
        modelPart(
            model,
            root,
            "RootGuardRight",
            Vector3.new(0.18, 0.78, 0.18),
            CFrame.new(0.62, 0.73, 0) * CFrame.Angles(0, 0, math.rad(38)),
            Enum.Material.Wood,
            theme.Dark
        )
    end
    return root, "Right"
end

local function bow(model, themeName)
    local theme = themeFor(themeName)
    local root = part(
        model,
        "Grip",
        Vector3.new(0.28, 1.0, 0.32),
        CFrame.new(),
        Enum.Material.Wood,
        theme.Dark
    )
    local segments = {
        {
            Vector3.new(0.22, 1.75, 0.3),
            CFrame.new(-0.38, 1.1, 0) * CFrame.Angles(0, 0, math.rad(-20)),
        },
        {
            Vector3.new(0.22, 1.75, 0.3),
            CFrame.new(-0.38, -1.1, 0) * CFrame.Angles(0, 0, math.rad(20)),
        },
        {
            Vector3.new(0.22, 1.45, 0.3),
            CFrame.new(-0.95, 2.42, 0) * CFrame.Angles(0, 0, math.rad(-30)),
        },
        {
            Vector3.new(0.22, 1.45, 0.3),
            CFrame.new(-0.95, -2.42, 0) * CFrame.Angles(0, 0, math.rad(30)),
        },
    }
    for index, spec in segments do
        modelPart(
            model,
            root,
            "BriarLimb" .. tostring(index),
            spec[1],
            spec[2],
            Enum.Material.Wood,
            theme.Metal
        )
    end
    modelPart(
        model,
        root,
        "String",
        Vector3.new(0.045, 5.55, 0.045),
        CFrame.new(-1.28, 0, 0),
        Enum.Material.SmoothPlastic,
        theme.Accent
    )
    modelPart(
        model,
        root,
        "LumenNock",
        Vector3.new(0.22, 0.5, 0.22),
        CFrame.new(-0.98, 0, 0),
        Enum.Material.Neon,
        theme.Accent,
        Enum.PartType.Ball
    )
    return root, "Left"
end

local function focus(model, themeName)
    local theme = themeFor(themeName)
    local root = part(
        model,
        "Grip",
        Vector3.new(0.26, 0.8, 0.26),
        CFrame.new(),
        Enum.Material.Metal,
        theme.Dark
    )
    local core = modelPart(
        model,
        root,
        "FocusCore",
        Vector3.new(0.72, 0.72, 0.72),
        CFrame.new(0, 0.7, 0),
        Enum.Material.Neon,
        theme.Accent,
        Enum.PartType.Ball
    )
    core.CastShadow = false
    for index = 0, 3 do
        modelPart(
            model,
            root,
            "PrismArm" .. tostring(index),
            Vector3.new(0.13, 1.3, 0.13),
            CFrame.new(0, 0.72, 0)
                * CFrame.Angles(0, 0, math.rad(45 + index * 90))
                * CFrame.new(0, 0.72, 0),
            Enum.Material.Neon,
            theme.Metal
        ).CastShadow =
            false
    end
    local light = Instance.new("PointLight")
    light.Color = theme.Accent
    light.Brightness = 0.75
    light.Range = 7
    light.Parent = core
    return root, "Right"
end

local function knife(model, theme, suffix)
    local root = part(
        model,
        "Grip" .. suffix,
        Vector3.new(0.22, 0.78, 0.22),
        CFrame.new(),
        Enum.Material.SmoothPlastic,
        theme.Dark
    )
    modelPart(
        model,
        root,
        "Guard" .. suffix,
        Vector3.new(0.82, 0.15, 0.24),
        CFrame.new(0, 0.48, 0),
        Enum.Material.Metal,
        theme.Accent
    )
    modelPart(
        model,
        root,
        "Blade" .. suffix,
        Vector3.new(0.32, 1.42, 0.12),
        CFrame.new(0, 1.23, 0),
        Enum.Material.Glass,
        theme.Metal
    )
    modelWedge(
        model,
        root,
        "Tip" .. suffix,
        Vector3.new(0.32, 0.55, 0.12),
        CFrame.new(0, 2.2, 0) * CFrame.Angles(0, 0, math.rad(180)),
        Enum.Material.Glass,
        theme.Accent
    )
    return root
end

local function twinKnives(model, themeName)
    local theme = themeFor(themeName)
    local right = knife(model, theme, "Right")
    local leftModel = Instance.new("Model")
    leftModel.Name = "Offhand"
    leftModel.Parent = model
    local left = knife(leftModel, theme, "Left")
    return right, "Right", left, "Left"
end

local function maul(model, themeName)
    local theme = themeFor(themeName)
    local root = part(
        model,
        "Grip",
        Vector3.new(0.34, 2.45, 0.34),
        CFrame.new(),
        Enum.Material.Wood,
        theme.Dark
    )
    modelPart(
        model,
        root,
        "LowerRivet",
        Vector3.new(0.58, 0.28, 0.58),
        CFrame.new(0, -1.36, 0),
        Enum.Material.Metal,
        theme.Accent
    )
    modelPart(
        model,
        root,
        "Head",
        Vector3.new(2.25, 1.25, 1.18),
        CFrame.new(0, 1.55, 0),
        Enum.Material.Metal,
        theme.Metal
    )
    modelPart(
        model,
        root,
        "Face",
        Vector3.new(0.4, 1.55, 1.42),
        CFrame.new(-1.26, 1.55, 0),
        Enum.Material.DiamondPlate,
        theme.Accent
    )
    for _, side in { -1, 1 } do
        for _, y in { 1.18, 1.92 } do
            modelPart(
                model,
                root,
                "Rivet" .. tostring(side) .. tostring(y),
                Vector3.new(0.16, 0.16, 0.16),
                CFrame.new(side * 0.86, y, -0.62),
                Enum.Material.Neon,
                theme.Accent,
                Enum.PartType.Ball
            )
        end
    end
    return root, "Right"
end

local BUILDERS = {
    Blade = blade,
    Bow = bow,
    Focus = focus,
    TwinKnives = twinKnives,
    Maul = maul,
}

local function findHand(character, side)
    if side == "Left" then
        return character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
    end
    return character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
end

local function gripCFrame(hand, side)
    local attachmentName = side .. "GripAttachment"
    local attachment = hand:FindFirstChild(attachmentName)
    if attachment and attachment:IsA("Attachment") then
        return attachment.CFrame
    end
    if side == "Left" then
        return CFrame.new(0, -0.72, 0) * CFrame.Angles(math.rad(-90), 0, math.rad(-90))
    end
    return CFrame.new(0, -0.72, 0) * CFrame.Angles(math.rad(-90), 0, math.rad(90))
end

local function attach(character, root, side, suffix)
    local hand = findHand(character, side)
    if not hand or not hand:IsA("BasePart") then
        return false
    end
    local motor = Instance.new("Motor6D")
    motor.Name = "EverLeafWeaponGrip" .. (suffix or "")
    motor.Part0 = hand
    motor.Part1 = root
    motor.C0 = gripCFrame(hand, side)
    motor.C1 = CFrame.new()
    motor.Parent = hand
    return true
end

local function buildVisual(character, itemId, definition)
    local builder = BUILDERS[definition.Style]
    if not builder then
        return false
    end
    local container = Instance.new("Model")
    container.Name = VISUAL_FOLDER
    container:SetAttribute("ItemId", itemId)
    container.Parent = character

    local root, side, secondaryRoot, secondarySide = builder(container, definition.Theme)
    if not root or not attach(character, root, side or "Right", "Primary") then
        container:Destroy()
        return false
    end
    if secondaryRoot then
        attach(character, secondaryRoot, secondarySide or "Left", "Secondary")
    end
    return true
end

function EquipmentVisualService.Apply(player, profile)
    local character = player.Character
    if not character or type(profile) ~= "table" then
        return false
    end
    local itemId = profile.Equipment and profile.Equipment.Weapon or ""
    local key = tostring(character) .. ":" .. tostring(itemId)
    if applied[player] == key then
        return true
    end

    clear(character)
    applied[player] = key
    if itemId == nil or itemId == "" then
        return true
    end
    local definition = WeaponVisualDefinitions[itemId]
    if not definition then
        return true
    end
    return buildVisual(character, itemId, definition)
end

function EquipmentVisualService.Reset(player)
    applied[player] = nil
    clear(player.Character)
end

Players.PlayerRemoving:Connect(function(player)
    applied[player] = nil
end)

return EquipmentVisualService
