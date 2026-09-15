local Profiles = require("../src/shared/RegionVisualProfiles")
local Rules = require("../src/shared/Logic/RegionVisualRules")

for name, profile in Profiles do
    local ok, reason = Rules.Validate(profile)
    assert(ok, string.format("visual profile %s valid: %s", name, tostring(reason)))
end

assert(
    Rules.Resolve("lumenreach", Profiles) == Profiles.lumenreach,
    "known region resolves profile"
)
assert(Rules.Resolve("brasshaven", Profiles) == Profiles.default, "unknown region uses default")
assert(Rules.Resolve(nil, Profiles) == Profiles.default, "missing region uses default")

print("region visual rules tests passed")
