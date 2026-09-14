local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local ActionClient = require(script.Parent.Parent.Services.ActionClient)
local CatalogClient = require(script.Parent.Parent.Services.CatalogClient)
local ProfileStore = require(script.Parent.Parent.State.ProfileStore)
local Net = require(ReplicatedStorage.Shared.Net)
local ProgressionMath = require(ReplicatedStorage.Shared.Math.ProgressionMath)

local ReactUIController = {}
local player = Players.LocalPlayer
local reactRoot = nil

local COLORS = {
    Panel = Color3.fromRGB(17, 24, 23),
    PanelSoft = Color3.fromRGB(27, 37, 35),
    Border = Color3.fromRGB(91, 129, 113),
    Text = Color3.fromRGB(234, 242, 237),
    Muted = Color3.fromRGB(160, 190, 176),
    Accent = Color3.fromRGB(113, 207, 155),
    Health = Color3.fromRGB(190, 72, 73),
    Mana = Color3.fromRGB(66, 128, 198),
    Exp = Color3.fromRGB(111, 197, 142),
}

local function ratio(value, maximum)
    if type(value) ~= "number" or type(maximum) ~= "number" or maximum <= 0 then
        return 0
    end
    return math.clamp(value / maximum, 0, 1)
end

local function roundedChildren(children, radius, strokeColor)
    local result = table.clone(children or {})
    result.Corner = React.createElement("UICorner", {
        CornerRadius = UDim.new(0, radius or 10),
    })
    if strokeColor then
        result.Stroke = React.createElement("UIStroke", {
            Color = strokeColor,
            Transparency = 0.5,
            Thickness = 1,
        })
    end
    return result
end

local function Panel(props)
    return React.createElement("Frame", {
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = props.Size,
        BackgroundColor3 = props.BackgroundColor3 or COLORS.Panel,
        BackgroundTransparency = props.BackgroundTransparency or 0.1,
        BorderSizePixel = 0,
        Visible = props.Visible ~= false,
        ZIndex = props.ZIndex or 1,
    }, roundedChildren(props.Children, props.Radius, COLORS.Border))
end

local function Label(props)
    return React.createElement("TextLabel", {
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = props.Size,
        BackgroundTransparency = 1,
        Text = props.Text or "",
        TextColor3 = props.Color or COLORS.Text,
        TextSize = props.TextSize or 14,
        Font = props.Bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
        TextXAlignment = props.Align or Enum.TextXAlignment.Left,
        TextYAlignment = props.VerticalAlign or Enum.TextYAlignment.Center,
        TextWrapped = props.Wrapped or false,
        ZIndex = props.ZIndex or 2,
    })
end

local function Bar(props)
    local fraction = ratio(props.Value or 0, props.Maximum or 1)
    return React.createElement(
        "Frame",
        {
            Position = props.Position,
            Size = props.Size,
            BackgroundColor3 = Color3.fromRGB(29, 35, 34),
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 2,
        },
        roundedChildren({
            Fill = React.createElement("Frame", {
                Size = UDim2.fromScale(fraction, 1),
                BackgroundColor3 = props.Color,
                BorderSizePixel = 0,
                ZIndex = 2,
            }, roundedChildren(nil, 6)),
            Text = React.createElement(Label, {
                Position = UDim2.fromScale(0, 0),
                Size = UDim2.fromScale(1, 1),
                Text = props.Text,
                TextSize = 12,
                Bold = true,
                Align = Enum.TextXAlignment.Center,
                ZIndex = 3,
            }),
        }, 6)
    )
end

local function Hotbar(props)
    local catalog = CatalogClient.Get()
    local profile = props.Profile or {}
    local hotbar = profile.Skills and profile.Skills.Hotbar or {}
    local children = {}

    for index = 1, 8 do
        local skillId = hotbar[tostring(index)] or hotbar[index]
        local definition = skillId and catalog and catalog.Skills and catalog.Skills[skillId]
        local displayName = if definition
            then definition.DisplayName
            else if skillId then tostring(skillId) else "—"

        children["Slot" .. index] = React.createElement(
            "Frame",
            {
                Position = UDim2.fromOffset(10 + (index - 1) * 75, 9),
                Size = UDim2.fromOffset(66, 56),
                BackgroundColor3 = COLORS.PanelSoft,
                BorderSizePixel = 0,
            },
            roundedChildren({
                Key = React.createElement(Label, {
                    Position = UDim2.fromOffset(6, 2),
                    Size = UDim2.fromOffset(16, 16),
                    Text = tostring(index),
                    TextSize = 10,
                    Color = COLORS.Muted,
                }),
                Skill = React.createElement(Label, {
                    Position = UDim2.fromOffset(4, 20),
                    Size = UDim2.new(1, -8, 0, 30),
                    Text = displayName,
                    TextSize = 10,
                    Align = Enum.TextXAlignment.Center,
                    Wrapped = true,
                }),
            }, 8)
        )
    end

    return React.createElement(Panel, {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -20),
        Size = UDim2.fromOffset(616, 74),
        Children = children,
    })
