local MonetizationConfig = {
    ExperienceId = 10766525835,
    FounderPassId = 1982246374,
    SupportProductId = 3712998285,
    MembershipSubscriptionId = "EXP-8349786609016766972",

    -- All three monetization surfaces are enabled in-game. Creator Hub remains
    -- the source of truth for whether the subscription itself is active/sellable.
    FounderSalesEnabled = true,
    SupportSalesEnabled = true,
    MembershipSalesEnabled = true,
    GiftingEnabled = false,
    PaidItemTradingEnabled = false,

    -- This flag controls the limited early-development badge. Flip it off when
    -- the founding era ends; existing badge owners keep it permanently.
    FoundingPhaseActive = true,

    Badges = {
        FoundingAdventurer = 3442974763042508,
        EverLeafFounder = 1164502295196812,
        WelcomeToLumenreach = 3109675189778606,
        FirstVictory = 4033795498055467,
        Level10 = 3949793123694068,
    },

    MonthlyMemberCosmetics = table.freeze({
        ["2026-09"] = "member_2026_09_lumen_trail",
    }),

    Benefits = {
        Founder = table.freeze({
            "founder_title",
            "founder_lumen_aura",
            "founder_recognition",
        }),
        Membership = table.freeze({
            "member_title",
            "member_cosmetics",
        }),
    },
}

return table.freeze(MonetizationConfig)
