local CatalogClient = require(script.Parent.Parent.Services.CatalogClient)

local UiText = {}

function UiText.PrettyId(value)
    local text = tostring(value or ""):gsub("_", " ")
    return (
        text:gsub("(%a)([%w']*)", function(first, rest)
            return string.upper(first) .. rest
        end)
    )
end

function UiText.RegionDisplayName(profile)
    local world = profile and profile.World or {}
    local regionId = world.RegionId or "lumenreach"
    local catalog = CatalogClient.Get()
    local region = catalog and catalog.Regions and catalog.Regions[regionId]
    return region and region.DisplayName or UiText.PrettyId(regionId), regionId
end

function UiText.ObjectiveText(objective, progress, fallbackText)
    if not objective then
        return fallbackText or "Explore"
    end
    local current = math.min(tonumber(progress) or 0, tonumber(objective.Required) or 1)
    local required = tonumber(objective.Required) or 1
    local target = UiText.PrettyId(objective.Target)
    if objective.Type == "Defeat" then
        return string.format("Defeat %s  %d/%d", target, current, required)
    elseif objective.Type == "Collect" then
        return string.format("Collect %s  %d/%d", target, current, required)
    elseif objective.Type == "Explore" then
        return string.format("Explore %s  %d/%d", target, current, required)
    elseif objective.Type == "Interact" then
        return string.format("Talk to %s  %d/%d", target, current, required)
    elseif objective.Type == "Craft" then
        return string.format("Craft %s  %d/%d", target, current, required)
    elseif objective.Type == "Use" then
        return string.format("Use %s  %d/%d", target, current, required)
    elseif objective.Type == "Reach" then
        return string.format("Reach %s  %d/%d", target, current, required)
    elseif objective.Type == "Escort" then
        return string.format("Escort %s  %d/%d", target, current, required)
    elseif objective.Type == "Survive" then
        return string.format("Survive %s  %d/%d", target, current, required)
    elseif objective.Type == "PublicEvent" then
        return string.format("Complete %s  %d/%d", target, current, required)
    end
    return string.format("%s %s  %d/%d", tostring(objective.Type), target, current, required)
end

return table.freeze(UiText)
