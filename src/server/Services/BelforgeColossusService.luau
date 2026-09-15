local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local BossDefinitions = require(script.Parent.Parent.Content.BossDefinitions)
local BelforgeAccessRules = require(ReplicatedStorage.Shared.Logic.BelforgeAccessRules)
local BelforgeColossusRules = require(ReplicatedStorage.Shared.Logic.BelforgeColossusRules)
local BelforgeEncounterRules = require(ReplicatedStorage.Shared.Logic.BelforgeEncounterRules)
local MonsterSpawnService = require(script.Parent.MonsterSpawnService)
local PartyService = require(script.Parent.PartyService)
local PlayerDamageService = require(script.Parent.PlayerDamageService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local WorldTravelService = require(script.Parent.WorldTravelService)

local BelforgeColossusService = {}
local BOSS_ID = "belforge_colossus"
local states = {}
local accumulator = 0
local ENCOUNTER_TRIGGER = "BelforgeColossusEncounter"
local MAX_PLAYERS = BossDefinitions.belforge_colossus.MaxPlayers
local WIPE_RESET_SECONDS = 8
local READY_CHECK_SECONDS = 20
local ASSEMBLY_RADIUS = 72
local encounter = {
    State = "Open",
    Participants = {},
    Eliminated = {},
    Boss = nil,
}

local function getRoot(model)
    return model and model:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(model)
    return model and model:FindFirstChildOfClass("Humanoid")
end

local function makeTelegraph(position, radius, color, windup)
    local marker = Instance.new("Part")
    marker.Name = "BelforgeTelegraph"
    marker.Shape = Enum.PartType.Cylinder
    marker.Size = Vector3.new(0.22, radius * 2, radius * 2)
    marker.CFrame = CFrame.new(position + Vector3.new(0, 0.15, 0))
        * CFrame.Angles(0, 0, math.rad(90))
    marker.Anchored = true
    marker.CanCollide = false
    marker.CanTouch = false
    marker.CanQuery = false
    marker.Material = Enum.Material.Neon
    marker.Color = color
    marker.Transparency = 0.62
    marker.Parent = Workspace

    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = 0.7
    light.Range = radius * 1.1
    light.Parent = marker

    TweenService
        :Create(
            marker,
            TweenInfo.new(
                math.max(0.15, windup * 0.82),
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.In
            ),
            { Transparency = 0.22 }
        )
        :Play()
    task.delay(windup, function()
        if marker.Parent then
            TweenService:Create(marker, TweenInfo.new(0.18), { Transparency = 1 }):Play()
        end
    end)
    Debris:AddItem(marker, windup + 0.25)
end

local function playersWithin(position, radius)
    local result = {}
    for _, player in Players:GetPlayers() do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if humanoid and humanoid.Health > 0 and root then
            local delta = root.Position - position
            local planar = Vector3.new(delta.X, 0, delta.Z)
            if planar.Magnitude <= radius and math.abs(delta.Y) <= 14 then
                table.insert(result, player)
            end
        end
    end
    return result
end

local function nearestPlayer(position, radius)
    local bestPlayer = nil
    local bestDistance = radius
    for _, player in Players:GetPlayers() do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if humanoid and humanoid.Health > 0 and root then
            local distance = (root.Position - position).Magnitude
            if distance <= bestDistance then
                bestDistance = distance
                bestPlayer = player
            end
        end
    end
    return bestPlayer
end

local function applyAreaDamage(
    enemy,
    position,
    radius,
    damage,
    knockback,
    knockup,
    stagger,
    sourceId
)
    if not enemy.Parent then
        return
    end
    local humanoid = getHumanoid(enemy)
    if not humanoid or humanoid.Health <= 0 then
        return
    end
    for _, player in playersWithin(position, radius) do
        PlayerDamageService.Apply(player, damage, sourceId, {
            SourcePosition = position,
            Knockback = knockback,
            Knockup = knockup,
            Stagger = stagger,
        })
    end
end

local function steamBurst(enemy, phase)
    local root = getRoot(enemy)
    if not root then
        return
    end
    local radius = if phase == 1 then 14 else if phase == 2 then 17 else 21
    local windup = if phase == 3 then 0.72 else 0.9
    local damage = BelforgeColossusRules.SpecialDamage(phase)
    local position = root.Position
    makeTelegraph(position, radius, Color3.fromRGB(243, 94, 38), windup)
    task.delay(windup, function()
        applyAreaDamage(
            enemy,
            position,
            radius,
            damage,
            if phase == 3 then 30 else 22,
            if phase == 3 then 9 else 6,
            if phase == 3 then 0.42 else 0.28,
            "belforge_colossus_steam"
        )
    end)
end

local function hammerfall(enemy, phase)
    local root = getRoot(enemy)
    if not root then
        return
    end
    local target = nearestPlayer(root.Position, 105)
    local character = target and target.Character
    local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        steamBurst(enemy, phase)
        return
    end

    local position = targetRoot.Position
    local radius = if phase == 3 then 10 else 8
    local windup = if phase == 3 then 0.7 else 0.88
    makeTelegraph(position, radius, Color3.fromRGB(255, 181, 62), windup)
    task.delay(windup, function()
        applyAreaDamage(
            enemy,
            position,
            radius,
            if phase == 3 then 42 else 32,
            if phase == 3 then 38 else 30,
            if phase == 3 then 12 else 9,
            if phase == 3 then 0.48 else 0.36,
            "belforge_colossus_hammerfall"
        )
    end)
end

local function performSpecial(enemy, state, phase)
    if phase == 1 then
        steamBurst(enemy, phase)
        return
    end
    state.Alternate = not state.Alternate
    if phase == 2 then
        if state.Alternate then
            hammerfall(enemy, phase)
        else
            steamBurst(enemy, phase)
        end
        return
    end

    hammerfall(enemy, phase)
    task.delay(0.72, function()
        if enemy.Parent then
            steamBurst(enemy, phase)
        end
    end)
end

local function updatePhase(enemy, state)
    local humanoid = state.Humanoid
    local phase, phaseName =
        BelforgeColossusRules.PhaseForHealth(humanoid.Health, humanoid.MaxHealth)
    if state.Phase ~= phase then
        state.Phase = phase
        state.NextSpecialAt = math.min(state.NextSpecialAt, os.clock() + 1.3)
    end
    enemy:SetAttribute("BelforgePhase", phase)
    enemy:SetAttribute("BelforgePhaseName", phaseName)
    return phase
end

local function participantCount()
    local count = 0
    for player in encounter.Participants do
        if player.Parent == Players then
            count += 1
        end
    end
    return count
end

local function clearAttempt(nextState)
    encounter.State = nextState or "Open"
    encounter.Participants = {}
    encounter.Eliminated = {}
    encounter.Boss = nil
end

local function refreshCooldownState()
    if encounter.State ~= "VictoryCooldown" and encounter.State ~= "Resetting" then
        return
    end
    local spawnState = MonsterSpawnService.GetStateByName(ENCOUNTER_TRIGGER)
    if spawnState == "Idle" then
        clearAttempt("Open")
    end
end

local function wipeIfNeeded()
    if encounter.State ~= "Active" then
        return
    end
    if not BelforgeEncounterRules.AllEliminated(encounter.Participants, encounter.Eliminated) then
        return
    end

    encounter.State = "Resetting"
    local boss = encounter.Boss
    encounter.Boss = nil
    if boss and boss.Parent then
        boss:Destroy()
    end
    MonsterSpawnService.ForceCooldownByName(ENCOUNTER_TRIGGER, WIPE_RESET_SECONDS)
end

local function validatePartyAssembly(party)
    if not party or not party.Leader or #party.Members < 2 then
        return false, "party_too_small"
    end
    if #party.Members + participantCount() > MAX_PLAYERS then
        return false, "encounter_full"
    end

    local antechamber = WorldTravelService.GetSpawn("belforge_antechamber")
    if not antechamber then
        return false, "spawn_unavailable"
    end

    for _, member in party.Members do
        if member.Parent ~= Players then
            return false, "party_member_unavailable"
        end
        local profile = PlayerDataService.Get(member)
        local allowed = BelforgeAccessRules.CanEnterColossus(profile)
        if not allowed then
            return false, "party_member_ineligible"
        end
        local character = member.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or humanoid.Health <= 0 or not root then
            return false, "party_member_unavailable"
        end
        if (root.Position - antechamber.Position).Magnitude > ASSEMBLY_RADIUS then
            return false, "party_not_assembled"
        end
    end
    return true
end

function BelforgeColossusService.StartPartyReadyCheck(player, profile)
    refreshCooldownState()
    local accessOk, accessReason = BelforgeAccessRules.CanEnterColossus(profile)
    if not accessOk then
        return false, accessReason
    end
    local party = PartyService.Get(player)
    if not party or #party.Members <= 1 then
        return false, "party_too_small"
    end
    if party.Leader ~= player then
        return false, "not_party_leader"
    end
    local canEnter, encounterReason =
        BelforgeEncounterRules.CanEnter(encounter.State, false, participantCount(), MAX_PLAYERS)
    if not canEnter then
        return false, encounterReason
    end
    local assembled, assemblyReason = validatePartyAssembly(party)
    if not assembled then
        return false, assemblyReason
    end
    return PartyService.StartReadyCheck(player, BOSS_ID, READY_CHECK_SECONDS)
end

function BelforgeColossusService.RequestEntry(player, profile)
    local party = PartyService.Get(player)
    if party and #party.Members > 1 then
        return BelforgeColossusService.StartPartyReadyCheck(player, profile)
    end
    return BelforgeColossusService.EnterArena(player, profile)
end

function BelforgeColossusService.RespondPartyReadyCheck(player, accepted)
    local ok, result = PartyService.RespondReadyCheck(player, accepted)
    if not ok then
        return false, result
    end
    if not result.Complete then
        return true, result
    end
    if result.Purpose ~= BOSS_ID then
        PartyService.NotifyReadyCheckOutcome(result.Party, false, "invalid_ready_check")
        return false, "invalid_ready_check"
    end

    refreshCooldownState()
    local canEnter, encounterReason =
        BelforgeEncounterRules.CanEnter(encounter.State, false, participantCount(), MAX_PLAYERS)
    if not canEnter then
        PartyService.NotifyReadyCheckOutcome(result.Party, false, encounterReason)
        return false, encounterReason
    end
    local assembled, assemblyReason = validatePartyAssembly(result.Party)
    if not assembled then
        PartyService.NotifyReadyCheckOutcome(result.Party, false, assemblyReason)
        return false, assemblyReason
    end

    -- Stream the sealed arena to every ready member in parallel before moving
    -- anyone. A slow member must not multiply group-entry latency by party size.
    WorldTravelService.PreparePlayers(result.Members, "belforge_colossus_arena")

    local entered = {}
    for _, member in result.Members do
        local profile = PlayerDataService.Get(member)
        local moved, moveReason = BelforgeColossusService.EnterArena(member, profile, {
            SkipStreamingPrefetch = true,
        })
        if not moved then
            for _, enteredMember in entered do
                BelforgeColossusService.LeaveArena(enteredMember)
            end
            PartyService.NotifyReadyCheckOutcome(result.Party, false, moveReason)
            return false, moveReason
        end
        table.insert(entered, member)
    end

    PartyService.NotifyReadyCheckOutcome(result.Party, true, "belforge_entry")
    return true, { Complete = true, Entered = true }
end

function BelforgeColossusService.EnterArena(player, profile, options)
    refreshCooldownState()
    local accessOk, accessReason = BelforgeAccessRules.CanEnterColossus(profile)
    if not accessOk then
        return false, accessReason
    end
    local isRegistered = encounter.Participants[player] == true
    local canEnter, reason = BelforgeEncounterRules.CanEnter(
        encounter.State,
        isRegistered,
        participantCount(),
        MAX_PLAYERS
    )
    if not canEnter then
        return false, reason
    end

    encounter.Participants[player] = true
    encounter.Eliminated[player] = nil
    WorldTravelService.SetRespawn(player, "belforge_antechamber")
    local teleported, teleportReason =
        WorldTravelService.Teleport(player, "belforge_colossus_arena", options)
    if not teleported and not isRegistered then
        encounter.Participants[player] = nil
        encounter.Eliminated[player] = nil
    end
    return teleported, teleportReason
end

function BelforgeColossusService.LeaveArena(player)
    if encounter.Participants[player] then
        if encounter.State == "Active" then
            encounter.Eliminated[player] = true
            wipeIfNeeded()
        else
            encounter.Participants[player] = nil
            encounter.Eliminated[player] = nil
        end
    end
    return WorldTravelService.Teleport(player, "belforge_antechamber")
end

function BelforgeColossusService.GetEncounterState()
    refreshCooldownState()
    return encounter.State, participantCount()
end

local function attach(enemy)
    if states[enemy] or not enemy:IsA("Model") or enemy:GetAttribute("EnemyId") ~= BOSS_ID then
        return
    end
    local humanoid = getHumanoid(enemy)
    local root = getRoot(enemy)
    if not humanoid or not root then
        return
    end
    local state = {
        Humanoid = humanoid,
        Root = root,
        Phase = 0,
        NextSpecialAt = os.clock() + 3.2,
        Alternate = false,
    }
    states[enemy] = state
    encounter.State = "Active"
    encounter.Boss = enemy
    -- Participants are registered only by explicit arena entry. Nearby players
    -- outside the sealed arena must never count toward wipe/lockout state.
    updatePhase(enemy, state)

    humanoid.HealthChanged:Connect(function()
        if states[enemy] == state and humanoid.Health > 0 then
            updatePhase(enemy, state)
        end
    end)
    humanoid.Died:Connect(function()
        states[enemy] = nil
        if encounter.Boss == enemy then
            encounter.Boss = nil
            encounter.State = "VictoryCooldown"
            encounter.Participants = {}
            encounter.Eliminated = {}
        end
    end)
    enemy.Destroying:Once(function()
        states[enemy] = nil
        if encounter.Boss == enemy then
            encounter.Boss = nil
        end
    end)
end

function BelforgeColossusService.Init()
    for _, enemy in CollectionService:GetTagged("EverLeafEnemy") do
        attach(enemy)
    end
    CollectionService:GetInstanceAddedSignal("EverLeafEnemy"):Connect(function(enemy)
        task.defer(attach, enemy)
    end)

    Players.PlayerRemoving:Connect(function(player)
        if encounter.Participants[player] then
            encounter.Eliminated[player] = true
            wipeIfNeeded()
        end
        encounter.Participants[player] = nil
        encounter.Eliminated[player] = nil
    end)

    for _, player in Players:GetPlayers() do
        player.CharacterAdded:Connect(function(character)
            local humanoid = character:WaitForChild("Humanoid")
            humanoid.Died:Connect(function()
                if encounter.State == "Active" and encounter.Participants[player] then
                    encounter.Eliminated[player] = true
                    wipeIfNeeded()
                end
            end)
        end)
    end
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            local humanoid = character:WaitForChild("Humanoid")
            humanoid.Died:Connect(function()
                if encounter.State == "Active" and encounter.Participants[player] then
                    encounter.Eliminated[player] = true
                    wipeIfNeeded()
                end
            end)
        end)
    end)

    RunService.Heartbeat:Connect(function(deltaTime)
        accumulator += deltaTime
        if accumulator < 0.15 then
            return
        end
        accumulator = 0
        local now = os.clock()
        refreshCooldownState()
        for enemy, state in states do
            local humanoid = state.Humanoid
            if not enemy.Parent or not humanoid.Parent or humanoid.Health <= 0 then
                states[enemy] = nil
                continue
            end
            if enemy:GetAttribute("MonsterEmerging") == true then
                continue
            end
            local phase = updatePhase(enemy, state)
            if now >= state.NextSpecialAt then
                state.NextSpecialAt = now + BelforgeColossusRules.SpecialInterval(phase)
                task.spawn(performSpecial, enemy, state, phase)
            end
        end
    end)
end

return BelforgeColossusService
