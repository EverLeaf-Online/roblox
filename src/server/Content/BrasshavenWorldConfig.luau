-- Canonical Brasshaven/Eastworks/Belforge spatial contract.
-- Encounter systems and public events consume these anchors instead of duplicating map coordinates.
local origin = Vector3.new(1450, 0, 40)

local encounterCenters = table.freeze({
    ScrapLanes = origin + Vector3.new(-22, 0, -56),
    LowerHotworks = origin + Vector3.new(58, 0, 58),
    Gearworks = origin + Vector3.new(-78, 0, 76),
    CinderDucts = origin + Vector3.new(83, 0, -72),
    RegulatorRow = origin + Vector3.new(122, 0, -40),
    Sootworks = origin + Vector3.new(-58, 0, 145),
    DynamoGallery = origin + Vector3.new(64, 0, -148),
    EastworksRail = origin + Vector3.new(108, 0, 145),
    BlueglassAnnex = origin + Vector3.new(-72, 0, 235),
    MaintenanceDeck = origin + Vector3.new(68, 0, -235),
    SmelterYard = origin + Vector3.new(108, 0, 235),
    FluxVaults = origin + Vector3.new(-105, 0, 325),
    AuthorityHall = origin + Vector3.new(-12, 0, 325),
    MoltenRunoff = origin + Vector3.new(88, 0, 325),
    BellowsCourt = origin + Vector3.new(-58, 0, 395),
    SentinelPost = origin + Vector3.new(92, 0, 395),
})

return table.freeze({
    Origin = origin,
    BelforgeAntechamberOrigin = origin + Vector3.new(430, 0, 395),
    BelforgeArenaOrigin = origin + Vector3.new(650, 0, 395),
    EncounterCenters = encounterCenters,
    GeneratedWorldName = "EverLeafGeneratedBrasshaven",
    GroundSurfaceName = "BrasshavenGroundCollision",
})
