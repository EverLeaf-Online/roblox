local WorldNoticeRules = {}

local MESSAGES = table.freeze({
    profile_not_loaded = table.freeze({
        "error",
        "Travel Unavailable",
        "Your character data is still loading.",
    }),
    region_locked = table.freeze({
        "warning",
        "Region Locked",
        "Complete the required progression before using this route.",
    }),
    level_too_low = table.freeze({
        "warning",
        "Level Requirement",
        "You have not reached the required level for this destination.",
    }),
    second_advancement_required = table.freeze({
        "warning",
        "Second Advancement Required",
        "Complete your Level 30 promotion with Mara before entering the Colossus arena.",
    }),
    sentinel_incomplete = table.freeze({
        "warning",
        "Belforge Sealed",
        "Defeat the Belforge Sentinel and complete Rook's gate route first.",
    }),
    encounter_locked = table.freeze({
        "warning",
        "Fight In Progress",
        "The Belforge Colossus encounter has already started. New entrants are locked out for this attempt.",
    }),
    encounter_active = table.freeze({
        "warning",
        "Attempt Already Active",
        "You cannot re-enter the Colossus arena during the same active attempt.",
    }),
    encounter_resetting = table.freeze({
        "warning",
        "Arena Resetting",
        "The Belforge arena is resetting after a failed attempt. Try again shortly.",
    }),
    encounter_full = table.freeze({
        "warning",
        "Arena Full",
        "The Belforge encounter already has the maximum number of entrants.",
    }),
    boss_recovering = table.freeze({
        "info",
        "Colossus Dormant",
        "The Belforge mechanisms are recovering before another Colossus attempt can begin.",
    }),
    spawn_unavailable = table.freeze({
        "error",
        "Route Unavailable",
        "That destination is not ready yet. Try again in a moment.",
    }),
    character_unavailable = table.freeze({
        "warning",
        "Cannot Travel",
        "You cannot travel while your character is unavailable.",
    }),
    wrong_source_region = table.freeze({
        "error",
        "Invalid Route",
        "This route cannot be used from your current region.",
    }),
    too_far = table.freeze({ "warning", "Too Far Away", "Move closer to the gate and try again." }),
    unknown_portal = table.freeze({
        "error",
        "Route Unavailable",
        "This travel route is not configured.",
    }),
    invalid_world_object = table.freeze({
        "error",
        "Interaction Failed",
        "That world object is no longer valid.",
    }),
})

function WorldNoticeRules.ForReason(reason)
    local entry = MESSAGES[tostring(reason)]
    if not entry then
        return {
            Kind = "error",
            Title = "Action Unavailable",
            Body = "That action could not be completed right now.",
            Duration = 4,
        }
    end
    return {
        Kind = entry[1],
        Title = entry[2],
        Body = entry[3],
        Duration = 4,
    }
end

return table.freeze(WorldNoticeRules)
