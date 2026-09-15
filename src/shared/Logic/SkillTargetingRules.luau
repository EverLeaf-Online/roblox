local SkillTargetingRules = {}

local VALID_SHAPES = table.freeze({
    Single = true,
    Cone = true,
    Box = true,
    Radius = true,
    Projectile = true,
})

local function finitePositive(value, maximum)
    value = tonumber(value)
    return value ~= nil
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value > 0
        and value <= maximum
end

function SkillTargetingRules.ResolveShape(effect)
    if type(effect) ~= "table" then
        return nil
    end
    if type(effect.TargetShape) == "string" and VALID_SHAPES[effect.TargetShape] then
        return effect.TargetShape
    end
    if effect.Mode == "Projectile" then
        return "Projectile"
    end
    return "Single"
end

function SkillTargetingRules.ResolveMaxTargets(effect)
    if type(effect) ~= "table" then
        return 1
    end
    local value = tonumber(effect.MaxTargets) or 1
    return math.clamp(math.floor(value), 1, 8)
end

function SkillTargetingRules.ResolveRange(effect)
    if type(effect) ~= "table" then
        return 1
    end
    local shape = SkillTargetingRules.ResolveShape(effect)
    if shape == "Radius" then
        return math.max(1, tonumber(effect.TargetRadius) or tonumber(effect.Range) or 1)
    end
    return math.max(1, tonumber(effect.Range) or 1)
end

function SkillTargetingRules.Validate(effect)
    if type(effect) ~= "table" or effect.Type ~= "DamageAttack" then
        return false, "invalid_effect"
    end
    local shape = SkillTargetingRules.ResolveShape(effect)
    if not shape or not VALID_SHAPES[shape] then
        return false, "invalid_shape"
    end
    if effect.TargetShape ~= nil and not VALID_SHAPES[effect.TargetShape] then
        return false, "invalid_shape"
    end
    local maxTargets = tonumber(effect.MaxTargets or 1)
    if not maxTargets or maxTargets % 1 ~= 0 or maxTargets < 1 or maxTargets > 8 then
        return false, "invalid_target_cap"
    end
    if not finitePositive(effect.Range, 100) then
        return false, "invalid_range"
    end
    if effect.VerticalRange ~= nil and not finitePositive(effect.VerticalRange, 100) then
        return false, "invalid_vertical_range"
    end
    if effect.ArcDegrees ~= nil and not finitePositive(effect.ArcDegrees, 360) then
        return false, "invalid_arc"
    end
    if shape == "Projectile" then
        if effect.Mode ~= "Projectile" then
            return false, "projectile_shape_requires_projectile_mode"
        end
        if maxTargets ~= 1 then
            return false, "projectile_target_cap"
        end
    elseif effect.Mode ~= "Melee" then
        return false, "non_projectile_shape_requires_melee_mode"
    end
    if shape == "Radius" and not finitePositive(effect.TargetRadius or effect.Range, 60) then
        return false, "invalid_radius"
    end
    if shape == "Box" and not finitePositive(effect.HitboxWidth, 60) then
        return false, "invalid_hitbox_width"
    end
    return true
end

function SkillTargetingRules.IsValidShape(shape)
    return VALID_SHAPES[shape] == true
end

return table.freeze(SkillTargetingRules)
