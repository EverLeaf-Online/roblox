local BossRewardRules = require("../src/shared/Logic/BossRewardRules")

assert(BossRewardRules.MinimumDamage(7200) == 144, "default boss threshold is two percent")
assert(BossRewardRules.MinimumDamage(1450) == 29, "threshold rounds up for smaller bosses")
assert(BossRewardRules.IsEligible(144, 7200), "exact threshold qualifies")
assert(not BossRewardRules.IsEligible(143, 7200), "below threshold does not qualify")
assert(BossRewardRules.MinimumDamage(1000, 0.05) == 50, "per-boss threshold override works")

print("boss reward rules tests passed")
