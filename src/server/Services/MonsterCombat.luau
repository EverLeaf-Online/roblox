local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local PlayerDamageService = require(script.Parent.PlayerDamageService)

local MonsterCombat = {}
local rng = Random.new()

local function getRoot(monster)
    return monster and monster:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(monster)
    return monster and monster:FindFirstChildOfClass("Humanoid")
end

local function makeHealthBar(monster, definition)
    local root = getRoot(monster)
    local humanoid = getHumanoid(monster)
    if not root or not humanoid or root:FindFirstChild("MonsterHealthBar") then
        return
    end

    local gui = Instance.new("BillboardGui")
    gui.Name = "MonsterHealthBar"
    gui.Size = UDim2.fromOffset(110, 28)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 85
    gui.Parent = root

    local name = Instance.new("TextLabel")
    name.Name = "Name"
    name.Size = UDim2.fromScale(1, 0.5)
    name.BackgroundTransparency = 1
    name.Text = definition.DisplayName or monster.Name
    name.TextColor3 = Color3.fromRGB(238, 244, 236)
    name.TextStrokeTransparency = 0.35
    name.Font = Enum.Font.GothamMedium
    name.TextScaled = true
    name.Parent = gui

    local back = Instance.new("Frame")
    back.Name = "Back"
    back.Position = UDim2.fromScale(0.08, 0.58)
    back.Size = UDim2.fromScale(0.84, 0.25)
    back.BackgroundColor3 = Color3.fromRGB(34, 37, 35)
    back.BorderSizePixel = 0
    back.Parent = gui

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = Color3.fromRGB(103, 211, 122)
    fill.BorderSizePixel = 0
    fill.Parent = back

    local function update()
        local ratio = if humanoid.MaxHealth > 0 then humanoid.Health / humanoid.MaxHealth else 0
        fill.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
    end
    update()
    humanoid.HealthChanged:Connect(update)
end

local function showDamage(monster, amount, text, color)
    local root = getRoot(monster)
    if not root then
        return
    end
    local gui = Instance.new("BillboardGui")
    gui.Name = "MonsterDamageNumber"
    gui.Size = UDim2.fromOffset(120, 44)
    gui.StudsOffsetWorldSpace = Vector3.new(rng:NextNumber(-0.8, 0.8), 4.4, 0)
    gui.AlwaysOnTop = true
    gui.Parent = root

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text or tostring(math.floor(amount or 0))
    label.TextColor3 = color or Color3.fromRGB(255, 227, 132)
    label.TextStrokeTransparency = 0.25
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = gui

    TweenService:Create(gui, TweenInfo.new(0.55, Enum.EasingStyle.Quad), {
        StudsOffsetWorldSpace = gui.StudsOffsetWorldSpace + Vector3.new(0, 2.1, 0),
    }):Play()
    TweenService
        :Create(label, TweenInfo.new(0.55), { TextTransparency = 1, TextStrokeTransparency = 1 })
        :Play()
    Debris:AddItem(gui, 0.65)
end

local function playFlinch(monster, duration)
    local root = getRoot(monster)
    if not root then
        return
    end
    monster:SetAttribute("MonsterReaction", "Hit")
    monster:SetAttribute("MonsterReactionUntil", os.clock() + duration)
    local original = root.CFrame
    root.CFrame = original * CFrame.Angles(math.rad(-4), 0, math.rad(rng:NextNumber(-5, 5)))
    task.delay(duration, function()
        if root.Parent and monster:GetAttribute("MonsterReaction") == "Hit" then
            monster:SetAttribute("MonsterReaction", "")
        end
    end)
end

local function tryDodge(monster, definition)
    local now = os.clock()
    if (monster:GetAttribute("MonsterNextDodgeAt") or 0) > now then
        return false
    end
    if rng:NextNumber() > (definition.DodgeChance or 0) then
        return false
    end

    local root = getRoot(monster)
    local humanoid = getHumanoid(monster)
    if not root or not humanoid then
        return false
    end

    local pause = definition.DodgePause or 0.4
    monster:SetAttribute("MonsterNextDodgeAt", now + (definition.DodgeCooldown or 4))
    monster:SetAttribute("MonsterInvulnerableUntil", now + pause)
    monster:SetAttribute("MonsterReaction", "Dodge")
    monster:SetAttribute("MonsterReactionUntil", now + pause)

    humanoid:Move(Vector3.zero, false)
    local backward = -root.CFrame.LookVector
    backward = Vector3.new(backward.X, 0, backward.Z)
    if backward.Magnitude > 0.01 then
        backward = backward.Unit
        local speed = (definition.DodgeDistance or 6) / math.max(0.2, pause)
        local verticalSpeed = 6
        if definition.Id == "skeleton" then
            verticalSpeed = 3
        elseif definition.Id == "peco_peco" then
            verticalSpeed = 10
        end
        root.AssemblyLinearVelocity =
            Vector3.new(backward.X * speed, verticalSpeed, backward.Z * speed)
    end
    showDamage(monster, 0, "DODGE", Color3.fromRGB(151, 230, 255))
    task.delay(pause, function()
        if monster.Parent and monster:GetAttribute("MonsterReaction") == "Dodge" then
            monster:SetAttribute("MonsterReaction", "")
        end
    end)
    return true
