local fs = require("@lune/fs")

local config = fs.readFile("src/shared/GameConfig.luau")
local validator = fs.readFile("src/shared/Validation/ActionPayloadRules.luau")
local dodgeService = fs.readFile("src/server/Services/PlayerDodgeService.luau")
local damageService = fs.readFile("src/server/Services/PlayerDamageService.luau")
local movementService = fs.readFile("src/server/Services/MovementSanityService.luau")
local controller = fs.readFile("src/client/Controllers/ThirdPersonController.luau")
local bootstrap = fs.readFile("src/server/bootstrap.server.luau")

assert(string.find(config, "DodgeIFrameDuration = 0.22", 1, true), "dodge iframe config missing")
assert(string.find(config, "NormalMaxHorizontalSpeed = 32", 1, true), "normal movement cap missing")
assert(string.find(config, "DodgeRollStartSpeed = 14", 1, true), "roll start speed missing")
assert(string.find(config, "DodgeRollPeakSpeed = 26", 1, true), "roll peak speed missing")
assert(string.find(config, "DodgeRollEndSpeed = 7", 1, true), "roll end speed missing")
assert(string.find(config, "DodgeRollPeakAlpha = 0.18", 1, true), "roll peak timing missing")
assert(string.find(config, "DodgeDuration = 0.58", 1, true), "roll duration missing")
assert(
    string.find(validator, "payload.Dodge == true", 1, true),
    "dodge movement intent validation missing"
)
assert(
    string.find(dodgeService, "function PlayerDodgeService.TryStart", 1, true),
    "server dodge start missing"
)
assert(
    string.find(dodgeService, 'player:SetAttribute("EverLeafDodging", true)', 1, true),
    "server dodge state must replicate"
)
assert(string.find(dodgeService, "DodgeCooldown", 1, true), "server dodge cooldown missing")
assert(
    string.find(damageService, "PlayerDodgeService.IsInvulnerable", 1, true),
    "damage path must honor server dodge iframe"
)
assert(
    string.find(movementService, 'player:GetAttribute("EverLeafDodging") == true', 1, true),
    "movement sanity must distinguish dodge speed"
)
assert(
    string.find(controller, 'Instance.new("LinearVelocity")', 1, true),
    "client dodge should use modern LinearVelocity"
)
assert(
    string.find(controller, 'rollAnimation = Instance.new("Animation")', 1, true)
        and string.find(controller, "animator:LoadAnimation(rollAnimation)", 1, true)
        and string.find(controller, "Enum.AnimationPriority.Action4", 1, true),
    "dodge must use a real Animator roll track"
)
assert(
    string.find(controller, "KeyframeSequenceProvider:RegisterKeyframeSequence", 1, true)
        and string.find(controller, "EverLeafCombatRollSequence", 1, true)
        and string.find(controller, "PoseEasingStyle.CubicV2", 1, true)
        and string.find(controller, "frameCount = 12", 1, true),
    "combat roll must author a local keyframe sequence instead of relying on a third-party asset"
)
assert(
    string.find(controller, "local function prepareRollAnimation", 1, true)
        and string.find(controller, "rollCharacter == character", 1, true),
    "roll track must be cached/prewarmed per character instead of rebuilt on every dodge"
)
assert(
    string.find(controller, "CFrame.Angles(-spin", 1, true) == nil
        and string.find(controller, "beginRollPose", 1, true) == nil,
    "dodge must never front-flip the whole character or use the old procedural pose"
)
assert(
    string.find(controller, "local function rollSpeed", 1, true)
        and string.find(controller, "DodgeRollPeakSpeed", 1, true)
        and string.find(controller, "DodgeRollPeakAlpha", 1, true),
    "roll movement must smoothly accelerate into and decelerate out of the roll"
)
assert(
    string.find(controller, "VelocityConstraintMode.Plane", 1, true),
    "dodge mover must preserve vertical gravity"
)
assert(
    string.find(controller, "movementIntentRemote:FireServer", 1, true),
    "client must request server dodge window"
)
assert(
    string.find(bootstrap, "PlayerDodgeService.TryStart", 1, true),
    "server movement intent must route through dodge service"
)

print("player dodge authority rules tests passed")
