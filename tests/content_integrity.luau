local Items = require("../src/server/Content/ItemDefinitions")
local Shops = require("../src/server/Content/ShopDefinitions")
local Drops = require("../src/server/Content/DropTableDefinitions")
local Recipes = require("../src/server/Content/RecipeDefinitions")
local Quests = require("../src/server/Content/QuestDefinitions")
local Npcs = require("../src/server/Content/NpcDefinitions")
local Regions = require("../src/server/Content/RegionDefinitions")
local Portals = require("../src/server/Content/PortalDefinitions")
local Bosses = require("../src/server/Content/BossDefinitions")
local Skills = require("../src/server/Content/SkillDefinitions")
local Families = require("../src/server/Content/ClassFamilyDefinitions")
local MonsterConfig = require("../src/server/Content/MonsterConfig")
local EquipmentTypeRules = require("../src/shared/Logic/EquipmentTypeRules")
local WeaponCombatProfiles = require("../src/shared/WeaponCombatProfiles")
local StatusEffectDefinitions = require("../src/shared/StatusEffectDefinitions")
local StatusEffectRules = require("../src/shared/Logic/StatusEffectRules")
local SkillTargetingRules = require("../src/shared/Logic/SkillTargetingRules")
local currencies = { Shards = true, Marks = true }

for effectId, definition in StatusEffectDefinitions do
    local ok, reason = StatusEffectRules.ValidateDefinition(effectId, definition)
    assert(ok, string.format("status effect %s valid: %s", effectId, tostring(reason)))
end

for itemId, definition in Items do
    assert(
        type(definition.DisplayName) == "string" and definition.DisplayName ~= "",
        "item display name: " .. itemId
    )
    if definition.Type == "Equipment" then
        local typeOk, typeReason = EquipmentTypeRules.Validate(definition)
        assert(
            typeOk,
            string.format("equipment taxonomy valid: %s (%s)", itemId, tostring(typeReason))
        )
    end
    if definition.EquipmentSlot == "Weapon" then
        assert(
            type(definition.WeaponType) == "string" and WeaponCombatProfiles[definition.WeaponType],
            "weapon type valid: " .. itemId
        )
    else
        assert(definition.WeaponType == nil, "non-weapon cannot declare WeaponType: " .. itemId)
    end
    local attackSpeed = definition.Stats and definition.Stats.AttackSpeed
    assert(
        attackSpeed == nil
            or (type(attackSpeed) == "number" and attackSpeed >= 0 and attackSpeed <= 30),
        "item AttackSpeed bonus valid: " .. itemId
    )
    if definition.SellPrice then
        assert(currencies[definition.SellPrice.Currency], "valid sell currency: " .. itemId)
        assert(
            type(definition.SellPrice.Amount) == "number"
                and definition.SellPrice.Amount % 1 == 0
                and definition.SellPrice.Amount > 0
                and definition.SellPrice.Amount <= 2_000_000_000,
            "valid sell amount: " .. itemId
        )
    end
end

for shopId, shop in Shops do
    assert(currencies[shop.Currency], "shop currency exists: " .. shopId)
    for itemId, price in shop.Items do
        assert(Items[itemId], string.format("shop %s references item %s", shopId, itemId))
        assert(
            type(price) == "number" and price % 1 == 0 and price > 0 and price <= 2_000_000_000,
            "positive integer shop price: " .. shopId .. "/" .. itemId
        )
        local definition = Items[itemId]
        local sellPrice = definition and definition.SellPrice
        if sellPrice and sellPrice.Currency == shop.Currency then
            assert(
                sellPrice.Amount < price,
                string.format(
                    "shop %s same-currency sell value below buy value: %s",
                    shopId,
                    itemId
                )
            )
        end
    end
end

