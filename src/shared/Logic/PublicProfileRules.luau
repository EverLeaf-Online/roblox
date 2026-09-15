local PublicProfileRules = {}

local EQUIPMENT_SLOTS = table.freeze({
    "Weapon",
    "Head",
    "Body",
    "Legs",
    "Accessory",
    "Ring1",
    "Ring2",
})

local CORE_STATS = table.freeze({ "Might", "Finesse", "Insight", "Fortune" })
local DERIVED_FIELDS = table.freeze({
    "MaxHP",
    "MaxMP",
    "AttackPower",
    "Defense",
    "CritChance",
    "CritPower",
    "AttackSpeed",
})

local function copySelected(source, keys)
    local result = {}
    source = type(source) == "table" and source or {}
    for _, key in keys do
        local value = source[key]
        if value ~= nil then
            result[key] = value
        end
    end
    return result
end

local function countTruthy(source)
    local count = 0
    for _, value in type(source) == "table" and source or {} do
        if value then
            count += 1
        end
    end
    return count
end

function PublicProfileRules.Build(profile, identity, derived)
    if type(profile) ~= "table" or type(identity) ~= "table" then
        return nil, "invalid_profile"
    end
    local userId = tonumber(identity.UserId)
    if not userId or userId <= 0 or userId % 1 ~= 0 then
        return nil, "invalid_identity"
    end

    local achievements = profile.Achievements and profile.Achievements.Unlocked or {}
    local cosmetics = profile.Cosmetics or {}
    return {
        UserId = userId,
        Name = tostring(identity.Name or "Wayfarer"),
        DisplayName = tostring(identity.DisplayName or identity.Name or "Wayfarer"),
        Recognition = identity.Recognition,
        Level = math.max(1, math.floor(tonumber(profile.Level) or 1)),
        FamilyId = type(profile.FamilyId) == "string" and profile.FamilyId or "",
        AdvancementTier = math.max(0, math.floor(tonumber(profile.AdvancementTier) or 0)),
        Stats = copySelected(profile.Stats, CORE_STATS),
        Derived = copySelected(derived, DERIVED_FIELDS),
        Equipment = copySelected(profile.Equipment, EQUIPMENT_SLOTS),
        Cosmetics = { Equipped = table.clone(cosmetics.Equipped or {}) },
        AchievementCount = countTruthy(achievements),
    }
end

return table.freeze(PublicProfileRules)
