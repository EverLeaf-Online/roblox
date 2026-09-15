local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ProfileStore = require(script.Parent.Parent.State.ProfileStore)
local RegionVisualProfiles = require(ReplicatedStorage.Shared.RegionVisualProfiles)
local RegionVisualRules = require(ReplicatedStorage.Shared.Logic.RegionVisualRules)

local RegionVisualController = {}
local currentRegionId = nil
local activeTweens = {}
local TRANSITION_SECONDS = 1.15

local function toColor3(rgb)
    return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function lightingProperties(profile)
    return {
        Brightness = profile.Brightness,
        ExposureCompensation = profile.ExposureCompensation,
        EnvironmentDiffuseScale = profile.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = profile.EnvironmentSpecularScale,
        ShadowSoftness = profile.ShadowSoftness,
        Ambient = toColor3(profile.Ambient),
        OutdoorAmbient = toColor3(profile.OutdoorAmbient),
    }
end

local function atmosphereProperties(profile)
    return {
        Density = profile.Density,
        Offset = profile.Offset,
        Haze = profile.Haze,
        Glare = profile.Glare,
        Color = toColor3(profile.Color),
        Decay = toColor3(profile.Decay),
    }
end

local function colorGradeProperties(profile)
    return {
        Brightness = profile.Brightness,
        Contrast = profile.Contrast,
        Saturation = profile.Saturation,
        TintColor = toColor3(profile.TintColor),
    }
end

local function ensureEffect(className, name)
    local existing = Lighting:FindFirstChild(name)
    if existing and existing.ClassName == className then
        return existing
    end
    if existing then
        existing:Destroy()
    end
    local effect = Instance.new(className)
    effect.Name = name
    effect.Parent = Lighting
    return effect
end

local function ensureAtmosphere()
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        return atmosphere
    end
    atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "EverLeafAtmosphere"
    atmosphere.Parent = Lighting
    return atmosphere
end

local function cancelTweens()
    for _, tween in activeTweens do
        pcall(function()
            tween:Cancel()
        end)
    end
    table.clear(activeTweens)
end

local function tween(instance, properties, instant)
    if instant then
        for property, value in properties do
            instance[property] = value
        end
        return
    end
    local created = TweenService:Create(
        instance,
        TweenInfo.new(TRANSITION_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        properties
    )
    table.insert(activeTweens, created)
    created:Play()
end

local function applyProfile(profile, instant)
    local valid, reason = RegionVisualRules.Validate(profile)
    if not valid then
        warn(string.format("[RegionVisualController] invalid visual profile: %s", tostring(reason)))
        return
    end

    cancelTweens()
    tween(Lighting, lightingProperties(profile.Lighting), instant)
    tween(ensureAtmosphere(), atmosphereProperties(profile.Atmosphere), instant)
    tween(
        ensureEffect("ColorCorrectionEffect", "EverLeafColorGrade"),
        colorGradeProperties(profile.ColorGrade),
        instant
    )
    tween(ensureEffect("BloomEffect", "EverLeafBloom"), profile.Bloom, instant)
    tween(ensureEffect("SunRaysEffect", "EverLeafSunRays"), profile.SunRays, instant)
end

local function regionFromSnapshot(snapshot)
    local world = type(snapshot) == "table" and snapshot.World or nil
    local regionId = type(world) == "table" and world.RegionId or nil
    return type(regionId) == "string" and regionId or "default"
end

function RegionVisualController.Start()
    local defaultProfile = RegionVisualRules.Resolve("default", RegionVisualProfiles)
    if defaultProfile then
        applyProfile(defaultProfile, true)
    end

    ProfileStore.Subscribe(function(snapshot)
        local regionId = regionFromSnapshot(snapshot)
        if regionId == currentRegionId then
            return
        end
        currentRegionId = regionId
        local profile = RegionVisualRules.Resolve(regionId, RegionVisualProfiles)
        if profile then
            applyProfile(profile, false)
        end
    end)
end

return RegionVisualController
