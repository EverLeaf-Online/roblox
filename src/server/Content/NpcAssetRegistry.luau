-- Canonical production NPC visual registry.
-- Reviewed original EverLeaf model assets are loaded into a hidden animated R15 skeleton.
local NpcAssetRegistry = {
    lumen_guide = {
        AssetId = 106620969880813,
        TemplateName = "IlyraWayfarerGuide",
        Status = "reviewed",
    },
    camp_quartermaster = {
        AssetId = 72467646496046,
        TemplateName = "OrinQuartermaster",
        Status = "reviewed",
    },
    moss_scout = {
        AssetId = 120296033309062,
        TemplateName = "TovinMossglenScout",
        Status = "reviewed",
    },
    archive_keeper = {
        AssetId = 74873617387258,
        TemplateName = "MaelaArchiveKeeper",
        Status = "reviewed",
    },
    path_mentor = {
        AssetId = 71702053408362,
        TemplateName = "SerenPathkeeper",
        Status = "reviewed",
    },
    camp_healer = {
        AssetId = 111953812075306,
        TemplateName = "EiraWayfarerHealer",
        Status = "reviewed",
    },
    glowmere_keeper = {
        AssetId = 109433487392238,
        TemplateName = "SellaGlowmereKeeper",
        Status = "reviewed",
    },
    sunmoss_researcher = {
        AssetId = 120365137194208,
        TemplateName = "AvenSunmossResearcher",
        Status = "reviewed",
    },
    veilfall_warden = {
        AssetId = 87049781819025,
        TemplateName = "NerisVeilfallWarden",
        Status = "reviewed",
    },
    foundry_quartermaster = {
        AssetId = 116143660020194,
        TemplateName = "NeraFoundryQuartermaster",
        Status = "reviewed",
    },
    belforge_mark_broker = {
        AssetId = 116327990771458,
        TemplateName = "CaleMarkBroker",
        Status = "reviewed",
    },
    eastworks_engineer = {
        AssetId = 99866941784802,
        TemplateName = "TamsinEastworksEngineer",
        Status = "reviewed",
    },
    belforge_oathkeeper = {
        AssetId = 107603565473038,
        TemplateName = "MaraForgeOathkeeper",
        Status = "reviewed",
    },
    belforge_marshal = {
        AssetId = 117267887089651,
        TemplateName = "RookBelforgeMarshal",
        Status = "reviewed",
    },
    belforge_foreman = {
        AssetId = 83906031250479,
        TemplateName = "ValeBelforgeForeman",
        Status = "reviewed",
    },
}

return table.freeze(NpcAssetRegistry)
