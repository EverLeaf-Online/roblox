local CurrencyRules = require("../src/shared/Logic/CurrencyRules")
local InventoryRules = require("../src/shared/Logic/InventoryRules")
local ProfileTransaction = require("../src/shared/Logic/ProfileTransaction")
local QuestTurnInRules = require("../src/shared/Logic/QuestTurnInRules")

local MAX_BALANCE = 2_000_000_000

local function turnIn(profile, questId, rewardShouldFail)
    return ProfileTransaction.Run(profile, function(working)
        local eligible, reason = QuestTurnInRules.Validate(working, questId)
        if not eligible then
            return false, reason
        end

        local added, nextBalance = CurrencyRules.Add(working.Currencies.Shards, 25, MAX_BALANCE)
        if not added then
            return false, nextBalance
        end
        working.Currencies.Shards = nextBalance

        if rewardShouldFail then
            return false, "forced_reward_failure"
        end

        local completed, completionReason = QuestTurnInRules.MarkCompleted(working, questId)
        if not completed then
            return false, completionReason
        end
        return true
    end)
end

-- Reward failure after a partial working mutation cannot leak currency or completion.
do
    local profile = {
        Currencies = { Shards = 10, Marks = 0 },
        Quests = {
            Active = { test_quest = { Progress = { 1 }, ReadyToTurnIn = true } },
            Completed = {},
        },
    }
    local ok, reason = turnIn(profile, "test_quest", true)
    assert(not ok and reason == "forced_reward_failure", "failed reward aborts turn-in")
    assert(profile.Currencies.Shards == 10, "failed reward cannot leak currency")
    assert(profile.Quests.Active.test_quest ~= nil, "failed reward keeps quest active")
    assert(profile.Quests.Completed.test_quest ~= true, "failed reward cannot mark complete")
end

-- Successful turn-in grants exactly once; replay cannot grant again.
do
    local profile = {
        Currencies = { Shards = 10, Marks = 0 },
        Quests = {
            Active = { test_quest = { Progress = { 1 }, ReadyToTurnIn = true } },
            Completed = {},
        },
    }
    local ok = turnIn(profile, "test_quest", false)
    assert(ok, "first turn-in succeeds")
    assert(profile.Currencies.Shards == 35, "first turn-in grants reward once")
    assert(profile.Quests.Active.test_quest == nil, "successful turn-in removes active state")
    assert(profile.Quests.Completed.test_quest == true, "successful turn-in marks completion")

    local replayOk, replayReason = turnIn(profile, "test_quest", false)
    assert(not replayOk and replayReason == "already_completed", "completed quest replay rejected")
    assert(profile.Currencies.Shards == 35, "replay cannot duplicate reward")
end

-- A one-time cache marker and its item grant commit together exactly once.
do
    local profile = {
        Inventory = { Capacity = 4, Slots = {} },
        World = { Secrets = {} },
    }
    local function claim()
        return ProfileTransaction.Run(profile, function(working)
            if working.World.Secrets.whisperroot_cache == true then
                return false, "already_claimed"
            end
            local added, addReason = InventoryRules.Add(
                working.Inventory.Slots,
                working.Inventory.Capacity,
                "old_wayfinder_page",
                1,
                1
            )
            if not added then
                return false, addReason
            end
            working.World.Secrets.whisperroot_cache = true
            return true
        end)
    end

    assert(claim(), "first one-time cache claim succeeds")
    local replayOk, replayReason = claim()
    assert(not replayOk and replayReason == "already_claimed", "one-time cache replay rejected")
    assert(
        InventoryRules.Count(profile.Inventory.Slots, "old_wayfinder_page") == 1,
        "one-time cache item exists exactly once"
    )
end

print("quest/reward replay abuse tests passed")
