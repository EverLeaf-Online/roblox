local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MonsterReactionMath = require(ReplicatedStorage.Shared.Math.MonsterReactionMath)
local MonsterAnimationService = require(script.Parent.MonsterAnimationService)
local PlayerDamageService = require(script.Parent.PlayerDamageService)

local MonsterCombat = {}
local rng = Random.new()

local function getRoot(monster)
    return monster and monster:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(monster)
    return monster and monster:FindFirstChildOfClass("Humanoid")
end

local function playSound(parent, soundId, volume, playbackSpeed)
    if not parent then
        return
    end
    local sound = Instance.new("Sound")
    sound.Name = "MonsterSfx"
    sound.SoundId = soundId
    sound.Volume = volume or 0.35
    sound.PlaybackSpeed = playbackSpeed or 1
    sound.RollOffMaxDistance = 55
    sound.Parent = parent
    sound:Play()
    Debris:AddItem(sound, 3)
end

local function effectColor(monsterId)
    if monsterId == "skeleton" or monsterId == "gravebone_captain" then
        return Color3.fromRGB(231, 223, 196)
    elseif monsterId == "slime" or monsterId == "royal_glowcap" then
        return Color3.fromRGB(104, 237, 157)
    elseif monsterId == "peco_peco" then
        return Color3.fromRGB(242, 171, 75)
    elseif monsterId == "brambleback" or monsterId == "mosswarden" then
        return Color3.fromRGB(121, 187, 96)
    elseif monsterId == "lumen_wisp" then
        return Color3.fromRGB(111, 237, 219)
    elseif monsterId == "rivet_scuttler" then
        return Color3.fromRGB(210, 146, 67)
    elseif monsterId == "slagmite" then
        return Color3.fromRGB(247, 116, 45)
    elseif monsterId == "gearjaw_hound" then
        return Color3.fromRGB(216, 145, 67)
    elseif monsterId == "cindercoil" then
        return Color3.fromRGB(255, 103, 42)
    elseif monsterId == "pressure_bastion" then
        return Color3.fromRGB(235, 91, 50)
    elseif monsterId == "furnace_husk" then
        return Color3.fromRGB(240, 114, 48)
    elseif monsterId == "arc_siphon" then
        return Color3.fromRGB(100, 205, 255)
    elseif monsterId == "railbreaker" then
        return Color3.fromRGB(225, 89, 48)
    elseif monsterId == "blueflame_sentry" then
        return Color3.fromRGB(91, 193, 242)
    elseif monsterId == "foundry_reaver" then
        return Color3.fromRGB(193, 126, 62)
    elseif monsterId == "smelter_golem" then
        return Color3.fromRGB(255, 86, 34)
    elseif monsterId == "forge_specter" then
        return Color3.fromRGB(199, 108, 242)
    elseif monsterId == "ironclad_enforcer" then
        return Color3.fromRGB(196, 129, 62)
    elseif monsterId == "molten_drake" then
        return Color3.fromRGB(255, 91, 35)
    elseif monsterId == "bellows_titan" then
        return Color3.fromRGB(243, 79, 32)
    elseif monsterId == "belforge_sentinel" then
        return Color3.fromRGB(224, 151, 64)
    elseif monsterId == "belforge_colossus" then
        return Color3.fromRGB(255, 83, 34)
    end
    return Color3.fromRGB(219, 211, 172)
end

local function hitBurst(monster)
    local root = getRoot(monster)
    if not root then
        return
    end
    local monsterId = monster:GetAttribute("EnemyId")
    local color = effectColor(monsterId)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "MonsterHitBurst"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color = ColorSequence.new(color)
    emitter.Lifetime = NumberRange.new(0.12, 0.28)
    emitter.Speed = NumberRange.new(4, 9)
    emitter.Rate = 0
    emitter.SpreadAngle = Vector2.new(160, 160)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.45),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Parent = root
    emitter:Emit(monsterId == "mosswarden" and 22 or 10)
    Debris:AddItem(emitter, 0.5)

    local highlight = Instance.new("Highlight")
    highlight.Name = "HitFlash"
    highlight.FillColor = color
    highlight.FillTransparency = 0.35
    highlight.OutlineTransparency = 1
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = monster
    TweenService:Create(highlight, TweenInfo.new(0.16), { FillTransparency = 1 }):Play()
    Debris:AddItem(highlight, 0.2)

    playSound(root, "rbxasset://sounds/electronicpingshort.wav", 0.22, rng:NextNumber(0.9, 1.1))
end

