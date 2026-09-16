-- Production NPC visuals should be reviewed authored R15 models.
-- Gameplay definitions remain in NpcDefinitions; this registry owns visuals only.
local NpcAssetRegistry = {
    -- npc_id = { TemplateName = "NpcVisualName", Status = "reviewed" },
}

return table.freeze(NpcAssetRegistry)
