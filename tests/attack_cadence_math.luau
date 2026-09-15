local Cadence = require("../src/shared/Math/AttackCadenceMath")

local tuning = {
    MinimumAttackSpeedBonus = -40,
    MaximumAttackSpeedBonus = 30,
    MinimumBasicAttackCooldown = 0.28,
}

local base, applied = Cadence.ResolveCooldown(0.6, 0, tuning)
assert(base == 0.6 and applied == 0, "zero speed preserves base cooldown")

local faster, fasterBonus = Cadence.ResolveCooldown(0.6, 20, tuning)
assert(math.abs(faster - 0.5) < 0.000001 and fasterBonus == 20, "positive speed reduces cooldown")

local capped, cappedBonus = Cadence.ResolveCooldown(0.6, 999, tuning)
assert(math.abs(capped - (0.6 / 1.3)) < 0.000001 and cappedBonus == 30, "speed bonus is capped")

local slowed, slowBonus = Cadence.ResolveCooldown(0.6, -80, tuning)
assert(math.abs(slowed - 1.0) < 0.000001 and slowBonus == -40, "future slows are bounded")

local floored = Cadence.ResolveCooldown(0.3, 30, tuning)
assert(floored == 0.28, "absolute cooldown floor is enforced")

assert(Cadence.ResolveBonus(0 / 0, tuning) == 0, "NaN speed fails safe")
assert(Cadence.ResolveBonus(math.huge, tuning) == 0, "infinite speed fails safe")

print("attack cadence math tests passed")
