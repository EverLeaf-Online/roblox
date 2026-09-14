local ShopDefinitions = require("../src/server/Content/ShopDefinitions")
local ItemDefinitions = require("../src/server/Content/ItemDefinitions")
local NpcDefinitions = require("../src/server/Content/NpcDefinitions")
local EquipmentEligibilityRules = require("../src/shared/Logic/EquipmentEligibilityRules")

local foundry = ShopDefinitions.foundry_supply
local marks = ShopDefinitions.belforge_mark_exchange
assert(foundry and foundry.Currency == "Shards", "Foundry Supply spends Shards")
assert(marks and marks.Currency == "Marks", "Belforge exchange spends Marks")
assert(foundry.Items.foundry_guard_vest == 42, "Foundry Guard Vest shard price locked")
assert(foundry.Items.ashrunner_coat == 42, "Ashrunner Coat shard price locked")
assert(foundry.Items.emberloop_charm == 58, "Emberloop Charm shard price locked")
assert(marks.Items.belforge_wayfarer_ring == 3, "Wayfarer Ring mark price locked")
assert(marks.Items.tempered_mark_charm == 5, "Tempered Mark Charm mark price locked")

local nera = NpcDefinitions.foundry_quartermaster
local cale = NpcDefinitions.belforge_mark_broker
assert(nera and nera.ShopId == "foundry_supply", "Nera owns Foundry Supply")
assert(cale and cale.ShopId == "belforge_mark_exchange", "Cale owns Mark Exchange")

local vest = ItemDefinitions.foundry_guard_vest
local coat = ItemDefinitions.ashrunner_coat
local ember = ItemDefinitions.emberloop_charm
local ring = ItemDefinitions.belforge_wayfarer_ring
local markCharm = ItemDefinitions.tempered_mark_charm
assert(
    vest.EquipmentSlot == "Body" and coat.EquipmentSlot == "Body",
    "Brasshaven armor uses Body slot"
)
assert(
    ember.EquipmentSlot == "Accessory" and markCharm.EquipmentSlot == "Accessory",
    "Brasshaven charms use Accessory slot"
)
assert(ring.EquipmentSlot == "Ring1", "Wayfarer Ring uses Ring1 slot")

local tierOne10 = { Level = 10, AdvancementTier = 1, FamilyId = "ironbloom" }
local tierZero20 = { Level = 20, AdvancementTier = 0, FamilyId = "" }
local tierOne12 = { Level = 12, AdvancementTier = 1, FamilyId = "thornrunner" }
local tierOne14 = { Level = 14, AdvancementTier = 1, FamilyId = "lumenweaver" }

local ok, reason = EquipmentEligibilityRules.CanEquip(tierOne10, vest)
assert(ok and reason == nil, "advanced Level 10 can equip Foundry Guard Vest")
ok, reason = EquipmentEligibilityRules.CanEquip(tierZero20, vest)
assert(not ok and reason == "tier_too_low", "unadvanced players cannot equip Foundry gear")
ok, reason = EquipmentEligibilityRules.CanEquip(tierOne10, ring)
assert(not ok and reason == "level_too_low", "Wayfarer Ring is Level 12 gated")
ok = EquipmentEligibilityRules.CanEquip(tierOne12, ring)
assert(ok, "advanced Level 12 can equip Wayfarer Ring")
ok, reason = EquipmentEligibilityRules.CanEquip(tierOne12, markCharm)
assert(not ok and reason == "level_too_low", "Tempered Mark Charm is Level 14 gated")
ok = EquipmentEligibilityRules.CanEquip(tierOne14, markCharm)
assert(ok, "advanced Level 14 can equip Tempered Mark Charm")

print("Brasshaven economy tests passed")
