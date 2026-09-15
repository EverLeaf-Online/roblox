local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ProfileMigration = require(ReplicatedStorage.Shared.Logic.ProfileMigration)
local ProfileTemplate = require(ReplicatedStorage.Shared.Logic.ProfileTemplate)

local ProfileSchema = {}
local TEMPLATE = ProfileTemplate.Build(GameConfig.DataStore.SchemaVersion)

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
