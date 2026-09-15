local ProfileSaveRules = require("../src/shared/Logic/ProfileSaveRules")
local RetryExecutor = require("../src/shared/Logic/RetryExecutor")

-- Transient throttles/errors recover on a later attempt and use exponential delays.
do
    local calls = 0
    local waits = {}
    local ok, result, attempts = RetryExecutor.Run(
        function()
            calls += 1
            if calls < 3 then
                error("simulated throttle")
            end
            return "saved"
        end,
        4,
        1,
        function(seconds)
            table.insert(waits, seconds)
        end
    )
    assert(ok and result == "saved" and attempts == 3, "transient failures recover")
    assert(calls == 3, "retry stops immediately after success")
    assert(#waits == 2 and waits[1] == 1 and waits[2] == 2, "retry backoff is exponential")
end

-- Exhaustion returns the last error and never sleeps after the final attempt.
do
    local calls = 0
    local waits = {}
    local ok, reason, attempts = RetryExecutor.Run(
        function(attempt)
            calls += 1
            error("failure-" .. tostring(attempt))
        end,
        4,
        0.5,
        function(seconds)
            table.insert(waits, seconds)
        end
    )
    assert(not ok and attempts == 4 and calls == 4, "retry exhausts configured attempts")
    assert(string.find(tostring(reason), "failure%-4") ~= nil, "last error is surfaced")
    assert(
        #waits == 3 and waits[1] == 0.5 and waits[2] == 1 and waits[3] == 2,
        "retry does not wait after terminal failure"
    )
end

-- Session ownership handoff: fresh lock blocks, stale lock can be claimed, old owner cannot save.
do
    local timeout = 180
    local sessionA = "server-a"
    local sessionB = "server-b"
    local lock = { Id = sessionA, TouchedAt = 100 }

    assert(
        not ProfileSaveRules.CanClaim(lock, sessionB, 200, timeout),
        "fresh foreign session lock blocks duplicate load"
    )
    assert(
        ProfileSaveRules.CanClaim(lock, sessionB, 280, timeout),
        "lock becomes claimable exactly at stale timeout"
    )

    lock = { Id = sessionB, TouchedAt = 280 }
    assert(ProfileSaveRules.OwnsLock(lock, sessionB), "new server owns reclaimed lock")
    assert(
        not ProfileSaveRules.OwnsLock(lock, sessionA),
        "old server cannot save after ownership moves"
    )
    assert(
        not ProfileSaveRules.CanClaim(lock, sessionA, 281, timeout),
        "old server cannot immediately steal fresh reclaimed lock"
    )
end

-- A mutation that arrives while a snapshot is saving remains dirty afterward.
do
    local saved, dirty = ProfileSaveRules.SavedRevisionAfterSuccess(7, 8, 6)
    assert(saved == 7 and dirty, "in-flight newer mutation remains dirty")
    saved, dirty = ProfileSaveRules.SavedRevisionAfterSuccess(8, 8, saved)
    assert(saved == 8 and not dirty, "following save catches up cleanly")
end

print("persistence failure/session simulation tests passed")
