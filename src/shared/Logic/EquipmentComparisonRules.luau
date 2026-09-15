local EquipmentComparisonRules = {}

local STAT_ORDER = table.freeze({
    "AttackPower",
    "AttackSpeed",
    "Might",
    "Finesse",
    "Insight",
    "Fortune",
    "Defense",
    "CritChance",
    "CritPower",
})

local function numericStats(definition)
    local result = {}
    local stats = type(definition) == "table" and definition.Stats or nil
    if type(stats) ~= "table" then
        return result
    end
    for statName, value in stats do
        if type(value) == "number" then
            result[statName] = value
        end
    end
    return result
end

function EquipmentComparisonRules.Compare(candidate, equipped)
    local candidateStats = numericStats(candidate)
    local equippedStats = numericStats(equipped)
    local seen = {}
    local entries = {}

    local function addStat(statName)
        if seen[statName] then
            return
        end
        seen[statName] = true
        local candidateValue = candidateStats[statName] or 0
        local equippedValue = equippedStats[statName] or 0
        local delta = candidateValue - equippedValue
        if delta ~= 0 then
            table.insert(entries, {
                Stat = statName,
                Delta = delta,
                Candidate = candidateValue,
                Equipped = equippedValue,
            })
        end
    end

    for _, statName in STAT_ORDER do
        addStat(statName)
    end

    local extras = {}
    for statName in candidateStats do
        if not seen[statName] then
            table.insert(extras, statName)
        end
    end
    for statName in equippedStats do
        if not seen[statName] then
            table.insert(extras, statName)
        end
    end
    table.sort(extras)
    for _, statName in extras do
        addStat(statName)
    end

    return entries
end

return table.freeze(EquipmentComparisonRules)
