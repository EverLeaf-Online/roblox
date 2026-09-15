local StatText = {}

local LABELS = table.freeze({
    AttackPower = "Attack",
    AttackSpeed = "Attack Speed",
    Defense = "Defense",
    CritChance = "Crit Chance",
    CritPower = "Crit Power",
    MaxHP = "Max HP",
    MaxMP = "Max MP",
})

function StatText.Label(name)
    return LABELS[name] or tostring(name)
end

function StatText.Format(name, value)
    local label = StatText.Label(name)
    if name == "CritChance" or name == "CritPower" or name == "AttackSpeed" then
        return string.format("%s +%s%%", label, tostring(value))
    end
    return string.format("%s +%s", label, tostring(value))
end

function StatText.FormatDelta(name, delta)
    delta = tonumber(delta) or 0
    local suffix = if name == "CritChance"
            or name == "CritPower"
            or name == "AttackSpeed"
        then "%"
        else ""
    return string
        .format("%s %+.1f%s", StatText.Label(name), delta, suffix)
        :gsub("%.0([%%]?)$", "%1")
end

return table.freeze(StatText)
