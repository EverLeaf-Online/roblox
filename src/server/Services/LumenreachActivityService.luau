local Players = game:GetService("Players")

local CraftingService = require(script.Parent.CraftingService)
local InventoryService = require(script.Parent.InventoryService)
local ItemDefinitions = require(script.Parent.Parent.Content.ItemDefinitions)
local PlayerDataService = require(script.Parent.PlayerDataService)
local ProfileTransaction =
    require(game:GetService("ReplicatedStorage").Shared.Logic.ProfileTransaction)
local QuestObjectiveService = require(script.Parent.QuestObjectiveService)
local ResourceService = require(script.Parent.ResourceService)
local RewardService = require(script.Parent.RewardService)
local WorldNoticeService = require(script.Parent.WorldNoticeService)

local LumenreachActivityService = {}

local cooldowns = {}
local initialized = false

local function now()
    return os.clock()
end

local function playerRoot(player)
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function withinPromptRange(player, prompt)
    local root = playerRoot(player)
    local parent = prompt.Parent
    if not root or not parent or not parent:IsA("BasePart") then
        return false
    end
    return (root.Position - parent.Position).Magnitude <= (prompt.MaxActivationDistance + 3)
end

local function notice(player, kind, title, body, duration)
    WorldNoticeService.Send(player, {
        Kind = kind,
        Title = title,
        Body = body,
        Duration = duration or 3,
    })
end

local function playerCooldowns(player)
    local userId = player.UserId
    local state = cooldowns[userId]
    if not state then
        state = {}
        cooldowns[userId] = state
    end
    return state
end

local function cooldownRemaining(player, activityId)
    local readyAt = playerCooldowns(player)[activityId] or 0
    return math.max(0, readyAt - now())
end

local function startCooldown(player, activityId, duration)
    playerCooldowns(player)[activityId] = now() + math.max(0, duration or 0)
end

local function gather(player, spec)
    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "profile_not_loaded"
    end
    local ok, reason = InventoryService.Add(profile, spec.ItemId, spec.Quantity or 1)
    if not ok then
        return false, reason
    end
    QuestObjectiveService.Record(profile, "Collect", spec.ItemId, spec.Quantity or 1)
    PlayerDataService.NotifyChanged(player)
    local item = ItemDefinitions[spec.ItemId]
    notice(
        player,
        "success",
        spec.Title or "Gathered",
        spec.SuccessText
            or string.format(
                "Collected %dx %s.",
                spec.Quantity or 1,
                item and item.DisplayName or spec.ItemId
            )
    )
    return true
end

local function craft(player, spec)
    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "profile_not_loaded"
    end
    local ok, result = CraftingService.Craft(profile, spec.RecipeId, spec.Quantity or 1)
    if not ok then
        return false, result
    end
    QuestObjectiveService.Record(profile, "Craft", spec.RecipeId, spec.Quantity or 1)
    PlayerDataService.NotifyChanged(player)
    local item = result and ItemDefinitions[result.ItemId]
    notice(
        player,
        "success",
        spec.Title or "Crafted",
        string.format(
            "Crafted %dx %s.",
            result and result.Quantity or 1,
            item and item.DisplayName or "item"
        )
    )
    return true
end

local function rest(player, spec)
    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "profile_not_loaded"
    end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false, "character_unavailable"
    end
    humanoid.Health = humanoid.MaxHealth
    ResourceService.RestoreMP(player, profile, 1_000_000)
    PlayerDataService.NotifyChanged(player)
    notice(
        player,
        "success",
        spec.Title or "Wayfarer Rest",
        spec.SuccessText or "HP and MP restored."
    )
    return true
end

local function cache(player, spec)
    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "profile_not_loaded"
    end
    local ok, result = ProfileTransaction.Run(profile, function(workingProfile)
        workingProfile.World.Secrets = workingProfile.World.Secrets or {}
        if workingProfile.World.Secrets[spec.SecretId] == true then
            return false, "already_claimed"
        end
        local rewarded, rewardResult = RewardService.Apply(workingProfile, spec.Reward or {})
        if not rewarded then
            return false, rewardResult
        end
        workingProfile.World.Secrets[spec.SecretId] = true
        return true, rewardResult
    end)
    if not ok then
        return false, result
    end
    PlayerDataService.NotifyChanged(player)
    notice(
        player,
        "success",
        spec.Title or "Wayfarer Cache",
        spec.SuccessText or "Supplies recovered.",
        4
    )
    return true
end

local HANDLERS = {
    Gather = gather,
    Craft = craft,
    Rest = rest,
    Cache = cache,
}

function LumenreachActivityService.Bind(prompt, spec)
    assert(prompt and prompt:IsA("ProximityPrompt"), "Bind expects ProximityPrompt")
    assert(type(spec) == "table" and type(spec.Type) == "string", "Bind expects activity spec")
    assert(type(spec.Id) == "string" and spec.Id ~= "", "activity Id required")
    local handler = HANDLERS[spec.Type]
    assert(handler, "unsupported activity type: " .. tostring(spec.Type))

    prompt:SetAttribute("EverLeafActivityId", spec.Id)
    prompt:SetAttribute("EverLeafActivityType", spec.Type)
    prompt.Triggered:Connect(function(player)
        if not player or player.Parent ~= Players then
            return
        end
        if not withinPromptRange(player, prompt) then
            notice(player, "warning", "Too Far Away", "Move closer before using that.")
            return
        end
        local remaining = cooldownRemaining(player, spec.Id)
        if remaining > 0 then
            notice(
                player,
                "info",
                spec.Title or "Not Ready",
                string.format("Try again in %.0f seconds.", math.ceil(remaining)),
                2
            )
            return
        end
        local ok, reason = handler(player, spec)
        if ok then
            startCooldown(player, spec.Id, spec.Cooldown or 0)
        else
            if reason == "already_claimed" then
                notice(
                    player,
                    "info",
                    spec.Title or "Already Claimed",
                    "You already recovered this cache."
                )
            elseif reason == "missing_ingredients" then
                notice(
                    player,
                    "warning",
                    "Missing Ingredients",
                    spec.MissingText or "You do not have the materials required."
                )
            elseif reason == "inventory_full" then
                notice(player, "warning", "Inventory Full", "Make room in your inventory first.")
            else
                notice(
                    player,
                    "warning",
                    spec.Title or "Action Unavailable",
                    tostring(reason or "Try again.")
                )
            end
        end
    end)
end

function LumenreachActivityService.Init()
    if initialized then
        return
    end
    initialized = true
    Players.PlayerRemoving:Connect(function(player)
        cooldowns[player.UserId] = nil
    end)
end

return LumenreachActivityService
