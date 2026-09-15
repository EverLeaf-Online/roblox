local MonetizationSafetyRules = {}

local COSMETIC_ALLOWED_FIELDS = table.freeze({
    DisplayName = true,
    Slot = true,
    Entitlement = true,
    Label = true,
    Description = true,
})

local PRESENTATION_ONLY_BENEFITS = table.freeze({
    founder_recognition = true,
    member_cosmetics = true,
})

local function expectedEntitlement(groupName)
    if groupName == "Founder" then
        return "Founder"
    end
    if groupName == "Membership" then
        return "Membership"
    end
    return nil
end

function MonetizationSafetyRules.ValidateCosmeticDefinitions(cosmetics)
    if type(cosmetics) ~= "table" then
        return false, "invalid_cosmetic_definitions"
    end

    for cosmeticId, definition in cosmetics do
        if type(cosmeticId) ~= "string" or cosmeticId == "" or type(definition) ~= "table" then
            return false, "invalid_cosmetic_definition"
        end
        for field in definition do
            if not COSMETIC_ALLOWED_FIELDS[field] then
                return false,
                    "power_or_unknown_cosmetic_field:" .. tostring(cosmeticId) .. ":" .. tostring(
                        field
                    )
            end
        end
        if type(definition.DisplayName) ~= "string" or definition.DisplayName == "" then
            return false, "invalid_cosmetic_display_name"
        end
        if type(definition.Slot) ~= "string" or definition.Slot == "" then
            return false, "invalid_cosmetic_slot"
        end
        if
            definition.Entitlement ~= nil
            and definition.Entitlement ~= "Founder"
            and definition.Entitlement ~= "Membership"
        then
            return false, "invalid_cosmetic_entitlement"
        end
    end
    return true
end

function MonetizationSafetyRules.Validate(config, cosmetics)
    local cosmeticOk, cosmeticReason =
        MonetizationSafetyRules.ValidateCosmeticDefinitions(cosmetics)
    if not cosmeticOk then
        return false, cosmeticReason
    end
    if type(config) ~= "table" or type(config.Benefits) ~= "table" then
        return false, "invalid_benefits"
    end

    for groupName, benefits in config.Benefits do
        local entitlement = expectedEntitlement(groupName)
        if not entitlement or type(benefits) ~= "table" then
            return false, "invalid_benefit_group"
        end
        local seen = {}
        for _, benefitId in benefits do
            if type(benefitId) ~= "string" or benefitId == "" or seen[benefitId] then
                return false, "invalid_benefit_id"
            end
            seen[benefitId] = true
            local cosmetic = cosmetics[benefitId]
            if cosmetic then
                if cosmetic.Entitlement ~= entitlement then
                    return false, "benefit_entitlement_mismatch:" .. benefitId
                end
            elseif not PRESENTATION_ONLY_BENEFITS[benefitId] then
                return false, "non_cosmetic_premium_benefit:" .. benefitId
            end
        end
    end

    if type(config.MonthlyMemberCosmetics) ~= "table" then
        return false, "invalid_monthly_cosmetics"
    end
    for period, cosmeticId in config.MonthlyMemberCosmetics do
        if type(period) ~= "string" or period == "" or type(cosmeticId) ~= "string" then
            return false, "invalid_monthly_cosmetic_entry"
        end
        local cosmetic = cosmetics[cosmeticId]
        if not cosmetic then
            return false, "unknown_monthly_cosmetic:" .. cosmeticId
        end
        -- Monthly member collectibles are permanent once earned. They must not
        -- carry a live Membership entitlement gate after ownership is granted.
        if cosmetic.Entitlement ~= nil then
            return false, "monthly_cosmetic_must_be_permanent:" .. cosmeticId
        end
    end

    return true
end

return table.freeze(MonetizationSafetyRules)
