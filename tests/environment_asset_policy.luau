local Registry = require("../src/server/Content/EnvironmentAssetRegistry")

local tree = Registry.TreePrimary
assert(type(tree) == "table", "TreePrimary registry entry exists")
assert(tree.AllowRuntimeLoad == true, "EverLeaf-owned primary tree remains runtime-loadable")
assert(type(tree.Appearance) == "table", "primary tree has controlled appearance")
for _, groupName in { "Bark", "Foliage" } do
    local maps = tree.Appearance[groupName]
    assert(type(maps) == "table", groupName .. " appearance maps exist")
    for _, fieldName in { "ColorMap", "NormalMap", "RoughnessMap" } do
        assert(
            type(maps[fieldName]) == "number" and maps[fieldName] > 0,
            groupName .. " " .. fieldName .. " is uploaded"
        )
    end
end

local manual = Registry.ForestTreesPack
assert(manual.Status == "manual_studio_import", "third-party forest tree pack remains manual-only")
assert(manual.AllowRuntimeLoad == false, "third-party forest tree pack cannot runtime-load")

print("environment asset policy tests passed")