end

local function Objective(props)
    local profile = props.Profile or {}
    local active = profile.Quests and profile.Quests.Active
    local title = "Explore Lumenreach"
    local progressText = "Speak with the Lumen Guide"

    if active then
        local questId, state = next(active)
        if questId then
            local catalog = CatalogClient.Get()
            local definition = catalog and catalog.Quests and catalog.Quests[questId]
            title = definition and definition.DisplayName or tostring(questId)
            local objective = definition and definition.Objectives and definition.Objectives[1]
            local progress = state.Progress and state.Progress[1] or 0
            if state.ReadyToTurnIn then
                progressText = "Return to the Lumen Guide"
            elseif objective then
                progressText =
                    string.format("Defeat targets: %d / %d", progress, objective.Required or 1)
            end
        end
    end

    return React.createElement(Panel, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 22, 0.5, -20),
        Size = UDim2.fromOffset(318, 92),
        Visible = not props.Hidden,
        Children = {
            Header = React.createElement(Label, {
                Position = UDim2.fromOffset(14, 8),
                Size = UDim2.new(1, -28, 0, 22),
                Text = "OBJECTIVE",
                TextSize = 12,
                Bold = true,
            }),
            Title = React.createElement(Label, {
                Position = UDim2.fromOffset(14, 31),
                Size = UDim2.new(1, -28, 0, 25),
                Text = title,
                TextSize = 15,
            }),
            Progress = React.createElement(Label, {
                Position = UDim2.fromOffset(14, 57),
                Size = UDim2.new(1, -28, 0, 22),
                Text = progressText,
                TextSize = 12,
                Color = COLORS.Muted,
            }),
        },
    })
end

local function HUD(props)
    local profile = props.Profile or {}
    local level = tonumber(profile.Level) or 1
    local exp = tonumber(profile.Exp) or 0
    local needed = ProgressionMath.ExpToNextLevel(level)
    local resources = profile.Resources or {}
    local derived = profile.Derived or {}
    local currencies = profile.Currencies or {}
    local currentMP = tonumber(resources.CurrentMP) or 0
    local maxMP = tonumber(derived.MaxMP) or 1

    return React.createElement(React.Fragment, nil, {
        Status = React.createElement(Panel, {
            Position = UDim2.fromOffset(22, 22),
            Size = UDim2.fromOffset(316, 112),
            Children = {
                Level = React.createElement(Label, {
                    Position = UDim2.fromOffset(18, 8),
                    Size = UDim2.fromOffset(150, 28),
                    Text = string.format("LV. %d", level),
                    TextSize = 18,
                    Bold = true,
                }),
                HP = React.createElement(Bar, {
                    Position = UDim2.fromOffset(18, 42),
                    Size = UDim2.fromOffset(276, 22),
                    Value = props.Health,
                    Maximum = props.MaxHealth,
                    Color = COLORS.Health,
                    Text = string.format(
                        "HP  %d / %d",
                        math.floor(props.Health + 0.5),
                        math.floor(props.MaxHealth + 0.5)
                    ),
                }),
                MP = React.createElement(Bar, {
                    Position = UDim2.fromOffset(18, 72),
                    Size = UDim2.fromOffset(276, 22),
                    Value = currentMP,
                    Maximum = maxMP,
                    Color = COLORS.Mana,
                    Text = string.format("MP  %d / %d", math.floor(currentMP), math.floor(maxMP)),
                }),
            },
        }),
        Currency = React.createElement(Panel, {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -22, 0, 96),
            Size = UDim2.fromOffset(224, 72),
            Children = {
                Shards = React.createElement(Label, {
                    Position = UDim2.fromOffset(14, 8),
                    Size = UDim2.new(1, -28, 0, 26),
                    Text = string.format("◇ %d Shards", tonumber(currencies.Shards) or 0),
                    Align = Enum.TextXAlignment.Right,
                }),
                Marks = React.createElement(Label, {
                    Position = UDim2.fromOffset(14, 36),
                    Size = UDim2.new(1, -28, 0, 26),
                    Text = string.format("✦ %d Marks", tonumber(currencies.Marks) or 0),
                    Align = Enum.TextXAlignment.Right,
                }),
            },
        }),
        Objective = React.createElement(Objective, {
            Profile = profile,
            Hidden = props.DialogueOpen,
        }),
        Exp = React.createElement(
            "Frame",
            {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, -101),
                Size = UDim2.fromOffset(616, 13),
                BackgroundColor3 = Color3.fromRGB(27, 32, 31),
                BorderSizePixel = 0,
                ClipsDescendants = true,
            },
            roundedChildren({
                Fill = React.createElement("Frame", {
                    Size = UDim2.fromScale(ratio(exp, needed), 1),
                    BackgroundColor3 = COLORS.Exp,
                    BorderSizePixel = 0,
                }, roundedChildren(nil, 6)),
            }, 6)
        ),
        ExpText = React.createElement(Label, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -116),
            Size = UDim2.fromOffset(300, 18),
            Text = string.format("EXP %d / %d", exp, needed),
            TextSize = 11,
            Align = Enum.TextXAlignment.Center,
        }),
        Hotbar = React.createElement(Hotbar, {
            Profile = profile,
        }),
    })
