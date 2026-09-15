local ActionPayloadRules = {}

local MAX_SAFE_INTEGER = 9_007_199_254_740_991
local CORE_STATS = { Might = true, Finesse = true, Insight = true, Fortune = true }
local EQUIPMENT_SLOTS = {
    Weapon = true,
    Head = true,
    Body = true,
    Legs = true,
    Accessory = true,
    Ring1 = true,
    Ring2 = true,
}
local COSMETIC_SLOTS = {
    Aura = true,
    Trail = true,
    Title = true,
    WeaponSkin = true,
    Outfit = true,
}

local function stringField(maxLength, allowEmpty, allowed)
    return {
        Kind = "string",
        MaxLength = maxLength,
        AllowEmpty = allowEmpty == true,
        Allowed = allowed,
    }
end

local function integerField(minimum, maximum)
    return { Kind = "number", Integer = true, Minimum = minimum, Maximum = maximum }
end

local function booleanField()
    return { Kind = "boolean" }
end

local SCHEMAS = {
    ["stat.allocate"] = {
        StatName = stringField(16, false, CORE_STATS),
        Amount = { Kind = "number", Integer = true, Minimum = 1, Maximum = 10_000, Optional = true },
    },
    ["inventory.use"] = { ItemId = stringField(64, false) },
    ["equipment.equip"] = { InventoryIndex = integerField(1, 512) },
    ["equipment.unequip"] = { Slot = stringField(16, false, EQUIPMENT_SLOTS) },
    ["skill.learn"] = { SkillId = stringField(64, false) },
    ["skill.hotbar"] = {
        Index = integerField(1, 8),
        SkillId = stringField(64, true),
    },
    ["skill.use"] = { SkillId = stringField(64, false) },
    ["quest.start"] = {
        NpcId = stringField(64, false),
        QuestId = stringField(64, false),
    },
    ["quest.turnin"] = {
        NpcId = stringField(64, false),
        QuestId = stringField(64, false),
    },
    ["shop.buy"] = {
        ShopId = stringField(64, false),
        ItemId = stringField(64, false),
        Quantity = { Kind = "number", Integer = true, Minimum = 1, Maximum = 99, Optional = true },
    },
    ["shop.sell"] = {
        ShopId = stringField(64, false),
        ItemId = stringField(64, false),
        Quantity = { Kind = "number", Integer = true, Minimum = 1, Maximum = 99, Optional = true },
    },
    ["advancement.first"] = {
        NpcId = stringField(64, false),
        FamilyId = stringField(64, false),
    },
    ["advancement.second"] = { NpcId = stringField(64, false) },
    ["party.create"] = {},
    ["party.invite"] = { TargetUserId = integerField(1, MAX_SAFE_INTEGER) },
    ["party.accept"] = {},
    ["party.decline"] = {},
    ["party.kick"] = { TargetUserId = integerField(1, MAX_SAFE_INTEGER) },
    ["party.leave"] = {},
    ["party.ready.respond"] = { Accepted = booleanField() },
    ["social.inspect"] = { TargetUserId = integerField(1, MAX_SAFE_INTEGER) },
    ["cosmetic.equip"] = {
        Slot = stringField(24, false, COSMETIC_SLOTS),
        CosmeticId = stringField(64, true),
    },
    ["settings.update"] = {
        Key = stringField(32, false, {
            MusicVolume = true,
            SfxVolume = true,
            ShowDamageNumbers = true,
        }),
        Value = { Kinds = { number = true, boolean = true } },
    },
}

local PROFILE_MUTATIONS = table.freeze({
    ["stat.allocate"] = true,
    ["inventory.use"] = true,
    ["equipment.equip"] = true,
    ["equipment.unequip"] = true,
    ["skill.learn"] = true,
    ["skill.hotbar"] = true,
    ["quest.start"] = true,
    ["quest.turnin"] = true,
    ["shop.buy"] = true,
    ["shop.sell"] = true,
    ["advancement.first"] = true,
    ["advancement.second"] = true,
    ["cosmetic.equip"] = true,
    ["settings.update"] = true,
})

local function validateField(value, rule)
    if value == nil then
        return rule.Optional == true
    end
    local kind = type(value)
    if rule.Kinds then
        if rule.Kinds[kind] ~= true then
            return false
        end
    elseif kind ~= rule.Kind then
        return false
    end

    if kind == "string" then
        if not rule.AllowEmpty and value == "" then
            return false
        end
        if rule.MaxLength and #value > rule.MaxLength then
            return false
        end
        if rule.Allowed and rule.Allowed[value] ~= true then
            return false
        end
    elseif kind == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return false
        end
        if rule.Integer and value % 1 ~= 0 then
            return false
        end
        if rule.Minimum and value < rule.Minimum then
            return false
        end
        if rule.Maximum and value > rule.Maximum then
            return false
        end
    end
    return true
end

function ActionPayloadRules.Validate(actionName, payload)
    local schema = SCHEMAS[actionName]
    if schema == nil then
        return false, "unknown_action"
    end
    if type(payload) ~= "table" then
        return false, "invalid_payload"
    end

    for key in payload do
        if type(key) ~= "string" or schema[key] == nil then
            return false, "unexpected_field"
        end
    end
    for fieldName, rule in schema do
        if not validateField(payload[fieldName], rule) then
            return false, "invalid_field"
        end
    end

    if actionName == "settings.update" then
        local key = payload.Key
        local value = payload.Value
        if key == "MusicVolume" or key == "SfxVolume" then
            if type(value) ~= "number" or value < 0 or value > 1 then
                return false, "invalid_field"
            end
        elseif key == "ShowDamageNumbers" and type(value) ~= "boolean" then
            return false, "invalid_field"
        end
    end

    return true
end

function ActionPayloadRules.ValidateMovementIntent(payload)
    if type(payload) ~= "table" then
        return false
    end
    for key in payload do
        if key ~= "Crouching" then
            return false
        end
    end
    return type(payload.Crouching) == "boolean"
end

function ActionPayloadRules.MutatesProfile(actionName)
    return PROFILE_MUTATIONS[actionName] == true
end

function ActionPayloadRules.IsCosmeticSlot(slotName)
    return COSMETIC_SLOTS[slotName] == true
end

return table.freeze(ActionPayloadRules)
