local Rules = require("../src/shared/Validation/ActionPayloadRules")

local validPayloads = {
    ["stat.allocate"] = { StatName = "Might", Amount = 1 },
    ["inventory.use"] = { ItemId = "field_tonic" },
    ["storage.deposit"] = { InventoryIndex = 1, Quantity = 2 },
    ["storage.withdraw"] = { StorageIndex = 1, Quantity = 1 },
    ["equipment.equip"] = { InventoryIndex = 1 },
    ["equipment.unequip"] = { Slot = "Weapon" },
    ["skill.learn"] = { SkillId = "beginner_strike" },
    ["skill.hotbar"] = { Index = 8, SkillId = "" },
    ["skill.use"] = { SkillId = "beginner_strike" },
    ["quest.start"] = { NpcId = "ilyra", QuestId = "lumen_first_steps" },
    ["quest.turnin"] = { NpcId = "ilyra", QuestId = "lumen_first_steps" },
    ["shop.buy"] = { ShopId = "lumen_supply", ItemId = "small_tonic", Quantity = 99 },
    ["shop.sell"] = { ShopId = "lumen_supply", ItemId = "small_tonic", Quantity = 1 },
    ["advancement.first"] = { NpcId = "mentor", FamilyId = "ironbloom" },
    ["advancement.second"] = { NpcId = "mentor" },
    ["party.create"] = {},
    ["party.invite"] = { TargetUserId = 123 },
    ["party.accept"] = {},
    ["party.decline"] = {},
    ["party.kick"] = { TargetUserId = 456 },
    ["party.leave"] = {},
    ["trade.request"] = { TargetUserId = 123 },
    ["trade.accept"] = {},
    ["trade.decline"] = {},
    ["trade.add_item"] = { InventoryIndex = 1, Quantity = 1 },
    ["trade.remove_item"] = { ItemId = "field_tonic", Quantity = 1 },
    ["trade.set_shards"] = { Amount = 10 },
    ["trade.lock"] = {},
    ["trade.unlock"] = {},
    ["trade.confirm"] = {},
    ["trade.cancel"] = {},
    ["party.ready.respond"] = { Accepted = true },
    ["social.inspect"] = { TargetUserId = 123 },
    ["cosmetic.equip"] = { Slot = "Aura", CosmeticId = "verdant_trail" },
    ["settings.update"] = { Key = "MusicVolume", Value = 0.5 },
}

for actionName, payload in validPayloads do
    local ok, reason = Rules.Validate(actionName, payload)
    assert(ok, string.format("valid payload accepted for %s: %s", actionName, tostring(reason)))
end

assert(Rules.Validate("stat.allocate", { StatName = "Might" }), "optional stat amount accepted")
assert(
    Rules.Validate("shop.buy", { ShopId = "lumen_supply", ItemId = "small_tonic" }),
    "optional shop quantity accepted"
)
assert(
    Rules.Validate("settings.update", { Key = "ShowDamageNumbers", Value = false }),
    "boolean setting accepted"
)
assert(
    Rules.Validate("cosmetic.equip", { Slot = "Trail", CosmeticId = "" }),
    "cosmetic unequip accepted"
)

assert(not Rules.MutatesProfile("social.inspect"), "profile inspection is read-only")
assert(not Rules.MutatesProfile("party.invite"), "party actions do not dirty persistent profile")
assert(not Rules.MutatesProfile("skill.use"), "runtime skill use does not dirty persistent profile")
assert(Rules.MutatesProfile("equipment.equip"), "equipment changes dirty persistent profile")
assert(Rules.MutatesProfile("storage.deposit"), "storage deposits dirty persistent profile")
assert(Rules.MutatesProfile("storage.withdraw"), "storage withdrawals dirty persistent profile")
assert(Rules.MutatesProfile("quest.turnin"), "quest turn-in dirties persistent profile")

local abuseCases = {
    { "unknown.action", {}, "unknown action" },
    { "party.create", { Extra = true }, "unknown fields rejected" },
    { "stat.allocate", { StatName = "Power", Amount = 1 }, "unknown stat rejected" },
    { "stat.allocate", { StatName = "Might", Amount = 1.5 }, "fractional AP request rejected" },
    { "equipment.equip", { InventoryIndex = 0 }, "zero inventory index rejected" },
    {
        "storage.deposit",
        { InventoryIndex = 0, Quantity = 1 },
        "zero storage inventory index rejected",
    },
    { "storage.withdraw", { StorageIndex = 1, Quantity = 0 }, "zero storage quantity rejected" },
    { "equipment.unequip", { Slot = "Backpack" }, "unknown equipment slot rejected" },
    { "skill.hotbar", { Index = 9, SkillId = "beginner_strike" }, "hotbar overflow rejected" },
    { "skill.hotbar", { Index = 1, SkillId = string.rep("x", 65) }, "oversized skill id rejected" },
    {
        "shop.buy",
        { ShopId = "lumen_supply", ItemId = "small_tonic", Quantity = 100 },
        "oversized buy quantity rejected",
    },
    { "party.invite", { TargetUserId = -1 }, "negative user id rejected" },
    { "trade.request", { TargetUserId = -1 }, "negative trade target rejected" },
    { "trade.add_item", { InventoryIndex = 0, Quantity = 1 }, "invalid trade slot rejected" },
    { "trade.add_item", { InventoryIndex = 1, Quantity = 0 }, "zero trade quantity rejected" },
    { "trade.set_shards", { Amount = -1 }, "negative trade shards rejected" },
    { "social.inspect", { TargetUserId = -1 }, "negative inspect target rejected" },
    { "party.ready.respond", { Accepted = 1 }, "non-boolean ready response rejected" },
    {
        "cosmetic.equip",
        { Slot = "../../Injected", CosmeticId = "x" },
        "arbitrary cosmetic slot rejected",
    },
    { "settings.update", { Key = "MusicVolume", Value = 1.1 }, "out-of-range volume rejected" },
    { "settings.update", { Key = "ShowDamageNumbers", Value = 1 }, "wrong setting type rejected" },
}

for _, case in abuseCases do
    local ok = Rules.Validate(case[1], case[2])
    assert(not ok, case[3])
end

assert(Rules.IsCosmeticSlot("Aura"), "Aura cosmetic slot allowed")
assert(not Rules.IsCosmeticSlot("Injected"), "arbitrary cosmetic profile key rejected")

assert(Rules.ValidateMovementIntent({ Crouching = true }), "valid crouch intent accepted")
assert(not Rules.ValidateMovementIntent({ Crouching = 1 }), "non-boolean crouch intent rejected")
assert(
    not Rules.ValidateMovementIntent({ Crouching = false, Injected = true }),
    "extra movement intent field rejected"
)

print("action payload schema tests passed")
