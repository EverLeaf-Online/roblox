local MaterialService = game:GetService("MaterialService")

local Definitions = require(script.Parent.Parent.Content.PBRMaterialDefinitions)

local PBRMaterialService = {}
local activeVariants = {}

local function contentId(assetId)
    if type(assetId) ~= "number" or assetId <= 0 then
        return ""
    end
    return "rbxassetid://" .. tostring(assetId)
end

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

    local existing = MaterialService:FindFirstChild(name)
    if existing and not existing:IsA("MaterialVariant") then
        existing:Destroy()
        existing = nil
    end
    local variant = existing or Instance.new("MaterialVariant")
    variant.Name = name
    variant.BaseMaterial = definition.BaseMaterial
    variant.ColorMap = contentId(definition.RobloxAssetIds.Color)
    variant.NormalMap = contentId(definition.RobloxAssetIds.Normal)
    variant.RoughnessMap = contentId(definition.RobloxAssetIds.Roughness)
    variant.MetalnessMap = ""
    variant.StudsPerTile = definition.StudsPerTile or 8
    pcall(function()
        variant.MaterialPattern = definition.Pattern or Enum.MaterialPattern.Regular
    end)
    variant.Parent = MaterialService
    activeVariants[name] = variant

    if definition.OverrideProperty then
        local ok, err = pcall(function()
            MaterialService[definition.OverrideProperty] = name
        end)
        if not ok then
            warn(
                string.format(
                    "[PBRMaterialService] Could not set %s override: %s",
                    definition.OverrideProperty,
                    tostring(err)
                )
            )
        end
    end
    return variant
end

function PBRMaterialService.Init()
    table.clear(activeVariants)
    for name, definition in Definitions do
        ensureVariant(name, definition)
    end
end

function PBRMaterialService.IsActive(name)
    return activeVariants[name] ~= nil
end

function PBRMaterialService.Apply(part, name)
    if not part:IsA("BasePart") or not activeVariants[name] then
        return false
    end
    part.MaterialVariant = name
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
