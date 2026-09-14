local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local ActionClient = require(script.Parent.Parent.Parent.Services.ActionClient)
local NotificationStore = require(script.Parent.Parent.NotificationStore)

local AdvancementOverlay = {}

local FAMILY_ORDER = { "ironbloom", "thornrunner", "lumenweaver", "veilstrider", "brasshand" }
local FAMILY_COLORS = {
    ironbloom = Color3.fromRGB(105, 166, 111),
    thornrunner = Color3.fromRGB(215, 159, 78),
    lumenweaver = Color3.fromRGB(83, 193, 174),
    veilstrider = Color3.fromRGB(157, 116, 196),
    brasshand = Color3.fromRGB(205, 159, 78),
}

local function corner(radius)
    return React.createElement("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function stroke(color, transparency, thickness)
    return React.createElement("UIStroke", {
        Color = color,
        Transparency = transparency or 0.4,
        Thickness = thickness or 1,
    })
end

local function label(props)
    return React.createElement("TextLabel", {
        Position = props.Position,
        Size = props.Size,
        BackgroundTransparency = 1,
        Text = props.Text or "",
        TextColor3 = props.Color or Color3.fromRGB(235, 244, 239),
        TextSize = props.TextSize or 12,
        Font = props.Bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
        TextXAlignment = props.Align or Enum.TextXAlignment.Left,
        TextYAlignment = props.VerticalAlign or Enum.TextYAlignment.Center,
        TextWrapped = props.Wrapped or false,
        ZIndex = props.ZIndex or 63,
    })
end

local function reasonText(reason, level, requiredLevel, trialComplete)
    if not trialComplete then
        return "Complete The Five Paths trial with Seren before choosing a family."
    end
    if level < requiredLevel then
        return string.format("Reach Level %d to bind this path.", requiredLevel)
    end
    if reason == "already_advanced" then
        return "Your first path is already bound."
    end
    return "This choice is permanent for the current character."
end

function AdvancementOverlay.Component(props)
    local profile = props.Profile or {}
    local catalog = props.Catalog or {}
    local families = catalog.Families or {}
    local selectedId, setSelectedId =
        React.useState(profile.FamilyId ~= "" and profile.FamilyId or FAMILY_ORDER[1])
    local status, setStatus =
        React.useState("Choose carefully. Your first family cannot be changed here.")

    local selected = families[selectedId]
    local level = tonumber(profile.Level) or 1
    local trialComplete = profile.Quests
        and profile.Quests.Completed
        and profile.Quests.Completed.first_advancement_trial == true
    local alreadyAdvanced = (tonumber(profile.AdvancementTier) or 0) >= 1
    local requiredLevel = selected and (tonumber(selected.FirstAdvancementLevel) or 999) or 999
    local canChoose = selected ~= nil
        and trialComplete
        and not alreadyAdvanced
        and level >= requiredLevel
    local starterSkill = selected and catalog.Skills and catalog.Skills[selected.StarterSkillId]
        or nil

    local familyRows = {}
    for index, familyId in FAMILY_ORDER do
        local family = families[familyId]
        if family then
            local isSelected = familyId == selectedId
            local accent = FAMILY_COLORS[familyId] or Color3.fromRGB(121, 244, 183)
            local unlockedByLevel = level >= (tonumber(family.FirstAdvancementLevel) or 999)
            familyRows[familyId] = React.createElement("TextButton", {
                Position = UDim2.fromOffset(0, (index - 1) * 72),
                Size = UDim2.new(1, -8, 0, 64),
                BackgroundColor3 = isSelected and Color3.fromRGB(27, 57, 45)
                    or Color3.fromRGB(20, 31, 29),
                BackgroundTransparency = 0.02,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = true,
                ZIndex = 63,
                [React.Event.Activated] = function()
                    setSelectedId(familyId)
                    setStatus("Choose carefully. Your first family cannot be changed here.")
                end,
            }, {
                Corner = corner(8),
                Stroke = stroke(
                    isSelected and accent or Color3.fromRGB(70, 105, 91),
                    isSelected and 0.18 or 0.58,
                    1
                ),
                Accent = React.createElement("Frame", {
                    Position = UDim2.fromOffset(0, 7),
                    Size = UDim2.fromOffset(4, 50),
                    BackgroundColor3 = accent,
                    BorderSizePixel = 0,
                    ZIndex = 64,
                }),
                Name = label({
                    Position = UDim2.fromOffset(14, 7),
                    Size = UDim2.new(1, -28, 0, 22),
                    Text = family.DisplayName,
                    TextSize = 13,
                    Bold = true,
                    Color = isSelected and accent or Color3.fromRGB(226, 240, 232),
                    ZIndex = 64,
                }),
                Meta = label({
                    Position = UDim2.fromOffset(14, 30),
                    Size = UDim2.new(1, -28, 0, 16),
                    Text = string.format(
                        "%s · %s",
                        family.PrimaryStat or "—",
                        family.CombatRole or "Path"
                    ),
                    TextSize = 9,
                    Color = Color3.fromRGB(149, 178, 164),
                    ZIndex = 64,
                }),
                Gate = label({
                    Position = UDim2.fromOffset(14, 46),
                    Size = UDim2.new(1, -28, 0, 14),
                    Text = unlockedByLevel
                            and string.format("LEVEL %d READY", family.FirstAdvancementLevel)
                        or string.format("REQUIRES LEVEL %d", family.FirstAdvancementLevel),
                    TextSize = 8,
                    Bold = true,
                    Color = unlockedByLevel and Color3.fromRGB(121, 244, 183)
                        or Color3.fromRGB(202, 150, 82),
                    ZIndex = 64,
                }),
            })
        end
    end

    local function choose()
        if not canChoose or not selected then
            setStatus(reasonText(nil, level, requiredLevel, trialComplete))
            return
        end
        local ok, result = ActionClient.Invoke("advancement.first", {
            NpcId = props.MentorNpcId,
            FamilyId = selectedId,
        })
        if not ok then
            setStatus("Advancement unavailable: " .. tostring(result))
            NotificationStore.Push("error", "Advancement Failed", tostring(result), 4)
            return
        end
        NotificationStore.Push(
            "success",
            "Path Bound",
            string.format("You advanced as %s.", result.FamilyDisplayName or selected.DisplayName),
            5
        )
        if props.OnClose then
            props.OnClose()
        end
    end

    local accent = FAMILY_COLORS[selectedId] or Color3.fromRGB(121, 244, 183)
    return React.createElement(React.Fragment, nil, {
        Backdrop = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(4, 8, 8),
            BackgroundTransparency = 0.28,
            BorderSizePixel = 0,
            ZIndex = 58,
        }),
        Window = React.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(860, 548),
            BackgroundColor3 = Color3.fromRGB(11, 19, 18),
            BorderSizePixel = 0,
            ZIndex = 60,
        }, {
            Corner = corner(10),
            Stroke = stroke(Color3.fromRGB(101, 158, 131), 0.16, 1.2),
            HeaderRule = React.createElement("Frame", {
                Position = UDim2.fromOffset(22, 72),
                Size = UDim2.new(1, -44, 0, 1),
                BackgroundColor3 = Color3.fromRGB(77, 126, 104),
                BackgroundTransparency = 0.42,
                BorderSizePixel = 0,
                ZIndex = 62,
            }),
            Kicker = label({
                Position = UDim2.fromOffset(24, 12),
                Size = UDim2.fromOffset(350, 18),
                Text = "FIRST ADVANCEMENT · THE FIVE PATHS",
                TextSize = 9,
                Bold = true,
                Color = Color3.fromRGB(121, 244, 183),
                ZIndex = 62,
            }),
            Title = label({
                Position = UDim2.fromOffset(24, 31),
                Size = UDim2.fromOffset(440, 34),
                Text = "Choose Your Wayfarer Family",
                TextSize = 23,
                Bold = true,
                ZIndex = 62,
            }),
            Close = React.createElement("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -18, 0, 18),
                Size = UDim2.fromOffset(42, 34),
                BackgroundColor3 = Color3.fromRGB(28, 40, 37),
                BorderSizePixel = 0,
                Text = "×",
                TextColor3 = Color3.fromRGB(226, 240, 232),
                TextSize = 20,
                Font = Enum.Font.GothamBold,
                ZIndex = 64,
                [React.Event.Activated] = props.OnClose,
            }, { Corner = corner(7), Stroke = stroke(Color3.fromRGB(81, 119, 102), 0.5) }),
            List = React.createElement("Frame", {
                Position = UDim2.fromOffset(22, 92),
                Size = UDim2.fromOffset(292, 354),
                BackgroundTransparency = 1,
                ZIndex = 62,
            }, familyRows),
            Detail = React.createElement("Frame", {
                Position = UDim2.fromOffset(334, 92),
                Size = UDim2.fromOffset(504, 354),
                BackgroundColor3 = Color3.fromRGB(17, 28, 25),
                BorderSizePixel = 0,
                ZIndex = 62,
            }, {
                Corner = corner(10),
                Stroke = stroke(accent, 0.28, 1),
                Accent = React.createElement("Frame", {
                    Position = UDim2.fromOffset(0, 0),
                    Size = UDim2.fromOffset(6, 354),
                    BackgroundColor3 = accent,
                    BorderSizePixel = 0,
                    ZIndex = 63,
                }),
                Family = label({
                    Position = UDim2.fromOffset(24, 20),
                    Size = UDim2.new(1, -48, 0, 36),
                    Text = selected and selected.DisplayName or "Select a family",
                    TextSize = 27,
                    Bold = true,
                    Color = accent,
                    ZIndex = 63,
                }),
                Role = label({
                    Position = UDim2.fromOffset(24, 59),
                    Size = UDim2.new(1, -48, 0, 20),
                    Text = selected and string.format(
                        "%s · Primary %s",
                        selected.CombatRole,
                        selected.PrimaryStat
                    ) or "",
                    TextSize = 11,
                    Bold = true,
                    Color = Color3.fromRGB(168, 194, 181),
                    ZIndex = 63,
                }),
                Summary = label({
                    Position = UDim2.fromOffset(24, 96),
                    Size = UDim2.new(1, -48, 0, 82),
                    Text = selected and selected.Summary or "",
                    TextSize = 13,
                    Wrapped = true,
                    VerticalAlign = Enum.TextYAlignment.Top,
                    Color = Color3.fromRGB(226, 238, 232),
                    ZIndex = 63,
                }),
                SkillKicker = label({
                    Position = UDim2.fromOffset(24, 194),
                    Size = UDim2.new(1, -48, 0, 17),
                    Text = "STARTER TECHNIQUE",
                    TextSize = 8,
                    Bold = true,
                    Color = Color3.fromRGB(121, 244, 183),
                    ZIndex = 63,
                }),
                Skill = label({
                    Position = UDim2.fromOffset(24, 212),
                    Size = UDim2.new(1, -48, 0, 26),
                    Text = starterSkill and starterSkill.DisplayName or "—",
                    TextSize = 16,
                    Bold = true,
                    ZIndex = 63,
                }),
                SkillBody = label({
                    Position = UDim2.fromOffset(24, 241),
                    Size = UDim2.new(1, -48, 0, 54),
                    Text = starterSkill and starterSkill.Description or "",
                    TextSize = 10,
                    Wrapped = true,
                    VerticalAlign = Enum.TextYAlignment.Top,
                    Color = Color3.fromRGB(148, 176, 162),
                    ZIndex = 63,
                }),
                Gate = label({
                    Position = UDim2.fromOffset(24, 309),
                    Size = UDim2.new(1, -48, 0, 24),
                    Text = selected
                            and reasonText(
                                alreadyAdvanced and "already_advanced" or nil,
                                level,
                                requiredLevel,
                                trialComplete
                            )
                        or "",
                    TextSize = 9,
                    Color = canChoose and Color3.fromRGB(121, 244, 183)
                        or Color3.fromRGB(202, 159, 101),
                    ZIndex = 63,
                }),
            }),
            Status = label({
                Position = UDim2.fromOffset(24, 466),
                Size = UDim2.new(1, -380, 0, 48),
                Text = status,
                TextSize = 10,
                Wrapped = true,
                Color = Color3.fromRGB(149, 178, 164),
                ZIndex = 62,
            }),
            Confirm = React.createElement("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -22, 0, 466),
                Size = UDim2.fromOffset(300, 52),
                BackgroundColor3 = canChoose and Color3.fromRGB(39, 88, 65)
                    or Color3.fromRGB(28, 39, 36),
                BackgroundTransparency = canChoose and 0 or 0.18,
                BorderSizePixel = 0,
                Text = selected and string.format("BIND %s", string.upper(selected.DisplayName))
                    or "SELECT A FAMILY",
                TextColor3 = canChoose and Color3.fromRGB(205, 255, 229)
                    or Color3.fromRGB(102, 126, 115),
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                Active = canChoose,
                AutoButtonColor = canChoose,
                ZIndex = 64,
                [React.Event.Activated] = choose,
            }, {
                Corner = corner(8),
                Stroke = stroke(accent, canChoose and 0.28 or 0.72, 1),
            }),
        }),
    })
end

return AdvancementOverlay.Component
