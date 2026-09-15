local Rules = require("../src/shared/Logic/PartyReadyRules")

local ok, reason = Rules.CanStart(true, 3, 6, false)
assert(ok and reason == nil, "party leader can start ready check")
ok, reason = Rules.CanStart(false, 3, 6, false)
assert(not ok and reason == "not_party_leader", "only leader starts ready check")
ok, reason = Rules.CanStart(true, 1, 6, false)
assert(not ok and reason == "party_too_small", "solo party does not need ready check")
ok, reason = Rules.CanStart(true, 3, 6, true)
assert(not ok and reason == "ready_check_active", "duplicate ready check rejected")
ok, reason = Rules.CanRespond(true, true, false)
assert(ok and reason == nil, "member can answer active ready check")
ok, reason = Rules.CanRespond(false, true, false)
assert(not ok and reason == "not_in_party", "nonmember response rejected")
assert(
    not Rules.AllReady({ 1, 2, 3 }, { [1] = true, [2] = true }),
    "missing response remains waiting"
)
assert(
    Rules.AllReady({ 1, 2, 3 }, { [1] = true, [2] = true, [3] = true }),
    "all responses complete check"
)

print("party ready rules tests passed")
