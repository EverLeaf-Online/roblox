local PortalDefinitions = require(script.Parent.Parent.Content.PortalDefinitions)
local RegionService = require(script.Parent.RegionService)
local WorldObjectService = require(script.Parent.WorldObjectService)

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
    return RegionService.SetCurrent(profile, definition.TargetRegionId, definition.TargetSpawnId)
end

return PortalService
