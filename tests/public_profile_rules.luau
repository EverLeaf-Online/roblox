local Rules = require("../src/shared/Logic/PublicProfileRules")

local profile = {
    Level = 30,
    FamilyId = "thornrunner",
    AdvancementTier = 2,
    AP = 99,
    SP = 88,
    Stats = { Might = 4, Finesse = 42, Insight = 5, Fortune = 21 },
    Currencies = { Shards = 9999, Marks = 9 },
    Inventory = { Capacity = 48, Slots = { { ItemId = "secret_item", Quantity = 1 } } },
    Equipment = { Weapon = "thornrunner_briarbow", Body = "ashrunner_coat" },
    Quests = { Active = { hidden = true }, Completed = {} },
    World = { Secrets = { whisperroot_cache = true } },
    Achievements = { Unlocked = { first_victory = 1, level_10 = 2 } },
    Cosmetics = { Owned = { founder = true }, Equipped = { Aura = "founder" } },
    Settings = { MusicVolume = 0.1 },
}
local public = assert(Rules.Build(profile, {
    UserId = 123,
    Name = "Tester",
    DisplayName = "Wayfarer",
    Recognition = "FOUNDER",
}, {
    MaxHP = 500,
    MaxMP = 120,
    AttackPower = 90,
    Defense = 25,
    CritChance = 17,
    CritPower = 55,
    AttackSpeed = 12,
}))
assert(public.UserId == 123 and public.Level == 30, "identity/progression included")
assert(public.Equipment.Weapon == "thornrunner_briarbow", "equipment included")
assert(public.Cosmetics.Equipped.Aura == "founder", "equipped cosmetics included")
assert(public.AchievementCount == 2, "achievement count included")
assert(public.Currencies == nil and public.Inventory == nil, "economy/inventory remain private")
assert(public.Quests == nil and public.World == nil, "quest/world secrets remain private")
assert(
    public.Settings == nil and public.AP == nil and public.SP == nil,
    "private settings/unspent points omitted"
)
assert(public.Cosmetics.Owned == nil, "cosmetic ownership inventory remains private")
profile.Equipment.Weapon = "changed_after_build"
assert(public.Equipment.Weapon == "thornrunner_briarbow", "public equipment snapshot is isolated")

print("public profile rules tests passed")
