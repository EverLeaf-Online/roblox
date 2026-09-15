local Cosmetics = require("../src/shared/CosmeticDefinitions")

local allowedSlots = {
    Aura = true,
    Trail = true,
    Title = true,
    WeaponSkin = true,
    Outfit = true,
}
local allowedEntitlements = { Founder = true, Membership = true }

for cosmeticId, definition in Cosmetics do
    assert(type(cosmeticId) == "string" and cosmeticId ~= "", "cosmetic id")
    assert(
        type(definition.DisplayName) == "string" and definition.DisplayName ~= "",
        "display name"
    )
    assert(allowedSlots[definition.Slot], "valid cosmetic slot: " .. cosmeticId)
    if definition.Entitlement then
        assert(allowedEntitlements[definition.Entitlement], "valid entitlement: " .. cosmeticId)
    end
end

assert(Cosmetics.founder_title.Slot == "Title", "founder title slot")
assert(Cosmetics.founder_title.Entitlement == "Founder", "founder title entitlement")
assert(Cosmetics.founder_lumen_aura.Slot == "Aura", "founder aura slot")
assert(Cosmetics.member_title.Entitlement == "Membership", "member title entitlement")
assert(Cosmetics.member_2026_09_lumen_trail.Slot == "Trail", "member reward trail slot")

print("cosmetic definition tests passed")
