local QuestAccessRules = require("../src/shared/Logic/QuestAccessRules")

local profile = {
    Level = 10,
    AdvancementTier = 1,
    Quests = { Completed = { first_advancement_trial = true } },
}
local definition = {
    MinimumLevel = 10,
    MinimumAdvancementTier = 1,
    PrerequisiteQuests = { "first_advancement_trial" },
}

local ok, reason = QuestAccessRules.CanStart(profile, definition)
assert(ok and reason == nil, "eligible quest starts")

profile.AdvancementTier = 0
ok, reason = QuestAccessRules.CanStart(profile, definition)
assert(not ok and reason == "advancement_too_low", "advancement gate enforced")
profile.AdvancementTier = 1

profile.Level = 9
ok, reason = QuestAccessRules.CanStart(profile, definition)
assert(not ok and reason == "level_too_low", "level gate enforced")
profile.Level = 10

profile.Quests.Completed.first_advancement_trial = nil
ok, reason = QuestAccessRules.CanStart(profile, definition)
assert(not ok and reason == "prerequisite_incomplete", "quest prerequisite enforced")

print("quest access rules tests passed")
