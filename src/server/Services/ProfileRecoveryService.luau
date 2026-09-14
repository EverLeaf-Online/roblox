local ProfileSchema = require(script.Parent.Parent.Data.ProfileSchema)
local PlayerDataService = require(script.Parent.PlayerDataService)
local ProfileRecoveryService = {}

function ProfileRecoveryService.Inspect(player)
    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "profile_not_loaded"
    end
    return true, ProfileSchema.DeepCopy(profile)
end

function ProfileRecoveryService.ReconcileLoaded(player)
    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "profile_not_loaded"
    end
    local ok, migrated = ProfileSchema.Migrate(profile)
    if not ok then
        return false, migrated
    end
    for key in profile do
        profile[key] = nil
    end
    for key, value in migrated do
        profile[key] = value
    end
    PlayerDataService.NotifyChanged(player)
    return true
end

return ProfileRecoveryService
