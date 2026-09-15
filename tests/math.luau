local DamageMath = require("../src/shared/Math/DamageMath")
local DerivedStatsMath = require("../src/shared/Math/DerivedStatsMath")
local ProgressionMath = require("../src/shared/Math/ProgressionMath")

local function expectEqual(actual, expected, message)
    if actual ~= expected then
        error(
            string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual))
        )
    end
end

local function expect(condition, message)
    if not condition then
        error(message)
    end
end

expectEqual(ProgressionMath.ExpToNextLevel(1), 75, "level 1 EXP curve")
expect(
    ProgressionMath.ExpToNextLevel(10) > ProgressionMath.ExpToNextLevel(9),
    "EXP curve must increase"
)

local minimum, maximum = DamageMath.CalculateRange(10, 5, 2, 0.25)
expectEqual(maximum, 25, "damage maximum")
expectEqual(minimum, 6.25, "damage minimum")
expectEqual(DamageMath.RollFromUnit(minimum, maximum, 0), 6, "minimum roll")
expectEqual(DamageMath.RollFromUnit(minimum, maximum, 1), 25, "maximum roll")
expectEqual(DamageMath.RollFromUnit(minimum, maximum, 0.5), 16, "mid roll")

local tuning = {
    BaseHP = 100,
    HPPerLevel = 12,
    HPPerMight = 5,
    BaseMP = 50,
    MPPerLevel = 4,
    MPPerInsight = 6,
    BaseDefense = 2,
    DefensePerLevel = 0.4,
    DefensePerMight = 0.6,
    BaseCritChance = 0.04,
    CritChancePerFortune = 0.0035,
    CritChancePerFinesse = 0.0015,
    MaximumCritChance = 0.35,
    BaseCritMultiplier = 1.45,
    CritMultiplierPerFinesse = 0.0025,
    CritMultiplierPerFortune = 0.0015,
    MaximumCritMultiplier = 2.25,
}
local derived = DerivedStatsMath.Compute(1, 4, 4, 4, 4, tuning)
expectEqual(derived.MaxHP, 120, "starting HP")
expectEqual(derived.MaxMP, 74, "starting MP")
expectEqual(derived.Defense, 4.4, "starting defense")
expect(math.abs(derived.CritChance - 0.06) < 0.000001, "starting crit chance")
expect(math.abs(derived.CritMultiplier - 1.466) < 0.000001, "starting crit multiplier")

local equippedDerived = DerivedStatsMath.Compute(1, 5, 4, 6, 5, tuning, {
    Defense = 6,
    CritChance = 3,
    CritPower = 10,
})
expectEqual(equippedDerived.MaxHP, 125, "equipment Might affects max HP")
expectEqual(equippedDerived.MaxMP, 86, "equipment Insight affects max MP")
expectEqual(equippedDerived.Defense, 11, "equipment defense is included")
expect(math.abs(equippedDerived.CritChance - 0.0935) < 0.000001, "equipment crit chance")
expect(math.abs(equippedDerived.CritMultiplier - 1.5675) < 0.000001, "equipment crit power")

local passiveDerived = DerivedStatsMath.Compute(1, 4, 4, 4, 4, tuning, {
    MaxHP = 16,
    MaxMP = 20,
    Defense = 3,
    CritChance = 2,
    CritPower = 5,
})
expectEqual(passiveDerived.MaxHP, 136, "flat passive max HP bonus")
expectEqual(passiveDerived.MaxMP, 94, "flat passive max MP bonus")
expectEqual(passiveDerived.Defense, 7.4, "passive defense bonus")
expect(math.abs(passiveDerived.CritChance - 0.08) < 0.000001, "passive crit chance")
expect(math.abs(passiveDerived.CritMultiplier - 1.516) < 0.000001, "passive crit power")

local critDamage, critical = DamageMath.ApplyCritical(100, 0.2, 1.5, 0.1)
expectEqual(critDamage, 150, "critical damage multiplier")
expect(critical == true, "critical roll succeeds below chance")
critDamage, critical = DamageMath.ApplyCritical(100, 0.2, 1.5, 0.2)
expectEqual(critDamage, 100, "non-critical damage unchanged")
expect(critical == false, "critical boundary is exclusive")

expectEqual(DamageMath.MitigateIncoming(100, 0, 100), 100, "zero defense mitigation")
expectEqual(DamageMath.MitigateIncoming(100, 25, 100), 80, "defense mitigation")
expectEqual(
    DamageMath.MitigateIncoming(10, 900, 100),
    1,
    "defense cannot reduce positive hit below one"
)
expectEqual(DamageMath.MitigateIncoming(0, 900, 100), 0, "zero damage remains zero")

local capped = DerivedStatsMath.Compute(100, 100, 100, 100, 100, tuning, {
    CritChance = 100,
    CritPower = 200,
})
expectEqual(capped.CritChance, tuning.MaximumCritChance, "crit chance cap")
expectEqual(capped.CritMultiplier, tuning.MaximumCritMultiplier, "crit multiplier cap")

print("math tests passed")
