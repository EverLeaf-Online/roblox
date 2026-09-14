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

local tierTwoFamily = {
    SecondAdvancement = {
        DisplayName = "Ironbloom Bulwark",
        StarterSkillId = "ironbloom_bastion_crash",
    },
}
local tierTwoProfile = {
    Level = 30,
    AdvancementTier = 1,
    FamilyId = "ironbloom",
    Quests = { Completed = { belforge_gate_sentinel = true } },
}

ok, reason =
    AdvancementRules.CanSecondAdvance(tierTwoProfile, tierTwoFamily, 30, "belforge_gate_sentinel")
assert(ok and reason == nil, "eligible Tier-1 profile can second-advance")

tierTwoProfile.Level = 29
ok, reason =
    AdvancementRules.CanSecondAdvance(tierTwoProfile, tierTwoFamily, 30, "belforge_gate_sentinel")
assert(not ok and reason == "level_too_low", "second advancement Level 30 gate enforced")
tierTwoProfile.Level = 30

tierTwoProfile.Quests.Completed.belforge_gate_sentinel = nil
ok, reason =
    AdvancementRules.CanSecondAdvance(tierTwoProfile, tierTwoFamily, 30, "belforge_gate_sentinel")
assert(not ok and reason == "trial_incomplete", "Sentinel progression required for Tier 2")
tierTwoProfile.Quests.Completed.belforge_gate_sentinel = true

tierTwoProfile.AdvancementTier = 2
ok, reason =
    AdvancementRules.CanSecondAdvance(tierTwoProfile, tierTwoFamily, 30, "belforge_gate_sentinel")
assert(not ok and reason == "already_advanced", "second advancement is one-time")
tierTwoProfile.AdvancementTier = 0
ok, reason =
    AdvancementRules.CanSecondAdvance(tierTwoProfile, tierTwoFamily, 30, "belforge_gate_sentinel")
assert(not ok and reason == "first_advancement_required", "Tier 1 is required before Tier 2")

print("advancement rules tests passed")