for enemyId, monster in MonsterConfig.All() do
    for _, fieldName in { "AttackWidth", "AttackVerticalRange" } do
        local value = monster[fieldName]
        assert(
            value == nil or (type(value) == "number" and value > 0),
            string.format("enemy %s %s must be positive when set", enemyId, fieldName)
        )
    end
    local depthSlack = monster.AttackDepthSlack
    assert(
        depthSlack == nil or (type(depthSlack) == "number" and depthSlack >= 0),
        string.format("enemy %s AttackDepthSlack must be non-negative when set", enemyId)
    )
    for _, fieldName in { "KnockbackResistance", "StaggerResistance" } do
        local value = monster[fieldName]
        assert(
            value == nil or (type(value) == "number" and value >= 0 and value <= 1),
            string.format("enemy %s %s must be normalized when set", enemyId, fieldName)
        )
    end

    local reward = monster.Reward
    if reward then
        assert(
            reward.Exp == nil or (type(reward.Exp) == "number" and reward.Exp > 0),
            "enemy reward EXP valid: " .. enemyId
        )
        for currencyName, amount in reward.Currencies or {} do
            assert(
                currencies[currencyName],
                string.format("enemy %s reward currency exists: %s", enemyId, currencyName)
            )
            assert(
                type(amount) == "number" and amount > 0,
                "enemy reward currency amount valid: " .. enemyId
            )
        end
        for itemId, quantity in reward.Items or {} do
            assert(Items[itemId], string.format("enemy %s reward item exists: %s", enemyId, itemId))
            assert(
                type(quantity) == "number" and quantity > 0,
                "enemy reward item quantity valid: " .. enemyId
            )
        end
    end
end

for enemyId, entries in Drops do
    assert(MonsterConfig.Get(enemyId), "drop table enemy exists: " .. enemyId)
    for _, entry in entries do
        assert(
            Items[entry.ItemId],
            string.format("drop %s references item %s", enemyId, tostring(entry.ItemId))
        )
        assert(
            type(entry.Chance) == "number" and entry.Chance >= 0 and entry.Chance <= 1,
            "drop chance bounds: " .. enemyId
        )
        assert(
            type(entry.Min) == "number"
                and type(entry.Max) == "number"
                and entry.Min >= 1
                and entry.Max >= entry.Min,
            "drop quantity bounds: " .. enemyId
        )
    end
end

for recipeId, recipe in Recipes do
    assert(Items[recipe.Output.ItemId], "recipe output exists: " .. recipeId)
    assert(
        type(recipe.Output.Quantity) == "number" and recipe.Output.Quantity >= 1,
        "recipe output quantity: " .. recipeId
    )
    for itemId, amount in recipe.Inputs do
        assert(Items[itemId], string.format("recipe %s input exists: %s", recipeId, itemId))
        assert(type(amount) == "number" and amount >= 1, "recipe input quantity: " .. recipeId)
    end
end

for questId, quest in Quests do
    for _, prereq in quest.PrerequisiteQuests or {} do
        assert(Quests[prereq], string.format("quest %s prerequisite exists: %s", questId, prereq))
    end
    for _, objective in quest.Objectives or {} do
        if objective.Type == "Defeat" then
            assert(
                MonsterConfig.Get(objective.Target),
                string.format(
                    "quest %s defeat target exists: %s",
                    questId,
                    tostring(objective.Target)
                )
            )
        elseif objective.Type == "Collect" then
            assert(
                Items[objective.Target],
                string.format(
                    "quest %s collect target exists: %s",
                    questId,
                    tostring(objective.Target)
                )
            )
        end
    end
    local reward = quest.Reward
    if reward then
        for itemId in reward.Items or {} do
            assert(Items[itemId], string.format("quest %s reward item exists: %s", questId, itemId))
        end
        for currencyName in reward.Currencies or {} do
            assert(
                currencies[currencyName],
                string.format("quest %s reward currency exists: %s", questId, currencyName)
            )
        end
        for _, regionId in reward.UnlockRegions or {} do
            assert(
                Regions[regionId],
                string.format("quest %s unlock region exists: %s", questId, regionId)
            )
        end
    end
end

for npcId, npc in Npcs do
    if npc.ShopId then
        assert(Shops[npc.ShopId], string.format("npc %s shop exists: %s", npcId, npc.ShopId))
    end
    for _, questId in npc.QuestOffers or {} do
        assert(Quests[questId], string.format("npc %s quest exists: %s", npcId, questId))
    end
end

for portalId, portal in Portals do
    assert(
        Regions[portal.SourceRegionId],
        string.format("portal %s source region exists", portalId)
    )
    assert(
        Regions[portal.TargetRegionId],
        string.format("portal %s target region exists", portalId)
    )
    assert(
        type(portal.TargetSpawnId) == "string" and portal.TargetSpawnId ~= "",
        "portal target spawn set: " .. portalId
    )
