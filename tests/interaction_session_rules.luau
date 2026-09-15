local Rules = require("../src/shared/Logic/InteractionSessionRules")

local ok, reason = Rules.CanValidate(false, true, true, true)
assert(ok and reason == nil, "valid session accepted")
ok, reason = Rules.CanValidate(true, true, true, true)
assert(not ok and reason == "expired", "expired session rejected")
ok, reason = Rules.CanValidate(false, false, true, true)
assert(not ok and reason == "id_mismatch", "wrong npc/shop rejected")
ok, reason = Rules.CanValidate(false, true, false, true)
assert(not ok and reason == "world_object_mismatch", "stale world object rejected")
ok, reason = Rules.CanValidate(false, true, true, false)
assert(not ok and reason == "too_far", "out-of-range session rejected")

print("interaction session rules tests passed")
