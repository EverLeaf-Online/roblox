local SkillBonusMath = require("../src/shared/Math/SkillBonusMath")
local Skills = require("../src/server/Content/SkillDefinitions")

local learned = {
    steady_footing = 2,
    ironbloom_rooted_guard = 3,
    beginner_strike = 5,
}
assert(
    math.abs(SkillBonusMath.Compute(learned, Skills, "Defense") - 5.5) < 0.0001,
    "defense bonuses accumulate"
)
assert(SkillBonusMath.Compute(learned, Skills, "MaxHP") == 32, "max HP bonuses accumulate")
assert(
    SkillBonusMath.Compute(learned, Skills, "AttackPower") == 0,
    "active skills do not produce passive bonus"
)
assert(SkillBonusMath.Compute({}, Skills, "Defense") == 0, "empty learned set")

print("skill bonus math tests passed")
