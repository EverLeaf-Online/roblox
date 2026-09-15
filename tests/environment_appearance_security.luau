local fs = require("@lune/fs")

local source = fs.readFile("src/server/Services/EnvironmentPrefabService.luau")

for _, propertyName in { "ColorMap", "NormalMap", "RoughnessMap", "MetalnessMap" } do
    local assignmentPattern = "%." .. propertyName .. "%s*="
    assert(
        string.find(source, assignmentPattern) == nil,
        "runtime prefab service must not assign protected SurfaceAppearance." .. propertyName
    )
end
assert(
    string.find(source, "%.TextureID%s*=", 1) == nil
        and string.find(source, "%.TextureId%s*=", 1) == nil,
    "runtime prefab service must not rewrite MeshPart texture identifiers"
)

assert(
    string.find(source, "template:Clone()", 1, true) ~= nil,
    "runtime appearance path clones a pre-authored template"
)

local project = fs.readFile("default.project.json")
for _, required in
    {
        '"EverLeafSurfaceAppearances"',
        '"PineBark"',
        '"PineFoliage"',
        "rbxassetid://77401003804409",
        "rbxassetid://107051695372257",
        '"AlphaMode": "Transparency"',
        '"TreeStump01"',
        '"DeadTreeTrunk"',
        '"PineRoots"',
        '"Fern02"',
        '"DryBranchesMedium01"',
        '"RockMossSet01"',
        '"RockFace02"',
        '"TreeStump02"',
        '"DeadTreeTrunk02"',
        "rbxassetid://75921120872030",
        "rbxassetid://87556766012982",
    }
do
    assert(
        string.find(project, required, 1, true) ~= nil,
        "project-authored appearance missing " .. required
    )
end

print("environment appearance security tests passed")

local lumenreach = fs.readFile("src/server/Services/LumenreachWorldService.luau")
assert(
    string.find(lumenreach, '"RockFace"', 1, true) == nil,
    "terrain-first Lumenreach must not place the paper-thin imported RockFace prefab"
)
assert(
    string.find(lumenreach, "terrain:Clear()", 1, true) ~= nil
        and string.find(
                lumenreach,
                'world:SetAttribute("TerrainFirstMMOLayout", true)',
                1,
                true
            )
            ~= nil,
    "Lumenreach must rebuild its terrain rather than layer scenery over the previous map"
)
assert(
    string.find(lumenreach, 'Instance.new("Beam")', 1, true) ~= nil,
    "Veilfall waterfall uses Beam ribbons instead of opaque slab parts"
)
