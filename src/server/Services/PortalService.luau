local PortalDefinitions = require(script.Parent.Parent.Content.PortalDefinitions)
local RegionService = require(script.Parent.RegionService)
local WorldObjectService = require(script.Parent.WorldObjectService)
local WorldTravelService = require(script.Parent.WorldTravelService)

local PortalService = {}

function PortalService.Travel(player, profile, portalId, worldObject)
    local definition = PortalDefinitions[portalId]
    if not definition then
        return false, "unknown_portal"
    end
    local registered = WorldObjectService.Get(worldObject)
    if not registered or registered.Kind ~= "Portal" or registered.Id ~= portalId then
        return false, "invalid_world_object"
    end
    if not WorldObjectService.CanInteract(player, worldObject, 10) then
        return false, "too_far"
    end
    if profile.World.RegionId ~= definition.SourceRegionId then
        return false, "wrong_source_region"
    end

    local previousRegionId = profile.World.RegionId
    local previousSpawnId = profile.World.SpawnId
    local changed, changeReason =
        RegionService.SetCurrent(profile, definition.TargetRegionId, definition.TargetSpawnId)
    if not changed then
        return false, changeReason
    end

    local moved, moveReason = WorldTravelService.Teleport(player, definition.TargetSpawnId)
    if not moved then
        profile.World.RegionId = previousRegionId
        profile.World.SpawnId = previousSpawnId
        WorldTravelService.SetRespawn(player, previousSpawnId)
        return false, moveReason
    end
    return true, definition.TargetRegionId
end

return PortalService
