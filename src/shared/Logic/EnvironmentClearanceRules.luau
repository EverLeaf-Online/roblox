local EnvironmentClearanceRules = {}

local CLEARANCES = table.freeze({
    TreePrimary = 11.5,
    WayfarerSignpost = 5.5,
    LumenLantern = 4.5,
    LumenWaystone = 5.5,
    WayfarerBench = 5.0,
    WayfarerSupplies = 5.0,
    GrassTuft = 7.5,
    LumenBush = 8.0,
    WildflowerPatch = 6.5,
    LumenMushroomCluster = 6.0,
    RockCluster = 7.0,
    RockFace = 9.0,
    PineRoots = 7.0,
    DryBranches = 7.0,
    FallenTreeTrunk = 9.0,
    FallenTreeTrunk2 = 9.0,
    FallenLog = 9.0,
    MossyRockSet = 7.0,
    TreeStump = 6.5,
    TreeStump2 = 6.5,
    FernPrimary = 6.0,
    LumenCattails = 5.0,
    WayfarerRemnant = 10.0,
})

local function finitePositive(value)
    value = tonumber(value)
    if
        value == nil
        or value ~= value
        or value == math.huge
        or value == -math.huge
        or value <= 0
    then
        return nil
    end
    return value
end

local function byName(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    if string.sub(name, 1, 10) == "ForestTree" then
        return 11.5
    end
    return CLEARANCES[name]
end

function EnvironmentClearanceRules.Resolve(instanceName, sourcePrefabName, explicitClearance)
    local explicit = finitePositive(explicitClearance)
    if explicit then
        return explicit
    end
    return byName(instanceName) or byName(sourcePrefabName)
end

return table.freeze(EnvironmentClearanceRules)
