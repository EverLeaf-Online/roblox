local MaterialService = game:GetService("MaterialService")

local Definitions = require(script.Parent.Parent.Content.PBRMaterialDefinitions)

local PBRMaterialService = {}
local activeVariants = {}

local function isReady(definition)
    local ids = definition.RobloxAssetIds
    return ids
        and type(ids.Color) == "number"
        and ids.Color > 0
        and type(ids.Normal) == "number"
        and ids.Normal > 0
        and type(ids.Roughness) == "number"
        and ids.Roughness > 0
end

local function ensureVariant(name, definition)
    if not isReady(definition) then
        return nil
    end

    local variant = MaterialService:FindFirstChild(name)
    if not variant or not variant:IsA("MaterialVariant") then
        warn(string.format("[PBRMaterialService] Missing authored MaterialVariant %s", name))
        return nil
    end

    activeVariants[name] = variant
    return variant
end

function PBRMaterialService.Init()
    table.clear(activeVariants)
    for name, definition in Definitions do
        local ok, err = pcall(function()
            ensureVariant(name, definition)
        end)
        if not ok then
            warn(
                string.format("[PBRMaterialService] Failed to activate %s: %s", name, tostring(err))
            )
        end
    end
end

function PBRMaterialService.IsActive(name)
    return activeVariants[name] ~= nil
end

function PBRMaterialService.Apply(part, name)
    if not part:IsA("BasePart") or not activeVariants[name] then
        return false
    end
    local ok, err = pcall(function()
        part.MaterialVariant = name
    end)
    if not ok then
        warn(
            string.format(
                "[PBRMaterialService] Could not apply %s to %s: %s",
                name,
                part:GetFullName(),
                tostring(err)
            )
        )
        return false
    end
    return true
end

function PBRMaterialService.ApplyGeneratedWorld(world)
    for _, descendant in world:GetDescendants() do
        if descendant:IsA("BasePart") then
            if
                descendant.Material == Enum.Material.Rock
                or descendant.Material == Enum.Material.Slate
            then
                PBRMaterialService.Apply(descendant, "MossyRock")
            elseif descendant.Material == Enum.Material.WoodPlanks then
                PBRMaterialService.Apply(descendant, "MossWood")
            elseif descendant.Material == Enum.Material.Cobblestone then
                PBRMaterialService.Apply(descendant, "WoodStonePathway")
            end
        end
    end
end

function PBRMaterialService.GetMissingUploads()
    local missing = {}
    for name, definition in Definitions do
        if not isReady(definition) then
            table.insert(missing, name)
        end
    end
    table.sort(missing)
    return missing
end

return PBRMaterialService
