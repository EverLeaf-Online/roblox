local Rules = require("../src/shared/Logic/ProfileSaveRules")

assert(Rules.CanClaim(nil, "job-a", 100, 180), "empty lock can be claimed")
assert(Rules.CanClaim({ Id = "job-a", TouchedAt = 99 }, "job-a", 100, 180), "own lock can refresh")
assert(
    not Rules.CanClaim({ Id = "job-b", TouchedAt = 90 }, "job-a", 100, 180),
    "fresh foreign lock blocks claim"
)
assert(
    Rules.CanClaim({ Id = "job-b", TouchedAt = 1 }, "job-a", 200, 180),
    "stale foreign lock can be claimed"
)
assert(Rules.OwnsLock({ Id = "job-a", TouchedAt = 1 }, "job-a"), "exact session owns lock")
assert(not Rules.OwnsLock({ Id = "job-b", TouchedAt = 1 }, "job-a"), "foreign lock never owned")
assert(not Rules.OwnsLock(nil, "job-a"), "missing lock is not silently reacquired")

local saved, dirty = Rules.SavedRevisionAfterSuccess(3, 3, 2)
assert(saved == 3 and not dirty, "same revision becomes clean")
saved, dirty = Rules.SavedRevisionAfterSuccess(3, 5, 2)
assert(saved == 3 and dirty, "newer mutation stays dirty after older save")
saved, dirty = Rules.SavedRevisionAfterSuccess(2, 5, 4)
assert(saved == 4 and dirty, "saved revision never moves backwards")

print("profile save rules tests passed")
