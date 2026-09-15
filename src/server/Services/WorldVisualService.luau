local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local EnvironmentAssetRegistry = require(script.Parent.Parent.Content.EnvironmentAssetRegistry)

local WorldVisualService = {}
local dayNightConnection = nil

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

local function ensureEffect(className, name)
    local existing = Lighting:FindFirstChild(name)
    if existing and existing.ClassName == className then
        return existing
    end
    if existing then
        existing:Destroy()
    end

    local ok, effect = pcall(function()
        return Instance.new(className)
    end)
    if not ok or not effect then
        return nil
    end
    effect.Name = name
    effect.Parent = Lighting
    return effect
end

local function ensureAtmosphere()
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Name = "EverLeafAtmosphere"
        atmosphere.Parent = Lighting
    end
    return atmosphere
end

local function configureCreatorSkybox()
    -- Third-party Creator Store assets are not guaranteed to be loadable by
    -- InsertService from a group-owned experience even when they are free.
    -- Prefer a Sky already inserted through Studio/Toolbox and never emit
    -- runtime authorization errors for the registry candidate.
    local existing = Lighting:FindFirstChild("EverLeafSky")
    if existing and existing:IsA("Sky") then
        return
    end

    local localSky = Lighting:FindFirstChildOfClass("Sky")
    if localSky then
        localSky.Name = "EverLeafSky"
        return
    end

    local entry = EnvironmentAssetRegistry.AnimeIslandSkybox
    if type(entry) ~= "table" or entry.Status ~= "manual_studio_import" then
        return
    end

    -- No Sky has been inserted yet. Keep EverLeaf's source-controlled lighting
    -- and atmosphere rather than failing or attempting an unauthorized fetch.
end

local function configurePostProcessing()
    local color = ensureEffect("ColorCorrectionEffect", "EverLeafColorGrade")
    if color then
        safeSet(color, "Brightness", -0.01)
        safeSet(color, "Contrast", 0.06)
        safeSet(color, "Saturation", 0.03)
        safeSet(color, "TintColor", Color3.fromRGB(241, 246, 238))
    end

    local bloom = ensureEffect("BloomEffect", "EverLeafBloom")
    if bloom then
        safeSet(bloom, "Intensity", 0.08)
        safeSet(bloom, "Size", 18)
        safeSet(bloom, "Threshold", 2)
    end

    local rays = ensureEffect("SunRaysEffect", "EverLeafSunRays")
    if rays then
        safeSet(rays, "Intensity", 0.025)
        safeSet(rays, "Spread", 0.62)
    end
end

local function configureCloudsAndWind()
    safeSet(Workspace, "GlobalWind", Vector3.new(7, 0, 3))

    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return
    end

    local clouds = terrain:FindFirstChildOfClass("Clouds")
    if not clouds then
        local ok, newClouds = pcall(function()
            return Instance.new("Clouds")
        end)
        if ok and newClouds then
            clouds = newClouds
            clouds.Name = "EverLeafClouds"
            clouds.Parent = terrain
        end
    end

    if clouds then
        safeSet(clouds, "Cover", 0.28)
        safeSet(clouds, "Density", 0.36)
        safeSet(clouds, "Color", Color3.fromRGB(235, 241, 244))
    end
end

local function configureDayNightCycle(graphics)
    if dayNightConnection then
        dayNightConnection:Disconnect()
        dayNightConnection = nil
    end

    local cycle = type(graphics.DayNightCycle) == "table" and graphics.DayNightCycle or nil
    if not cycle or cycle.Enabled ~= true then
        return
    end

    local fullDayLength = math.max(60, tonumber(cycle.FullDayLengthSeconds) or 2880)
    local hoursPerSecond = 24 / fullDayLength
    local nightVisibility = ensureEffect("ColorCorrectionEffect", "EverLeafNightVisibility")
    if nightVisibility then
        safeSet(nightVisibility, "Contrast", -0.02)
        safeSet(nightVisibility, "Saturation", -0.03)
    end

    dayNightConnection = RunService.Heartbeat:Connect(function(deltaTime)
        Lighting.ClockTime = (Lighting.ClockTime + deltaTime * hoursPerSecond) % 24
        if nightVisibility then
            local solar = (math.sin((Lighting.ClockTime - 6) / 24 * math.pi * 2) + 1) * 0.5
            local nightFactor = 1 - solar
            nightVisibility.Brightness = nightFactor * 0.14
        end
    end)
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
    safeSet(Lighting, "Ambient", Color3.fromRGB(75, 92, 85))
    safeSet(Lighting, "OutdoorAmbient", Color3.fromRGB(112, 126, 117))

    local atmosphere = ensureAtmosphere()
    safeSet(atmosphere, "Density", graphics.AtmosphereDensity)
    safeSet(atmosphere, "Offset", 0.1)
    safeSet(atmosphere, "Haze", graphics.AtmosphereHaze)
    safeSet(atmosphere, "Glare", graphics.AtmosphereGlare)
    safeSet(atmosphere, "Color", Color3.fromRGB(199, 220, 255))
    safeSet(atmosphere, "Decay", Color3.fromRGB(106, 122, 111))

    configureCreatorSkybox()
    configurePostProcessing()
    configureCloudsAndWind()
    configureDayNightCycle(graphics)
end

return WorldVisualService
