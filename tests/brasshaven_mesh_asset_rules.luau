local fs = require("@lune/fs")

local registry = fs.readFile("src/server/Content/EnvironmentAssetRegistry.luau")
local world = fs.readFile("src/server/Services/BrasshavenWorldService.luau")
local manifest = fs.readFile("assets/original/brasshaven_architecture_v2/manifest.json")
local uploads = fs.readFile("assets/original/brasshaven_architecture_v2/upload_results.json")
local generator = fs.readFile("scripts/generate_brasshaven_architecture_v2.py")

assert(
    fs.isFile("assets/original/brasshaven_architecture_v2/brass_v2_palette.png"),
    "Brasshaven architecture palette is missing"
)
assert(
    string.find(generator, "apply_atlas", 1, true),
    "Brasshaven generator must bake the palette atlas"
)

local assets = {
    { "BrassFoundryAdminHall", "124973222924746", "BrassFoundryAdminHallV2" },
    { "BrassMachinistWorkshop", "138267838471833", "BrassMachinistWorkshopV2" },
    { "BrassSmelterHouse", "120967242976120", "BrassSmelterHouseV2" },
    { "BrassBoilerStation", "104828075505604", "BrassBoilerStationV2" },
    { "BrassWorkerBarracks", "136478312344800", "BrassWorkerBarracksV2" },
    { "BrassLoadingDepot", "80090386975748", "BrassLoadingDepotV2" },
    { "BrassIndustrialGatehouse", "76713540788976", "BrassIndustrialGatehouseV2" },
    { "BrassRefineryTower", "83172229593216", "BrassRefineryTowerV2" },
}
for _, spec in assets do
    local name = spec[1]
    local assetId = spec[2]
    assert(string.find(registry, name .. " = {", 1, true), "registry missing " .. name)
    assert(
        string.find(registry, "AssetId = " .. assetId, 1, true),
        "wrong/missing asset ID for " .. name
    )
    local manifestName = spec[3] or name
    assert(string.find(manifest, '"' .. manifestName .. '"', 1, true), "manifest missing " .. name)
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
