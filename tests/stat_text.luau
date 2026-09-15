local StatText = require("../src/client/UI/StatText")

assert(StatText.Format("AttackPower", 4) == "Attack +4", "attack label")
assert(StatText.Format("Defense", 6) == "Defense +6", "defense label")
assert(StatText.Format("CritChance", 3) == "Crit Chance +3%", "crit chance percent")
assert(StatText.Format("CritPower", 10) == "Crit Power +10%", "crit power percent")
assert(StatText.Format("Might", 2) == "Might +2", "core stat fallback")

print("stat text tests passed")
