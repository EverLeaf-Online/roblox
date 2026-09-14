local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

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
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, child in value do
        copy[ProfileSchema.DeepCopy(key)] = ProfileSchema.DeepCopy(child)
    end
    return copy
end

function ProfileSchema.Reconcile(target, template)
    template = template or TEMPLATE
    for key, defaultValue in template do
        local currentValue = target[key]
        if currentValue == nil or type(currentValue) ~= type(defaultValue) then
            target[key] = ProfileSchema.DeepCopy(defaultValue)
        elseif type(defaultValue) == "table" then
            ProfileSchema.Reconcile(currentValue, defaultValue)
        end
    end
    return target
end

function ProfileSchema.New()
    local profile = ProfileSchema.DeepCopy(TEMPLATE)
    local now = os.time()
    profile.Meta.CreatedAt = now
    profile.Meta.LastSeenAt = now
    return profile
end

function ProfileSchema.Migrate(raw)
    local profile = if type(raw) == "table"
        then ProfileSchema.DeepCopy(raw)
        else ProfileSchema.New()
    local meta = if type(profile.Meta) == "table" then profile.Meta else {}
    local oldVersion = tonumber(meta.SchemaVersion) or 1
    if oldVersion > GameConfig.DataStore.SchemaVersion then
        return false, "future_schema"
    end
    ProfileSchema.Reconcile(profile)
    profile.Meta.SchemaVersion = GameConfig.DataStore.SchemaVersion
    if profile.Meta.CreatedAt == 0 then
        profile.Meta.CreatedAt = os.time()
    end
    profile.Meta.LastSeenAt = os.time()
    return true, profile
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
