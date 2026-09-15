local Registry = require("../src/server/Content/EnvironmentAssetRegistry")

local tree = Registry.TreePrimary
assert(type(tree) == "table", "TreePrimary registry entry exists")
assert(tree.AllowRuntimeLoad == true, "EverLeaf-owned primary tree remains runtime-loadable")
assert(type(tree.Appearance) == "table", "primary tree has controlled appearance")
for _, groupName in { "Bark", "Foliage" } do
    local appearance = tree.Appearance[groupName]
    assert(type(appearance) == "table", groupName .. " appearance policy exists")
    assert(
        type(appearance.TemplateName) == "string" and appearance.TemplateName ~= "",
        groupName .. " uses a pre-authored SurfaceAppearance template"
    )
    local maps = appearance.AuthoredMaps
    assert(type(maps) == "table", groupName .. " authored map metadata exists")
    for _, fieldName in { "Color", "Normal", "Roughness" } do
        assert(
            type(maps[fieldName]) == "number" and maps[fieldName] > 0,
            groupName .. " " .. fieldName .. " is uploaded"
        )
    end
end
assert(
    tree.Appearance.Bark.MaterialVariant == "MossWood",
    "pine bark uses MossWood fallback variant"
)
assert(tree.Appearance.Foliage.DoubleSided == true, "pine foliage remains double-sided")

local manual = Registry.ForestTreesPack
assert(manual.Status == "manual_studio_import", "third-party forest tree pack remains manual-only")
assert(manual.AllowRuntimeLoad == false, "third-party forest tree pack cannot runtime-load")

local runtimeAppearanceEntries = {
    "TreePrimary",
    "TreeStump",
    "FallenTreeTrunk",
    "PineRoots",
    "FernPrimary",
    "DryBranches",
    "MossyRockSet",
    "RockFace",
    "TreeStump2",
    "FallenTreeTrunk2",
}
for _, entryName in runtimeAppearanceEntries do
    local entry = assert(Registry[entryName], entryName .. " exists")
    assert(entry.AllowRuntimeLoad == true, entryName .. " is an EverLeaf-owned runtime prefab")
    assert(type(entry.Appearance) == "table", entryName .. " has explicit authored appearance")
    local policy = entry.Appearance.Bark or entry.Appearance.Foliage
    assert(type(policy) == "table", entryName .. " appearance has a material policy")
    assert(
        type(policy.TemplateName) == "string" and policy.TemplateName ~= "",
        entryName .. " uses a pre-authored SurfaceAppearance template"
    )
    local maps = policy.AuthoredMaps
    assert(type(maps) == "table", entryName .. " authored maps exist")
    for _, mapName in { "Color", "Normal", "Roughness" } do
        assert(
            type(maps[mapName]) == "number" and maps[mapName] > 0,
            entryName .. " " .. mapName .. " uploaded"
        )
    end
end

print("environment asset policy tests passed")
