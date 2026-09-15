local Definitions = require("../src/shared/StatusEffectDefinitions")
local Rules = require("../src/shared/Logic/StatusEffectRules")

local ok, definition = Rules.ValidateApply("staggered", 0.2, Definitions, 3600)
assert(ok and definition.Kind == "Debuff", "known stagger debuff accepted")

ok = Rules.ValidateApply("unknown", 1, Definitions, 3600)
assert(not ok, "unknown status rejected")
ok = Rules.ValidateApply("staggered", 0, Definitions, 3600)
assert(not ok, "zero duration rejected")
ok = Rules.ValidateApply("staggered", 4000, Definitions, 3600)
assert(not ok, "overlong duration rejected")
ok = Rules.ValidateApply("staggered", 0 / 0, Definitions, 3600)
assert(not ok, "NaN duration rejected")

assert(Rules.ResolveExpiry(10, nil, 3) == 13, "new status expiry uses duration")
assert(Rules.ResolveExpiry(10, 20, 3) == 20, "shorter refresh cannot shorten active status")
assert(Rules.ResolveExpiry(10, 11, 3) == 13, "longer refresh extends active status")

for effectId, status in Definitions do
    local valid = Rules.ValidateDefinition(effectId, status)
    assert(valid, "status metadata valid: " .. effectId)
end

print("status effect rules tests passed")
