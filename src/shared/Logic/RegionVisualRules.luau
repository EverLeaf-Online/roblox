local RegionVisualRules = {}

local function finiteNumber(value, minimum, maximum)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value >= minimum
        and value <= maximum
end

local function validColor(value)
    if type(value) ~= "table" or #value ~= 3 then
        return false
    end
    for index = 1, 3 do
        if not finiteNumber(value[index], 0, 255) then
            return false
        end
    end
    return true
end

function RegionVisualRules.Validate(profile)
    if type(profile) ~= "table" then
        return false, "invalid_profile"
    end
    local lighting = profile.Lighting
    local atmosphere = profile.Atmosphere
    local grade = profile.ColorGrade
    local bloom = profile.Bloom
    local rays = profile.SunRays
    if type(lighting) ~= "table" or type(atmosphere) ~= "table" then
        return false, "missing_lighting"
    end
    if type(grade) ~= "table" or type(bloom) ~= "table" or type(rays) ~= "table" then
        return false, "missing_post_processing"
    end
    if not finiteNumber(lighting.Brightness, 0, 10) then
        return false, "invalid_brightness"
    end
    if not finiteNumber(lighting.ExposureCompensation, -5, 5) then
        return false, "invalid_exposure"
    end
    if not finiteNumber(lighting.EnvironmentDiffuseScale, 0, 1) then
        return false, "invalid_diffuse"
    end
    if not finiteNumber(lighting.EnvironmentSpecularScale, 0, 1) then
        return false, "invalid_specular"
    end
    if not finiteNumber(lighting.ShadowSoftness, 0, 1) then
        return false, "invalid_shadow_softness"
    end
    if not validColor(lighting.Ambient) or not validColor(lighting.OutdoorAmbient) then
        return false, "invalid_ambient"
    end
    if not finiteNumber(atmosphere.Density, 0, 1) then
        return false, "invalid_atmosphere_density"
    end
    if not finiteNumber(atmosphere.Offset, -1, 1) then
        return false, "invalid_atmosphere_offset"
    end
    if not finiteNumber(atmosphere.Haze, 0, 10) or not finiteNumber(atmosphere.Glare, 0, 10) then
        return false, "invalid_atmosphere_scatter"
    end
    if not validColor(atmosphere.Color) or not validColor(atmosphere.Decay) then
        return false, "invalid_atmosphere_color"
    end
    if
        not finiteNumber(grade.Brightness, -1, 1)
        or not finiteNumber(grade.Contrast, -1, 1)
        or not finiteNumber(grade.Saturation, -1, 1)
        or not validColor(grade.TintColor)
    then
        return false, "invalid_color_grade"
    end
    if
        not finiteNumber(bloom.Intensity, 0, 10)
        or not finiteNumber(bloom.Size, 0, 56)
        or not finiteNumber(bloom.Threshold, 0, 20)
    then
        return false, "invalid_bloom"
    end
    if not finiteNumber(rays.Intensity, 0, 1) or not finiteNumber(rays.Spread, 0, 1) then
        return false, "invalid_sun_rays"
    end
    return true
end

function RegionVisualRules.Resolve(regionId, profiles)
    if type(profiles) ~= "table" then
        return nil
    end
    if type(regionId) == "string" and profiles[regionId] then
        return profiles[regionId]
    end
    return profiles.default
end

return table.freeze(RegionVisualRules)
