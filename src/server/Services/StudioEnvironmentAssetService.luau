local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")

local EnvironmentAssetRegistry = require(script.Parent.Parent.Content.EnvironmentAssetRegistry)
local EnvironmentPrefabService = require(script.Parent.EnvironmentPrefabService)

local StudioEnvironmentAssetService = {}

local function chooseVisualRoot(container)
    local children = container:GetChildren()
    if #children == 1 and (children[1]:IsA("Model") or children[1]:IsA("BasePart")) then
        local child = children[1]
        child.Parent = nil
        container:Destroy()
        return child
    end

    local model = Instance.new("Model")
    model.Name = "ImportedEnvironmentAsset"
    for _, child in children do
        if child:IsA("Model") or child:IsA("BasePart") or child:IsA("Folder") then
            child.Parent = model
        else
            child:Destroy()
        end
    end
    container:Destroy()
    return model
end

local function importAsset(entry)
    if EnvironmentPrefabService.Get(entry.PrefabName) then
        return true
    end

    local ok, containerOrError = pcall(function()
        return InsertService:LoadAsset(entry.AssetId)
    end)
    if not ok then
        warn(
            string.format(
                "[StudioEnvironmentAssetService] Could not load %s (%s): %s",
                entry.Name,
                tostring(entry.AssetId),
                tostring(containerOrError)
            )
        )
        return false
    end

    local visualRoot = chooseVisualRoot(containerOrError)
    local registered, reason =
        EnvironmentPrefabService.Register(entry.PrefabName, visualRoot, entry.AssetId, {
            AutoUpright = entry.AutoUpright == true,
            GroundToPivot = entry.GroundToPivot == true,
            Appearance = entry.Appearance,
        })
    if not registered then
        visualRoot:Destroy()
        warn(
            string.format(
                "[StudioEnvironmentAssetService] Could not register %s: %s",
                entry.Name,
                tostring(reason)
            )
        )
        return false
    end

    print(
        string.format(
            "[StudioEnvironmentAssetService] Loaded sanitized prefab %s from asset %s",
            entry.PrefabName,
            tostring(entry.AssetId)
        )
    )
    return true
end

function StudioEnvironmentAssetService.Init()
    local inStudio = RunService:IsStudio()

    for _, entry in EnvironmentAssetRegistry do
        local approved = entry.Status == "approved_for_sanitized_import"
            or entry.Status == "approved_for_studio_sanitized_import"
        local allowedHere = inStudio or entry.AllowRuntimeLoad == true
        if approved and allowedHere and entry.PrefabName then
            importAsset(entry)
        end
    end
end

return StudioEnvironmentAssetService
