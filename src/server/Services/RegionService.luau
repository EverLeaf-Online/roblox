local RegionDefinitions = require(script.Parent.Parent.Content.RegionDefinitions)
local RegionService = {}

function RegionService.Unlock(profile, regionId)
    if not RegionDefinitions[regionId] then
        return false, "unknown_region"
    end
    profile.World.UnlockedRegions[regionId] = true
    return true
end

function RegionService.CanEnter(profile, regionId)
    local definition = RegionDefinitions[regionId]
    if not definition then
        return false, "unknown_region"
    end
    if not profile.World.UnlockedRegions[regionId] then
        return false, "region_locked"
    end
    if profile.Level < (definition.MinimumLevel or 1) then
        return false, "level_too_low"
    end
    return true
end

function RegionService.SetCurrent(profile, regionId, spawnId)
    local ok, reason = RegionService.CanEnter(profile, regionId)
    if not ok then
        return false, reason
    end
    local definition = RegionDefinitions[regionId]
    profile.World.RegionId = regionId
    profile.World.SpawnId = spawnId or definition.DefaultSpawnId
    return true
end

return RegionService