local function makeHealthBar(monster, definition)
    local root = getRoot(monster)
    local humanoid = getHumanoid(monster)
    if not root or not humanoid or root:FindFirstChild("MonsterHealthBar") then
        return
    end

    local gui = Instance.new("BillboardGui")
    gui.Name = "MonsterHealthBar"
    gui.Size = if definition.Boss
        then UDim2.fromOffset(230, 48)
        else if definition.Elite then UDim2.fromOffset(170, 38) else UDim2.fromOffset(132, 34)
    gui.StudsOffsetWorldSpace = Vector3.new(0, if definition.Boss then 7.6 else 4.8, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 85
    gui.Parent = root

    local name = Instance.new("TextLabel")
    name.Name = "Name"
    name.Size = UDim2.fromScale(1, 0.48)
    name.BackgroundTransparency = 1
    name.Text = definition.DisplayName or monster.Name
    name.TextColor3 = if definition.Boss
        then Color3.fromRGB(255, 212, 112)
        else if definition.Elite
            then Color3.fromRGB(210, 177, 255)
            else Color3.fromRGB(238, 244, 236)
    name.TextStrokeColor3 = Color3.fromRGB(16, 25, 22)
    name.TextStrokeTransparency = 0.2
    name.Font = if definition.Boss then Enum.Font.GothamBold else Enum.Font.GothamMedium
    name.TextScaled = true
    name.Parent = gui

    local back = Instance.new("Frame")
    back.Name = "Back"
    back.Position = UDim2.fromScale(0.08, 0.58)
    back.Size = UDim2.fromScale(0.84, 0.24)
    back.BackgroundColor3 = Color3.fromRGB(17, 24, 23)
    back.BorderSizePixel = 0
    back.Parent = gui
    local backCorner = Instance.new("UICorner")
    backCorner.CornerRadius = UDim.new(1, 0)
    backCorner.Parent = back
    local backStroke = Instance.new("UIStroke")
    backStroke.Color = if definition.Boss
        then Color3.fromRGB(211, 163, 93)
        else if definition.Elite
            then Color3.fromRGB(159, 124, 203)
            else Color3.fromRGB(83, 126, 108)
    backStroke.Transparency = 0.35
    backStroke.Thickness = 1
    backStroke.Parent = back

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = if definition.Boss
        then Color3.fromRGB(205, 114, 76)
        else if definition.Elite
            then Color3.fromRGB(152, 109, 220)
            else Color3.fromRGB(103, 211, 122)
    fill.BorderSizePixel = 0
    fill.Parent = back
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local function update()
        local ratio = if humanoid.MaxHealth > 0 then humanoid.Health / humanoid.MaxHealth else 0
        TweenService:Create(
            fill,
            TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1) }
        ):Play()
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
    gui.Size = UDim2.fromOffset(132, 48)
    gui.StudsOffsetWorldSpace = Vector3.new(rng:NextNumber(-0.8, 0.8), 4.7, 0)
    gui.AlwaysOnTop = true
    gui.Parent = root

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text or tostring(math.floor(amount or 0))
    label.TextColor3 = color or Color3.fromRGB(255, 227, 132)
    label.TextStrokeColor3 = Color3.fromRGB(22, 24, 23)
    label.TextStrokeTransparency = 0.14
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

local function applyPlayerKnockback(monster, sourcePosition, knockback, knockup)
    local root = getRoot(monster)
    if not root or root.Anchored or typeof(sourcePosition) ~= "Vector3" then
        return
    end
    if knockback <= 0 and knockup <= 0 then
        return
    end

    local delta = root.Position - sourcePosition
    local planar = Vector3.new(delta.X, 0, delta.Z)
    if planar.Magnitude <= 0.01 then
        local look = root.CFrame.LookVector
        planar = Vector3.new(look.X, 0, look.Z)
    end
    planar = planar.Magnitude > 0.01 and planar.Unit or Vector3.new(0, 0, 1)

    local velocity = root.AssemblyLinearVelocity
    root.AssemblyLinearVelocity =
        Vector3.new(planar.X * knockback, math.max(velocity.Y, 0) + knockup, planar.Z * knockback)
end

local function playFlinch(monster, duration)
    local root = getRoot(monster)
    if not root or duration <= 0 then
        return
    end
    monster:SetAttribute("MonsterReaction", "Hit")
    monster:SetAttribute("MonsterReactionUntil", os.clock() + duration)
    MonsterAnimationService.Restart(monster, "Hit")
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
    MonsterAnimationService.Restart(monster, "Dodge")

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

function MonsterCombat.ApplyPlayerHit(monster, definition, damage, options)
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
    options = options or {}
    if options.Critical == true then
        showDamage(
            monster,
            applied,
            string.format("CRIT  %d", applied),
            Color3.fromRGB(255, 196, 76)
        )
    else
        showDamage(monster, applied)
    end
    hitBurst(monster)
    if humanoid.Health > 0 then
        local reaction = MonsterReactionMath.Resolve(definition, options, GameConfig.Combat)
        applyPlayerKnockback(monster, options.SourcePosition, reaction.Knockback, reaction.Knockup)
        if reaction.Interrupts then
            playFlinch(monster, reaction.Stagger)
        end
    end
    return true, applied
end

function MonsterCombat.DamagePlayer(monster, player, definition)
    local root = getRoot(monster)
    return PlayerDamageService.Apply(
        player,
        definition.Damage or 5,
        monster:GetAttribute("EnemyId"),
        {
            SourcePosition = root and root.Position or nil,
            Knockback = definition.PlayerKnockback or 0,
            Knockup = definition.PlayerKnockup or 0,
            Stagger = definition.PlayerStagger or 0,
        }
    )
end

function MonsterCombat.PlayDeath(monster)
    monster:SetAttribute("MonsterReaction", "Dead")
    MonsterAnimationService.PlayOneShot(monster, "Dead")
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
        local burstColor = effectColor(monsterId)
        local debrisColor = burstColor
        local deathSound = if monsterId == "slime" or monsterId == "royal_glowcap"
            then "rbxasset://sounds/impact_water.mp3"
            else "rbxasset://sounds/electronicpingshort.wav"
        playSound(
            root,
            deathSound,
            (monsterId == "mosswarden" or monsterId == "belforge_colossus") and 0.55 or 0.32,
            (monsterId == "mosswarden" or monsterId == "belforge_colossus") and 0.7 or 0.82
        )

        local burst = Instance.new("ParticleEmitter")
        burst.Name = "DeathBurst"
        burst.Texture = "rbxasset://textures/particles/smoke_main.dds"
        burst.Color = ColorSequence.new(burstColor)
        burst.Lifetime = NumberRange.new(0.35, 0.75)
        burst.Speed = NumberRange.new(5, 11)
        burst.Rate = 0
        burst.SpreadAngle = Vector2.new(180, 180)
        burst.Parent = root
        burst:Emit(
            if monsterId == "belforge_colossus" then 42 else if monsterId == "slime" then 26 else 18
        )
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
    end
end

return MonsterCombat
