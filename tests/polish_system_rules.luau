local fs = require("@lune/fs")

local gameConfig = fs.readFile("src/shared/GameConfig.luau")
local worldVisuals = fs.readFile("src/server/Services/WorldVisualService.luau")
local combatPresentation = fs.readFile("src/client/Presentation/CombatPresentation.luau")
local progressionPresentation = fs.readFile("src/client/Presentation/ProgressionPresentation.luau")
local ui = fs.readFile("src/client/Controllers/ReactUIController.luau")

assert(
    string.find(gameConfig, "DayNightCycle", 1, true) ~= nil
        and string.find(gameConfig, "FullDayLengthSeconds = 2880", 1, true) ~= nil,
    "day/night cycle must be explicitly configured"
)
assert(
    string.find(worldVisuals, "RunService.Heartbeat:Connect", 1, true) ~= nil
        and string.find(worldVisuals, "Lighting.ClockTime =", 1, true) ~= nil,
    "WorldVisualService must advance the shared day/night clock"
)

assert(
    string.find(worldVisuals, '"EverLeafNightVisibility"', 1, true) ~= nil
        and string.find(worldVisuals, "nightVisibility.Brightness = nightFactor * 0.26", 1, true) ~= nil
        and string.find(worldVisuals, "Lighting.Ambient = Color3.fromRGB(75, 92, 85)", 1, true) ~= nil
        and string.find(
                worldVisuals,
                "Lighting.OutdoorAmbient = Color3.fromRGB(112, 126, 117)",
                1,
                true
            )
            ~= nil,
    "night cycle must retain playable visibility instead of becoming nearly black"
)
assert(
    string.find(combatPresentation, "local function impactParticleBurst", 1, true) ~= nil
        and string.find(combatPresentation, 'Instance.new("ParticleEmitter")', 1, true) ~= nil
        and string.find(combatPresentation, "impactParticleBurst(hit.TargetPosition", 1, true)
            ~= nil,
    "skill hits must emit a particle impact burst"
)
assert(
    string.find(progressionPresentation, "function ProgressionPresentation.PlayLevelUp", 1, true)
            ~= nil
        and string.find(progressionPresentation, 'Instance.new("ParticleEmitter")', 1, true) ~= nil
        and string.find(ui, "ProgressionPresentation.PlayLevelUp(newLevel)", 1, true) ~= nil,
    "level-up profile transitions must trigger particle presentation"
)

print("polish system rules tests passed")
