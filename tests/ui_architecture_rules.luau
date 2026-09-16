local fs = require("@lune/fs")

local controller = fs.readFile("src/client/Controllers/ReactUIController.luau")
local hud = fs.readFile("src/client/UI/Components/MainHud.luau")
local quests = fs.readFile("src/client/UI/Components/QuestPanel.luau")
local settings = fs.readFile("src/client/UI/Components/SettingsPanel.luau")
local primitives = fs.readFile("src/client/UI/Primitives.luau")
local theme = fs.readFile("src/client/UI/Theme.luau")
local uiText = fs.readFile("src/client/UI/UiText.luau")

for _, requiredImport in
    {
        "UI.Components.MainHud",
        "UI.Components.QuestPanel",
        "UI.Components.SettingsPanel",
        "UI.Primitives",
        "UI.Theme",
        "UI.UiText",
    }
do
    assert(
        string.find(controller, requiredImport, 1, true),
        "controller missing modular UI import " .. requiredImport
    )
end

for _, forbiddenDefinition in
    {
        "local function HUD(",
        "local function Hotbar(",
        "local function QuestsPanel(",
        "local function SettingsPanel(",
        "local function ResourceMeter(",
    }
do
    assert(
        not string.find(controller, forbiddenDefinition, 1, true),
        "controller still owns extracted UI " .. forbiddenDefinition
    )
end

assert(#controller < 125000, "ReactUIController regressed above first decomposition size budget")
assert(string.find(hud, "SkillCooldownStore", 1, true), "HUD owns hotbar cooldown presentation")
assert(string.find(hud, "StatusEffectDefinitions", 1, true), "HUD owns status-effect strip")
assert(
    string.find(quests, "UiText.ObjectiveText", 1, true),
    "quest panel uses shared objective text"
)
assert(
    string.find(settings, "settings.update", 1, true),
    "settings panel retains profile settings actions"
)
assert(
    string.find(primitives, "function Primitives.Panel", 1, true),
    "shared panel primitive missing"
)
assert(string.find(theme, "Theme.Colors", 1, true), "shared UI color theme missing")
assert(
    string.find(uiText, "function UiText.ObjectiveText", 1, true),
    "shared objective text presenter missing"
)

print("UI architecture rules tests passed")
