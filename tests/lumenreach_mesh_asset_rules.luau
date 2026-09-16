local fs = require("@lune/fs")

local registry = fs.readFile("src/server/Content/EnvironmentAssetRegistry.luau")
local world = fs.readFile("src/server/Services/LumenreachWorldService.luau")
local manifest = fs.readFile("assets/original/lumenreach_architecture/manifest.json")
local uploads = fs.readFile("assets/original/lumenreach_architecture/upload_results.json")
local generator = fs.readFile("scripts/generate_lumenreach_architecture.py")
assert(
    fs.isFile("assets/original/lumenreach_architecture/lumen_palette.png"),
    "architecture palette texture is missing"
)
assert(
    string.find(generator, "apply_palette_atlas", 1, true),
    "architecture generator must bake the flat-color palette into the GLBs"
)

local assets = {
    { "LumenCivicHall", "133556360685406" },
    { "LumenQuartermasterDepot", "137239183865764" },
    { "LumenArchiveLodge", "137267951808879" },
    { "LumenWayfarerInn", "71957319643364" },
    { "LumenHealerLodge", "120378183892930" },
    { "LumenCraftWorkshop", "131833611058968" },
    { "LumenOpenStable", "85851512665594" },
    { "LumenProvingLodge", "119304858476581" },
    { "LumenRoadWayhouse", "98034643639937" },
    { "LumenFarmBarn", "89701830913140" },
    { "LumenCroftCottageA", "132542848015613" },
    { "LumenCroftCottageB", "116174241850482" },
    { "LumenGlowmereStiltHouse", "139234768601269" },
    { "LumenMossglenRangerHall", "106301394317624" },
    { "LumenFrontierGatehouse", "120621904681287" },
    { "LumenRuinedHall", "70784355192049" },
    { "LumenForgeYard", "123625015286607" },
    { "LumenGraveboneMausoleum", "84123705929702" },
    { "LumenSunmossObservatory", "106886408516548" },
    { "LumenVeilfallSanctuary", "136210017750290" },
    { "LumenShatteredFortressTower", "111947348903814" },
    { "LumenStoneShrine", "120864356034791" },
}

for _, spec in assets do
    local name = spec[1]
    local assetId = spec[2]
    assert(string.find(registry, name .. " = {", 1, true), "registry missing " .. name)
    assert(
        string.find(registry, "AssetId = " .. assetId, 1, true),
        "wrong/missing asset ID for " .. name
    )
    assert(
        string.find(registry, 'Source = "Original EverLeaf low-poly architecture"', 1, true),
        "architecture assets must be original EverLeaf work"
    )
    assert(
        string.find(manifest, '"' .. name .. '"', 1, true),
        "generated GLB manifest missing " .. name
    )
    assert(
        string.find(uploads, '"assetId": ' .. assetId, 1, true),
        "upload manifest missing " .. name
    )
    assert(string.find(world, '"' .. name .. '"', 1, true), "world does not reference " .. name)
end

assert(
    string.find(world, "placeArchitectureBuilding", 1, true),
    "MeshPart architecture placement helper missing"
)
assert(
    string.find(world, "EnvironmentPrefabService.Place", 1, true),
    "architecture must place sanitized prefabs"
)
print("Lumenreach MeshPart architecture asset rules tests passed")
