local Rules = require("../src/server/Services/NpcGroundingRules")

local function approx(a, b)
    assert(math.abs(a - b) < 0.0001, string.format("expected %.4f, got %.4f", b, a))
end

approx(Rules.ComputeRootY(0, -2.75, 0.12), 2.87)
approx(Rules.ComputeRootY(4.5, -3.1, 0.08), 7.68)
approx(Rules.ComputeRootY(-1.25, -2.4, 0), 1.15)

print("npc grounding rule tests passed")
