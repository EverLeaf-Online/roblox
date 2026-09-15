local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PublicProfileRules = require(ReplicatedStorage.Shared.Logic.PublicProfileRules)
local DerivedStatsService = require(script.Parent.DerivedStatsService)
local PlayerDataService = require(script.Parent.PlayerDataService)

local SocialProfileService = {}

local function recognitionFor(player)
    if player:GetAttribute("EverLeafFounder") == true then
        return "FOUNDER"
    elseif player:GetAttribute("EverLeafMember") == true then
        return "MEMBER"
    end
    return nil
end

function SocialProfileService.Inspect(targetUserId)
    local target = Players:GetPlayerByUserId(targetUserId)
    if not target or target.Parent ~= Players then
        return false, "player_unavailable"
    end
    local profile = PlayerDataService.Get(target)
    if not profile then
        return false, "profile_not_loaded"
    end
    local snapshot, reason = PublicProfileRules.Build(profile, {
        UserId = target.UserId,
        Name = target.Name,
        DisplayName = target.DisplayName,
        Recognition = recognitionFor(target),
    }, DerivedStatsService.Compute(profile))
    if not snapshot then
        return false, reason
    end
    return true, snapshot
end

return SocialProfileService
