local fs = require("@lune/fs")

local registry = fs.readFile("src/server/Content/EnvironmentAssetRegistry.luau")
local world = fs.readFile("src/server/Services/BrasshavenWorldService.luau")
local manifest = fs.readFile("assets/original/brasshaven_architecture/manifest.json")
local uploads = fs.readFile("assets/original/brasshaven_architecture/upload_results.json")
local generator = fs.readFile("scripts/generate_brasshaven_architecture.py")

assert(
    fs.isFile("assets/original/brasshaven_architecture/brass_palette.png"),
    "Brasshaven architecture palette is missing"
)
assert(
    string.find(generator, "apply_atlas", 1, true),
    "Brasshaven generator must bake the palette atlas"
)

local assets = {
    { "BrassFoundryAdminHall", "85296622746361" },
    { "BrassMachinistWorkshop", "133204573945623" },
    { "BrassSmelterHouse", "110764557535204" },
    { "BrassBoilerStation", "130754611285486" },
    { "BrassWorkerBarracks", "132013178216030" },
    { "BrassLoadingDepot", "103716454867226" },
    { "BrassIndustrialGatehouse", "123786283006636" },
    { "BrassRefineryTower", "93415297640992" },
}
for _, spec in assets do
    local name = spec[1]
    local assetId = spec[2]
    assert(string.find(registry, name .. " = {", 1, true), "registry missing " .. name)
    assert(
        string.find(registry, "AssetId = " .. assetId, 1, true),
        "wrong/missing asset ID for " .. name
    )
    assert(string.find(manifest, '"' .. name .. '"', 1, true), "manifest missing " .. name)
    assert(
        string.find(uploads, '"assetId": ' .. assetId, 1, true),
        "upload results missing " .. name
    )
    assert(
        string.find(world, '"' .. name .. '"', 1, true),
        "Brasshaven service does not reference " .. name
    )
end
assert(
    string.find(world, "placeIndustrialBuilding", 1, true),
    "Brasshaven MeshPart placement helper missing"
)
assert(
    string.find(world, "EnvironmentPrefabService.Place", 1, true),
    "Brasshaven must place sanitized prefabs"
)
assert(
    string.find(world, "spec.Size * scale", 1, true),
    "Brasshaven collision size must scale with mesh"
)
assert(
    string.find(world, "spec.Offset * scale", 1, true),
    "Brasshaven collision offset must scale with mesh"
)
print("Brasshaven MeshPart architecture asset rules tests passed")
