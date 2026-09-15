local MonetizationConfig = {
    ExperienceId = 10766525835,
    FounderPassId = 1982246374,
    SupportProductId = 3712998285,
    MembershipSubscriptionId = "EXP-8349786609016766972",

    -- Founder and support products are live in Creator Hub. Membership remains
    -- deliberately disabled in-game until the recurring benefits are complete
    -- and the Creator Hub subscription is activated.
    FounderSalesEnabled = true,
    SupportSalesEnabled = true,
    MembershipSalesEnabled = false,
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

    Benefits = {
        Founder = table.freeze({
            "founder_title",
            "founder_cosmetics",
            "founder_recognition",
        }),
        Membership = table.freeze({
            "member_title",
            "member_cosmetics",
            "member_qol",
        }),
    },
}

return table.freeze(MonetizationConfig)
