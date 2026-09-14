local ProgressionMath = {}

function ProgressionMath.ExpToNextLevel(level)
    assert(type(level) == "number" and level >= 1, "level must be >= 1")
    return math.floor(50 + (level ^ 1.6) * 25)
end

return ProgressionMath
