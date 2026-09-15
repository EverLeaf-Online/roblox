local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DamageMath = require(ReplicatedStorage.Shared.Math.DamageMath)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerDamageFeedbackRules = require(ReplicatedStorage.Shared.Logic.PlayerDamageFeedbackRules)
local DerivedStatsService = require(script.Parent.DerivedStatsService)
local MovementSanityService = require(script.Parent.MovementSanityService)
local PlayerDataService = require(script.Parent.PlayerDataService)

local PlayerDamageService = {}
local damageEvent = Instance.new("BindableEvent")
PlayerDamageService.Event = damageEvent.Event
local lastDamageAt = {}
local staggerGeneration = {}

local function applyStagger(player, duration)
    duration = tonumber(duration) or 0
    if duration <= 0 then
        return
    end
    local generation = (staggerGeneration[player] or 0) + 1
    staggerGeneration[player] = generation
    player:SetAttribute("EverLeafStaggered", true)
    task.delay(duration, function()
        if player.Parent == Players and staggerGeneration[player] == generation then
            player:SetAttribute("EverLeafStaggered", false)
        end
    end)
end

local function applyImpulse(player, character, options)
    local root = character:FindFirstChild("HumanoidRootPart")
    local sourcePosition = options.SourcePosition
    local knockback = tonumber(options.Knockback) or 0
    local knockup = tonumber(options.Knockup) or 0
    if not root or typeof(sourcePosition) ~= "Vector3" or knockback <= 0 and knockup <= 0 then
        return
    end

    local delta = root.Position - sourcePosition
    local planar = Vector3.new(delta.X, 0, delta.Z)
    if planar.Magnitude <= 0.01 then
        local look = root.CFrame.LookVector
        planar = Vector3.new(look.X, 0, look.Z)
    end
    planar = planar.Magnitude > 0.01 and planar.Unit or Vector3.new(0, 0, 1)

    MovementSanityService.AllowExternalImpulse(
        player,
        math.max(0.45, (tonumber(options.Stagger) or 0) + 0.25)
    )
    local velocity = root.AssemblyLinearVelocity
    root.AssemblyLinearVelocity =
        Vector3.new(planar.X * knockback, math.max(velocity.Y, 0) + knockup, planar.Z * knockback)
end

function PlayerDamageService.Apply(player, amount, sourceId, options)
    if not player or player.Parent ~= Players then
        return false, "invalid_player"
    end
    if type(amount) ~= "number" or amount <= 0 or amount ~= amount then
        return false, "invalid_damage"
    end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not humanoid or humanoid.Health <= 0 then
        return false, "character_unavailable"
    end
    local now = os.clock()
    if now - (lastDamageAt[player] or 0) < GameConfig.Combat.PlayerDamageIFrames then
        return false, "invulnerable"
    end

    lastDamageAt[player] = now
    local profile = PlayerDataService.Get(player)
    local derived = profile and DerivedStatsService.Compute(profile) or nil
    local appliedDamage = DamageMath.MitigateIncoming(
        amount,
        derived and derived.Defense or 0,
        GameConfig.Combat.DefenseConstant
    )
    options = options or {}
    local feedback = PlayerDamageFeedbackRules.Build(
        amount,
        appliedDamage,
        humanoid.MaxHealth,
        options.Stagger,
        sourceId
    )
    humanoid:SetAttribute("LastDamageSource", feedback.SourceId)
    humanoid:SetAttribute("LastDamageRaw", feedback.RawAmount)
    humanoid:SetAttribute("LastDamageApplied", appliedDamage)
    humanoid:TakeDamage(appliedDamage)
    if humanoid.Health > 0 then
        applyImpulse(player, character, options)
        applyStagger(player, options.Stagger)
    end
    damageEvent:Fire(player, feedback)
    return true, humanoid.Health
end

function PlayerDamageService.GetLastDamageAt(player)
    return lastDamageAt[player] or -math.huge
end

Players.PlayerRemoving:Connect(function(player)
    lastDamageAt[player] = nil
    staggerGeneration[player] = nil
end)
return PlayerDamageService
