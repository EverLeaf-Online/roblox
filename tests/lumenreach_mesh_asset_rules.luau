local fs = require("@lune/fs")

local registry = fs.readFile("src/server/Content/EnvironmentAssetRegistry.luau")
local world = fs.readFile("src/server/Services/LumenreachWorldService.luau")
local manifest = fs.readFile("assets/original/lumenreach_architecture/manifest.json")
local uploads = fs.readFile("assets/original/lumenreach_architecture/upload_results.json")
local heroManifest = fs.readFile("assets/original/lumenreach_hero_architecture_v2/manifest.json")
local heroUploads =
    fs.readFile("assets/original/lumenreach_hero_architecture_v2/upload_results.json")
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
    { "LumenCivicHall", "139081513944879", "LumenCivicHallV2" },
    { "LumenQuartermasterDepot", "107132117930894", "LumenQuartermasterDepotV2" },
    { "LumenArchiveLodge", "121183648834267", "LumenArchiveLodgeV2" },
    { "LumenWayfarerInn", "86450756988917", "LumenWayfarerInnV2" },
    { "LumenHealerLodge", "126397764459907", "LumenHealerLodgeV2" },
    { "LumenCraftWorkshop", "92965358111834", "LumenCraftWorkshopV2" },
    { "LumenOpenStable", "108271598307427", "LumenOpenStableV2" },
    { "LumenProvingLodge", "88192788505333", "LumenProvingLodgeV2" },
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
        string.find(registry, 'Source = "Original EverLeaf', 1, true),
        "architecture assets must be original EverLeaf work"
    )
    local heroName = spec[3]
    local expectedManifest = if heroName then heroManifest else manifest
    local expectedUploads = if heroName then heroUploads else uploads
    local manifestName = heroName or name
    assert(
        string.find(expectedManifest, '"' .. manifestName .. '"', 1, true),
        "generated GLB manifest missing " .. name
    )
    assert(
        string.find(expectedUploads, '"assetId": ' .. assetId, 1, true),
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

for _, token in
    {
        "139081513944879",
        "107132117930894",
        "121183648834267",
        "86450756988917",
        "126397764459907",
        "92965358111834",
        "108271598307427",
        "88192788505333",
        "individually authored hero architecture V2",
    }
do
    assert(
        string.find(registry, token, 1, true) ~= nil,
        "missing V24 hero architecture V2 contract: " .. token
    )
end
assert(
    fs.isFile("scripts/generate_lumenreach_hero_architecture_v2.py"),
    "hero architecture V2 generator missing"
)
assert(
    fs.isDir("assets/original/lumenreach_hero_architecture_v2"),
    "hero architecture V2 source assets missing"
)

print("Lumenreach MeshPart architecture asset rules tests passed")
