local ClassFamilyDefinitions = require("../src/server/Content/ClassFamilyDefinitions")
local SkillDefinitions = require("../src/server/Content/SkillDefinitions")

local expected = {
    ironbloom = { "Ironbloom Bulwark", "ironbloom_bastion_crash" },
    thornrunner = { "Thornrunner Windshot", "thornrunner_gale_piercer" },
    lumenweaver = { "Lumenweaver Prismwright", "lumenweaver_prism_lance" },
    veilstrider = { "Veilstrider Gloamknife", "veilstrider_gloam_rush" },
    brasshand = { "Brasshand Crucible", "brasshand_forgebreaker" },
}

for familyId, expectation in expected do
    local family = ClassFamilyDefinitions[familyId]
    assert(family, "family exists: " .. familyId)
    local advancement = family.SecondAdvancement
    assert(type(advancement) == "table", "Tier-2 definition exists: " .. familyId)
    assert(advancement.DisplayName == expectation[1], "Tier-2 title locked: " .. familyId)
    assert(
        advancement.StarterSkillId == expectation[2],
        "Tier-2 starter skill locked: " .. familyId
    )
    local skill = SkillDefinitions[advancement.StarterSkillId]
    assert(skill, "Tier-2 skill exists: " .. advancement.StarterSkillId)
    assert(skill.FamilyId == familyId, "Tier-2 skill cannot cross families: " .. familyId)
    assert(skill.RequiredLevel == 30, "Tier-2 skill requires Level 30: " .. familyId)
    assert(skill.RequiredTier == 2, "Tier-2 skill requires Advancement Tier 2: " .. familyId)
    assert(skill.Kind == "Active", "Tier-2 starter technique is active: " .. familyId)
end

print("second advancement content tests passed")
