local Rules = require("../src/shared/Logic/PartyInstanceRules")

local definition = {
    Id = "test_instance",
    Purpose = "test_instance",
    EntrySpawnId = "test_entry",
    DestinationSpawnId = "test_arena",
    ReturnSpawnId = "test_entry",
    MinimumPartySize = 2,
    MaximumPartySize = 6,
    AssemblyRadius = 72,
    ReadyCheckSeconds = 20,
}

assert(Rules.ValidateDefinition("test_instance", definition), "valid instance definition accepted")
local ok, reason = Rules.CanStart(false, 3, definition)
assert(not ok and reason == "not_party_leader", "non-leader cannot start group instance")
ok, reason = Rules.CanStart(true, 1, definition)
assert(not ok and reason == "party_too_small", "minimum party size enforced")
ok, reason = Rules.CanStart(true, 7, definition)
assert(not ok and reason == "party_too_large", "maximum party size enforced")
assert(Rules.CanStart(true, 6, definition), "valid party size accepted")
assert(Rules.IsAssembled(72, definition), "assembly boundary accepted")
assert(not Rules.IsAssembled(72.01, definition), "outside assembly radius rejected")

local invalid = table.clone(definition)
invalid.DestinationSpawnId = ""
ok, reason = Rules.ValidateDefinition("test_instance", invalid)
assert(not ok and reason ~= nil, "missing destination rejected")

print("party instance rules tests passed")
