local MovementSanityService = require(script.Parent.MovementSanityService)

local WorldTravelService = {}
local spawns = {}

function WorldTravelService.RegisterSpawn(spawnId, instance)
    if type(spawnId) ~= "string" or spawnId == "" then
        return false, "invalid_spawn_id"
    end
    if typeof(instance) ~= "Instance" or not instance:IsA("BasePart") then
        return false, "invalid_spawn"
    end
    spawns[spawnId] = instance
    instance.Destroying:Once(function()
        if spawns[spawnId] == instance then
            spawns[spawnId] = nil
        end
    end)
    return true
end

function WorldTravelService.GetSpawn(spawnId)
    local spawn = spawns[spawnId]
    if spawn and spawn.Parent then
        return spawn
    end
    return nil
end

function WorldTravelService.SetRespawn(player, spawnId)
    local spawn = WorldTravelService.GetSpawn(spawnId)
    if not spawn then
        return false, "spawn_unavailable"
    end
    if spawn:IsA("SpawnLocation") then
        player.RespawnLocation = spawn
    end
    return true
end

function WorldTravelService.Teleport(player, spawnId)
    local spawn = WorldTravelService.GetSpawn(spawnId)
    if not spawn then
        return false, "spawn_unavailable"
    end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not humanoid or humanoid.Health <= 0 or not root then
        return false, "character_unavailable"
    end

    WorldTravelService.SetRespawn(player, spawnId)
    MovementSanityService.AllowTeleport(player)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    character:PivotTo(spawn.CFrame * CFrame.new(0, 4.2, 0))
    MovementSanityService.AllowTeleport(player)
    return true
end

function WorldTravelService.SyncPlayer(player, profile, moveCharacter)
    if type(profile) ~= "table" or type(profile.World) ~= "table" then
        return false, "invalid_profile"
    end
    local spawnId = profile.World.SpawnId
    local ok, reason = WorldTravelService.SetRespawn(player, spawnId)
    if not ok then
        return false, reason
    end
    if moveCharacter and player.Character then
        return WorldTravelService.Teleport(player, spawnId)
    end
    return true
end

return WorldTravelService
