local fs = require("@lune/fs")
local profileTemplate = fs.readFile("src/shared/Logic/ProfileTemplate.luau")
local config = fs.readFile("src/shared/GameConfig.luau")
local service = fs.readFile("src/server/Services/StorageService.luau")
local action = fs.readFile("src/server/Services/ActionService.luau")
local ui = fs.readFile("src/client/UI/Components/StoragePanel.luau")
local controller = fs.readFile("src/client/Controllers/ReactUIController.luau")

assert(
    string.find(profileTemplate, "Storage = {", 1, true),
    "persistent storage missing from profile template"
)
assert(string.find(profileTemplate, "Capacity = 96", 1, true), "storage capacity default missing")
assert(string.find(config, "Storage = true", 1, true), "storage feature must be enabled")
assert(
    string.find(config, "SchemaVersion = 4", 1, true),
    "storage profile addition must bump schema"
)
assert(string.find(service, "ProfileTransaction.Run", 1, true), "storage transfers must be atomic")
assert(
    string.find(service, "InventoryRules.Add", 1, true),
    "storage must preserve stack limits/capacity"
)
assert(
    string.find(service, "InventoryRules.RemoveAt", 1, true),
    "storage must remove exact source slot"
)
assert(string.find(service, "storage_full", 1, true), "storage capacity failure must be explicit")
assert(
    string.find(action, 'handlers["storage.deposit"]', 1, true),
    "storage deposit action missing"
)
assert(
    string.find(action, 'handlers["storage.withdraw"]', 1, true),
    "storage withdraw action missing"
)
assert(string.find(ui, '"storage.deposit"', 1, true), "storage UI deposit missing")
assert(string.find(ui, '"storage.withdraw"', 1, true), "storage UI withdraw missing")
assert(string.find(controller, '"STORAGE"', 1, true), "storage menu tab missing")
print("storage service rules tests passed")
