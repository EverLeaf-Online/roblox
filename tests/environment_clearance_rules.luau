local Rules = require("../src/shared/Logic/EnvironmentClearanceRules")

assert(Rules.Resolve("TreePrimary", nil, nil) == 11.5, "primary tree clearance")
assert(Rules.Resolve("ForestTree07", nil, nil) == 11.5, "forest tree variant clearance")
assert(
    Rules.Resolve("PathRock", "RockFace", nil) == 9.0,
    "renamed rock uses source prefab clearance"
)
assert(Rules.Resolve("VeilfallRockFace2", "RockFace", nil) == 9.0, "renamed face remains clearable")
assert(Rules.Resolve("IntegratedRockFace", nil, 12.5) == 12.5, "wrapper explicit clearance wins")
assert(Rules.Resolve("UnknownDecoration", nil, nil) == nil, "unknown decoration is not scrubbed")
assert(Rules.Resolve("UnknownDecoration", nil, 0 / 0) == nil, "invalid explicit clearance rejected")

print("environment clearance rules tests passed")
