local EquipmentEligibilityRules = require("../src/shared/Logic/EquipmentEligibilityRules")

local profile = { Level = 8, AdvancementTier = 1, FamilyId = "ironbloom" }
local weapon = { FamilyId = "ironbloom", RequiredAdvancementTier = 1, RequiredLevel = 8 }
local ok, reason = EquipmentEligibilityRules.CanEquip(profile, weapon)
assert(ok and reason == nil, "matching family weapon allowed")

profile.FamilyId = "thornrunner"
ok, reason = EquipmentEligibilityRules.CanEquip(profile, weapon)
assert(not ok and reason == "wrong_family", "foreign family weapon rejected")
profile.FamilyId = "ironbloom"

profile.AdvancementTier = 0
ok, reason = EquipmentEligibilityRules.CanEquip(profile, weapon)
assert(not ok and reason == "tier_too_low", "tier requirement enforced")
profile.AdvancementTier = 1

profile.Level = 7
ok, reason = EquipmentEligibilityRules.CanEquip(profile, weapon)
assert(not ok and reason == "level_too_low", "level requirement enforced")

print("equipment eligibility tests passed")
