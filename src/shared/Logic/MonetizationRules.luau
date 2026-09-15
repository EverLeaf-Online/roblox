local MonetizationRules = {}

function MonetizationRules.Validate(config)
    if type(config) ~= "table" then
        return false, "invalid_config"
    end
    for _, field in { "ExperienceId", "FounderPassId", "SupportProductId" } do
        local value = config[field]
        if type(value) ~= "number" or value % 1 ~= 0 or value <= 0 then
            return false, "invalid_" .. field
        end
    end
    if
        type(config.MembershipSubscriptionId) ~= "string"
        or config.MembershipSubscriptionId == ""
    then
        return false, "invalid_membership_subscription_id"
    end
    if type(config.Badges) ~= "table" then
        return false, "invalid_badges"
    end
    local seen = {}
    local badgeCount = 0
    for badgeName, badgeId in config.Badges do
        if type(badgeName) ~= "string" or badgeName == "" then
            return false, "invalid_badge_name"
        end
        if type(badgeId) ~= "number" or badgeId % 1 ~= 0 or badgeId <= 0 then
            return false, "invalid_badge_id"
        end
        if seen[badgeId] then
            return false, "duplicate_badge_id"
        end
        seen[badgeId] = true
        badgeCount += 1
    end
    if badgeCount == 0 then
        return false, "no_badges"
    end
    return true
end

function MonetizationRules.ShouldRefreshMembership(config)
    return type(config) == "table" and config.MembershipSalesEnabled == true
end

function MonetizationRules.ShouldFetchCatalogEntry(config, kind)
    if type(config) ~= "table" then
        return false
    end
    if kind == "Founder" then
        return config.FounderSalesEnabled == true
    end
    if kind == "Support" then
        return config.SupportSalesEnabled == true
    end
    if kind == "Membership" then
        return config.MembershipSalesEnabled == true
    end
    return false
end

return table.freeze(MonetizationRules)
