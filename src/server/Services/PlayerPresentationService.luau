local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CosmeticDefinitions = require(ReplicatedStorage.Shared.CosmeticDefinitions)
local PlayerDataService = require(script.Parent.PlayerDataService)

local PlayerPresentationService = {}
local initialized = false
local connections = {}
local appliedState = {}
local NAMEPLATE_NAME = "EverLeafPlayerNameplate"
local VISUAL_FOLDER = "EverLeafCosmeticVisuals"

local function entitlementActive(player, entitlement)
    if entitlement == nil then
        return true
    elseif entitlement == "Founder" then
        return player:GetAttribute("EverLeafFounder") == true
    elseif entitlement == "Membership" then
        return player:GetAttribute("EverLeafMember") == true
    end
    return false
end

local function equippedDefinition(player, profile, slotName)
    local cosmeticId = profile.Cosmetics
        and profile.Cosmetics.Equipped
        and profile.Cosmetics.Equipped[slotName]
    local definition = type(cosmeticId) == "string" and CosmeticDefinitions[cosmeticId] or nil
    if
        not definition
        or definition.Slot ~= slotName
        or not entitlementActive(player, definition.Entitlement)
    then
        return nil, nil
    end
    return cosmeticId, definition
end

local function titleFor(player, profile)
    local _, definition = equippedDefinition(player, profile, "Title")
    if definition and definition.Label then
        return definition.Label
    elseif player:GetAttribute("EverLeafMember") == true then
        return "MEMBER"
    end
    return nil
end

local function clearVisuals(character)
    local existing = character:FindFirstChild(VISUAL_FOLDER)
    if existing then
        existing:Destroy()
    end
end

local function makeCarrier(folder, root, name, offset)
    local carrier = Instance.new("Part")
    carrier.Name = name
    carrier.Size = Vector3.new(0.2, 0.2, 0.2)
    carrier.Transparency = 1
    carrier.CanCollide = false
    carrier.CanTouch = false
    carrier.CanQuery = false
    carrier.Massless = true
    carrier.Anchored = true
    carrier.CFrame = root.CFrame * offset
    carrier.Parent = folder

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = carrier
    weld.Parent = carrier
    carrier.Anchored = false
    return carrier
end

local function addFounderAura(folder, root)
    local carrier = makeCarrier(folder, root, "FounderLumenCarrier", CFrame.new(0, -1.2, 0))
    local attachment = Instance.new("Attachment")
    attachment.Name = "FounderLumenAttachment"
    attachment.Parent = carrier

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "FounderLumen"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(110, 242, 166)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(63, 183, 121)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(231, 193, 105)),
    })
    emitter.LightEmission = 0.55
    emitter.Rate = 7
    emitter.Lifetime = NumberRange.new(0.9, 1.5)
    emitter.Speed = NumberRange.new(0.35, 1.05)
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.RotSpeed = NumberRange.new(-25, 25)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18),
        NumberSequenceKeypoint.new(0.55, 0.11),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(0.25, 0.12),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = attachment
end

local function addFoundingMonthTrail(folder, root)
    local carrier = makeCarrier(folder, root, "MemberLumenTrailCarrier", CFrame.new(0, -1.55, 0.7))
    local attachment = Instance.new("Attachment")
    attachment.Name = "MemberLumenTrailAttachment"
    attachment.Parent = carrier

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "FoundingMonthLumenTrail"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(121, 244, 183)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(86, 186, 159)),
    })
    emitter.LightEmission = 0.45
    emitter.Rate = 10
    emitter.Lifetime = NumberRange.new(0.45, 0.8)
    emitter.Speed = NumberRange.new(0.15, 0.45)
    emitter.VelocityInheritance = 0.2
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.RotSpeed = NumberRange.new(-40, 40)
    emitter.SpreadAngle = Vector2.new(45, 45)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.14),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = attachment
end

