local MonetizationRules = require("../src/shared/Logic/MonetizationRules")
local MonetizationConfig = require("../src/shared/MonetizationConfig")

assert(MonetizationConfig.ExperienceId == 10766525835, "experience id")
assert(MonetizationConfig.FounderPassId == 1982246374, "founder pass id")
assert(MonetizationConfig.SupportProductId == 3712998285, "support product id")
assert(
    MonetizationConfig.MembershipSubscriptionId == "EXP-8349786609016766972",
    "membership subscription id"
)
assert(MonetizationConfig.Badges.FoundingAdventurer == 3442974763042508, "founding badge")
assert(MonetizationConfig.Badges.EverLeafFounder == 1164502295196812, "founder badge")
assert(MonetizationConfig.Badges.WelcomeToLumenreach == 3109675189778606, "welcome badge")
assert(MonetizationConfig.Badges.FirstVictory == 4033795498055467, "first victory badge")
assert(MonetizationConfig.Badges.Level10 == 3949793123694068, "level 10 badge")
assert(MonetizationConfig.FounderSalesEnabled == true, "founder sales enabled")
assert(MonetizationConfig.SupportSalesEnabled == true, "support sales enabled")
assert(MonetizationConfig.MembershipSalesEnabled == true, "membership sales enabled")
assert(MonetizationConfig.GiftingEnabled == false, "gifting remains disabled")
assert(MonetizationConfig.PaidItemTradingEnabled == false, "paid item trading remains disabled")
assert(
    MonetizationConfig.MonthlyMemberCosmetics["2026-09"] == "member_2026_09_lumen_trail",
    "September member cosmetic"
)
assert(
    table.find(MonetizationConfig.Benefits.Founder, "founder_title"),
    "founder title benefit hook"
)
assert(
    table.find(MonetizationConfig.Benefits.Founder, "founder_lumen_aura"),
    "founder aura benefit hook"
)
assert(table.find(MonetizationConfig.Benefits.Membership, "member_title"), "membership title hook")
assert(
    table.find(MonetizationConfig.Benefits.Membership, "member_cosmetics"),
    "membership cosmetic hook"
)
assert(
    not table.find(MonetizationConfig.Benefits.Membership, "member_qol"),
    "no unimplemented membership qol promise"
)

local configOk, configReason = MonetizationRules.Validate(MonetizationConfig)
assert(configOk, "monetization config valid: " .. tostring(configReason))
assert(
    MonetizationRules.ShouldFetchCatalogEntry(MonetizationConfig, "Founder"),
    "founder catalog enabled"
)
assert(
    MonetizationRules.ShouldFetchCatalogEntry(MonetizationConfig, "Support"),
    "support catalog enabled"
)
assert(
    MonetizationRules.ShouldFetchCatalogEntry(MonetizationConfig, "Membership"),
    "membership catalog enabled"
)
assert(
    MonetizationRules.ShouldRefreshMembership(MonetizationConfig),
    "enabled membership refreshed"
)

print("monetization config tests passed")
