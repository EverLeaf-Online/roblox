local RewardRules = require("../src/shared/Logic/RewardRules")
assert(
    RewardRules.Validate({ Exp = 25, Currencies = { Shards = 3 }, Items = { tonic = 1 } }),
    "valid reward"
)
local ok = RewardRules.Validate({ Exp = -1 })
assert(not ok, "negative EXP reward rejected")
ok = RewardRules.Validate({ Items = { tonic = 1.5 } })
assert(not ok, "fractional item reward rejected")
print("reward rules tests passed")
assert(RewardRules.Validate({ UnlockRegions = { "brasshaven" } }), "region unlock reward")
ok = RewardRules.Validate({ UnlockRegions = { "" } })
assert(not ok, "empty region reward rejected")
