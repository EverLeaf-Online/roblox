local Rules = require("../src/shared/Logic/EquipmentTypeRules")

assert(Rules.IsArmorType("LightArmor"), "light armor type valid")
assert(Rules.IsArmorType("HeavyArmor"), "heavy armor type valid")
assert(not Rules.IsArmorType("Injected"), "unknown armor type rejected")
assert(Rules.IsAccessoryType("Charm"), "charm type valid")
assert(Rules.IsAccessoryType("Ring"), "ring type valid")

assert(
    Rules.Validate({ Type = "Equipment", EquipmentSlot = "Weapon", WeaponType = "Blade" }),
    "weapon taxonomy"
)
assert(
    Rules.Validate({ Type = "Equipment", EquipmentSlot = "Body", ArmorType = "HeavyArmor" }),
    "body armor taxonomy"
)
assert(
    Rules.Validate({ Type = "Equipment", EquipmentSlot = "Accessory", AccessoryType = "Charm" }),
    "charm taxonomy"
)
assert(
    Rules.Validate({ Type = "Equipment", EquipmentSlot = "Ring1", AccessoryType = "Ring" }),
    "ring taxonomy"
)

local ok, reason = Rules.Validate({ Type = "Equipment", EquipmentSlot = "Body" })
assert(not ok and reason == "armor_type_required", "armor subtype required")
ok, reason =
    Rules.Validate({ Type = "Equipment", EquipmentSlot = "Accessory", AccessoryType = "Ring" })
assert(not ok and reason == "ring_slot_required", "ring cannot use generic accessory slot")
ok = Rules.Validate({
    Type = "Equipment",
    EquipmentSlot = "Weapon",
    WeaponType = "Blade",
    ArmorType = "HeavyArmor",
})
assert(not ok, "weapon cannot inject armor category")

print("equipment type rules tests passed")
