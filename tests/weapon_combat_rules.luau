local Families = require("../src/server/Content/ClassFamilyDefinitions")
local Items = require("../src/server/Content/ItemDefinitions")
local Rules = require("../src/shared/Logic/WeaponCombatRules")
local Profiles = require("../src/shared/WeaponCombatProfiles")

local tuning = {
    BasicAttackCooldown = 0.55,
    BasicAttackRange = 9,
    BasicAttackVerticalRange = 6,
    BasicAttackArcDegrees = 120,
    BasicAttackHitboxWidth = 7,
    BasicProjectileSpeed = 76,
    BasicProjectileRadius = 0.4,
    BeginnerAttackPower = 5,
    BeginnerStatScale = 1.5,
    DefaultMastery = 0.25,
    BeginnerKnockback = 8,
    BeginnerKnockup = 1.5,
    BeginnerStagger = 0.18,
    MinimumAttackSpeedBonus = -40,
    MaximumAttackSpeedBonus = 30,
    MinimumBasicAttackCooldown = 0.28,
}

for itemId, definition in Items do
    if definition.EquipmentSlot == "Weapon" then
        assert(Profiles[definition.WeaponType], "weapon item has combat profile: " .. itemId)
    end
end

local thorn = Families.thornrunner.BasicAttack
local blade = Rules.Resolve(thorn, "Blade", Profiles.Blade, tuning)
assert(blade.AttackMode == "Melee", "blade overrides Thornrunner projectile into melee")
assert(
    blade.Range == Profiles.Blade.Range and blade.HitboxWidth == Profiles.Blade.HitboxWidth,
    "blade geometry"
)
assert(
    blade.AttackPower == thorn.AttackPower and blade.Mastery == thorn.Mastery,
    "family power/mastery retained"
)

local bow = Rules.Resolve(thorn, "Bow", Profiles.Bow, tuning)
assert(bow.AttackMode == "Projectile", "bow resolves projectile attack")
assert(bow.ProjectileSpeed == Profiles.Bow.ProjectileSpeed, "bow projectile speed")
assert(bow.BaseCooldown == thorn.Cooldown, "bow preserves family base cadence multiplier")

local veil = Families.veilstrider.BasicAttack
local twins = Rules.Resolve(veil, "TwinBlades", Profiles.TwinBlades, tuning)
assert(
    twins.AttackMode == "Melee" and twins.ArcDegrees == 165,
    "twin blades use wide melee profile"
)
assert(twins.BaseCooldown < veil.Cooldown, "twin blades have weapon cadence multiplier")

local brass = Families.brasshand.BasicAttack
local maul = Rules.Resolve(brass, "Maul", Profiles.Maul, tuning)
assert(maul.Knockback == 15 and maul.Knockup == 4, "maul owns heavy reaction profile")
assert(maul.BaseCooldown > brass.Cooldown, "maul cadence is deliberately heavier")

local unarmed = Rules.Resolve(thorn, nil, nil, tuning)
assert(
    unarmed.AttackMode == thorn.AttackMode and unarmed.Range == thorn.Range,
    "unequipped fallback preserves family basic"
)

assert(Rules.IsValidWeaponType("Focus", Profiles), "known weapon type valid")
assert(not Rules.IsValidWeaponType("InjectedWeapon", Profiles), "unknown weapon type rejected")

print("weapon combat rules tests passed")
