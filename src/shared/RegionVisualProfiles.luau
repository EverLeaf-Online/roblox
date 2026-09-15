local function rgb(r, g, b)
    return table.freeze({ r, g, b })
end

local RegionVisualProfiles = {
    default = table.freeze({
        Lighting = table.freeze({
            Brightness = 1.75,
            ExposureCompensation = -0.12,
            EnvironmentDiffuseScale = 0.38,
            EnvironmentSpecularScale = 0.72,
            ShadowSoftness = 0.35,
            Ambient = rgb(75, 92, 85),
            OutdoorAmbient = rgb(112, 126, 117),
        }),
        Atmosphere = table.freeze({
            Density = 0.2,
            Offset = 0.1,
            Haze = 1.15,
            Glare = 0.04,
            Color = rgb(199, 220, 255),
            Decay = rgb(106, 122, 111),
        }),
        ColorGrade = table.freeze({
            Brightness = -0.01,
            Contrast = 0.06,
            Saturation = 0.03,
            TintColor = rgb(241, 246, 238),
        }),
        Bloom = table.freeze({
            Intensity = 0.08,
            Size = 18,
            Threshold = 2,
        }),
        SunRays = table.freeze({
            Intensity = 0.025,
            Spread = 0.62,
        }),
    }),
    lumenreach = table.freeze({
        Lighting = table.freeze({
            Brightness = 1.68,
            ExposureCompensation = -0.08,
            EnvironmentDiffuseScale = 0.44,
            EnvironmentSpecularScale = 0.58,
            ShadowSoftness = 0.42,
            Ambient = rgb(66, 85, 76),
            OutdoorAmbient = rgb(118, 132, 116),
        }),
        Atmosphere = table.freeze({
            Density = 0.225,
            Offset = 0.12,
            Haze = 1.3,
            Glare = 0.035,
            Color = rgb(190, 218, 236),
            Decay = rgb(88, 112, 95),
        }),
        ColorGrade = table.freeze({
            Brightness = -0.005,
            Contrast = 0.085,
            Saturation = 0.055,
            TintColor = rgb(239, 248, 235),
        }),
        Bloom = table.freeze({
            Intensity = 0.10,
            Size = 20,
            Threshold = 1.85,
        }),
        SunRays = table.freeze({
            Intensity = 0.035,
            Spread = 0.68,
        }),
    }),
}

return table.freeze(RegionVisualProfiles)
