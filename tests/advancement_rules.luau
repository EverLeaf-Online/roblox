local AdvancementRules = require("../src/shared/Logic/AdvancementRules")

local family = { FirstAdvancementLevel = 8 }
local profile = {
    Level = 8,
    AdvancementTier = 0,
    FamilyId = "",
    Quests = { Completed = { first_advancement_trial = true } },
}

local ok, reason = AdvancementRules.CanFirstAdvance(profile, family, "first_advancement_trial")
assert(ok and reason == nil, "eligible profile can first-advance")

profile.Level = 7
ok, reason = AdvancementRules.CanFirstAdvance(profile, family, "first_advancement_trial")
assert(not ok and reason == "level_too_low", "family level requirement enforced")
profile.Level = 8

profile.Quests.Completed.first_advancement_trial = nil
ok, reason = AdvancementRules.CanFirstAdvance(profile, family, "first_advancement_trial")
assert(not ok and reason == "trial_incomplete", "mentor trial required")
profile.Quests.Completed.first_advancement_trial = true

profile.AdvancementTier = 1
ok, reason = AdvancementRules.CanFirstAdvance(profile, family, "first_advancement_trial")
assert(not ok and reason == "already_advanced", "first advancement is one-time")
profile.AdvancementTier = 0

ok, reason = AdvancementRules.CanUseFamilySkill(
    { FamilyId = "ironbloom" },
    { FamilyId = "ironbloom" }
)
assert(ok, "matching family skill allowed")
ok, reason = AdvancementRules.CanUseFamilySkill(
    { FamilyId = "thornrunner" },
    { FamilyId = "ironbloom" }
)
assert(not ok and reason == "wrong_family", "cross-family skill rejected")

print("advancement rules tests passed")
