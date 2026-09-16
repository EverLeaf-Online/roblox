local fs = require("@lune/fs")

local registry = fs.readFile("src/server/Content/EnvironmentAssetRegistry.luau")
local world = fs.readFile("src/server/Services/LumenreachWorldService.luau")
local loader = fs.readFile("src/server/Services/StudioEnvironmentAssetService.luau")
local sanitizer = fs.readFile("src/server/Services/EnvironmentPrefabService.luau")
local project = fs.readFile("default.project.json")

local villageRoles = {
    "LumenCivicHall",
    "LumenQuartermasterDepot",
    "LumenArchiveLodge",
    "LumenWayfarerInn",
    "LumenHealerLodge",
    "LumenCraftWorkshop",
    "LumenOpenStable",
    "LumenProvingLodge",
    "LumenRoadWayhouse",
    "LumenFarmBarn",
    "LumenCroftCottageA",
    "LumenCroftCottageB",
    "LumenGlowmereStiltHouse",
    "LumenMossglenRangerHall",
    "LumenForgeYard",
}
local landmarkRoles = {
    "LumenFrontierGatehouse",
    "LumenRuinedHall",
    "LumenGraveboneMausoleum",
    "LumenSunmossObservatory",
    "LumenVeilfallSanctuary",
    "LumenShatteredFortressTower",
    "LumenStoneShrine",
}

local function assertRole(name, assetId)
    local entryAt =
        assert(string.find(registry, name .. " = {", 1, true), "registry missing " .. name)
    local nextEntry = string.find(registry, "\n    },", entryAt, true) or #registry
    local entry = string.sub(registry, entryAt, nextEntry)
    assert(string.find(entry, "AssetId = " .. assetId, 1, true), "wrong cohesive pack for " .. name)
    assert(
        string.find(entry, 'Status = "approved_free_creator_store"', 1, true),
        name .. " must use free Creator Store status"
    )
    assert(
        string.find(entry, "ThirdPartyFree = true", 1, true),
        name .. " must declare free provenance"
    )
    assert(
        string.find(entry, "SelectModelFromPack = true", 1, true),
        name .. " must extract one building instead of importing a whole pack"
    )
    assert(
        string.find(entry, "VariantOrdinal = ", 1, true),
        name .. " needs a deterministic pack variant"
    )
    assert(
        string.find(entry, "SelectTokens = table.freeze", 1, true),
        name .. " needs building-role selection tokens"
    )
    assert(
        string.find(entry, "CreatorStoreUrl = ", 1, true),
        name .. " must preserve Creator Store provenance"
    )
    assert(string.find(world, '"' .. name .. '"', 1, true), "world does not reference " .. name)
end

for _, name in villageRoles do
    assertRole(name, "86710303527267")
end
for _, name in landmarkRoles do
    assertRole(name, "12007890134")
end

assert(
    string.find(loader, 'game:GetService("AssetService")', 1, true),
    "Creator Store loader must use AssetService"
)
assert(
    string.find(loader, "AssetService:LoadAssetAsync(assetId)", 1, true),
    "Creator Store loads must flow through the cached sandboxed loader"
)
assert(
    string.find(loader, "assetContainerCache", 1, true),
    "shared Creator Store packs must load once and clone from cache"
)
assert(
    string.find(loader, "collectArchitectureCandidates", 1, true),
    "pack architecture needs candidate extraction"
)
assert(
    string.find(loader, "architectureCandidateScore", 1, true),
    "pack architecture needs role-aware candidate scoring"
)
assert(
    string.find(loader, "refusing whole-pack fallback", 1, true),
    "failed pack extraction must never place the whole asset pack"
)
assert(
    string.find(project, '"AllowInsertFreeAssets": true', 1, true),
    "place must explicitly allow free Creator Store assets"
)
assert(
    string.find(sanitizer, "EnvironmentPrefabService.Place", 1, true),
    "sanitized prefabs must retain placement path"
)
assert(
    string.find(world, "EnvironmentPrefabService.Place", 1, true),
    "Lumenreach architecture must place sanitized Creator Store prefabs"
)
assert(
    string.find(
        world,
        "math.clamp(prefabScaleForLongest(prefabName, targetLongest), 0.55, 1.75)",
        1,
        true
    ),
    "architecture scaling must reject extreme source-unit distortion"
)
assert(
    string.find(world, 'wrapper:SetAttribute("ArchitectureScale", architectureScale)', 1, true),
    "placed architecture must expose normalized scale"
)

print("Lumenreach cohesive Creator Store architecture rules tests passed")
