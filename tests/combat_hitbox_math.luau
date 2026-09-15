local HitboxMath = require("../src/shared/Math/CombatHitboxMath")

local x, y, z = HitboxMath.BoxSize(10, 7.5, 7)
assert(x == 7.5, "hitbox width")
assert(y == 14, "hitbox full vertical size")
assert(z == 10, "hitbox forward length")

local cx, cy, cz = HitboxMath.BoxSize(-4, 0, 0)
assert(cx == 1 and cy == 2 and cz == 1, "hitbox dimensions clamp")

print("combat hitbox math tests passed")
