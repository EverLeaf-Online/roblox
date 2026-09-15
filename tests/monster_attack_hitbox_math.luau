local MonsterAttackHitboxMath = require("../src/shared/Math/MonsterAttackHitboxMath")

local tuning = {
    WidthMultiplier = 1.15,
    MinWidth = 4,
    MaxWidth = 10,
}

assert(MonsterAttackHitboxMath.ResolveWidth(2, nil, tuning) == 4, "small attacks use minimum width")
assert(
    math.abs(MonsterAttackHitboxMath.ResolveWidth(6, nil, tuning) - 6.9) < 0.000001,
    "ordinary attack width scales with range"
)
assert(
    MonsterAttackHitboxMath.ResolveWidth(20, nil, tuning) == 10,
    "large attacks cap default width"
)
assert(
    MonsterAttackHitboxMath.ResolveWidth(6, 3.25, tuning) == 3.25,
    "explicit width overrides tuning"
)
assert(MonsterAttackHitboxMath.ResolveDepth(5, 1) == 6, "depth includes forward slack")
assert(MonsterAttackHitboxMath.ResolveDepth(0, 0) == 1, "depth is always queryable")

print("monster attack hitbox math tests passed")