end

local function Dialogue(props)
    local description = props.Description
    local profile = props.Profile or {}
    local status, setStatus = React.useState("E to interact · Left click to attack · Q to dodge")
    if not description then
        return nil
    end

    local questId = description.QuestOffers and description.QuestOffers[1]
    local quests = profile.Quests or {}
    local completed = questId ~= nil and quests.Completed and quests.Completed[questId] == true
    local activeState = questId ~= nil and quests.Active and quests.Active[questId] or nil
    local active = activeState ~= nil
    local readyToTurnIn = activeState ~= nil and activeState.ReadyToTurnIn == true
    local questButtonText = if completed
        then "QUEST COMPLETED"
        else if readyToTurnIn
            then "TURN IN QUEST"
            else if active then "QUEST ACTIVE" else "ACCEPT QUEST"
    local questButtonEnabled = questId ~= nil and not completed and (not active or readyToTurnIn)

    local function activateQuestButton()
        if not questButtonEnabled then
            return
        end
        local action = if readyToTurnIn then "quest.turnin" else "quest.start"
        local ok, result = ActionClient.Invoke(action, {
            NpcId = description.NpcId,
            QuestId = questId,
        })
        if ok then
            setStatus(
                if readyToTurnIn then "Quest turned in. Rewards received." else "Quest accepted."
            )
        else
            setStatus(string.format("Quest: %s", tostring(result)))
        end
    end

    local function buyTonic()
        if not description.ShopId then
            return
        end
        local ok, result = ActionClient.Invoke("shop.buy", {
            ShopId = description.ShopId,
            ItemId = "small_tonic",
            Quantity = 1,
        })
        setStatus(
            if ok then "Small Tonic purchased." else string.format("Shop: %s", tostring(result))
        )
    end

    local buttonChildren = {}
    if questId then
        buttonChildren.Quest = React.createElement("TextButton", {
            Position = UDim2.fromOffset(22, 166),
            Size = UDim2.fromOffset(250, 48),
            BackgroundColor3 = Color3.fromRGB(45, 65, 61),
            BorderSizePixel = 0,
            Text = questButtonText,
            TextColor3 = if questButtonEnabled then COLORS.Text else COLORS.Muted,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = questButtonEnabled,
            Active = questButtonEnabled,
            [React.Event.Activated] = activateQuestButton,
        }, roundedChildren(nil, 9))
    end
    if description.ShopId then
        buttonChildren.Shop = React.createElement("TextButton", {
            Position = UDim2.fromOffset(286, 166),
            Size = UDim2.fromOffset(272, 48),
            BackgroundColor3 = Color3.fromRGB(45, 65, 61),
            BorderSizePixel = 0,
            Text = "BUY SMALL TONIC · 2 SHARDS",
            TextColor3 = COLORS.Text,
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = true,
            [React.Event.Activated] = buyTonic,
        }, roundedChildren(nil, 9))
    end

    return React.createElement(Panel, {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.fromScale(0.5, 0.72),
        Size = UDim2.fromOffset(580, 236),
        ZIndex = 20,
        Children = {
            Title = React.createElement(Label, {
                Position = UDim2.fromOffset(22, 14),
                Size = UDim2.new(1, -92, 0, 34),
                Text = description.DisplayName or "Traveler",
                TextSize = 24,
                Bold = true,
                Color = Color3.fromRGB(196, 236, 211),
                ZIndex = 21,
            }),
            Close = React.createElement("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -16, 0, 14),
                Size = UDim2.fromOffset(42, 36),
                BackgroundColor3 = Color3.fromRGB(47, 53, 52),
                BorderSizePixel = 0,
                Text = "×",
                TextColor3 = COLORS.Text,
                TextSize = 22,
                Font = Enum.Font.GothamBold,
                ZIndex = 22,
                [React.Event.Activated] = props.OnClose,
            }, roundedChildren(nil, 8)),
            Body = React.createElement(Label, {
                Position = UDim2.fromOffset(22, 55),
                Size = UDim2.new(1, -44, 0, 68),
                Text = "The grove beyond the camp is stirring. Test your strength there, then return when you're ready to travel deeper into Lumenreach.",
                TextSize = 16,
                Wrapped = true,
                VerticalAlign = Enum.TextYAlignment.Top,
                ZIndex = 21,
            }),
            Status = React.createElement(Label, {
                Position = UDim2.fromOffset(22, 126),
                Size = UDim2.new(1, -44, 0, 26),
                Text = status,
                TextSize = 13,
                Color = COLORS.Muted,
                ZIndex = 21,
            }),
            Buttons = React.createElement(React.Fragment, nil, buttonChildren),
        },
    })
