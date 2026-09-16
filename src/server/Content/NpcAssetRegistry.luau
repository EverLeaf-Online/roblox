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
}

return table.freeze(NpcAssetRegistry)
