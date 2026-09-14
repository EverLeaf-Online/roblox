local DerivedStatsService = require(script.Parent.DerivedStatsService)
local PartyService = require(script.Parent.PartyService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local ResourceService = require(script.Parent.ResourceService)
local StatusEffectService = require(script.Parent.StatusEffectService)

local SnapshotService = {}

function SnapshotService.Build(player)
    local profile = PlayerDataService.Get(player)
    local snapshot = PlayerDataService.GetSnapshot(player)
    if not profile or not snapshot then
        return nil
    end

    snapshot.Derived = DerivedStatsService.Compute(profile)
    snapshot.Resources = ResourceService.GetSnapshot(player, profile)
    snapshot.StatusEffects = StatusEffectService.GetSnapshot(player)
    snapshot.Party = PartyService.GetSnapshot(player)
    return snapshot
end

return SnapshotService
