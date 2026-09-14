local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

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

function WorldVisualService.Init()
    local graphics = GameConfig.Graphics
    Lighting.GlobalShadows = true
    Lighting.Brightness = graphics.Brightness
    Lighting.ClockTime = graphics.ClockTime
    Lighting.ExposureCompensation = graphics.ExposureCompensation
    Lighting.EnvironmentDiffuseScale = graphics.EnvironmentDiffuseScale
    Lighting.EnvironmentSpecularScale = graphics.EnvironmentSpecularScale
    Lighting.ShadowSoftness = graphics.ShadowSoftness

    local atmosphere = ensureAtmosphere()
    atmosphere.Density = graphics.AtmosphereDensity
    atmosphere.Haze = graphics.AtmosphereHaze
    atmosphere.Glare = graphics.AtmosphereGlare
    atmosphere.Color = Color3.fromRGB(199, 220, 255)
    atmosphere.Decay = Color3.fromRGB(106, 112, 125)

    Workspace.Terrain.Decoration = true
end

return WorldVisualService