end

for bossId, boss in Bosses do
    assert(
        MonsterConfig.Get(boss.MonsterId),
        string.format("boss %s monster exists: %s", bossId, tostring(boss.MonsterId))
    )
    assert(
        Regions[boss.RegionId],
        string.format("boss %s region exists: %s", bossId, tostring(boss.RegionId))
    )
end

for familyId, family in Families do
    local starterItem = Items[family.StarterItemId]
    assert(starterItem, string.format("family %s starter item exists", familyId))
    assert(
        starterItem.WeaponType == family.PreferredWeaponType,
        string.format("family %s starter weapon type matches preference", familyId)
    )
    assert(Skills[family.StarterSkillId], string.format("family %s starter skill exists", familyId))
    if family.SecondAdvancement then
        assert(
            Skills[family.SecondAdvancement.StarterSkillId],
            string.format("family %s tier-2 skill exists", familyId)
        )
    end
end

for skillId, skill in Skills do
    if skill.FamilyId then
        assert(
            Families[skill.FamilyId],
            string.format("skill %s family exists: %s", skillId, skill.FamilyId)
        )
    end
    for _, requirement in skill.Prerequisites or {} do
        local requiredSkill = Skills[requirement.SkillId]
        assert(
            requiredSkill,
            string.format(
                "skill %s prerequisite exists: %s",
                skillId,
                tostring(requirement.SkillId)
            )
        )
        assert(
            type(requirement.Rank) == "number"
                and requirement.Rank >= 1
                and requirement.Rank <= (requiredSkill.MaxRank or 1),
            "skill prerequisite rank valid: " .. skillId
        )
        assert(requirement.SkillId ~= skillId, "skill cannot require itself: " .. skillId)
    end
    if skill.Effect and skill.Effect.Type == "SelfStatus" then
        assert(
            StatusEffectDefinitions[skill.Effect.StatusId] ~= nil,
            "status skill references known status: " .. skillId
        )
    end
    if skill.Effect and skill.Effect.Type == "DamageAttack" then
        local targetingOk, targetingReason = SkillTargetingRules.Validate(skill.Effect)
        assert(
            targetingOk,
            string.format("skill %s targeting valid: %s", skillId, tostring(targetingReason))
        )
        assert(
            skill.Effect.Mode == "Melee" or skill.Effect.Mode == "Projectile",
            "damage skill mode valid: " .. skillId
        )
        for _, fieldName in { "Knockback", "Knockup", "Stagger" } do
            local value = skill.Effect[fieldName]
            assert(
                type(value) == "number" and value >= 0,
                string.format("damage skill %s has non-negative %s", skillId, fieldName)
            )
        end
        if skill.Effect.Mode == "Melee" then
            assert(
                type(skill.Effect.HitboxWidth) == "number" and skill.Effect.HitboxWidth > 0,
                "melee skill hitbox width valid: " .. skillId
            )
        else
            assert(
                type(skill.Effect.ProjectileSpeed) == "number"
                    and skill.Effect.ProjectileSpeed > 0
                    and type(skill.Effect.ProjectileRadius) == "number"
                    and skill.Effect.ProjectileRadius > 0,
                "projectile skill geometry valid: " .. skillId
            )
        end
    end
    if skill.PassiveBonuses then
        assert(skill.Kind == "Passive", "only passive skills define PassiveBonuses: " .. skillId)
        for statName, amount in skill.PassiveBonuses do
            assert(
                type(statName) == "string" and type(amount) == "number" and amount > 0,
                "valid passive bonus: " .. skillId
            )
        end
    end
end

local visiting = {}
local visited = {}
local function visitSkill(skillId)
    if visited[skillId] then
        return
    end
    assert(not visiting[skillId], "skill prerequisite cycle detected at: " .. skillId)
    visiting[skillId] = true
    local skill = Skills[skillId]
    for _, requirement in skill and skill.Prerequisites or {} do
        visitSkill(requirement.SkillId)
    end
    visiting[skillId] = nil
    visited[skillId] = true
end
for skillId in Skills do
    visitSkill(skillId)
end

print("content integrity tests passed")
