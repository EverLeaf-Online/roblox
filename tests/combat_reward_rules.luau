local Rules = require("../src/shared/Logic/CombatRewardRules")

local tuning = {
    NormalRewardContributionFraction = 0.05,
    EliteRewardContributionFraction = 0.03,
}

assert(Rules.CreditDamage(0, 100, 25) == 25, "ordinary contribution credits full hit")
assert(Rules.CreditDamage(90, 100, 40) == 10, "overkill contribution is capped to remaining health")
assert(Rules.CreditDamage(100, 100, 40) == 0, "fully credited enemy cannot add contribution")

local contributors = {
    { UserId = 10, Damage = 60 },
    { UserId = 20, Damage = 30 },
    { UserId = 30, Damage = 10 },
}
local reward = { Exp = 101, Currencies = { Shards = 11 } }
local plan = Rules.BuildPlan(contributors, 100, {}, reward, tuning)
assert(plan.SharedPool, "normal enemies use shared conserved reward pool")
assert(
    #plan.Eligible == 3 and plan.WinnerUserId == 10,
    "all qualified normal contributors included"
)
assert(
    #plan.LootUserIds == 1 and plan.LootUserIds[1] == 10,
    "normal loot roll belongs to top contributor"
)

local expTotal = 0
local shardTotal = 0
for _, share in plan.RewardByUserId do
    expTotal += share.Exp or 0
    shardTotal += share.Currencies and share.Currencies.Shards or 0
end
assert(expTotal == 101, "normal shared EXP is exactly conserved")
assert(shardTotal == 11, "normal shared currency is exactly conserved")
assert(
    plan.RewardByUserId[10].Exp > plan.RewardByUserId[20].Exp,
    "larger contributor receives larger share"
)

local thresholdPlan = Rules.BuildPlan(
    { { UserId = 1, Damage = 96 }, { UserId = 2, Damage = 4 } },
    100,
    {},
    { Exp = 10 },
    tuning
)
assert(
    #thresholdPlan.Eligible == 1 and thresholdPlan.Eligible[1].UserId == 1,
    "normal minimum contribution blocks tag leech"
)

local fallback = Rules.BuildPlan(
    { { UserId = 7, Damage = 2 }, { UserId = 5, Damage = 2 } },
    1000,
    {},
    { Exp = 8 },
    tuning
)
assert(
    #fallback.Eligible == 1 and fallback.Eligible[1].UserId == 5,
    "top contributor fallback is deterministic on ties"
)
assert(fallback.RewardByUserId[5].Exp == 8, "fallback winner gets full conserved pool")

local elite = Rules.BuildPlan(
    { { UserId = 1, Damage = 30 }, { UserId = 2, Damage = 29 }, { UserId = 3, Damage = 1 } },
    1000,
    { Elite = true },
    { Exp = 100, Currencies = { Marks = 1 } },
    tuning
)
assert(
    #elite.Eligible == 1 and elite.Eligible[1].UserId == 1,
    "elite threshold uses configured three percent"
)
assert(
    elite.RewardByUserId[1].Currencies.Marks == 1,
    "indivisible shared currency remains conserved"
)

local boss = Rules.BuildPlan(
    { { UserId = 1, Damage = 600 }, { UserId = 2, Damage = 250 }, { UserId = 3, Damage = 150 } },
    1000,
    { Boss = true, MinimumRewardContribution = 0.2 },
    { Exp = 500, Currencies = { Marks = 2 } },
    tuning
)
assert(not boss.SharedPool, "bosses use individual rewards")
assert(#boss.Eligible == 2, "boss threshold selects qualified contributors")
assert(#boss.LootUserIds == 2, "qualified boss contributors receive personal loot rolls")
assert(
    boss.RewardByUserId[1].Exp == 500 and boss.RewardByUserId[2].Exp == 500,
    "boss reward remains full per qualified contributor"
)
assert(boss.RewardByUserId[1].Currencies.Marks == 2, "boss personal currency remains full")

assert(Rules.HasReward({ Exp = 1 }), "positive EXP is a reward")
assert(not Rules.HasReward({}), "empty share is not a reward")

print("combat reward rules tests passed")
