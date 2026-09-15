local Rules = require("../src/shared/Logic/WorldNoticeRules")

local locked = Rules.ForReason("region_locked")
assert(
    locked.Kind == "warning" and locked.Title == "Region Locked",
    "region lock notice is explicit"
)
local tier = Rules.ForReason("second_advancement_required")
assert(tier.Body:find("Level 30") ~= nil, "second advancement notice explains Level 30 promotion")
local active = Rules.ForReason("encounter_locked")
assert(active.Title == "Fight In Progress", "active encounter notice is explicit")
local assembled = Rules.ForReason("party_not_assembled")
assert(assembled.Title == "Party Not Assembled", "party assembly denial is explicit")
local leader = Rules.ForReason("not_party_leader")
assert(leader.Title == "Leader Required", "party leader requirement is explicit")
local fallback = Rules.ForReason("something_new")
assert(fallback.Title == "Action Unavailable", "unknown reasons use safe fallback")

print("world notice rules tests passed")
