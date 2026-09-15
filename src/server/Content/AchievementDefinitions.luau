local MonetizationConfig = require(game:GetService("ReplicatedStorage").Shared.MonetizationConfig)

return table.freeze({
    founding_adventurer = table.freeze({
        DisplayName = "Founding Adventurer",
        Description = "Entered Lumenreach during EverLeaf Online's early-development era.",
        RobloxBadgeId = MonetizationConfig.Badges.FoundingAdventurer,
    }),
    everleaf_founder = table.freeze({
        DisplayName = "EverLeaf Founder",
        Description = "A founding supporter of EverLeaf Online.",
        RobloxBadgeId = MonetizationConfig.Badges.EverLeafFounder,
    }),
    welcome_to_lumenreach = table.freeze({
        DisplayName = "Welcome to Lumenreach",
        Description = "Begin your first adventure in Lumenreach.",
        RobloxBadgeId = MonetizationConfig.Badges.WelcomeToLumenreach,
    }),
    first_victory = table.freeze({
        DisplayName = "First Victory",
        Description = "Defeat your first enemy.",
        RobloxBadgeId = MonetizationConfig.Badges.FirstVictory,
    }),
    level_10 = table.freeze({
        DisplayName = "Level 10",
        Description = "Reach Level 10.",
        RobloxBadgeId = MonetizationConfig.Badges.Level10,
    }),
})
