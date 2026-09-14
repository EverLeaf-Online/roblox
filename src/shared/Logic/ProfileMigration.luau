local ProfileMigration = {}

function ProfileMigration.DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, child in value do
        copy[ProfileMigration.DeepCopy(key)] = ProfileMigration.DeepCopy(child)
    end
    return copy
end

function ProfileMigration.Reconcile(target, template)
    for key, defaultValue in template do
        local currentValue = target[key]
        if currentValue == nil or type(currentValue) ~= type(defaultValue) then
            target[key] = ProfileMigration.DeepCopy(defaultValue)
        elseif type(defaultValue) == "table" then
            ProfileMigration.Reconcile(currentValue, defaultValue)
        end
    end
    return target
end

function ProfileMigration.Migrate(raw, template, schemaVersion, now)
    local profile = if type(raw) == "table"
        then ProfileMigration.DeepCopy(raw)
        else ProfileMigration.DeepCopy(template)
    profile.Meta = if type(profile.Meta) == "table" then profile.Meta else {}
    local oldVersion = tonumber(profile.Meta.SchemaVersion) or 1
    if oldVersion > schemaVersion then
        return false, "future_schema"
    end
    ProfileMigration.Reconcile(profile, template)
    profile.Meta.SchemaVersion = schemaVersion
    if profile.Meta.CreatedAt == 0 then
        profile.Meta.CreatedAt = now
    end
    profile.Meta.LastSeenAt = now
    return true, profile
end

return ProfileMigration
