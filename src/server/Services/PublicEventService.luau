local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PublicEventDefinitions = require(script.Parent.Parent.Content.PublicEventDefinitions)
local EnemySpawnerService = require(script.Parent.EnemySpawnerService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local QuestObjectiveService = require(script.Parent.QuestObjectiveService)
local RewardService = require(script.Parent.RewardService)
local WorldNoticeService = require(script.Parent.WorldNoticeService)

local PublicEventService = {}
local event = Instance.new("BindableEvent")
local active = nil
local generation = 0
local rng = Random.new()
local initialized = false
local rotationIndex = 0

PublicEventService.Event = event.Event

local function tuning()
    return GameConfig.PublicEvents or {}
end

local function eligiblePlayer(player, definition)
    local profile = PlayerDataService.Get(player)
    if not profile or not profile.World or profile.World.RegionId ~= definition.RegionId then
        return false
    end
    local minimumLevel = math.max(1, tonumber(definition.MinimumLevel) or 1)
    return (tonumber(profile.Level) or 1) >= minimumLevel
end

local function recipientCount(definition)
    local count = 0
    for _, player in Players:GetPlayers() do
        if eligiblePlayer(player, definition) then
            count += 1
        end
    end
    return count
end

local function broadcast(payload, definition)
    for _, player in Players:GetPlayers() do
        if eligiblePlayer(player, definition) then
            event:Fire(player, payload)
        end
    end
end

local function stateSnapshot(state)
    return {
        Id = state.Id,
        Title = state.Definition.DisplayName,
        RegionId = state.Definition.RegionId,
        MinimumLevel = math.max(1, tonumber(state.Definition.MinimumLevel) or 1),
        Stage = state.Wave,
        StageCount = #state.Definition.Waves,
        Alive = state.Alive,
        EndsIn = math.max(0, state.EndsAt - os.clock()),
        Center = state.Definition.Center,
        Radius = state.Definition.Radius,
    }
end

local function broadcastState(state, eventType)
    broadcast({ Type = eventType or "Changed", Event = stateSnapshot(state) }, state.Definition)
end

local function noticeRegion(definition, kind, title, body, duration)
    for _, player in Players:GetPlayers() do
        if eligiblePlayer(player, definition) then
            WorldNoticeService.Send(player, {
                Kind = kind,
                Title = title,
                Body = body,
                Duration = duration or 5,
            })
        end
    end
end

local function eventParent(definition)
    local worldName = definition.WorldModelName or "EverLeafGeneratedWorld"
    local world = Workspace:FindFirstChild(worldName)
    if not world then
        return Workspace
    end
    local folder = world:FindFirstChild("PublicEvents")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "PublicEvents"
        folder.Parent = world
    end
    return folder
end

local function resolveGroundInclude(definition)
    if type(definition.GroundSurfaceName) ~= "string" or definition.GroundSurfaceName == "" then
        return nil
    end
    local root = Workspace
    if type(definition.WorldModelName) == "string" and definition.WorldModelName ~= "" then
        root = Workspace:FindFirstChild(definition.WorldModelName)
        if not root then
            return nil, "event_world_unavailable"
        end
    end
    local surface = root:FindFirstChild(definition.GroundSurfaceName, true)
    if not surface or not surface:IsA("BasePart") then
        return nil, "event_ground_surface_unavailable"
    end
    return { surface }
end

local function cleanupState(state)
    if state.Folder and state.Folder.Parent then
        state.Folder:Destroy()
    end
end

local function finish(state, succeeded, reason)
    if active ~= state or state.Finished then
        return
    end
    state.Finished = true
    active = nil
    cleanupState(state)

    if succeeded then
        local rewarded = 0
        for userId in state.Participants do
            local player = Players:GetPlayerByUserId(userId)
            local profile = player and PlayerDataService.Get(player)
            if player and profile then
                local ok = RewardService.Grant(profile, state.Definition.Reward)
                if ok then
                    QuestObjectiveService.Record(profile, "PublicEvent", state.Id, 1)
                    PlayerDataService.NotifyChanged(player)
                    rewarded += 1
                end
            end
        end
        broadcast({
            Type = "Completed",
            Event = stateSnapshot(state),
            Reward = state.Definition.Reward,
            RewardedPlayers = rewarded,
        }, state.Definition)
        noticeRegion(
            state.Definition,
            "success",
            state.Definition.DisplayName .. " Cleared",
            state.Definition.SuccessText
                or "The threat is contained. Participating Wayfarers received an event reward.",
            5
        )
    else
        broadcast(
            { Type = "Failed", Event = stateSnapshot(state), Reason = reason },
            state.Definition
        )
        noticeRegion(
            state.Definition,
            "warning",
            state.Definition.DisplayName .. " Failed",
            state.Definition.FailureText
                or "The response failed. Local defenders will regroup before the next attempt.",
            5
        )
    end
end

local function randomSpawnPosition(definition)
    local angle = rng:NextNumber(0, math.pi * 2)
    local outerRadius = math.max(8, tonumber(definition.SpawnRadius) or definition.Radius * 0.72)
    local innerRadius = math.clamp(tonumber(definition.SpawnInnerRadius) or 34, 0, outerRadius)
    local distance = rng:NextNumber(innerRadius, outerRadius)
    return definition.Center
        + Vector3.new(math.cos(angle) * distance, 8, math.sin(angle) * distance)
end

local function markParticipants(userIds, state)
    if type(userIds) ~= "table" then
        return
    end
    for _, userId in userIds do
        if type(userId) == "number" then
            state.Participants[userId] = true
        end
    end
end

local spawnWave
spawnWave = function(state)
    if active ~= state or state.Finished then
        return
    end
    local wave = state.Definition.Waves[state.Wave]
    if not wave then
        finish(state, true, "completed")
        return
    end
    state.Alive = 0
    for _, group in wave do
        for _ = 1, group.Count do
            state.Alive += 1
            local enemy, reason = EnemySpawnerService.Spawn(
                group.MonsterId,
                randomSpawnPosition(state.Definition),
                state.Folder,
                {
                    AutoRespawn = false,
                    GroundToTerrain = state.GroundInclude == nil,
                    GroundInclude = state.GroundInclude,
                    DeathLinger = 2.0,
                    OnDeath = function(_, _, _, eligibleUserIds)
                        if active ~= state or state.Finished then
                            return
                        end
                        markParticipants(eligibleUserIds, state)
                        state.Alive = math.max(0, state.Alive - 1)
                        broadcastState(state, "Changed")
                        if state.Alive == 0 then
                            state.Wave += 1
                            task.delay(3, function()
                                spawnWave(state)
                            end)
                        end
                    end,
                }
            )
            if not enemy then
                state.Alive = math.max(0, state.Alive - 1)
                warn(
                    string.format(
                        "[PublicEventService] Spawn failed for %s: %s",
                        group.MonsterId,
                        tostring(reason)
                    )
                )
            else
                enemy:SetAttribute("PublicEventId", state.Id)
                enemy:SetAttribute("PublicEventWave", state.Wave)
            end
        end
    end
    broadcastState(state, "Changed")
    if state.Alive == 0 then
        state.Wave += 1
        task.delay(1, function()
            spawnWave(state)
        end)
    end
end

function PublicEventService.GetActive()
    return active and stateSnapshot(active) or nil
end

function PublicEventService.SendSnapshot(player)
    if not active or not player or player.Parent ~= Players then
        return false
    end
    if not eligiblePlayer(player, active.Definition) then
        return false
    end
    event:Fire(player, { Type = "Started", Event = stateSnapshot(active) })
    return true
end

function PublicEventService.Start(eventId)
    if active then
        return false, "event_already_active"
    end
    local definition = PublicEventDefinitions[eventId]
    if not definition then
        return false, "unknown_public_event"
    end
    if recipientCount(definition) == 0 then
        return false, "no_eligible_players_in_region"
    end

    local groundInclude, groundReason = resolveGroundInclude(definition)
    if definition.GroundSurfaceName and not groundInclude then
        return false, groundReason or "event_ground_surface_unavailable"
    end

    generation += 1
    local folder = Instance.new("Folder")
    folder.Name = "PublicEvent_" .. eventId .. "_" .. generation
    folder.Parent = eventParent(definition)
    local duration = tonumber(definition.DurationSeconds)
        or tonumber(tuning().DurationSeconds)
        or 180
    local state = {
        Id = eventId,
        Definition = definition,
        Wave = 1,
        Alive = 0,
        Participants = {},
        EndsAt = os.clock() + duration,
        Folder = folder,
        Finished = false,
        Generation = generation,
        GroundInclude = groundInclude,
    }
    active = state
    broadcastState(state, "Started")
    noticeRegion(
        definition,
        "warning",
        definition.DisplayName,
        definition.StartText or "A public threat has emerged. Join nearby Wayfarers to contain it.",
        6
    )
    spawnWave(state)
    task.delay(duration, function()
        if active == state and not state.Finished then
            finish(state, false, "timeout")
        end
    end)
    return true, stateSnapshot(state)
end

local function nextConfiguredEventId()
    local order = tuning().Order
    if type(order) ~= "table" or #order == 0 then
        local fallback = PublicEventDefinitions.greenway_breach
        return fallback and recipientCount(fallback) > 0 and "greenway_breach" or nil
    end
    for _ = 1, #order do
        rotationIndex = (rotationIndex % #order) + 1
        local eventId = order[rotationIndex]
        local definition = type(eventId) == "string" and PublicEventDefinitions[eventId] or nil
        if definition and recipientCount(definition) > 0 then
            return eventId
        end
    end
    return nil
end

function PublicEventService.Init()
    if initialized then
        return
    end
    initialized = true
    if tuning().Enabled == false then
        return
    end
    task.spawn(function()
        task.wait(math.max(10, tonumber(tuning().InitialDelaySeconds) or 90))
        while true do
            if not active then
                local eventId = nextConfiguredEventId()
                if eventId then
                    PublicEventService.Start(eventId)
                end
            end
            task.wait(math.max(60, tonumber(tuning().CooldownSeconds) or 300))
        end
    end)
end

return PublicEventService
