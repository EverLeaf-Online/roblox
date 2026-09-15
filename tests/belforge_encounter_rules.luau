local Rules = require("../src/shared/Logic/BelforgeEncounterRules")

local ok, reason = Rules.CanEnter("Open", false, 0, 6)
assert(ok and reason == nil, "open encounter accepts entrants")
ok, reason = Rules.CanEnter("Open", false, 6, 6)
assert(not ok and reason == "encounter_full", "encounter caps at six entrants")
ok, reason = Rules.CanEnter("Active", false, 3, 6)
assert(not ok and reason == "encounter_locked", "new entrants cannot join active pull")
ok, reason = Rules.CanEnter("Active", true, 3, 6)
assert(not ok and reason == "encounter_active", "registered players cannot death-rush reenter")
ok, reason = Rules.CanEnter("Resetting", false, 0, 6)
assert(not ok and reason == "encounter_resetting", "wipe reset locks entry")
ok, reason = Rules.CanEnter("VictoryCooldown", false, 0, 6)
assert(not ok and reason == "boss_recovering", "victory cooldown locks entry")

local participants = { a = true, b = true }
assert(
    not Rules.AllEliminated(participants, { a = true }),
    "one surviving participant prevents wipe"
)
assert(
    Rules.AllEliminated(participants, { a = true, b = true }),
    "all eliminated participants trigger wipe"
)
assert(not Rules.AllEliminated({}, {}), "empty participant set is not a wipe")

print("Belforge encounter rules tests passed")
