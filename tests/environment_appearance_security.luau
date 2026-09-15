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
    }
do
    assert(
        string.find(project, required, 1, true) ~= nil,
        "project-authored appearance missing " .. required
    )
end

print("environment appearance security tests passed")
