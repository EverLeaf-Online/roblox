local Rules = require("../src/server/Services/NpcGroundingRules")

local function approx(a, b)
    assert(math.abs(a - b) < 0.0001, string.format("expected %.4f, got %.4f", b, a))
end

approx(Rules.ComputeVerticalShift(0, 10, 0.12), -9.88)
approx(Rules.ComputeVerticalShift(4.5, 7.2, 0.08), -2.62)
approx(Rules.ComputeVerticalShift(-1.25, -0.5, 0), -0.75)

print("npc grounding rule tests passed")
