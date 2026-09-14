local ResourceRegenMath = require("../src/shared/Math/ResourceRegenMath")

local config = {
    RegenTickSeconds = 1,
    BaseMPPerSecond = 2,
    MPPerInsightPerSecond = 0.12,
    MinimumHPPerSecond = 2,
    HPPercentPerSecond = 0.015,
}

assert(math.abs(ResourceRegenMath.MPPerTick(10, config) - 3.2) < 0.001, "Insight scales MP regen")
assert(math.abs(ResourceRegenMath.HPPerTick(100, config) - 2) < 0.001, "HP regen floor applies")
assert(math.abs(ResourceRegenMath.HPPerTick(400, config) - 6) < 0.001, "HP percentage regen scales")
print("resource regen tests passed")
