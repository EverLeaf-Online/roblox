local StatText = {}

local LABELS = table.freeze({
    AttackPower = "Attack",
    Defense = "Defense",
    CritChance = "Crit Chance",
    CritPower = "Crit Power",
})

function StatText.Format(name, value)
    local label = LABELS[name] or tostring(name)
    if name == "CritChance" or name == "CritPower" then
        return string.format("%s +%s%%", label, tostring(value))
    end
    return string.format("%s +%s", label, tostring(value))
end

return table.freeze(StatText)
