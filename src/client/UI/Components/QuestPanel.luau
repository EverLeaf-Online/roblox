local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local Primitives = require(script.Parent.Parent.Primitives)
local Theme = require(script.Parent.Parent.Theme)
local UiText = require(script.Parent.Parent.UiText)

local COLORS = Theme.Colors
local Button = Primitives.Button
local Label = Primitives.Label
local Panel = Primitives.Panel
local Pill = Primitives.Pill
local withChrome = Primitives.WithChrome

local function QuestPanel(props)
    local profile = props.Profile or {}
    local catalog = props.Catalog or {}
    local filter = props.Filter or "ACTIVE"
    local setFilter = props.OnFilterChanged or function() end
    local active = profile.Quests and profile.Quests.Active or {}
    local completed = profile.Quests and profile.Quests.Completed or {}
    local activeRows = {}
    local readyCount = 0
    for questId, state in active do
        if state.ReadyToTurnIn == true then
            readyCount += 1
        end
        table.insert(activeRows, { Id = questId, State = state })
    end
    table.sort(activeRows, function(a, b)
        if a.State.ReadyToTurnIn ~= b.State.ReadyToTurnIn then
            return a.State.ReadyToTurnIn == true
        end
        local aDefinition = catalog.Quests and catalog.Quests[a.Id]
        local bDefinition = catalog.Quests and catalog.Quests[b.Id]
        local aLevel = tonumber(aDefinition and aDefinition.MinimumLevel) or 0
        local bLevel = tonumber(bDefinition and bDefinition.MinimumLevel) or 0
        if aLevel ~= bLevel then
            return aLevel < bLevel
        end
        local aName = aDefinition and aDefinition.DisplayName or a.Id
        local bName = bDefinition and bDefinition.DisplayName or b.Id
        return aName < bName
    end)

    local completedRows = {}
    for questId, done in completed do
        if done then
            local definition = catalog.Quests and catalog.Quests[questId]
            table.insert(completedRows, {
                Id = questId,
                Name = definition and definition.DisplayName or questId,
                Definition = definition,
            })
        end
    end
    table.sort(completedRows, function(a, b)
        return a.Name < b.Name
    end)

    local filterButtons = {}
    local filters = {
        { Id = "ACTIVE", Count = #activeRows },
        { Id = "READY", Count = readyCount },
        { Id = "COMPLETED", Count = #completedRows },
    }
    for index, entry in filters do
        local selected = filter == entry.Id
        filterButtons["QuestFilter_" .. entry.Id] = React.createElement(Button, {
            Position = UDim2.fromOffset((index - 1) * 196, 0),
            Size = UDim2.fromOffset(186, 30),
            Text = string.format("%s · %d", entry.Id, entry.Count),
            TextSize = 9,
            Tone = selected and "accent" or nil,
            OnActivated = function()
                setFilter(entry.Id)
            end,
            ZIndex = 6,
        })
    end

    local listChildren = {}
    local y = 0
    if filter == "COMPLETED" then
        for _, row in completedRows do
            listChildren["Completed_" .. row.Id] = React.createElement(Panel, {
                Position = UDim2.fromOffset(0, y),
                Size = UDim2.new(1, -8, 0, 56),
                BackgroundColor3 = COLORS.PanelRaised,
                StrokeTransparency = 0.68,
                Children = {
                    Check = React.createElement(Label, {
                        Position = UDim2.fromOffset(12, 0),
                        Size = UDim2.fromOffset(28, 56),
                        Text = "✓",
                        TextSize = 15,
                        Bold = true,
                        Color = COLORS.Accent,
                        Align = Enum.TextXAlignment.Center,
                        ZIndex = 6,
                    }),
                    Name = React.createElement(Label, {
                        Position = UDim2.fromOffset(50, 8),
                        Size = UDim2.new(1, -62, 0, 22),
                        Text = row.Name,
                        TextSize = 12,
                        Bold = true,
                        Color = COLORS.Muted,
                        ZIndex = 6,
                    }),
                    Meta = React.createElement(Label, {
                        Position = UDim2.fromOffset(50, 31),
                        Size = UDim2.new(1, -62, 0, 16),
                        Text = string.format(
                            "Completed%s",
                            row.Definition
                                    and row.Definition.MinimumLevel
                                    and (" · Level " .. tostring(row.Definition.MinimumLevel))
                                or ""
                        ),
                        TextSize = 8,
                        Color = COLORS.Faint,
                        ZIndex = 6,
                    }),
                },
            })
            y += 64
        end
    else
        for _, row in activeRows do
            local ready = row.State.ReadyToTurnIn == true
            if filter == "ACTIVE" or ready then
                local definition = catalog.Quests and catalog.Quests[row.Id]
                local name = definition and definition.DisplayName or row.Id
                local objectives = definition and definition.Objectives or {}
                local progressLines = {}
                for index, objective in objectives do
                    table.insert(
                        progressLines,
                        UiText.ObjectiveText(
                            objective,
                            row.State.Progress and row.State.Progress[index] or 0
                        )
                    )
                end
                local height = 78 + math.max(0, #progressLines - 1) * 18
                listChildren[row.Id] = React.createElement(Panel, {
                    Position = UDim2.fromOffset(0, y),
                    Size = UDim2.new(1, -8, 0, height),
                    BackgroundColor3 = COLORS.PanelRaised,
                    StrokeColor = ready and COLORS.Gold or COLORS.Border,
                    StrokeTransparency = ready and 0.25 or 0.6,
                    Children = {
                        Status = React.createElement(Pill, {
                            Position = UDim2.fromOffset(12, 10),
                            Size = UDim2.fromOffset(ready and 96 or 64, 21),
                            Text = ready and "TURN IN" or "ACTIVE",
                            TextSize = 9,
                            Color = ready and Color3.fromRGB(94, 74, 42) or COLORS.AccentDark,
                            TextColor = ready and COLORS.Gold or COLORS.Accent,
                            ZIndex = 6,
                        }),
                        Level = React.createElement(Label, {
                            AnchorPoint = Vector2.new(1, 0),
                            Position = UDim2.new(1, -14, 0, 11),
                            Size = UDim2.fromOffset(90, 18),
                            Text = definition
                                    and definition.MinimumLevel
                                    and ("LEVEL " .. tostring(definition.MinimumLevel))
                                or "",
                            TextSize = 8,
                            Bold = true,
                            Align = Enum.TextXAlignment.Right,
                            Color = COLORS.Faint,
                            ZIndex = 6,
                        }),
                        Name = React.createElement(Label, {
                            Position = UDim2.fromOffset(12, 35),
                            Size = UDim2.new(1, -24, 0, 22),
                            Text = name,
                            TextSize = 13,
                            Bold = true,
                            ZIndex = 6,
                        }),
                        Progress = React.createElement(Label, {
                            Position = UDim2.fromOffset(12, 58),
                            Size = UDim2.new(1, -24, 0, math.max(18, #progressLines * 18)),
                            Text = #progressLines > 0 and table.concat(progressLines, "\n")
                                or "No objectives",
                            TextSize = 10,
                            Wrapped = true,
                            Color = COLORS.Muted,
                            VerticalAlign = Enum.TextYAlignment.Top,
                            ZIndex = 6,
                        }),
                    },
                })
                y += height + 10
            end
        end
    end

    if next(listChildren) == nil then
        local emptyText = if filter == "READY"
            then "No quests are ready to turn in."
            else if filter == "COMPLETED"
                then "No completed quests yet."
                else "No active quests. Talk to a Wayfarer or region contact."
        listChildren.Empty = React.createElement(Label, {
            Position = UDim2.fromOffset(16, 16),
            Size = UDim2.new(1, -32, 0, 48),
            Text = emptyText,
            TextSize = 11,
            Wrapped = true,
            Color = COLORS.Faint,
            ZIndex = 5,
        })
        y = 80
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, {
        Filters = React.createElement("Frame", {
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(598, 32),
            BackgroundTransparency = 1,
            ZIndex = 5,
        }, filterButtons),
        QuestList = React.createElement("ScrollingFrame", {
            Position = UDim2.fromOffset(0, 42),
            Size = UDim2.fromOffset(598, 344),
            CanvasSize = UDim2.fromOffset(0, math.max(344, y)),
            BackgroundColor3 = COLORS.PanelDeep,
            BackgroundTransparency = 0.18,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = COLORS.BorderStrong,
            ZIndex = 4,
        }, withChrome(listChildren, 10, COLORS.Border, 0.55, 1)),
    })
end

return QuestPanel
