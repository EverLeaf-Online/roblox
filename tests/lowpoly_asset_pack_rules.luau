local fs = require("@lune/fs")

local project = fs.readFile("default.project.json")
local registry = fs.readFile("src/server/Content/EnvironmentAssetRegistry.luau")
local importer = fs.readFile("src/server/Services/StudioEnvironmentAssetService.luau")
local world = fs.readFile("src/server/Services/LumenreachWorldService.luau")
local worldConfig = fs.readFile("src/server/Content/LumenreachWorldConfig.luau")

assert(
    string.find(project, '"$path": "assets/lowpoly-megapack"', 1, true) ~= nil,
    "low-poly authored asset folder must be mapped into ServerStorage"
)
assert(
    string.find(importer, 'entry.Status == "authored_lowpoly_pack"', 1, true) ~= nil,
    "authored low-poly assets must register without runtime marketplace loading"
)
assert(
    string.find(worldConfig, "DesignVersion = 29", 1, true) ~= nil,
    "low-poly environment pass must bump the Lumenreach design version"
)

local prefabs = {
    "LowPolyTreeRound",
    "LowPolyTreeCanopy",
    "LowPolyMushroomCluster",
    "LowPolyLog",
    "LowPolyBush",
    "LowPolyRockCluster",
    "LowPolyBench",
    "LowPolyBarrel",
    "LowPolyLantern",
    "LowPolyCrate",
    "LowPolyVillageWell",
}

for _, prefab in prefabs do
    assert(string.find(registry, prefab, 1, true) ~= nil, prefab .. " missing from asset registry")
    local path = "assets/lowpoly-megapack/" .. prefab .. ".model.json"
    local model = fs.readFile(path)
    assert(
        string.find(model, '"ClassName": "MeshPart"', 1, true) ~= nil,
        prefab .. " has no MeshPart geometry"
    )
    assert(
        string.find(model, '"Anchored": true', 1, true) ~= nil,
        prefab .. " geometry must be anchored"
    )
    assert(
        string.find(model, '"CanCollide": false', 1, true) ~= nil,
        prefab .. " imported mesh collision must be disabled"
    )
    assert(
        string.find(model, '"ClassName": "Script"', 1, true) == nil,
        prefab .. " must not contain scripts"
    )
end

for _, token in
    {
        'placeDressingPrefab(parent, "LowPolyLantern"',
        'placeDressingPrefab(parent, "LowPolyBench"',
        '"LowPolyCrate"',
        '"LowPolyBarrel"',
        '"LowPolyVillageWell"',
        '"LowPolyTreeRound"',
        '"LowPolyTreeCanopy"',
        '"LowPolyMushroomCluster"',
        '"LowPolyRockCluster"',
        '"LowPolyLog"',
        '"LowPolyBush"',
    }
do
    assert(string.find(world, token, 1, true) ~= nil, "Lumenreach does not consume " .. token)
end

print("low-poly asset pack integration tests passed")
