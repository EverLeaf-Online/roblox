local BelforgeEncounterRules = {}

function BelforgeEncounterRules.CanEnter(stateName, isRegistered, participantCount, maxPlayers)
    participantCount = math.max(0, tonumber(participantCount) or 0)
    maxPlayers = math.max(1, tonumber(maxPlayers) or 1)
    if stateName == "Active" then
        return false, isRegistered and "encounter_active" or "encounter_locked"
    elseif stateName == "Resetting" then
        return false, "encounter_resetting"
    elseif stateName == "VictoryCooldown" then
        return false, "boss_recovering"
    end
    if not isRegistered and participantCount >= maxPlayers then
        return false, "encounter_full"
    end
    return true
end

function BelforgeEncounterRules.AllEliminated(participants, eliminated)
    local count = 0
    for participant in participants do
        count += 1
        if eliminated[participant] ~= true then
            return false
        end
    end
    return count > 0
end

return table.freeze(BelforgeEncounterRules)
