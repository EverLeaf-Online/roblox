local CosmeticDefinitions = require("../src/shared/CosmeticDefinitions")
local MonetizationConfig = require("../src/shared/MonetizationConfig")
local Safety = require("../src/shared/Logic/MonetizationSafetyRules")

local ok, reason = Safety.Validate(MonetizationConfig, CosmeticDefinitions)
assert(ok, "live monetization remains cosmetic-only: " .. tostring(reason))

local unsafeCosmetics = {
    premium_sword = {
        DisplayName = "Premium Sword",
        Slot = "WeaponSkin",
        Entitlement = "Founder",
        Stats = { AttackPower = 999 },
    },
}
local cosmeticOk, cosmeticReason = Safety.ValidateCosmeticDefinitions(unsafeCosmetics)
assert(
    not cosmeticOk and string.find(cosmeticReason, "power_or_unknown_cosmetic_field", 1, true),
    "power-bearing cosmetic fields are rejected"
)

local configWithPowerBenefit = {
    Benefits = {
        Founder = { "double_damage" },
        Membership = { "member_cosmetics" },
    },
    MonthlyMemberCosmetics = {},
}
local benefitOk, benefitReason = Safety.Validate(configWithPowerBenefit, CosmeticDefinitions)
assert(
    not benefitOk and benefitReason == "non_cosmetic_premium_benefit:double_damage",
    "unknown premium power benefits fail closed"
)

local badMonthlyConfig = {
    Benefits = {
        Founder = { "founder_title" },
        Membership = { "member_title" },
    },
    MonthlyMemberCosmetics = { ["2026-09"] = "member_title" },
}
local monthlyOk, monthlyReason = Safety.Validate(badMonthlyConfig, CosmeticDefinitions)
assert(
    not monthlyOk and string.find(monthlyReason, "monthly_cosmetic_must_be_permanent", 1, true),
    "monthly earned collectibles cannot require an active subscription after grant"
)

print("monetization safety tests passed")
