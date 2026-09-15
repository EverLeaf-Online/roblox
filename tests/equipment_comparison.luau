local Rules = require("../src/shared/Logic/EquipmentComparisonRules")

local candidate = { Stats = { AttackPower = 8, Might = 2, Defense = 1, CritChance = 2 } }
local equipped = { Stats = { AttackPower = 5, Might = 1, Defense = 4, Fortune = 1 } }
local entries = Rules.Compare(candidate, equipped)
assert(#entries == 5, "five changed stats expected")
assert(entries[1].Stat == "AttackPower" and entries[1].Delta == 3, "attack delta")
assert(entries[2].Stat == "Might" and entries[2].Delta == 1, "might delta")
assert(entries[3].Stat == "Fortune" and entries[3].Delta == -1, "lost fortune delta")
assert(entries[4].Stat == "Defense" and entries[4].Delta == -3, "defense delta")
assert(entries[5].Stat == "CritChance" and entries[5].Delta == 2, "crit delta")

local empty = Rules.Compare({ Stats = { Defense = 6 } }, nil)
assert(#empty == 1 and empty[1].Stat == "Defense" and empty[1].Delta == 6, "empty-slot comparison")
assert(
    #Rules.Compare({ Stats = { Might = 1 } }, { Stats = { Might = 1 } }) == 0,
    "equal stats omit deltas"
)
assert(#Rules.Compare({}, {}) == 0, "statless definitions compare cleanly")

print("equipment comparison tests passed")
