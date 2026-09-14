local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local CatalogClient = require(script.Parent.Parent.Parent.Services.CatalogClient)

local player = Players.LocalPlayer

local function findBossDefinition(enemyId)
    local catalog = CatalogClient.Get()
    for bossId, definition in catalog and catalog.Bosses or {} do
        if definition.MonsterId == enemyId then
            return bossId, definition
        end
    end
    return nil, nil
end

local function snapshotNearbyBoss()
    local character = player.Character
    local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not playerRoot then
        return nil
    end

    local best = nil
    local bestDistance = math.huge
    for _, enemy in CollectionService:GetTagged("EverLeafEnemy") do
        if enemy:IsA("Model") then
            local enemyId = enemy:GetAttribute("EnemyId")
            local bossId, definition = findBossDefinition(enemyId)
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            local root = enemy:FindFirstChild("HumanoidRootPart")
            if bossId and definition and humanoid and root and humanoid.Health > 0 then
                local distance = (root.Position - playerRoot.Position).Magnitude
                if distance <= 240 and distance < bestDistance then
                    bestDistance = distance
                    best = {
                        BossId = bossId,
                        EnemyId = enemyId,
                        Name = definition.DisplayName or enemy.Name,
                        RecommendedLevel = definition.RecommendedLevel,
                        Health = humanoid.Health,
                        MaxHealth = humanoid.MaxHealth,
                    }
                end
            end
        end
    end
    return best
end

local function BossHud(props)
    local boss, setBoss = React.useState(nil)

    React.useEffect(function()
        local alive = true
        task.spawn(function()
            while alive do
                setBoss(snapshotNearbyBoss())
                task.wait(0.12)
            end
        end)
        return function()
            alive = false
        end
    end, {})

    if not boss or props.Hidden then
        return nil
    end

    local fraction = math.clamp((boss.Health or 0) / math.max(1, boss.MaxHealth or 1), 0, 1)
    return React.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 78),
        Size = UDim2.fromOffset(520, 72),
        BackgroundColor3 = Color3.fromRGB(12, 16, 14),
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        ZIndex = 25,
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Stroke = React.createElement(
            "UIStroke",
            { Color = Color3.fromRGB(165, 111, 69), Transparency = 0.22, Thickness = 1.2 }
        ),
        Title = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(16, 8),
            Size = UDim2.new(1, -32, 0, 24),
            BackgroundTransparency = 1,
            Text = boss.Name,
            TextColor3 = Color3.fromRGB(244, 226, 200),
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 26,
        }),
        Meta = React.createElement("TextLabel", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -16, 0, 10),
            Size = UDim2.fromOffset(130, 20),
            BackgroundTransparency = 1,
            Text = boss.RecommendedLevel
                    and string.format("Recommended Lv. %d", boss.RecommendedLevel)
                or "FIELD BOSS",
            TextColor3 = Color3.fromRGB(181, 151, 117),
            TextSize = 9,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 26,
        }),
        Track = React.createElement("Frame", {
            Position = UDim2.fromOffset(16, 39),
            Size = UDim2.new(1, -32, 0, 20),
            BackgroundColor3 = Color3.fromRGB(44, 31, 25),
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 26,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 5) }),
            Fill = React.createElement("Frame", {
                Size = UDim2.fromScale(fraction, 1),
                BackgroundColor3 = Color3.fromRGB(176, 72, 67),
                BorderSizePixel = 0,
                ZIndex = 27,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 5) }),
                Gradient = React.createElement("UIGradient", {
                    Color = ColorSequence.new(
                        Color3.fromRGB(208, 96, 76),
                        Color3.fromRGB(126, 54, 56)
                    ),
                    Rotation = 0,
                }),
            }),
            Value = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = string.format(
                    "%d / %d   ·   %d%%",
                    math.max(0, math.floor(boss.Health + 0.5)),
                    math.floor(boss.MaxHealth + 0.5),
                    math.floor(fraction * 100 + 0.5)
                ),
                TextColor3 = Color3.fromRGB(247, 238, 226),
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 28,
            }),
        }),
    })
end

return BossHud
