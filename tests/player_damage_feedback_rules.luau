local Rules = require("../src/shared/Logic/PlayerDamageFeedbackRules")

local hit = Rules.Build(30, 24, 120, 0.2, "rivet_scuttler")
assert(hit.Amount == 24, "applied damage")
assert(hit.RawAmount == 30, "raw damage")
assert(hit.Mitigated == 6, "mitigated amount")
assert(hit.SourceId == "rivet_scuttler", "source id")
assert(hit.Heavy == true, "20 percent max-health hit is heavy")

local light = Rules.Build(12, 9, 120, 0.1, "slagmite")
assert(light.Mitigated == 3, "light hit mitigation")
assert(light.Heavy == false, "light hit is not heavy")

local stagger = Rules.Build(8, 6, 200, 0.45, "belforge_colossus_steam")
assert(stagger.Heavy == true, "strong stagger marks heavy feedback")

print("player damage feedback rules tests passed")
