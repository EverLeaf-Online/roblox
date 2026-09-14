local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildInfo = require(ReplicatedStorage.Shared.BuildInfo)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local ReleaseService = {}

function ReleaseService.GetMetadata()
    return {
        Environment = GameConfig.Environment,
        ArchitecturePhase = BuildInfo.ArchitecturePhase,
        ProtocolVersion = BuildInfo.ProtocolVersion,
        ContentVersion = BuildInfo.ContentVersion,
        PlaceId = game.PlaceId,
        JobId = game.JobId,
    }
end

function ReleaseService.CanPublishAutomatically()
    return false
end

return ReleaseService
