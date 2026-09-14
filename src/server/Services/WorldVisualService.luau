local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local WorldVisualService = {}

local function ensureAtmosphere()
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Name = "EverLeafAtmosphere"
        atmosphere.Parent = Lighting
    end
    return atmosphere
end

local function safeSet(instance, propertyName, value)
    local ok, err = pcall(function()
        instance[propertyName] = value
    end)
    if not ok then
        warn(
            string.format(
                "[WorldVisualService] Could not set %s.%s: %s",
                instance:GetFullName(),
                propertyName,
                tostring(err)
            )
        )
    end
    return ok
end

function WorldVisualService.Init()
    local graphics = GameConfig.Graphics

    safeSet(Lighting, "GlobalShadows", true)
    safeSet(Lighting, "Brightness", graphics.Brightness)
    safeSet(Lighting, "ClockTime", graphics.ClockTime)
    safeSet(Lighting, "ExposureCompensation", graphics.ExposureCompensation)
    safeSet(Lighting, "EnvironmentDiffuseScale", graphics.EnvironmentDiffuseScale)
    safeSet(Lighting, "EnvironmentSpecularScale", graphics.EnvironmentSpecularScale)
    safeSet(Lighting, "ShadowSoftness", graphics.ShadowSoftness)

    local atmosphere = ensureAtmosphere()
    safeSet(atmosphere, "Density", graphics.AtmosphereDensity)
    safeSet(atmosphere, "Haze", graphics.AtmosphereHaze)
    safeSet(atmosphere, "Glare", graphics.AtmosphereGlare)
    safeSet(atmosphere, "Color", Color3.fromRGB(199, 220, 255))
    safeSet(atmosphere, "Decay", Color3.fromRGB(106, 112, 125))
end

return WorldVisualService
