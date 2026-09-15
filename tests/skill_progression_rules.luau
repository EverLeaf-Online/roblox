local Rules = require("../src/shared/Logic/SkillProgressionRules")

local definition = {
    Id = "passive",
    FamilyId = "ironbloom",
    RequiredLevel = 12,
    RequiredTier = 1,
    MaxRank = 5,
    SPCostPerRank = 1,
    Prerequisites = { { SkillId = "root", Rank = 3 } },
}

local profile = {
    Level = 12,
    AdvancementTier = 1,
    FamilyId = "ironbloom",
    SP = 2,
    Skills = { Learned = { root = 2 } },
}
local ok, reason, skillId, rank = Rules.CanLearn(profile, definition)
assert(not ok and reason == "prerequisite_unmet", "prerequisite blocks")
assert(skillId == "root" and rank == 3, "missing prerequisite detail")
profile.Skills.Learned.root = 3
ok = Rules.CanLearn(profile, definition)
assert(ok, "met prerequisite permits learn")
profile.Level = 11
ok, reason = Rules.CanLearn(profile, definition)
assert(not ok and reason == "level_too_low", "level gate")
profile.Level = 12
profile.FamilyId = "thornrunner"
ok, reason = Rules.CanLearn(profile, definition)
assert(not ok and reason == "wrong_family", "family gate")
profile.FamilyId = "ironbloom"
profile.SP = 0
ok, reason = Rules.CanLearn(profile, definition)
assert(not ok and reason == "insufficient_sp", "SP gate")
profile.SP = 2
profile.Skills.Learned.passive = 5
definition.CurrentRank = 5
ok, reason = Rules.CanLearn(profile, definition)
assert(not ok and reason == "max_rank", "max rank gate")

print("skill progression rules tests passed")
