local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ActionClient = require(script.Parent.Parent.Services.ActionClient)
local ProfileStore = require(script.Parent.Parent.State.ProfileStore)
local SkillCooldownStore = require(script.Parent.Parent.State.SkillCooldownStore)
local NotificationStore = require(script.Parent.Parent.UI.NotificationStore)

local SkillController = {}
local player = Players.LocalPlayer
local lastFailureAt = {}

local FAILURE_TEXT = table.freeze({
    no_target = "No valid target is in range.",
    cooldown = "That skill is still cooling down.",
    insufficient_mp = "You do not have enough MP.",
    skill_not_learned = "That skill has not been learned.",
    invalid_skill = "That hotbar skill is unavailable.",
})

local function showFailure(reason)
    local text = FAILURE_TEXT[reason]
    if not text then
        warn(string.format("[SkillController] skill use failed: %s", tostring(reason)))
        return
    end
    local now = os.clock()
    if now - (lastFailureAt[reason] or -math.huge) < 0.75 then
        return
    end
    lastFailureAt[reason] = now
    NotificationStore.Push("warning", "Skill Unavailable", text, 1.6)
end

local keyToSlot = {
    [Enum.KeyCode.One] = 1,
    [Enum.KeyCode.Two] = 2,
    [Enum.KeyCode.Three] = 3,
    [Enum.KeyCode.Four] = 4,
    [Enum.KeyCode.Five] = 5,
    [Enum.KeyCode.Six] = 6,
    [Enum.KeyCode.Seven] = 7,
    [Enum.KeyCode.Eight] = 8,
}

local gamepadToSlot = {
    [Enum.KeyCode.DPadLeft] = 1,
    [Enum.KeyCode.DPadUp] = 2,
    [Enum.KeyCode.DPadRight] = 3,
    [Enum.KeyCode.DPadDown] = 4,
    [Enum.KeyCode.ButtonL1] = 5,
    [Enum.KeyCode.ButtonR1] = 6,
    [Enum.KeyCode.ButtonL2] = 7,
    [Enum.KeyCode.ButtonR3] = 8,
}

local function useSlot(slotIndex)
    if
        player:GetAttribute("EverLeafUiCapture") == true
        or GuiService.MenuIsOpen
        or UserInputService:GetFocusedTextBox() ~= nil
    then
        return
    end

    local profile = ProfileStore.Get()
    local hotbar = profile and profile.Skills and profile.Skills.Hotbar
    if not hotbar then
        return
    end

    local skillId = hotbar[tostring(slotIndex)] or hotbar[slotIndex]
    if type(skillId) ~= "string" or skillId == "" then
        return
    end

    task.spawn(function()
        local ok, result = ActionClient.Invoke("skill.use", { SkillId = skillId })
        if not ok then
            showFailure(result)
            return
        end
        if type(result) == "table" then
            SkillCooldownStore.Start(skillId, result.Cooldown)
        end
    end)
end

function SkillController.Start()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        local slot = keyToSlot[input.KeyCode] or gamepadToSlot[input.KeyCode]
        if slot then
            useSlot(slot)
        end
    end)
end

return SkillController
