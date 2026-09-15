local Rules = require("../src/shared/Logic/SkillPresentationRules")

local melee = { Mode = "Melee" }
local projectile = { Mode = "Projectile" }
local valid = {
    AnimationStyle = "heavy",
    CastDurationMultiplier = 1.2,
    ImpactStyle = "heavy_burst",
    CastVFX = "pulse",
    CastSound = "heavy",
    ImpactSound = "impact",
    ImpactWeight = 1.1,
}
assert(Rules.Validate(valid, melee), "valid melee presentation accepted")

local shot = table.clone(valid)
shot.AnimationStyle = "shot"
shot.ImpactStyle = "pierce"
shot.ProjectileKind = "lance"
assert(Rules.Validate(shot, projectile), "valid projectile presentation accepted")

local badAnimation = table.clone(valid)
badAnimation.AnimationStyle = "ClientAnimation"
assert(not Rules.Validate(badAnimation, melee), "unknown animation style rejected")
local badProjectile = table.clone(valid)
badProjectile.ProjectileKind = "orb"
assert(not Rules.Validate(badProjectile, melee), "melee skill cannot define projectile kind")
local badWeight = table.clone(valid)
badWeight.ImpactWeight = 99
assert(not Rules.Validate(badWeight, melee), "excessive impact weight rejected")

print("skill presentation rules tests passed")
