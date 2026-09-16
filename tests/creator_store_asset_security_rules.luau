local fs = require("@lune/fs")

local registry = fs.readFile("src/server/Content/EnvironmentAssetRegistry.luau")
local loader = fs.readFile("src/server/Services/StudioEnvironmentAssetService.luau")
local sanitizer = fs.readFile("src/server/Services/EnvironmentPrefabService.luau")
local project = fs.readFile("default.project.json")

assert(
    string.find(project, '"AssetService"', 1, true),
    "AssetService must be authored into the place"
)
assert(
    string.find(project, '"AllowInsertFreeAssets": true', 1, true),
    "third-party free loading must be explicit"
)
assert(
    string.find(loader, "AssetService:LoadAssetAsync(entry.AssetId)", 1, true),
    "third-party assets must use the sandboxed modern loader"
)
assert(
    string.find(loader, "InsertService:LoadAsset", 1, true) == nil,
    "legacy InsertService loader must not return"
)
assert(
    string.find(registry, 'Status = "approved_free_creator_store"', 1, true),
    "registry needs an explicit curated free-asset status"
)

for _, token in
    {
        "Script = true",
        "LocalScript = true",
        "ModuleScript = true",
        "RemoteEvent = true",
        "RemoteFunction = true",
        "BindableEvent = true",
        "BindableFunction = true",
        "Sound = true",
        "Animation = true",
        "Tool = true",
        "Humanoid = true",
        "AnimationController = true",
        "Animator = true",
        'descendant:IsA("LuaSourceContainer")',
        'descendant:IsA("Constraint")',
        'descendant:IsA("JointInstance")',
        'descendant:IsA("WeldConstraint")',
        'descendant:IsA("PackageLink")',
    }
do
    assert(string.find(sanitizer, token, 1, true), "Creator Store sanitizer missing " .. token)
end

-- Textures/decals are visual data, not executable behavior. Curated Store assets
-- may retain them so importing a model does not destroy the visual quality we selected.
assert(
    string.find(sanitizer, "Texture = true", 1, true) == nil,
    "sanitizer must not blindly destroy curated texture visuals"
)
assert(
    string.find(sanitizer, "Decal = true", 1, true) == nil,
    "sanitizer must not blindly destroy curated decal visuals"
)

print("Creator Store asset security rules tests passed")
