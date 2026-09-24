local fs = require("@lune/fs")

local lumen = fs.readFile("src/server/Services/LumenreachWorldService.luau")
local worldConfig = fs.readFile("src/server/Content/LumenreachWorldConfig.luau")
local brass = fs.readFile("src/server/Services/BrasshavenWorldService.luau")

assert(
    string.find(worldConfig, "DesignVersion = 29", 1, true),
    "Lumenreach building-layout pass must be V25"
)
assert(
    string.find(lumen, "local function makeWorldMMOComposition", 1, true) == nil,
    "obsolete Lumenreach clutter-overlay composition helper must stay removed"
)
assert(
    string.find(lumen, "local function makeWorldSettlements", 1, true)
        and string.find(lumen, "makeWorldSettlements(parent)", 1, true),
    "Lumenreach actual settlement layout pass must be wired"
)
for _, building in
    {
        "GreenwayCottageWest",
        "GreenwayCottageEast",
        "CrossroadsKeeperHouse",
        "GlowmereDrybankHouse",
        "EastbridgeBarracks",
        "GraveboneMausoleum",
        "MossglenRangerLodge",
        "SunmossObservatory",
        "VeilfallSanctuary",
        "ShatteredNorthTower",
        "ShatteredSouthTower",
        "ProvingMentorLodge",
    }
do
    assert(
        string.find(lumen, '"' .. building .. '"', 1, true),
        "Lumenreach layout missing " .. building
    )
end

assert(
    string.find(brass, "local function makeBrasshavenMMOComposition", 1, true) == nil,
    "obsolete Brasshaven clutter-court overlay must stay removed"
)
assert(
    string.find(brass, "local function makeBrasshavenBuildingLayouts", 1, true)
        and string.find(brass, "makeBrasshavenBuildingLayouts(world)", 1, true),
    "Brasshaven actual industrial building layout pass must be wired"
)
assert(
    string.find(brass, 'world:SetAttribute("WorldDesignVersion", 6)', 1, true)
        and string.find(brass, 'world:SetAttribute("MMOBuildingLayoutPass", true)', 1, true),
    "Brasshaven generated world must advertise the real building-layout pass"
)
for _, building in
    {
        "FoundryAdministration",
        "ThresholdTradeDepot",
        "ThresholdWorkerHouse",
        "GearworksMachineHall",
        "SootworksShiftHouse",
        "CinderBoilerHouse",
        "DynamoPowerHouse",
        "EastworksLoadingDepot",
        "EastworksMaintenanceHall",
        "SmelterCrucibleHouse",
        "BlueglassRefinery",
        "AuthorityHall",
        "FluxVaultRefinery",
        "RunoffControlHouse",
        "UpperBellowsHouse",
        "BelforgeOuterControlGate",
    }
do
    assert(
        string.find(brass, '"' .. building .. '"', 1, true),
        "Brasshaven layout missing " .. building
    )
end

print("whole-world MMO building layout rules tests passed")
