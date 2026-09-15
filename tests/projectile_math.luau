local ProjectileMath = require("../src/shared/Math/ProjectileMath")

assert(math.abs(ProjectileMath.TravelTime(22, 88) - 0.25) < 0.0001, "travel time")
assert(math.abs(ProjectileMath.StepLength(80, 0.05, 20) - 4) < 0.0001, "step length")
assert(ProjectileMath.StepLength(80, 0.2, 3) == 3, "step clamps delta and remaining")
assert(ProjectileMath.StepLength(80, -1, 3) == 0, "negative delta clamps")

print("projectile math tests passed")
