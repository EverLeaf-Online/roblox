local Rules = require("../src/shared/Logic/SkillTargetingRules")

local base = {
    Type = "DamageAttack",
    Mode = "Melee",
    TargetShape = "Cone",
    MaxTargets = 3,
    Range = 12,
    VerticalRange = 8,
    ArcDegrees = 120,
}
assert(Rules.Validate(base), "valid cone targeting accepted")
assert(Rules.ResolveShape(base) == "Cone", "explicit cone shape resolves")
assert(Rules.ResolveMaxTargets(base) == 3, "target cap resolves")
assert(Rules.ResolveRange(base) == 12, "normal targeting range resolves")

local radius = table.clone(base)
radius.TargetShape = "Radius"
radius.TargetRadius = 7
radius.ArcDegrees = 360
assert(Rules.Validate(radius), "valid radius targeting accepted")
assert(Rules.ResolveRange(radius) == 7, "radius uses target radius")

local projectile = table.clone(base)
projectile.Mode = "Projectile"
projectile.TargetShape = "Projectile"
projectile.MaxTargets = 1
assert(Rules.Validate(projectile), "valid projectile targeting accepted")

local invalidCap = table.clone(base)
invalidCap.MaxTargets = 9
assert(not Rules.Validate(invalidCap), "target cap above eight rejected")
local invalidProjectile = table.clone(projectile)
invalidProjectile.MaxTargets = 2
assert(not Rules.Validate(invalidProjectile), "projectile multi-target rejected")
local invalidRadius = table.clone(radius)
invalidRadius.TargetRadius = 0
assert(not Rules.Validate(invalidRadius), "zero radius rejected")
local invalidShape = table.clone(base)
invalidShape.TargetShape = "ClientSelected"
assert(not Rules.Validate(invalidShape), "unknown/client-selected shape rejected")

print("skill targeting rules tests passed")