end

local function MainMenu(props)
    local profile = props.Profile or {}
    local activeTab, setActiveTab = React.useState("CHARACTER")
    local status, setStatus = React.useState("M toggles menu · Esc closes")
    local catalog = CatalogClient.Get() or {}
    local tabs = { "CHARACTER", "INVENTORY", "SKILLS", "QUESTS", "SETTINGS" }

    local function invoke(action, payload, successText)
        local ok, result = ActionClient.Invoke(action, payload)
        if ok then
            setStatus(successText or "Updated.")
        else
            setStatus(string.format("%s: %s", action, tostring(result)))
        end
    end

    local bodyLines = {}
    local actionChildren = {}
    local actionCount = 0

    local function addAction(key, text, callback, width)
        local buttonWidth = width or 116
        local x = 22 + actionCount * (buttonWidth + 10)
        actionCount += 1
        actionChildren[key] = React.createElement("TextButton", {
            Position = UDim2.fromOffset(x, 390),
            Size = UDim2.fromOffset(buttonWidth, 42),
            BackgroundColor3 = Color3.fromRGB(45, 65, 61),
            BorderSizePixel = 0,
            Text = text,
            TextColor3 = COLORS.Text,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = true,
            ZIndex = 32,
            [React.Event.Activated] = callback,
        }, roundedChildren(nil, 7))
    end

    if activeTab == "CHARACTER" then
        local stats = profile.Stats or {}
        bodyLines = {
            string.format(
                "Level %d · AP %d · SP %d",
                tonumber(profile.Level) or 1,
                tonumber(profile.AP) or 0,
                tonumber(profile.SP) or 0
            ),
            string.format("Might %d", tonumber(stats.Might) or 0),
            string.format("Finesse %d", tonumber(stats.Finesse) or 0),
            string.format("Insight %d", tonumber(stats.Insight) or 0),
            string.format("Fortune %d", tonumber(stats.Fortune) or 0),
            string.format("Advancement Tier %d", tonumber(profile.AdvancementTier) or 0),
        }
        for _, statName in { "Might", "Finesse", "Insight", "Fortune" } do
            addAction("Add" .. statName, "+1 " .. string.upper(statName), function()
                invoke("stat.allocate", { StatName = statName, Amount = 1 }, "+1 " .. statName)
            end, 136)
        end
    elseif activeTab == "INVENTORY" then
        local inventory = profile.Inventory or {}
        local firstConsumable = nil
        local firstEquipment = nil
        for index, slot in inventory.Slots or {} do
            local definition = catalog.Items and catalog.Items[slot.ItemId]
            table.insert(
                bodyLines,
                string.format(
                    "%02d  %s  x%d",
                    index,
                    definition and definition.DisplayName or tostring(slot.ItemId),
                    tonumber(slot.Quantity) or 0
                )
            )
            if definition and definition.Type == "Consumable" and not firstConsumable then
                firstConsumable = { Index = index, ItemId = slot.ItemId }
            elseif definition and definition.Type == "Equipment" and not firstEquipment then
                firstEquipment = { Index = index, ItemId = slot.ItemId }
            end
        end
        if #bodyLines == 0 then
            bodyLines = { "Inventory is empty." }
        end
        local equipment = profile.Equipment or {}
        table.insert(bodyLines, "")
        table.insert(bodyLines, "EQUIPPED")
        for _, slotName in { "Weapon", "Head", "Body", "Legs", "Accessory", "Ring1", "Ring2" } do
            local itemId = equipment[slotName]
            local definition = itemId and itemId ~= "" and catalog.Items and catalog.Items[itemId]
            table.insert(
                bodyLines,
                string.format("%s: %s", slotName, definition and definition.DisplayName or "—")
            )
        end
        if firstConsumable then
            addAction("UseItem", "USE " .. string.upper(firstConsumable.ItemId), function()
                invoke("inventory.use", { ItemId = firstConsumable.ItemId }, "Consumable used.")
            end, 170)
        end
        if firstEquipment then
            addAction("EquipItem", "EQUIP ITEM", function()
                invoke(
                    "equipment.equip",
                    { InventoryIndex = firstEquipment.Index },
                    "Item equipped."
                )
            end, 150)
        end
        if equipment.Weapon and equipment.Weapon ~= "" then
            addAction("UnequipWeapon", "UNEQUIP WEAPON", function()
                invoke("equipment.unequip", { Slot = "Weapon" }, "Weapon unequipped.")
            end, 170)
        end
    elseif activeTab == "SKILLS" then
        local skills = profile.Skills or {}
        for skillId, rank in skills.Learned or {} do
            local definition = catalog.Skills and catalog.Skills[skillId]
            table.insert(
                bodyLines,
                string.format(
                    "%s  Rank %s",
                    definition and definition.DisplayName or tostring(skillId),
                    tostring(rank)
                )
            )
        end
        if #bodyLines == 0 then
            bodyLines = { "No skills learned yet." }
        end
        table.insert(bodyLines, "")
        table.insert(bodyLines, "Press 1–8 in gameplay to use assigned hotbar skills.")
        addAction("LearnStrike", "RANK UP STRIKE", function()
            invoke("skill.learn", { SkillId = "beginner_strike" }, "Beginner Strike ranked up.")
        end, 170)
        addAction("AssignStrike", "ASSIGN SLOT 1", function()
            invoke(
                "skill.hotbar",
                { Index = 1, SkillId = "beginner_strike" },
                "Beginner Strike assigned to slot 1."
            )
        end, 160)
        addAction("UseStrike", "USE SLOT 1", function()
            invoke("skill.use", { SkillId = "beginner_strike" }, "Beginner Strike used.")
        end, 140)
    elseif activeTab == "QUESTS" then
        local quests = profile.Quests or {}
        table.insert(bodyLines, "ACTIVE")
        local activeCount = 0
        for questId, state in quests.Active or {} do
            activeCount += 1
            local definition = catalog.Quests and catalog.Quests[questId]
            local suffix = if state.ReadyToTurnIn then " · READY TO TURN IN" else ""
            table.insert(
                bodyLines,
                (definition and definition.DisplayName or tostring(questId)) .. suffix
            )
        end
        if activeCount == 0 then
            table.insert(bodyLines, "No active quests.")
        end
        table.insert(bodyLines, "")
        table.insert(bodyLines, "COMPLETED")
        local completedCount = 0
        for questId, done in quests.Completed or {} do
            if done then
                completedCount += 1
                local definition = catalog.Quests and catalog.Quests[questId]
                table.insert(bodyLines, definition and definition.DisplayName or tostring(questId))
            end
        end
        if completedCount == 0 then
            table.insert(bodyLines, "None yet.")
        end
    else
        local settings = profile.Settings or {}
        local music = tonumber(settings.MusicVolume) or 1
        local sfx = tonumber(settings.SfxVolume) or 1
        bodyLines = {
            string.format("Music Volume: %d%%", math.floor(music * 100 + 0.5)),
            string.format("SFX Volume: %d%%", math.floor(sfx * 100 + 0.5)),
            string.format(
                "Damage Numbers: %s",
                settings.ShowDamageNumbers == false and "Off" or "On"
            ),
        }
        addAction("MusicDown", "MUSIC -", function()
            invoke("settings.update", { Key = "MusicVolume", Value = math.max(0, music - 0.1) })
        end, 110)
        addAction("MusicUp", "MUSIC +", function()
            invoke("settings.update", { Key = "MusicVolume", Value = math.min(1, music + 0.1) })
        end, 110)
        addAction("SfxDown", "SFX -", function()
            invoke("settings.update", { Key = "SfxVolume", Value = math.max(0, sfx - 0.1) })
        end, 110)
        addAction("SfxUp", "SFX +", function()
            invoke("settings.update", { Key = "SfxVolume", Value = math.min(1, sfx + 0.1) })
        end, 110)
        addAction(
            "DamageToggle",
            "DAMAGE " .. (settings.ShowDamageNumbers == false and "ON" or "OFF"),
            function()
                invoke(
                    "settings.update",
                    { Key = "ShowDamageNumbers", Value = settings.ShowDamageNumbers == false },
                    "Damage-number preference updated."
                )
            end,
            120
        )
    end

    local tabChildren = {}
    for index, tabName in tabs do
        tabChildren[tabName] = React.createElement("TextButton", {
            Position = UDim2.fromOffset(18 + (index - 1) * 128, 62),
            Size = UDim2.fromOffset(118, 38),
            BackgroundColor3 = if activeTab == tabName
                then Color3.fromRGB(61, 100, 84)
                else COLORS.PanelSoft,
            BorderSizePixel = 0,
            Text = tabName,
            TextColor3 = COLORS.Text,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            ZIndex = 31,
            [React.Event.Activated] = function()
                setActiveTab(tabName)
                setStatus(tabName .. " panel")
            end,
        }, roundedChildren(nil, 7))
    end

    local bodyText = table.concat(bodyLines, "\n")
    return React.createElement(Panel, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(666, 470),
        ZIndex = 30,
        Children = {
            Title = React.createElement(Label, {
                Position = UDim2.fromOffset(20, 14),
                Size = UDim2.new(1, -90, 0, 34),
                Text = "EVERLEAF",
                TextSize = 25,
                Bold = true,
                Color = Color3.fromRGB(196, 236, 211),
                ZIndex = 31,
            }),
            Close = React.createElement("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -16, 0, 14),
                Size = UDim2.fromOffset(42, 36),
                BackgroundColor3 = Color3.fromRGB(47, 53, 52),
                BorderSizePixel = 0,
                Text = "×",
                TextColor3 = COLORS.Text,
                TextSize = 22,
                Font = Enum.Font.GothamBold,
                ZIndex = 32,
                [React.Event.Activated] = props.OnClose,
            }, roundedChildren(nil, 8)),
            Tabs = React.createElement(React.Fragment, nil, tabChildren),
            Body = React.createElement(Label, {
                Position = UDim2.fromOffset(24, 118),
                Size = UDim2.new(1, -48, 0, 230),
                Text = bodyText,
                TextSize = 15,
                VerticalAlign = Enum.TextYAlignment.Top,
                Wrapped = true,
                ZIndex = 31,
            }),
            Status = React.createElement(Label, {
                Position = UDim2.fromOffset(24, 352),
                Size = UDim2.new(1, -48, 0, 28),
                Text = status,
                TextSize = 12,
                Color = COLORS.Muted,
                ZIndex = 31,
            }),
            Actions = React.createElement(React.Fragment, nil, actionChildren),
        },
    })