local function applyCosmeticVisuals(player, profile, character)
    clearVisuals(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local auraId = equippedDefinition(player, profile, "Aura")
    local trailId = equippedDefinition(player, profile, "Trail")
    if auraId == nil and trailId == nil then
        return
    end

    local folder = Instance.new("Folder")
    folder.Name = VISUAL_FOLDER
    folder.Parent = character

    if auraId == "founder_lumen_aura" then
        addFounderAura(folder, root)
    end
    if trailId == "member_2026_09_lumen_trail" then
        addFoundingMonthTrail(folder, root)
    end
end

local function applyNameplate(player, profile, character)
    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not head or not humanoid then
        return
    end
    local old = head:FindFirstChild(NAMEPLATE_NAME)
    if old then
        old:Destroy()
    end
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

    local title = titleFor(player, profile)
    local family = "WAYFARER"
    if type(profile.FamilyId) == "string" and profile.FamilyId ~= "" then
        family = string.upper(profile.FamilyId)
    end

    local gui = Instance.new("BillboardGui")
    gui.Name = NAMEPLATE_NAME
    gui.Size = UDim2.fromOffset(220, title and 50 or 38)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 2.35, 0)
    gui.MaxDistance = 70
    gui.Parent = head

    local titleOffset = title and 14 or 2
    local name = Instance.new("TextLabel")
    name.Name = "Name"
    name.Position = UDim2.fromOffset(0, titleOffset)
    name.Size = UDim2.new(1, 0, 0, 22)
    name.BackgroundTransparency = 1
    name.Text = player.DisplayName
    name.TextColor3 = Color3.fromRGB(239, 246, 242)
    name.TextStrokeColor3 = Color3.fromRGB(6, 13, 11)
    name.TextStrokeTransparency = 0.2
    name.Font = Enum.Font.GothamBold
    name.TextSize = 14
    name.Parent = gui

    local meta = Instance.new("TextLabel")
    meta.Name = "Meta"
    meta.Position = UDim2.fromOffset(0, titleOffset + 20)
    meta.Size = UDim2.new(1, 0, 0, 14)
    meta.BackgroundTransparency = 1
    meta.Text = string.format("LV.%d · %s", tonumber(profile.Level) or 1, family)
    meta.TextColor3 = Color3.fromRGB(154, 181, 168)
    meta.TextStrokeColor3 = Color3.fromRGB(6, 13, 11)
    meta.TextStrokeTransparency = 0.3
    meta.Font = Enum.Font.GothamMedium
    meta.TextSize = 9
    meta.Parent = gui

    if title then
        local label = Instance.new("TextLabel")
        label.Name = "Title"
        label.Size = UDim2.new(1, 0, 0, 14)
        label.BackgroundTransparency = 1
        label.Text = "◆ " .. title .. " ◆"
        label.TextColor3 = title == "FOUNDER" and Color3.fromRGB(232, 193, 105)
            or Color3.fromRGB(121, 244, 183)
        label.TextStrokeColor3 = Color3.fromRGB(6, 13, 11)
        label.TextStrokeTransparency = 0.25
        label.Font = Enum.Font.GothamBold
        label.TextSize = 9
        label.Parent = gui
    end
end

function PlayerPresentationService.Apply(player)
    local profile = PlayerDataService.Get(player)
    local character = player.Character
    if not profile or not character then
        return
    end

    local equipped = profile.Cosmetics and profile.Cosmetics.Equipped or {}
    local signature = table.concat({
        tostring(profile.Level or 1),
        tostring(profile.FamilyId or ""),
        tostring(equipped.Title or ""),
        tostring(equipped.Aura or ""),
        tostring(equipped.Trail or ""),
        tostring(player:GetAttribute("EverLeafFounder") == true),
        tostring(player:GetAttribute("EverLeafMember") == true),
        tostring(player.DisplayName),
    }, "|")
    local previous = appliedState[player]
    if previous and previous.Character == character and previous.Signature == signature then
        return
    end
    appliedState[player] = { Character = character, Signature = signature }

    applyNameplate(player, profile, character)
    applyCosmeticVisuals(player, profile, character)
end

local function bindPlayer(player)
    if connections[player] then
        return
    end
    local bucket = {}
    connections[player] = bucket
    table.insert(
        bucket,
        player.CharacterAdded:Connect(function()
            task.defer(PlayerPresentationService.Apply, player)
        end)
    )
    for _, attribute in { "EverLeafFounder", "EverLeafMember" } do
        table.insert(
            bucket,
            player:GetAttributeChangedSignal(attribute):Connect(function()
                PlayerPresentationService.Apply(player)
            end)
        )
    end
end

function PlayerPresentationService.Init()
    if initialized then
        return
    end
    initialized = true
    PlayerDataService.Changed:Connect(PlayerPresentationService.Apply)
    Players.PlayerAdded:Connect(bindPlayer)
    Players.PlayerRemoving:Connect(function(player)
        for _, connection in connections[player] or {} do
            connection:Disconnect()
        end
        connections[player] = nil
        appliedState[player] = nil
    end)
    for _, player in Players:GetPlayers() do
        bindPlayer(player)
    end
end

return PlayerPresentationService
