local Families = require("../src/server/Content/ClassFamilyDefinitions")

local expected = {
    ironbloom = { Stat = "Might", Ranged = false },
    thornrunner = { Stat = "Finesse", Ranged = true },
    lumenweaver = { Stat = "Insight", Ranged = true },
    veilstrider = { Stat = "Fortune", Ranged = false },
    brasshand = { Stat = "Might", Ranged = false },
}

for familyId, expectation in expected do
    local family = assert(Families[familyId], familyId .. " family exists")
    local attack = assert(family.BasicAttack, familyId .. " has basic attack profile")
    assert(family.PrimaryStat == expectation.Stat, familyId .. " primary stat is stable")
    assert(type(attack.Cooldown) == "number" and attack.Cooldown > 0, familyId .. " cooldown valid")
    assert(
        type(attack.AttackPower) == "number" and attack.AttackPower > 0,
        familyId .. " attack power valid"
    )
    assert(
        type(attack.Mastery) == "number" and attack.Mastery >= 0.1 and attack.Mastery <= 1,
        familyId .. " mastery valid"
    )
    assert(
        type(attack.Knockback) == "number" and attack.Knockback >= 0,
        familyId .. " knockback valid"
    )
    assert(type(attack.Knockup) == "number" and attack.Knockup >= 0, familyId .. " knockup valid")
    assert(type(attack.Stagger) == "number" and attack.Stagger >= 0, familyId .. " stagger valid")
    if expectation.Ranged then
        assert(attack.Range >= 20, familyId .. " maintains ranged basic identity")
    else
        assert(attack.Range <= 12, familyId .. " maintains close-range identity")
    end
end

assert(
    Families.veilstrider.BasicAttack.Cooldown < Families.ironbloom.BasicAttack.Cooldown,
    "Veilstrider attacks faster than Ironbloom"
)
assert(
    Families.brasshand.BasicAttack.AttackPower > Families.thornrunner.BasicAttack.AttackPower,
    "Brasshand basic is heavier than Thornrunner"
)
print("family combat profile tests passed")