end

local function DeathOverlay()
    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(5, 8, 8),
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        ZIndex = 80,
    }, {
        Title = React.createElement(Label, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.46),
            Size = UDim2.fromOffset(420, 54),
            Text = "FALLEN",
            TextSize = 34,
            Bold = true,
            Align = Enum.TextXAlignment.Center,
            ZIndex = 81,
        }),
        Subtitle = React.createElement(Label, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.53),
            Size = UDim2.fromOffset(520, 34),
            Text = "Returning to Lumenreach Wayfarer Camp...",
            TextSize = 16,
            Color = COLORS.Muted,
            Align = Enum.TextXAlignment.Center,
            ZIndex = 81,
        }),
    })
end

local function App()
    local profile, setProfile = React.useState(ProfileStore.Get())
    local interaction, setInteraction = React.useState(nil)
    local menuOpen, setMenuOpen = React.useState(false)
    local health, setHealth = React.useState(100)
    local maxHealth, setMaxHealth = React.useState(100)
    local dead, setDead = React.useState(false)

    React.useEffect(function()
        local connection = ProfileStore.Subscribe(setProfile)
        return function()
            connection:Disconnect()
        end
    end, {})

    React.useEffect(function()
        local healthConnection = nil
        local maxConnection = nil

        local bindGeneration = 0

        local function bindCharacter(character)
            bindGeneration += 1
            local generation = bindGeneration

            if healthConnection then
                healthConnection:Disconnect()
                healthConnection = nil
            end
            if maxConnection then
                maxConnection:Disconnect()
                maxConnection = nil
            end

            setInteraction(nil)
            setMenuOpen(false)
            setDead(false)
            player:SetAttribute("EverLeafUiCapture", false)

            local humanoid = character:WaitForChild("Humanoid")
            if generation ~= bindGeneration or character ~= player.Character then
                return
            end

            setHealth(humanoid.Health)
            setMaxHealth(humanoid.MaxHealth)
            setDead(humanoid.Health <= 0)
            healthConnection = humanoid.HealthChanged:Connect(function(value)
                if generation ~= bindGeneration then
                    return
                end
                setHealth(value)
                setDead(value <= 0)
            end)
            maxConnection = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
                if generation == bindGeneration then
                    setMaxHealth(humanoid.MaxHealth)
                end
            end)
        end

        local characterConnection = player.CharacterAdded:Connect(bindCharacter)
        if player.Character then
            task.spawn(bindCharacter, player.Character)
        end

        return function()
            characterConnection:Disconnect()
            if healthConnection then
                healthConnection:Disconnect()
            end
            if maxConnection then
                maxConnection:Disconnect()
            end
        end
    end, {})

    React.useEffect(function()
        local remotes = ReplicatedStorage:FindFirstChild(Net.RemoteFolderName)
        local remote = remotes and remotes:FindFirstChild(Net.Events.InteractionEvent)
        if not remote or not remote:IsA("RemoteEvent") then
            warn("[ReactUI] InteractionEvent was not found")
            return nil
        end

        local connection = remote.OnClientEvent:Connect(function(eventName, payload)
            if eventName == "open" and type(payload) == "table" then
                setInteraction(payload)
            end
        end)
        return function()
            connection:Disconnect()
        end
    end, {})

    React.useEffect(function()
        player:SetAttribute("EverLeafUiCapture", interaction ~= nil or menuOpen or dead)
        return function()
            player:SetAttribute("EverLeafUiCapture", false)
        end
    end, { interaction, menuOpen, dead })

    React.useEffect(function()
        local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or dead then
                return
            end

            if input.KeyCode == Enum.KeyCode.M and interaction == nil then
                setMenuOpen(not menuOpen)
                return
            end

            if input.KeyCode == Enum.KeyCode.Escape then
                if interaction ~= nil then
                    setInteraction(nil)
                elseif menuOpen then
                    setMenuOpen(false)
                end
            end
        end)
        return function()
            connection:Disconnect()
        end
    end, { interaction, menuOpen, dead })

    return React.createElement("ScreenGui", {
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        DisplayOrder = 10,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, {
        HUD = React.createElement(HUD, {
            Profile = profile,
            Health = health,
            MaxHealth = maxHealth,
            DialogueOpen = interaction ~= nil or menuOpen,
        }),
        Menu = menuOpen and React.createElement(MainMenu, {
            Profile = profile,
            OnClose = function()
                setMenuOpen(false)
            end,
        }) or nil,
        Dialogue = interaction and React.createElement(Dialogue, {
            Description = interaction,
            Profile = profile,
            OnClose = function()
                setInteraction(nil)
            end,
        }) or nil,
        Death = dead and React.createElement(DeathOverlay) or nil,
    })
end

function ReactUIController.Start()
    local playerGui = player:WaitForChild("PlayerGui")
    local existing = playerGui:FindFirstChild("EverLeafReactMount")
    if existing then
        existing:Destroy()
    end

    local mount = Instance.new("Folder")
    mount.Name = "EverLeafReactMount"
    mount.Parent = playerGui

    reactRoot = ReactRoblox.createRoot(mount)
    reactRoot:render(React.createElement(App))
end

return ReactUIController
