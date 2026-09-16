local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local COLORS = table.freeze({
    Panel = Color3.fromRGB(16, 25, 23),
    Raised = Color3.fromRGB(28, 42, 38),
    Border = Color3.fromRGB(85, 127, 107),
    Text = Color3.fromRGB(239, 246, 242),
    Muted = Color3.fromRGB(159, 184, 172),
    Lumen = Color3.fromRGB(121, 244, 183),
    Warning = Color3.fromRGB(231, 165, 87),
})

local function remainingSeconds(event, now)
    local initial = math.max(0, tonumber(event.EndsIn) or 0)
    local received = tonumber(event.LocalReceivedAt) or now
    return math.max(0, initial - math.max(0, now - received))
end

local function PublicEventHud(props)
    local event = props.Event
    local now, setNow = React.useState(os.clock())

    React.useEffect(function()
        if not event then
            return nil
        end
        local active = true
        task.spawn(function()
            while active do
                task.wait(0.25)
                if active then
                    setNow(os.clock())
                end
            end
        end)
        return function()
            active = false
        end
    end, { event })

    if not event or props.Hidden then
        return nil
    end

    local seconds = remainingSeconds(event, now)
    if seconds <= 0 or (event.RegionId and props.RegionId and event.RegionId ~= props.RegionId) then
        return nil
    end
    local minutes = math.floor(seconds / 60)
    local remainder = math.floor(seconds % 60)
    local stage = math.max(1, tonumber(event.Stage) or 1)
    local stageCount = math.max(stage, tonumber(event.StageCount) or stage)
    local alive = math.max(0, tonumber(event.Alive) or 0)

    return React.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 72),
        Size = UDim2.fromOffset(360, 84),
        BackgroundColor3 = COLORS.Panel,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 18,
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 9) }),
        Stroke = React.createElement("UIStroke", {
            Color = COLORS.Border,
            Transparency = 0.2,
            Thickness = 1.2,
        }),
        Rail = React.createElement("Frame", {
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(5, 84),
            BackgroundColor3 = COLORS.Warning,
            BorderSizePixel = 0,
            ZIndex = 19,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 9) }),
        }),
        Type = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(18, 8),
            Size = UDim2.fromOffset(120, 15),
            BackgroundTransparency = 1,
            Text = "PUBLIC EVENT",
            TextColor3 = COLORS.Warning,
            TextSize = 8,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 19,
        }),
        Title = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(18, 23),
            Size = UDim2.new(1, -120, 0, 25),
            BackgroundTransparency = 1,
            Text = tostring(event.Title or "World Event"),
            TextColor3 = COLORS.Text,
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 19,
        }),
        Timer = React.createElement("TextLabel", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -15, 0, 12),
            Size = UDim2.fromOffset(72, 26),
            BackgroundColor3 = COLORS.Raised,
            BorderSizePixel = 0,
            Text = string.format("%d:%02d", minutes, remainder),
            TextColor3 = seconds <= 30 and COLORS.Warning or COLORS.Lumen,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            ZIndex = 19,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
        }),
        Progress = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(18, 52),
            Size = UDim2.new(1, -36, 0, 22),
            BackgroundTransparency = 1,
            Text = string.format("WAVE %d/%d   ·   %d HOSTILES REMAIN", stage, stageCount, alive),
            TextColor3 = COLORS.Muted,
            TextSize = 9,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 19,
        }),
    })
end

return PublicEventHud
