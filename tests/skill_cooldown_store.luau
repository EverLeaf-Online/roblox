local SkillCooldownStore = require("../src/client/State/SkillCooldownStore")

assert(SkillCooldownStore.Start("test_skill", 2, 10), "cooldown starts")
assert(
    math.abs(SkillCooldownStore.Remaining("test_skill", 10.5) - 1.5) < 0.000001,
    "remaining time"
)
assert(
    math.abs(SkillCooldownStore.Fraction("test_skill", 2, 11) - 0.5) < 0.000001,
    "cooldown fraction"
)
assert(SkillCooldownStore.Remaining("test_skill", 12) == 0, "expired cooldown clears")
assert(SkillCooldownStore.Fraction("test_skill", 2, 12) == 0, "expired fraction is zero")
assert(SkillCooldownStore.Start("instant", 0, 20), "zero cooldown accepted")
assert(SkillCooldownStore.Remaining("instant", 20) == 0, "zero cooldown is not retained")
assert(not SkillCooldownStore.Start("", 2, 10), "empty skill id rejected")

print("skill cooldown store tests passed")
