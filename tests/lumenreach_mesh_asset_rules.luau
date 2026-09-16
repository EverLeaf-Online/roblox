local fs = require("@lune/fs")

local registry = fs.readFile("src/server/Content/EnvironmentAssetRegistry.luau")
local world = fs.readFile("src/server/Services/LumenreachWorldService.luau")
local loader = fs.readFile("src/server/Services/StudioEnvironmentAssetService.luau")
local sanitizer = fs.readFile("src/server/Services/EnvironmentPrefabService.luau")
local project = fs.readFile("default.project.json")

local assets = {
    { "LumenCivicHall", "25561936" },
    { "LumenQuartermasterDepot", "125612298" },
    { "LumenArchiveLodge", "4989402992" },
    { "LumenWayfarerInn", "1819167267" },
    { "LumenHealerLodge", "2914202068" },
    { "LumenCraftWorkshop", "125612298" },
    { "LumenOpenStable", "506010511" },
    { "LumenProvingLodge", "103444669708339" },
    { "LumenRoadWayhouse", "254849325" },
    { "LumenFarmBarn", "13902499907" },
    { "LumenCroftCottageA", "4989402992" },
    { "LumenCroftCottageB", "2914202068" },
    { "LumenGlowmereStiltHouse", "15413223952" },
    { "LumenMossglenRangerHall", "16421571" },
    { "LumenFrontierGatehouse", "4455026229" },
    { "LumenRuinedHall", "49387516" },
    { "LumenForgeYard", "125612298" },
    { "LumenGraveboneMausoleum", "1115559295" },
    { "LumenSunmossObservatory", "28483443" },
    { "LumenVeilfallSanctuary", "270668855" },
    { "LumenShatteredFortressTower", "28483443" },
    { "LumenStoneShrine", "270668855" },
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
        string.find(entry, 'Source = "Roblox Creator Store', 1, true),
        name .. " must document Creator Store provenance"
    )
    assert(
        string.find(entry, "CreatorStoreUrl = ", 1, true),
        name .. " must preserve its Creator Store source URL"
    )
    assert(string.find(world, '"' .. name .. '"', 1, true), "world does not reference " .. name)
end

assert(
    string.find(loader, 'game:GetService("AssetService")', 1, true),
    "Creator Store loader must use AssetService"
)
assert(
    string.find(loader, "AssetService:LoadAssetAsync(entry.AssetId)", 1, true),
    "free third-party models must use sandboxed LoadAssetAsync"
)
assert(
    string.find(loader, 'entry.Status == "approved_free_creator_store"', 1, true),
    "free Creator Store status must be loadable"
)
assert(
    string.find(project, '"AllowInsertFreeAssets": true', 1, true),
    "place must explicitly allow public free Creator Store assets"
)
for _, dangerous in
    {
        'descendant:IsA("LuaSourceContainer")',
        'descendant:IsA("Constraint")',
        'descendant:IsA("JointInstance")',
        'descendant:IsA("PackageLink")',
    }
do
    assert(
        string.find(sanitizer, dangerous, 1, true),
        "sanitizer missing dangerous-instance removal: " .. dangerous
    )
end
assert(
    string.find(sanitizer, "EnvironmentPrefabService.Place", 1, true),
    "sanitized prefabs must retain placement path"
)
assert(
    string.find(world, "EnvironmentPrefabService.Place", 1, true),
    "Lumenreach architecture must place sanitized Creator Store prefabs"
)

print("Lumenreach Creator Store architecture asset rules tests passed")
