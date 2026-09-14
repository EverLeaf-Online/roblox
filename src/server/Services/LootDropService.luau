local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local DropTableDefinitions = require(script.Parent.Parent.Content.DropTableDefinitions)
local ItemDefinitions = require(script.Parent.Parent.Content.ItemDefinitions)
local InventoryService = require(script.Parent.InventoryService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local QuestService = require(script.Parent.QuestService)

local LootDropService = {}
local rng = Random.new()

local ITEM_COLORS = {
    Material = Color3.fromRGB(117, 221, 170),
    Consumable = Color3.fromRGB(123, 185, 255),
    Equipment = Color3.fromRGB(255, 208, 105),
    Quest = Color3.fromRGB(194, 139, 255),
}

local function makeDrop(itemId, quantity, position, ownerPlayer)
    local definition = ItemDefinitions[itemId]
    if not definition then
        return nil
    end

    local model = Instance.new("Model")
    model.Name = "Loot_" .. itemId
    model:SetAttribute("ItemId", itemId)
    model:SetAttribute("Quantity", quantity)
    model:SetAttribute("OwnerUserId", ownerPlayer.UserId)
    model:SetAttribute("SpawnedAt", os.clock())

    local orb = Instance.new("Part")
    orb.Name = "LootOrb"
    orb.Shape = Enum.PartType.Ball
    orb.Size = Vector3.new(1.25, 1.25, 1.25)
    orb.Material = Enum.Material.Neon
    orb.Color = ITEM_COLORS[definition.Type] or Color3.fromRGB(205, 220, 205)
    orb.Anchored = true
    orb.CanCollide = false
    orb.CanTouch = false
    orb.CanQuery = false
    orb.CFrame = CFrame.new(
        position + Vector3.new(rng:NextNumber(-1.3, 1.3), 1.35, rng:NextNumber(-1.3, 1.3))
    )
    orb.Parent = model
    model.PrimaryPart = orb

    local light = Instance.new("PointLight")
    light.Color = orb.Color
    light.Brightness = 0.65
    light.Range = 7
    light.Parent = orb

    local attachment = Instance.new("Attachment")
    attachment.Parent = orb
    local sparkles = Instance.new("ParticleEmitter")
    sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    sparkles.Color = ColorSequence.new(orb.Color)
    sparkles.Lifetime = NumberRange.new(0.45, 0.8)
    sparkles.Speed = NumberRange.new(0.4, 1.1)
    sparkles.Rate = 9
    sparkles.SpreadAngle = Vector2.new(180, 180)
    sparkles.Parent = attachment

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "LootLabel"
    billboard.Size = UDim2.fromOffset(180, 34)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.55, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 55
    billboard.Parent = orb

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = string.format("%s  x%d", definition.DisplayName, quantity)
    label.TextColor3 = Color3.fromRGB(242, 248, 241)
    label.TextStrokeColor3 = Color3.fromRGB(24, 35, 30)
    label.TextStrokeTransparency = 0.2
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = billboard

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "CollectPrompt"
    prompt.ActionText = "Collect"
    prompt.ObjectText = definition.DisplayName
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 9
    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false
    prompt.Parent = orb

    local claimed = false
    prompt.Triggered:Connect(function(player)
        if claimed or player ~= ownerPlayer then
            return
        end
        local profile = PlayerDataService.Get(player)
        if not profile then
            return
        end
        local added, reason = InventoryService.Add(profile, itemId, quantity)
        if not added then
            if reason == "inventory_full" then
                label.Text = "INVENTORY FULL"
            end
            return
        end

        claimed = true
        prompt.Enabled = false
        QuestService.Record(profile, "Collect", itemId, quantity)
        PlayerDataService.NotifyChanged(player)
        TweenService:Create(
            orb,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1 }
        ):Play()
        task.delay(0.2, function()
            if model.Parent then
                model:Destroy()
            end
        end)
    end)

    model.Parent = workspace
    CollectionService:AddTag(model, "EverLeafLoot")
    Debris:AddItem(model, 35)

    local base = orb.CFrame
    TweenService:Create(
        orb,
        TweenInfo.new(0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { CFrame = base + Vector3.new(0, 0.45, 0) }
    ):Play()
    return model
end

function LootDropService.RollAndSpawn(enemyId, position, ownerPlayer)
    if not ownerPlayer or not ownerPlayer:IsA("Player") then
        return {}
    end
    local drops = DropTableDefinitions[enemyId]
    if not drops then
        return {}
    end

    local spawned = {}
    for _, entry in drops do
        if rng:NextNumber() <= (entry.Chance or 0) then
            local minimum = math.max(1, math.floor(entry.Min or 1))
            local maximum = math.max(minimum, math.floor(entry.Max or minimum))
            local quantity = rng:NextInteger(minimum, maximum)
            local drop = makeDrop(entry.ItemId, quantity, position, ownerPlayer)
            if drop then
                table.insert(spawned, drop)
            end
        end
    end
    return spawned
end

return LootDropService
