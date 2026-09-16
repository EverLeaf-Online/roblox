local ProfileTemplate = {}

function ProfileTemplate.Build(schemaVersion)
    schemaVersion = math.max(1, math.floor(tonumber(schemaVersion) or 1))
    return {
        Meta = {
            SchemaVersion = schemaVersion,
            ActiveSession = nil,
            CreatedAt = 0,
            LastSeenAt = 0,
        },
        Level = 1,
        Exp = 0,
        AP = 0,
        SP = 0,
        AdvancementTier = 0,
        FamilyId = "",
        Stats = {
            Might = 4,
            Finesse = 4,
            Insight = 4,
            Fortune = 4,
        },
        Currencies = {
            Shards = 0,
            Marks = 0,
        },
        Inventory = {
            Capacity = 48,
            Slots = {},
        },
        Storage = {
            Capacity = 96,
            Slots = {},
        },
        Equipment = {
            Weapon = "",
            Head = "",
            Body = "",
            Legs = "",
            Accessory = "",
            Ring1 = "",
            Ring2 = "",
        },
        Skills = {
            Learned = { beginner_strike = 1 },
            Hotbar = { ["1"] = "beginner_strike" },
        },
        Quests = {
            Active = {},
            Completed = {},
        },
        World = {
            RegionId = "lumenreach",
            SpawnId = "lumenreach_start",
            UnlockedRegions = { lumenreach = true },
            Secrets = {},
        },
        Achievements = { Unlocked = {} },
        Cosmetics = { Owned = {}, Equipped = {} },
        Settings = {
            MusicVolume = 1,
            SfxVolume = 1,
            ShowDamageNumbers = true,
        },
    }
end

return table.freeze(ProfileTemplate)
