local fs = require("@lune/fs")

local registry = fs.readFile("src/server/Content/EnvironmentAssetRegistry.luau")
local world = fs.readFile("src/server/Services/BrasshavenWorldService.luau")

local assets = {
    { "BrassFoundryAdminHall", "2195158233" },
    { "BrassMachinistWorkshop", "4729280834" },
    { "BrassSmelterHouse", "10694469551" },
    { "BrassBoilerStation", "2195158233" },
    { "BrassWorkerBarracks", "655063599" },
    { "BrassLoadingDepot", "10694469551" },
    { "BrassIndustrialGatehouse", "5037991647" },
    { "BrassRefineryTower", "272953704" },
}

for _, spec in assets do
    local name = spec[1]
    local assetId = spec[2]
    local entryAt =
        assert(string.find(registry, name .. " = {", 1, true), "registry missing " .. name)
    local nextEntry = string.find(registry, "\n    },", entryAt, true) or #registry
    local entry = string.sub(registry, entryAt, nextEntry)
    assert(
        string.find(entry, "AssetId = " .. assetId, 1, true),
        "wrong Creator Store asset ID for " .. name
    )
    assert(
        string.find(entry, 'Status = "approved_free_creator_store"', 1, true),
        name .. " must use approved free Creator Store status"
    )
    assert(
        string.find(entry, "ThirdPartyFree = true", 1, true),
        name .. " must explicitly declare free third-party provenance"
    )
    assert(
        string.find(entry, "CreatorStoreUrl = ", 1, true),
        name .. " must preserve its Creator Store source URL"
    )
    assert(
        string.find(world, '"' .. name .. '"', 1, true),
        "Brasshaven service does not reference " .. name
    )
end

assert(
    string.find(world, "placeIndustrialBuilding", 1, true),
    "Brasshaven placement helper missing"
)
assert(
    string.find(world, "EnvironmentPrefabService.Place", 1, true),
    "Brasshaven must place sanitized Creator Store prefabs"
)
assert(
    string.find(world, "spec.Size * scale", 1, true),
    "Brasshaven collision size must scale with imported geometry"
)
assert(
    string.find(world, "spec.Offset * scale", 1, true),
    "Brasshaven collision offset must scale with imported geometry"
)

for _, propName in { "CreatorFactoryProps", "CreatorIndustrialPipes" } do
    assert(
        string.find(registry, propName .. " = {", 1, true),
        "missing industrial Creator Store dressing source " .. propName
    )
end

assert(
    string.find(world, "local function architectureScaleForLongest", 1, true),
    "Brasshaven architecture needs a dedicated third-party scale guard"
)
assert(
    string.find(
        world,
        "math.clamp(prefabScaleForLongest(prefabName, targetLongest), 0.25, 3.0)",
        1,
        true
    ),
    "Brasshaven Creator Store buildings must clamp pathological source-unit scaling"
)
assert(
    string.find(world, 'model:SetAttribute("ArchitectureScale", scale)', 1, true),
    "placed Brasshaven architecture must expose its normalized scale for Studio QA"
)

print("Brasshaven Creator Store architecture asset rules tests passed")

assert(
    string.find(world, '"CreatorStoreSmokestack"', 1, true),
    "Brasshaven skyline forge towers must prefer the free Creator Store smokestack prefab"
)
assert(
    string.find(world, 'world:SetAttribute("CreatorStoreArchitecture", true)', 1, true),
    "Brasshaven must advertise Creator Store architecture pass"
)
