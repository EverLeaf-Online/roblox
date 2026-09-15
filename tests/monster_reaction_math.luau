local Reaction = require("../src/shared/Math/MonsterReactionMath")

local tuning = {
    NormalMonsterKnockbackResistance = 0.12,
    EliteMonsterKnockbackResistance = 0.6,
    BossMonsterKnockbackResistance = 0.92,
    NormalMonsterStaggerResistance = 0.1,
    EliteMonsterStaggerResistance = 0.55,
    BossMonsterStaggerResistance = 0.85,
    MonsterInterruptStaggerThresholdSeconds = 0.08,
}

local normal = Reaction.Resolve({}, { Knockback = 10, Knockup = 2, Stagger = 0.2 }, tuning)
assert(math.abs(normal.Knockback - 8.8) < 0.000001, "normal knockback resistance")
assert(math.abs(normal.Knockup - 1.76) < 0.000001, "normal knockup resistance")
assert(math.abs(normal.Stagger - 0.18) < 0.000001 and normal.Interrupts, "normal hit staggers")

local elite = Reaction.Resolve(
    { Elite = true },
    { Knockback = 20, Knockup = 4, Stagger = 0.2 },
    tuning
)
assert(elite.Knockback == 8 and elite.Knockup == 1.6, "elite displacement is reduced")
assert(
    math.abs(elite.Stagger - 0.09) < 0.000001 and elite.Interrupts,
    "strong elite hit can interrupt"
)

local boss = Reaction.Resolve(
    { Boss = true },
    { Knockback = 20, Knockup = 5, Stagger = 0.3 },
    tuning
)
assert(math.abs(boss.Knockback - 1.6) < 0.000001, "boss nearly ignores knockback")
assert(math.abs(boss.Knockup - 0.4) < 0.000001, "boss nearly ignores launch")
assert(not boss.Interrupts, "ordinary boss hit cannot cancel attacks")

local override = Reaction.Resolve(
    { Elite = true, KnockbackResistance = 0.25, StaggerResistance = 0 },
    { Knockback = 12, Stagger = 0.1 },
    tuning
)
assert(override.Knockback == 9, "per-monster knockback override wins")
assert(override.Stagger == 0.1 and override.Interrupts, "per-monster stagger override wins")

local fallback = Reaction.Resolve({ HitStun = 0.2 }, {}, tuning)
assert(math.abs(fallback.Stagger - 0.18) < 0.000001, "definition HitStun remains fallback reaction")

print("monster reaction math tests passed")
