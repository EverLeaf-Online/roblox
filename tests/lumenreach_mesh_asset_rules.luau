local fs = require("@lune/fs")

local registry = fs.readFile("src/server/Content/EnvironmentAssetRegistry.luau")
local world = fs.readFile("src/server/Services/LumenreachWorldService.luau")
local manifest = fs.readFile("assets/original/lumenreach_architecture/manifest.json")
local uploads = fs.readFile("assets/original/lumenreach_architecture/upload_results.json")

local assets = {
    { "LumenCivicHall", "127768353689424" },
    { "LumenQuartermasterDepot", "84750321219058" },
    { "LumenArchiveLodge", "103322782929462" },
    { "LumenWayfarerInn", "118338713936616" },
    { "LumenHealerLodge", "88168406420725" },
    { "LumenCraftWorkshop", "105268332724582" },
    { "LumenOpenStable", "87422611932371" },
    { "LumenProvingLodge", "97764957110691" },
    { "LumenRoadWayhouse", "104717310952590" },
    { "LumenFarmBarn", "74150114579140" },
    { "LumenCroftCottageA", "134706181384015" },
    { "LumenCroftCottageB", "128457775419453" },
    { "LumenGlowmereStiltHouse", "98647766328538" },
    { "LumenMossglenRangerHall", "105347638360093" },
    { "LumenFrontierGatehouse", "90751638251875" },
    { "LumenRuinedHall", "133702935578347" },
    { "LumenForgeYard", "115045579898423" },
    { "LumenGraveboneMausoleum", "90687448622867" },
    { "LumenSunmossObservatory", "72910144160451" },
    { "LumenVeilfallSanctuary", "89230413054325" },
    { "LumenShatteredFortressTower", "136833732602200" },
    { "LumenStoneShrine", "105255978786194" },
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
