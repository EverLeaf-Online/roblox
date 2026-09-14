local ProfileMigration = require("../src/shared/Logic/ProfileMigration")
local template = {
    Meta = { SchemaVersion = 2, CreatedAt = 0, LastSeenAt = 0 },
    Level = 1,
    Settings = { Music = 1 },
}
local ok, migrated = ProfileMigration.Migrate(
    { Meta = { SchemaVersion = 1, CreatedAt = 5 }, Level = 9 },
    template,
    2,
    100
)
assert(ok, "old profile migrates")
assert(
    migrated.Meta.SchemaVersion == 2
        and migrated.Meta.CreatedAt == 5
        and migrated.Meta.LastSeenAt == 100,
    "meta migrated"
)
assert(migrated.Settings.Music == 1, "missing fields reconciled")
local futureOk, reason =
    ProfileMigration.Migrate({ Meta = { SchemaVersion = 3 } }, template, 2, 100)
assert(not futureOk and reason == "future_schema", "future schema fails closed")
print("profile migration tests passed")
