local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ProfileMigration = require(ReplicatedStorage.Shared.Logic.ProfileMigration)

local ProfileSchema = {}

local TEMPLATE = {
    Meta = {
        SchemaVersion = GameConfig.DataStore.SchemaVersion,
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
        Learned = {},
        Hotbar = {},
    },
    Quests = {
        Active = {},
        Completed = {},
    },
    World = {
        RegionId = "lumenreach",
        SpawnId = "lumenreach_start",
        UnlockedRegions = { lumenreach = true },
    },
    Achievements = { Unlocked = {} },
    Cosmetics = { Owned = {}, Equipped = {} },
    Settings = {
        MusicVolume = 1,
        SfxVolume = 1,
        ShowDamageNumbers = true,
    },
}

function ProfileSchema.DeepCopy(value)
    return ProfileMigration.DeepCopy(value)
end

function ProfileSchema.Reconcile(target, template)
    return ProfileMigration.Reconcile(target, template or TEMPLATE)
end

function ProfileSchema.New()
    local profile = ProfileSchema.DeepCopy(TEMPLATE)
    local now = os.time()
    profile.Meta.CreatedAt = now
    profile.Meta.LastSeenAt = now
    return profile
end

function ProfileSchema.Migrate(raw)
    return ProfileMigration.Migrate(raw, TEMPLATE, GameConfig.DataStore.SchemaVersion, os.time())
end

function ProfileSchema.PublicSnapshot(profile)
    local snapshot = ProfileSchema.DeepCopy(profile)
    snapshot.Meta = {
        SchemaVersion = profile.Meta.SchemaVersion,
        CreatedAt = profile.Meta.CreatedAt,
    }
    return snapshot
end

return ProfileSchema
