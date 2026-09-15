local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildInfo = require(ReplicatedStorage.Shared.BuildInfo)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local BossDefinitions = require(script.Parent.Parent.Content.BossDefinitions)
local ClassFamilyDefinitions = require(script.Parent.Parent.Content.ClassFamilyDefinitions)
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
        Items = copySelected(ItemDefinitions, {
            "DisplayName",
            "Type",
            "EquipmentSlot",
            "WeaponType",
            "ArmorType",
            "AccessoryType",
            "FamilyId",
            "RequiredAdvancementTier",
            "RequiredLevel",
            "StackLimit",
            "Stats",
            "Effects",
            "SellPrice",
        }),
        Skills = copySelected(SkillDefinitions, {
            "Id",
            "DisplayName",
            "Description",
            "FamilyId",
            "MaxRank",
            "RequiredLevel",
            "RequiredTier",
            "SPCostPerRank",
            "MPCost",
            "Cooldown",
            "Kind",
            "Prerequisites",
            "PassiveBonuses",
            "Presentation",
            "Effect",
        }),
        Quests = copySelected(
            QuestDefinitions,
            { "DisplayName", "MinimumLevel", "MinimumAdvancementTier", "Objectives" }
        ),
        Npcs = copySelected(
            NpcDefinitions,
            { "DisplayName", "RegionId", "AdvancementMentor", "AdvancementTargetTier" }
        ),
        Regions = copySelected(RegionDefinitions, { "DisplayName", "MinimumLevel", "Kind" }),
        Bosses = copySelected(
            BossDefinitions,
            { "DisplayName", "RegionId", "RecommendedLevel", "MaxPlayers", "MonsterId" }
        ),
        Families = copySelected(ClassFamilyDefinitions, {
            "DisplayName",
            "PrimaryStat",
            "PreferredWeaponType",
            "CombatRole",
            "FirstAdvancementLevel",
            "StarterSkillId",
            "StarterItemId",
            "SecondAdvancement",
            "Accent",
            "Summary",
        }),
    }
end

return CatalogService
