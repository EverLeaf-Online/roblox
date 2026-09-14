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
        return nil
    end

    activeVariants[name] = variant
    return variant
end

local function applyBaseOverride(name, definition)
    if not activeVariants[name] or not definition.OverrideMaterial then
        return
    end

    local ok, err = pcall(function()
        MaterialService:SetBaseMaterialOverride(definition.OverrideMaterial, name)
    end)
    if not ok then
        warn(
            string.format(
                "[PBRMaterialService] Failed to override %s with %s: %s",
                tostring(definition.OverrideMaterial),
                name,
                tostring(err)
            )
        )
    end
end

function PBRMaterialService.Init()
    table.clear(activeVariants)
    for name, definition in Definitions do
        local ok, err = pcall(function()
            if ensureVariant(name, definition) then
                applyBaseOverride(name, definition)
            end
        end)
        if not ok then
            warn(
                string.format("[PBRMaterialService] Failed to activate %s: %s", name, tostring(err))
            )
        end
    end

    MaterialService.ChildAdded:Connect(function(child)
        if not child:IsA("MaterialVariant") then
            return
        end

        local definition = Definitions[child.Name]
        if not definition or not isReady(definition) then
            return
        end

        activeVariants[child.Name] = child
        applyBaseOverride(child.Name, definition)
        task.defer(function()
            local world = workspace:FindFirstChild("EverLeafGeneratedWorld")
            if world then
                PBRMaterialService.ApplyGeneratedWorld(world)
            end
        end)
    end)
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
            local explicitVariant = descendant:GetAttribute("EverLeafMaterialVariant")
            if type(explicitVariant) == "string" and explicitVariant ~= "" then
                PBRMaterialService.Apply(descendant, explicitVariant)
            elseif descendant.Material == Enum.Material.WoodPlanks then
                PBRMaterialService.Apply(descendant, "MossWood")
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
