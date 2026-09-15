local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MovementSanityService = require(script.Parent.MovementSanityService)

local WorldTravelService = {}
local spawns = {}

local function getSpawnPosition(spawn)
    return spawn.Position + Vector3.new(0, 4.2, 0)
end

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

function WorldTravelService.Prepare(player, spawnId)
    local spawn = WorldTravelService.GetSpawn(spawnId)
    if not spawn then
        return false, "spawn_unavailable"
    end
    if typeof(player) ~= "Instance" or not player:IsA("Player") or not player.Parent then
        return false, "player_unavailable"
    end

    local timeout = math.max(0, tonumber(GameConfig.Streaming.PrefetchTimeoutSeconds) or 3)
    local ok, err = pcall(function()
        player:RequestStreamAroundAsync(getSpawnPosition(spawn), timeout)
    end)
    if not ok then
        warn(
            string.format(
                "[WorldTravelService] Stream prefetch failed for %s -> %s: %s",
                player.Name,
                spawnId,
                tostring(err)
            )
        )
        return false, "stream_prefetch_failed"
    end
    return true
end

function WorldTravelService.PreparePlayers(players, spawnId)
    if type(players) ~= "table" then
        return false, "invalid_players"
    end
    if not WorldTravelService.GetSpawn(spawnId) then
        return false, "spawn_unavailable"
    end
    if #players == 0 then
        return true, { Prepared = 0, Failed = 0 }
    end

    local remaining = #players
    local prepared = 0
    local failed = 0
    local completed = Instance.new("BindableEvent")

    for _, player in players do
        local member = player
        task.spawn(function()
            local ok = WorldTravelService.Prepare(member, spawnId)
            if ok then
                prepared += 1
            else
                failed += 1
            end
            remaining -= 1
            if remaining <= 0 then
                completed:Fire()
            end
        end)
    end

    if remaining > 0 then
        completed.Event:Wait()
    end
    completed:Destroy()
    return true, { Prepared = prepared, Failed = failed }
end

function WorldTravelService.Teleport(player, spawnId, options)
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

    options = options or {}
    if options.SkipStreamingPrefetch ~= true then
        -- Prefetch is deliberately fail-open. Streaming can time out on a slow
        -- client, but travel must not strand the player. Workspace streaming
        -- integrity pauses the local simulation if the destination is not ready.
        WorldTravelService.Prepare(player, spawnId)
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
