local ThreatRules = require("../src/shared/Logic/ThreatRules")

assert(ThreatRules.Add(0, 10) == 10, "damage creates threat")
assert(ThreatRules.Add(10, 5) == 15, "threat accumulates")
assert(ThreatRules.Add(10, -5) == 10, "negative threat is ignored")
assert(ThreatRules.Add(10, 0 / 0) == 10, "NaN threat is ignored")
assert(not ThreatRules.ShouldSwitch(100, 110, 1.15), "small lead does not pull aggro")
assert(ThreatRules.ShouldSwitch(100, 115, 1.15), "configured lead can pull aggro")
assert(ThreatRules.ShouldSwitch(0, 1, 1.15), "damage threat beats proximity-only target")
assert(not ThreatRules.ShouldSwitch(100, 0, 1.15), "zero-threat challenger never pulls")

print("threat rules tests passed")
