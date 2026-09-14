local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildInfo = require(ReplicatedStorage.Shared.BuildInfo)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local BossDefinitions = require(script.Parent.Parent.Content.BossDefinitions)
local ItemDefinitions = require(script.Parent.Parent.Content.ItemDefinitions)
local NpcDefinitions = require(script.Parent.Parent.Content.NpcDefinitions)
local QuestDefinitions = require(script.Parent.Parent.Content.QuestDefinitions)
local RegionDefinitions = require(script.Parent.Parent.Content.RegionDefinitions)
local SkillDefinitions = require(script.Parent.Parent.Content.SkillDefinitions)

local CatalogService = {}

local function copySelected(source, fields)
    local result = {}
    for id, definition in source do
        local public = {}
        for _, field in fields do
            if definition[field] ~= nil then
                public[field] = definition[field]
            end
        end
        result[id] = public
    end
    return result
end

function CatalogService.Build()
    return {
        Build = BuildInfo,
        Features = GameConfig.Features,
        Items = copySelected(
            ItemDefinitions,
            { "DisplayName", "Type", "EquipmentSlot", "StackLimit", "Stats" }
        ),
        Skills = copySelected(
            SkillDefinitions,
            { "DisplayName", "MaxRank", "RequiredLevel", "RequiredTier", "Kind" }
        ),
        Quests = copySelected(QuestDefinitions, { "DisplayName", "MinimumLevel", "Objectives" }),
        Npcs = copySelected(NpcDefinitions, { "DisplayName", "RegionId" }),
        Regions = copySelected(RegionDefinitions, { "DisplayName", "MinimumLevel", "Kind" }),
        Bosses = copySelected(
            BossDefinitions,
            { "DisplayName", "RegionId", "RecommendedLevel", "MaxPlayers" }
        ),
    }
end

return CatalogService
