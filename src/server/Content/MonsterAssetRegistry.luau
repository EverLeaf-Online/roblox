-- Production monster visuals should be authored models.
-- Entries become active only after an original/reviewed model is available under
-- ServerStorage/AuthoredMonsterTemplates using the declared TemplateName.
local MonsterAssetRegistry = {
    -- Example shape:
    -- lumen_mossling = { TemplateName = "LumenMossling", Status = "reviewed" },
}

return table.freeze(MonsterAssetRegistry)
