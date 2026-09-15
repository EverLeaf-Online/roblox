local WeaponCombatRules = {}

function WeaponCombatRules.Resolve(baseAttack, weaponType, weapon, tuning)
    baseAttack = type(baseAttack) == "table" and baseAttack or {}
    weapon = type(weapon) == "table" and weapon or nil
    tuning = type(tuning) == "table" and tuning or {}

    local baseCooldown = tonumber(baseAttack.Cooldown)
        or tonumber(tuning.BasicAttackCooldown)
        or 0.55
    if weapon then
        baseCooldown *= math.max(0.1, tonumber(weapon.CooldownMultiplier) or 1)
    end

    return {
        WeaponType = weapon and weaponType or nil,
        BaseCooldown = baseCooldown,
        Range = weapon and weapon.Range or baseAttack.Range or tuning.BasicAttackRange,
        VerticalRange = weapon and weapon.VerticalRange
            or baseAttack.VerticalRange
            or tuning.BasicAttackVerticalRange,
        ArcDegrees = weapon and weapon.ArcDegrees
            or baseAttack.ArcDegrees
            or tuning.BasicAttackArcDegrees,
        HitboxWidth = weapon and weapon.HitboxWidth
            or baseAttack.HitboxWidth
            or tuning.BasicAttackHitboxWidth,
        AttackMode = weapon and weapon.AttackMode or baseAttack.AttackMode or "Melee",
        ProjectileSpeed = weapon and weapon.ProjectileSpeed
            or baseAttack.ProjectileSpeed
            or tuning.BasicProjectileSpeed,
        ProjectileRadius = weapon and weapon.ProjectileRadius
            or baseAttack.ProjectileRadius
            or tuning.BasicProjectileRadius,
        AttackPower = baseAttack.AttackPower or tuning.BeginnerAttackPower,
        StatScale = baseAttack.StatScale or tuning.BeginnerStatScale,
        Mastery = baseAttack.Mastery or tuning.DefaultMastery,
        Knockback = weapon and weapon.Knockback or baseAttack.Knockback or tuning.BeginnerKnockback,
        Knockup = weapon and weapon.Knockup or baseAttack.Knockup or tuning.BeginnerKnockup,
        Stagger = weapon and weapon.Stagger or baseAttack.Stagger or tuning.BeginnerStagger,
    }
end

function WeaponCombatRules.IsValidWeaponType(weaponType, profiles)
    return type(weaponType) == "string"
        and type(profiles) == "table"
        and profiles[weaponType] ~= nil
end

return table.freeze(WeaponCombatRules)
