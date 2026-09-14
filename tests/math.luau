local DamageMath = require("../src/shared/Math/DamageMath")
local DerivedStatsMath = require("../src/shared/Math/DerivedStatsMath")
local ProgressionMath = require("../src/shared/Math/ProgressionMath")

local function expectEqual(actual, expected, message)
    if actual ~= expected then
        error(
            string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual))
        )
    end
end

local function expect(condition, message)
    if not condition then
        error(message)
    end
end

expectEqual(ProgressionMath.ExpToNextLevel(1), 75, "level 1 EXP curve")
expect(
    ProgressionMath.ExpToNextLevel(10) > ProgressionMath.ExpToNextLevel(9),
    "EXP curve must increase"
)

local minimum, maximum = DamageMath.CalculateRange(10, 5, 2, 0.25)
expectEqual(maximum, 25, "damage maximum")
expectEqual(minimum, 6.25, "damage minimum")
expectEqual(DamageMath.RollFromUnit(minimum, maximum, 0), 6, "minimum roll")
expectEqual(DamageMath.RollFromUnit(minimum, maximum, 1), 25, "maximum roll")
expectEqual(DamageMath.RollFromUnit(minimum, maximum, 0.5), 16, "mid roll")

local derived = DerivedStatsMath.Compute(1, 4, 4, {
    BaseHP = 100,
    HPPerLevel = 12,
    HPPerMight = 5,
    BaseMP = 50,
    MPPerLevel = 4,
    MPPerInsight = 6,
})
expectEqual(derived.MaxHP, 120, "starting HP")
expectEqual(derived.MaxMP, 74, "starting MP")

print("math tests passed")
