local ProfileMigration = require("../src/shared/Logic/ProfileMigration")
local ProfileTemplate = require("../src/shared/Logic/ProfileTemplate")

local SCHEMA_VERSION = 4
local template = ProfileTemplate.Build(SCHEMA_VERSION)

-- Fresh profile defaults are complete and isolated between builds.
assert(
    template.Level == 1 and template.Exp == 0 and template.AP == 0 and template.SP == 0,
    "fresh progression defaults"
)
assert(template.AdvancementTier == 0 and template.FamilyId == "", "fresh advancement defaults")
assert(template.Stats.Might == 4 and template.Stats.Fortune == 4, "fresh core stat defaults")
assert(
    template.Currencies.Shards == 0 and template.Currencies.Marks == 0,
    "fresh currency defaults"
)
assert(
    template.Inventory.Capacity == 48 and #template.Inventory.Slots == 0,
    "fresh inventory defaults"
)
assert(template.Storage.Capacity == 96 and #template.Storage.Slots == 0, "fresh storage defaults")
assert(template.Skills.Learned.beginner_strike == 1, "fresh starter skill")
assert(template.Skills.Hotbar["1"] == "beginner_strike", "fresh starter hotbar")
assert(
    template.World.RegionId == "lumenreach" and template.World.SpawnId == "lumenreach_start",
    "fresh world defaults"
)
assert(template.World.UnlockedRegions.lumenreach == true, "fresh region unlock")
assert(
    template.Settings.MusicVolume == 1 and template.Settings.SfxVolume == 1,
    "fresh audio defaults"
)
assert(template.Settings.ShowDamageNumbers == true, "fresh combat UI default")

local secondTemplate = ProfileTemplate.Build(SCHEMA_VERSION)
template.Inventory.Slots[1] = { ItemId = "should_not_leak", Quantity = 1 }
assert(#secondTemplate.Inventory.Slots == 0, "profile template builds are independent")
template = ProfileTemplate.Build(SCHEMA_VERSION)

-- Build a representative progressed profile touching every persisted domain.
local profile = ProfileMigration.DeepCopy(template)
profile.Meta.CreatedAt = 1000
profile.Meta.LastSeenAt = 1500
profile.Meta.ActiveSession = { Id = "server-a", TouchedAt = 1500 }
profile.Level = 30
profile.Exp = 12345
profile.AP = 7
profile.SP = 4
profile.AdvancementTier = 2
profile.FamilyId = "thornrunner"
profile.Stats.Might = 17
profile.Stats.Finesse = 42
profile.Stats.Insight = 13
profile.Stats.Fortune = 21
profile.Currencies.Shards = 9876
profile.Currencies.Marks = 8
profile.Inventory.Capacity = 48
profile.Inventory.Slots = {
    { ItemId = "field_tonic", Quantity = 17 },
    { ItemId = "belforge_wayfarer_ring", Quantity = 1 },
    { ItemId = "old_wayfinder_page", Quantity = 1 },
}
profile.Storage.Slots = {
    { ItemId = "lumen_fragment", Quantity = 11 },
    { ItemId = "small_tonic", Quantity = 4 },
}
profile.Equipment.Weapon = "thornrunner_briarbow"
profile.Equipment.Body = "ashrunner_coat"
profile.Equipment.Accessory = "emberloop_charm"
profile.Equipment.Ring1 = "belforge_wayfarer_ring"
profile.Skills.Learned = {
    beginner_strike = 5,
    steady_footing = 3,
    thornrunner_piercing_shot = 7,
    thornrunner_trail_focus = 4,
    thornrunner_gale_piercer = 2,
}
profile.Skills.Hotbar = {
    ["1"] = "beginner_strike",
    ["2"] = "thornrunner_piercing_shot",
    ["3"] = "thornrunner_gale_piercer",
}
profile.Quests.Active = {
    rejoin_active = { Progress = { 2, 1 }, ReadyToTurnIn = false },
}
profile.Quests.Completed = {
    lumen_first_steps = true,
    old_grove_stirs = true,
    belforge_gate_sentinel = true,
}
profile.World.RegionId = "brasshaven"
profile.World.SpawnId = "belforge_antechamber"
profile.World.UnlockedRegions.brasshaven = true
profile.World.Secrets.whisperroot_cache = true
profile.Achievements.Unlocked.first_victory = 1111
profile.Cosmetics.Owned.verdant_trail = true
profile.Cosmetics.Equipped.Aura = "verdant_trail"
profile.Settings.MusicVolume = 0.4
profile.Settings.SfxVolume = 0.7
profile.Settings.ShowDamageNumbers = false

-- Simulate persisted bytes becoming a new server's raw load, then migration/reconciliation.
local saved = ProfileMigration.DeepCopy(profile)
local ok, rejoined = ProfileMigration.Migrate(saved, template, SCHEMA_VERSION, 2000)
assert(ok, "saved profile migrates on rejoin")
assert(rejoined.Meta.SchemaVersion == SCHEMA_VERSION, "schema version preserved")
assert(
    rejoined.Meta.CreatedAt == 1000 and rejoined.Meta.LastSeenAt == 2000,
    "rejoin timestamps reconcile"
)
assert(
    rejoined.Meta.ActiveSession.Id == "server-a",
    "migration itself does not discard session metadata"
)
assert(
    rejoined.Level == 30 and rejoined.Exp == 12345 and rejoined.AP == 7 and rejoined.SP == 4,
    "progression survives rejoin"
)
assert(
    rejoined.AdvancementTier == 2 and rejoined.FamilyId == "thornrunner",
    "advancement survives rejoin"
)
assert(
    rejoined.Stats.Finesse == 42 and rejoined.Stats.Fortune == 21,
    "allocated stats survive rejoin"
)
assert(
    rejoined.Currencies.Shards == 9876 and rejoined.Currencies.Marks == 8,
    "currencies survive rejoin"
)
assert(#rejoined.Inventory.Slots == 3, "inventory slot count survives rejoin")
assert(
    rejoined.Inventory.Slots[1].ItemId == "field_tonic"
        and rejoined.Inventory.Slots[1].Quantity == 17,
    "stack survives rejoin"
)
assert(#rejoined.Storage.Slots == 2, "storage slot count survives rejoin")
assert(
    rejoined.Storage.Slots[1].ItemId == "lumen_fragment"
        and rejoined.Storage.Slots[1].Quantity == 11,
    "storage stack survives rejoin"
)
assert(rejoined.Equipment.Weapon == "thornrunner_briarbow", "weapon survives rejoin")
assert(
    rejoined.Equipment.Body == "ashrunner_coat"
        and rejoined.Equipment.Accessory == "emberloop_charm",
    "equipment survives rejoin"
)
assert(rejoined.Skills.Learned.thornrunner_gale_piercer == 2, "skill ranks survive rejoin")
assert(rejoined.Skills.Hotbar["3"] == "thornrunner_gale_piercer", "hotbar survives rejoin")
assert(
    rejoined.Quests.Active.rejoin_active.Progress[1] == 2,
    "active quest progress survives rejoin"
)
assert(rejoined.Quests.Completed.old_grove_stirs == true, "completed quests survive rejoin")
assert(
    rejoined.World.RegionId == "brasshaven" and rejoined.World.SpawnId == "belforge_antechamber",
    "region/spawn survive rejoin"
)
assert(rejoined.World.UnlockedRegions.brasshaven == true, "region unlock survives rejoin")
assert(rejoined.World.Secrets.whisperroot_cache == true, "one-time secret survives rejoin")
assert(rejoined.Achievements.Unlocked.first_victory == 1111, "achievement survives rejoin")
assert(rejoined.Cosmetics.Owned.verdant_trail == true, "cosmetic ownership survives rejoin")
assert(rejoined.Cosmetics.Equipped.Aura == "verdant_trail", "cosmetic equip survives rejoin")
assert(
    rejoined.Settings.MusicVolume == 0.4 and rejoined.Settings.SfxVolume == 0.7,
    "audio settings survive rejoin"
)
assert(rejoined.Settings.ShowDamageNumbers == false, "damage-number setting survives rejoin")

-- Migration must not alias saved data: post-load mutation cannot mutate the persisted snapshot.
rejoined.Inventory.Slots[1].Quantity = 1
rejoined.World.Secrets.whisperroot_cache = false
assert(
    saved.Inventory.Slots[1].Quantity == 17,
    "loaded inventory is deep-copied from persisted data"
)
assert(
    saved.World.Secrets.whisperroot_cache == true,
    "loaded nested state does not alias persisted data"
)

print("fresh profile/rejoin roundtrip tests passed")
