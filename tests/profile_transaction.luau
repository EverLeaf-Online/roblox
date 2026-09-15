local ProfileTransaction = require("../src/shared/Logic/ProfileTransaction")

local profile = { Level = 4, Currencies = { Shards = 10 }, Nested = { Value = 1 } }
local ok, reason = ProfileTransaction.Run(profile, function(working)
    working.Level = 99
    working.Currencies.Shards = 0
    working.Nested.Value = 8
    return false, "forced_failure"
end)
assert(not ok and reason == "forced_failure", "failed transaction returns reason")
assert(profile.Level == 4, "failed transaction does not mutate scalar")
assert(profile.Currencies.Shards == 10, "failed transaction does not mutate nested currency")
assert(profile.Nested.Value == 1, "failed transaction does not mutate nested table")

ok = ProfileTransaction.Run(profile, function(working)
    working.Level = 5
    working.Currencies.Shards = 13
    working.Nested.Value = 2
    return true, "committed"
end)
assert(ok, "successful transaction commits")
assert(
    profile.Level == 5 and profile.Currencies.Shards == 13 and profile.Nested.Value == 2,
    "committed state replaces original"
)

print("profile transaction tests passed")
