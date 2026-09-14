local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BossDefinitions = require(script.Parent.Parent.Content.BossDefinitions)
local InstanceService = require(script.Parent.InstanceService)
local InstanceTeleportService = require(script.Parent.InstanceTeleportService)
local StateMachine = require(ReplicatedStorage.Shared.StateMachine)

local BossService = {}
local encounterMachines = {}

function BossService.GetDefinition(bossId)
    return BossDefinitions[bossId]
end

function BossService.CreateEncounter(bossId, ownerUserId, memberUserIds)
    local definition = BossDefinitions[bossId]
    if not definition then
        return false, "unknown_boss"
    end
    memberUserIds = memberUserIds or { ownerUserId }
    if #memberUserIds > definition.MaxPlayers then
        return false, "too_many_players"
    end
    local instanceState = InstanceService.Create("Boss:" .. bossId, ownerUserId, memberUserIds)
    encounterMachines[instanceState.Id] = StateMachine.new("Waiting", {
        Waiting = { "Active", "Closed" },
        Active = { "Victory", "Failed", "Closed" },
        Victory = { "Closed" },
        Failed = { "Closed" },
        Closed = {},
    })
    return true, instanceState
end

function BossService.Launch(instanceId, players)
    local instanceState = InstanceService.Get(instanceId)
    if not instanceState then
        return false, "unknown_encounter"
    end
    return InstanceTeleportService.Teleport(players, instanceState)
end

function BossService.Transition(instanceId, nextState)
    local machine = encounterMachines[instanceId]
    if not machine then
        return false, "unknown_encounter"
    end
    local ok, reason = machine:Transition(nextState)
    if ok and nextState == "Closed" then
        encounterMachines[instanceId] = nil
        InstanceService.Close(instanceId)
    end
    return ok, reason
end

function BossService.GetState(instanceId)
    local machine = encounterMachines[instanceId]
    return machine and machine:GetState() or nil
end

return BossService
