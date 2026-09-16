local fs = require("@lune/fs")

local registry = fs.readFile("src/server/Content/EnvironmentAssetRegistry.luau")
local world = fs.readFile("src/server/Services/LumenreachWorldService.luau")
local manifest = fs.readFile("assets/original/lumenreach_architecture/manifest.json")
local uploads = fs.readFile("assets/original/lumenreach_architecture/upload_results.json")
local heroManifest = fs.readFile("assets/original/lumenreach_hero_architecture_v2/manifest.json")
local heroUploads =
    fs.readFile("assets/original/lumenreach_hero_architecture_v2/upload_results.json")
local districtManifest =
    fs.readFile("assets/original/lumenreach_district_architecture_v2/manifest.json")
local districtUploads =
    fs.readFile("assets/original/lumenreach_district_architecture_v2/upload_results.json")
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
    { "LumenRoadWayhouse", "113522507708416", nil, "LumenRoadWayhouseV2" },
    { "LumenFarmBarn", "95470404760231", nil, "LumenFarmBarnV2" },
    { "LumenCroftCottageA", "85398853803273", nil, "LumenCroftCottageAV2" },
    { "LumenCroftCottageB", "124535713833238", nil, "LumenCroftCottageBV2" },
    { "LumenGlowmereStiltHouse", "75557217788082", nil, "LumenGlowmereStiltHouseV2" },
    { "LumenMossglenRangerHall", "107286041863676", nil, "LumenMossglenRangerHallV2" },
    { "LumenFrontierGatehouse", "95912537374601", nil, "LumenFrontierGatehouseV2" },
    { "LumenRuinedHall", "114819696409739", nil, "LumenRuinedHallV2" },
    { "LumenForgeYard", "112336892534267", nil, "LumenForgeYardV2" },
    { "LumenGraveboneMausoleum", "113037057944108", nil, "LumenGraveboneMausoleumV2" },
    { "LumenSunmossObservatory", "127786137346539", nil, "LumenSunmossObservatoryV2" },
    { "LumenVeilfallSanctuary", "129935484262557", nil, "LumenVeilfallSanctuaryV2" },
    { "LumenShatteredFortressTower", "105681641070050", nil, "LumenShatteredFortressTowerV2" },
    { "LumenStoneShrine", "88981727079686", nil, "LumenStoneShrineV2" },
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
    local districtName = spec[4]
    local expectedManifest = if heroName
        then heroManifest
        elseif districtName then districtManifest
        else manifest
    local expectedUploads = if heroName
        then heroUploads
        elseif districtName then districtUploads
        else uploads
    local manifestName = heroName or districtName or name
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
        "missing V25 hero architecture V2 contract: " .. token
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

for _, token in
    {
        "LumenRoadWayhouseV2",
        "LumenFarmBarnV2",
        "LumenCroftCottageAV2",
        "LumenCroftCottageBV2",
        "LumenGlowmereStiltHouseV2",
        "LumenMossglenRangerHallV2",
        "LumenFrontierGatehouseV2",
        "LumenRuinedHallV2",
        "LumenForgeYardV2",
        "LumenGraveboneMausoleumV2",
        "LumenSunmossObservatoryV2",
        "LumenVeilfallSanctuaryV2",
        "LumenShatteredFortressTowerV2",
        "LumenStoneShrineV2",
    }
do
    assert(string.find(districtManifest, token, 1, true), "district V2 manifest missing " .. token)
end
assert(
    string.find(districtUploads, '"moderation": "Approved"', 1, true),
    "district V2 assets must be approved"
)
assert(
    fs.isFile("scripts/generate_lumenreach_district_architecture_v2.py"),
    "district V2 generator missing"
)

print("Lumenreach MeshPart architecture asset rules tests passed")
