local MonsterReactionMath = {}

local function finiteNonNegative(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value or value == math.huge or value == -math.huge then
        return math.max(0, tonumber(fallback) or 0)
    end
    return math.max(0, value)
end

local function resistanceFor(definition, tuning, kind)
    local overrideName = if kind == "Knockback" then "KnockbackResistance" else "StaggerResistance"
    local override = tonumber(definition[overrideName])
    if
        override ~= nil
        and override == override
        and override ~= math.huge
        and override ~= -math.huge
    then
        return math.clamp(override, 0, 1)
    end

    local tier = if definition.Boss == true
        then "Boss"
        else if definition.Elite == true then "Elite" else "Normal"
    return math.clamp(tonumber(tuning[tier .. "Monster" .. kind .. "Resistance"]) or 0, 0, 1)
end

function MonsterReactionMath.Resolve(definition, options, tuning)
    definition = type(definition) == "table" and definition or {}
    options = type(options) == "table" and options or {}
    tuning = type(tuning) == "table" and tuning or {}

    local knockbackResistance = resistanceFor(definition, tuning, "Knockback")
    local staggerResistance = resistanceFor(definition, tuning, "Stagger")
    local requestedStagger = finiteNonNegative(options.Stagger, definition.HitStun or 0.22)
    local effectiveStagger = requestedStagger * (1 - staggerResistance)
    local interruptThreshold =
        finiteNonNegative(tuning.MonsterInterruptStaggerThresholdSeconds, 0.08)

    return {
        Knockback = finiteNonNegative(options.Knockback, 0) * (1 - knockbackResistance),
        Knockup = finiteNonNegative(options.Knockup, 0) * (1 - knockbackResistance),
        Stagger = effectiveStagger,
        Interrupts = effectiveStagger >= interruptThreshold,
        KnockbackResistance = knockbackResistance,
        StaggerResistance = staggerResistance,
    }
end

return table.freeze(MonsterReactionMath)
