local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MovementSanityService = require(script.Parent.MovementSanityService)

local PlayerDodgeService = {}
local states = {}

local function clearActiveState(player, generation)
    local state = states[player]
    if not state or state.Generation ~= generation then
        return
    end
    state.ActiveUntil = 0
    state.InvulnerableUntil = 0
    if player.Parent == Players then
        player:SetAttribute("EverLeafDodging", false)
    end
end

function PlayerDodgeService.TryStart(player, directionX, directionZ)
    if not player or player.Parent ~= Players then
        return false, "invalid_player"
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root then
        return false, "character_unavailable"
    end
    if player:GetAttribute("EverLeafStaggered") == true then
        return false, "staggered"
    end
    if humanoid.FloorMaterial == Enum.Material.Air then
        return false, "airborne"
    end

    directionX = tonumber(directionX)
    directionZ = tonumber(directionZ)
    if not directionX or not directionZ then
        return false, "invalid_direction"
    end
    if directionX ~= directionX or directionZ ~= directionZ then
        return false, "invalid_direction"
    end
    local direction = Vector3.new(directionX, 0, directionZ)
    if direction.Magnitude < 0.5 or direction.Magnitude > 1.1 then
        return false, "invalid_direction"
    end
    direction = direction.Unit

    local now = os.clock()
    local previous = states[player]
    if previous and now - previous.LastStartedAt < GameConfig.Movement.DodgeCooldown then
        return false, "cooldown"
    end

    local generation = (previous and previous.Generation or 0) + 1
    states[player] = {
        Generation = generation,
        LastStartedAt = now,
        ActiveUntil = now + GameConfig.Movement.DodgeDuration,
        InvulnerableUntil = now + GameConfig.Movement.DodgeIFrameDuration,
        Direction = direction,
    }

    player:SetAttribute("EverLeafCrouching", false)
    player:SetAttribute("EverLeafDodging", true)
    MovementSanityService.AllowExternalImpulse(player, GameConfig.Movement.DodgeServerGraceSeconds)

    task.delay(GameConfig.Movement.DodgeDuration + 0.04, function()
        clearActiveState(player, generation)
    end)

    return true
end

function PlayerDodgeService.IsActive(player)
    local state = states[player]
    return state ~= nil and os.clock() <= state.ActiveUntil
end

function PlayerDodgeService.IsInvulnerable(player)
    local state = states[player]
    return state ~= nil and os.clock() <= state.InvulnerableUntil
end

function PlayerDodgeService.GetLastStartedAt(player)
    local state = states[player]
    return state and state.LastStartedAt or -math.huge
end

function PlayerDodgeService.Init()
    Players.PlayerRemoving:Connect(function(player)
        states[player] = nil
    end)
end

return PlayerDodgeService