end

function MonsterCombat.Initialize(monster, definition)
    monster:SetAttribute("MonsterInvulnerableUntil", 0)
    monster:SetAttribute("MonsterNextDodgeAt", 0)
    monster:SetAttribute("MonsterReaction", "")
    monster:SetAttribute("MonsterReactionUntil", 0)
    makeHealthBar(monster, definition)
end

function MonsterCombat.ApplyPlayerHit(monster, definition, damage)
    local humanoid = getHumanoid(monster)
    if not humanoid or humanoid.Health <= 0 then
        return false, "dead"
    end
    if monster:GetAttribute("MonsterEmerging") == true then
        return false, "emerging"
    end
    if (monster:GetAttribute("MonsterInvulnerableUntil") or 0) > os.clock() then
        return false, "invulnerable"
    end
    if tryDodge(monster, definition) then
        return false, "dodged"
    end

    local applied = math.max(0, math.floor(damage))
    if applied <= 0 then
        return false, "no_damage"
    end
    humanoid:TakeDamage(applied)
    showDamage(monster, applied)
    if humanoid.Health > 0 then
        playFlinch(monster, definition.HitStun or 0.22)
    end
    return true, applied
end

function MonsterCombat.DamagePlayer(monster, player, definition)
    return PlayerDamageService.Apply(
        player,
        definition.Damage or 5,
        monster:GetAttribute("EnemyId")
    )
end

function MonsterCombat.PlayDeath(monster)
    monster:SetAttribute("MonsterReaction", "Dead")
    for _, descendant in monster:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.CanTouch = false
        end
    end

    local root = getRoot(monster)
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.Anchored = true

        local monsterId = monster:GetAttribute("EnemyId")
        local burstColor = Color3.fromRGB(150, 140, 120)
        local debrisColor = Color3.fromRGB(150, 140, 120)
        if monsterId == "skeleton" then
            burstColor = Color3.fromRGB(224, 219, 194)
            debrisColor = Color3.fromRGB(210, 205, 180)
        elseif monsterId == "slime" then
            burstColor = Color3.fromRGB(99, 224, 145)
            debrisColor = Color3.fromRGB(91, 190, 126)
        elseif monsterId == "peco_peco" then
            burstColor = Color3.fromRGB(226, 155, 72)
            debrisColor = Color3.fromRGB(201, 126, 57)
        end

        local burst = Instance.new("ParticleEmitter")
        burst.Name = "DeathBurst"
        burst.Texture = "rbxasset://textures/particles/smoke_main.dds"
        burst.Color = ColorSequence.new(burstColor)
        burst.Lifetime = NumberRange.new(0.35, 0.75)
        burst.Speed = NumberRange.new(5, 11)
        burst.Rate = 0
        burst.SpreadAngle = Vector2.new(180, 180)
        burst.Parent = root
        burst:Emit(if monsterId == "slime" then 26 else 18)
        Debris:AddItem(burst, 1)

        local debrisCount = if monsterId == "skeleton"
            then 8
            elseif monsterId == "peco_peco" then 7
            else 5
        for _ = 1, debrisCount do
            local piece = Instance.new("Part")
            piece.Name = "MonsterDeathDebris"
            piece.Anchored = false
            piece.CanCollide = false
            piece.CanTouch = false
            piece.Material = if monsterId == "slime"
                then Enum.Material.Neon
                else Enum.Material.SmoothPlastic
            piece.Color = debrisColor
            if monsterId == "skeleton" then
                piece.Size = Vector3.new(0.22, rng:NextNumber(0.7, 1.5), 0.22)
            elseif monsterId == "peco_peco" then
                piece.Size = Vector3.new(0.16, 0.7, 0.42)
            else
                local size = rng:NextNumber(0.28, 0.55)
                piece.Size = Vector3.new(size, size, size)
                piece.Shape = Enum.PartType.Ball
            end
            piece.CFrame = root.CFrame
                * CFrame.new(
                    rng:NextNumber(-1.2, 1.2),
                    rng:NextNumber(-0.2, 1.7),
                    rng:NextNumber(-1.2, 1.2)
                )
                * CFrame.Angles(
                    rng:NextNumber(0, math.pi),
                    rng:NextNumber(0, math.pi),
                    rng:NextNumber(0, math.pi)
                )
            piece.AssemblyLinearVelocity =
                Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(7, 14), rng:NextNumber(-8, 8))
            piece.Parent = workspace
            Debris:AddItem(piece, 1.6)
        end

        local bodyJoint = monster:FindFirstChild("BodyJoint", true)
        if bodyJoint and bodyJoint:IsA("Motor6D") then
            local deathTransform = if monsterId == "slime"
                then CFrame.new(0, -0.55, 0) * CFrame.Angles(0, 0, math.rad(8))
                else CFrame.Angles(math.rad(68), 0, math.rad(8))
            TweenService:Create(
                bodyJoint,
                TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { Transform = deathTransform }
            ):Play()
        end
    end
end

return MonsterCombat
