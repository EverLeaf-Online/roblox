local SkillPresentationRules = {}

local VALID_ANIMATIONS = table.freeze({
    family = true,
    heavy = true,
    fast = true,
    shot = true,
    cast = true,
})
local VALID_IMPACTS = table.freeze({
    slash = true,
    cross = true,
    burst = true,
    heavy_burst = true,
    pulse = true,
    pierce = true,
})
local VALID_PROJECTILES = table.freeze({ arrow = true, orb = true, lance = true })
local VALID_CAST_VFX = table.freeze({ none = true, pulse = true })
local VALID_SOUNDS = table.freeze({
    none = true,
    slash = true,
    heavy = true,
    shot = true,
    magic = true,
    impact = true,
})

local function finiteInRange(value, minimum, maximum)
    value = tonumber(value)
    return value ~= nil
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value >= minimum
        and value <= maximum
end

function SkillPresentationRules.Validate(presentation, effect)
    if type(presentation) ~= "table" then
        return false, "missing_presentation"
    end
    if not VALID_ANIMATIONS[presentation.AnimationStyle or "family"] then
        return false, "invalid_animation_style"
    end
    if not VALID_IMPACTS[presentation.ImpactStyle or "burst"] then
        return false, "invalid_impact_style"
    end
    if not VALID_CAST_VFX[presentation.CastVFX or "none"] then
        return false, "invalid_cast_vfx"
    end
    if not VALID_SOUNDS[presentation.CastSound or "none"] then
        return false, "invalid_cast_sound"
    end
    if not VALID_SOUNDS[presentation.ImpactSound or "none"] then
        return false, "invalid_impact_sound"
    end
    if not finiteInRange(presentation.CastDurationMultiplier or 1, 0.5, 1.75) then
        return false, "invalid_cast_duration_multiplier"
    end
    if not finiteInRange(presentation.ImpactWeight or 0.6, 0, 2) then
        return false, "invalid_impact_weight"
    end
    if type(effect) == "table" and effect.Mode == "Projectile" then
        if not VALID_PROJECTILES[presentation.ProjectileKind or "arrow"] then
            return false, "invalid_projectile_kind"
        end
    elseif presentation.ProjectileKind ~= nil then
        return false, "projectile_kind_on_melee"
    end
    return true
end

return table.freeze(SkillPresentationRules)
