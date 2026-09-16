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
    string.find(loader, "AssetService:LoadAssetAsync(assetId)", 1, true),
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

for _, token in
    {
        "Message = true",
        "Hint = true",
        "BillboardGui = true",
        "SurfaceGui = true",
        "ScreenGui = true",
        'descendant:IsA("LayerCollector")',
        'descendant:IsA("GuiObject")',
    }
do
    assert(
        string.find(sanitizer, token, 1, true),
        "Creator Store sanitizer must strip embedded UI/credit content: " .. token
    )
end
assert(
    string.find(registry, "25561936", 1, true) == nil,
    "malformed Bevillia inn must stay retired"
)
assert(
    string.find(registry, "99210238800832", 1, true) == nil,
    "random one-off civic replacement must stay retired"
)
assert(string.find(registry, "86710303527267", 1, true), "cohesive free village kit missing")
assert(string.find(registry, "12007890134", 1, true), "cohesive free landmark kit missing")
assert(
    string.find(loader, "SelectModelFromPack", 1, true),
    "pack entries must extract one architectural model"
)
assert(
    string.find(loader, "refusing whole-pack fallback", 1, true),
    "dirty pack imports must fail closed"
)

for _, token in
    {
        "ParticleEmitter = true",
        "Beam = true",
        "Trail = true",
        "Smoke = true",
        "Fire = true",
        "Sparkles = true",
        "Highlight = true",
        'descendant:IsA("Light")',
    }
do
    assert(
        string.find(sanitizer, token, 1, true),
        "Creator Store sanitizer must strip imported presentation behavior: " .. token
    )
end
assert(
    string.find(sanitizer, "model.PrimaryPart = nil", 1, true),
    "Creator Store models must discard imported/arbitrary PrimaryPart pivots"
)
assert(
    string.find(sanitizer, "model.PrimaryPart = candidate", 1, true) == nil,
    "an arbitrary roof/beam must never become a building PrimaryPart"
)
assert(
    string.find(sanitizer, "model:PivotTo(CFrame.new(sourcePivot.Position))", 1, true),
    "Creator Store model pivot rotation must be neutralized before placement"
)
assert(
    string.find(sanitizer, 'model:SetAttribute("EverLeafSanitizedRemovedCount", removed)', 1, true),
    "sanitized imports must expose how much third-party content was removed"
)

assert(
    string.find(sanitizer, "descendant.Transparency >= 0.98", 1, true),
    "sanitizer must remove invisible imported helper/collision parts"
)
assert(
    string.find(sanitizer, "math.max(size.X, size.Z) >= 180", 1, true),
    "sanitizer must reject giant imported display/base plates"
)
assert(
    string.find(sanitizer, "pivot.Position.X - boundsCFrame.Position.X", 1, true),
    "placement must recenter imported models from visible bounds instead of dirty pivots"
)

print("Creator Store asset security rules tests passed")
