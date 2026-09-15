local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartyInstanceRules = require(ReplicatedStorage.Shared.Logic.PartyInstanceRules)
local PlayerDataService = require(script.Parent.PlayerDataService)
local WorldTravelService = require(script.Parent.WorldTravelService)

local PartyInstanceService = {}

function PartyInstanceService.ValidateAssembly(party, initiator, definition, eligibilityCallback)
    if type(party) ~= "table" or not party.Leader or type(party.Members) ~= "table" then
        return false, "party_unavailable"
    end
    local allowed, reason = PartyInstanceRules.CanStart(
        initiator == party.Leader and initiator.Parent == Players,
        #party.Members,
        definition
    )
    if not allowed then
        return false, reason
    end

    local entrySpawn = WorldTravelService.GetSpawn(definition.EntrySpawnId)
    if not entrySpawn then
        return false, "spawn_unavailable"
    end

    for _, member in party.Members do
        if member.Parent ~= Players then
            return false, "party_member_unavailable"
        end
        local profile = PlayerDataService.Get(member)
        if not profile then
            return false, "party_member_unavailable"
        end
        if eligibilityCallback then
            local eligible, eligibilityReason = eligibilityCallback(member, profile)
            if not eligible then
                return false, eligibilityReason or "party_member_ineligible"
            end
        end

        local character = member.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or humanoid.Health <= 0 or not root then
            return false, "party_member_unavailable"
        end
        if
            not PartyInstanceRules.IsAssembled(
                (root.Position - entrySpawn.Position).Magnitude,
                definition
            )
        then
            return false, "party_not_assembled"
        end
    end
    return true
end

function PartyInstanceService.EnterGroup(members, definition, enterMember, rollbackMember)
    if type(members) ~= "table" or #members == 0 then
        return false, "invalid_members"
    end
    if
        type(definition) ~= "table"
        or not WorldTravelService.GetSpawn(definition.DestinationSpawnId)
    then
        return false, "spawn_unavailable"
    end
    if enterMember ~= nil and type(enterMember) ~= "function" then
        return false, "invalid_enter_callback"
    end
    if rollbackMember ~= nil and type(rollbackMember) ~= "function" then
        return false, "invalid_rollback_callback"
    end

    -- All clients prefetch concurrently so group latency is bounded by the
    -- slowest member instead of growing linearly with party size. Prefetch is
    -- fail-open in WorldTravelService; the authoritative move can still proceed.
    WorldTravelService.PreparePlayers(members, definition.DestinationSpawnId)

    local entered = {}
    local function rollbackEntered()
        for index = #entered, 1, -1 do
            local enteredMember = entered[index]
            if rollbackMember then
                local ok, err = pcall(rollbackMember, enteredMember)
                if not ok then
                    warn(
                        string.format(
                            "[PartyInstanceService] Rollback callback failed for %s: %s",
                            enteredMember.Name,
                            tostring(err)
                        )
                    )
                end
            else
                WorldTravelService.Teleport(enteredMember, definition.ReturnSpawnId)
            end
        end
    end

    for _, member in members do
        if member.Parent ~= Players then
            rollbackEntered()
            return false, "party_member_unavailable"
        end
        local profile = PlayerDataService.Get(member)
        if not profile then
            rollbackEntered()
            return false, "party_member_unavailable"
        end

        local moved, moveReason
        if enterMember then
            local invokeOk, callbackMoved, callbackReason =
                pcall(enterMember, member, profile, { SkipStreamingPrefetch = true })
            if not invokeOk then
                moved = false
                moveReason = "group_entry_error"
                warn(
                    string.format(
                        "[PartyInstanceService] Entry callback failed for %s: %s",
                        member.Name,
                        tostring(callbackMoved)
                    )
                )
            else
                moved = callbackMoved
                moveReason = callbackReason
            end
        else
            moved, moveReason = WorldTravelService.Teleport(member, definition.DestinationSpawnId, {
                SkipStreamingPrefetch = true,
                RespawnSpawnId = definition.ReturnSpawnId,
            })
        end

        if not moved then
            rollbackEntered()
            return false, moveReason or "group_entry_failed"
        end
        table.insert(entered, member)
    end

    return true, { Entered = entered, Count = #entered }
end

return PartyInstanceService
