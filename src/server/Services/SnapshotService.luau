local DerivedStatsService = require(script.Parent.DerivedStatsService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local ResourceService = require(script.Parent.ResourceService)

local SnapshotService = {}

function SnapshotService.Build(player)
    local profile = PlayerDataService.Get(player)
    local snapshot = PlayerDataService.GetSnapshot(player)
    if not profile or not snapshot then
        return nil
    end

    snapshot.Derived = DerivedStatsService.Compute(profile)
    snapshot.Resources = ResourceService.GetSnapshot(player, profile)
    return snapshot
end

return SnapshotService
