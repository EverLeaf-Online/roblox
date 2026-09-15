local Players = game:GetService("Players")
local React = require(game:GetService("ReplicatedStorage").Packages.React)

local localPlayer = Players.LocalPlayer

local function healthSnapshot(party)
    local result = {}
    for _, member in party and party.Members or {} do
        local player = Players:GetPlayerByUserId(member.UserId)
        local character = player and player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        result[member.UserId] = {
            Health = humanoid and humanoid.Health or 0,
            MaxHealth = humanoid and humanoid.MaxHealth or 1,
            Online = player ~= nil,
        }
    end
    return result
end

local function PartyHud(props)
    local party = props.Party
    local health, setHealth = React.useState(healthSnapshot(party))

    React.useEffect(function()
        local alive = true
        task.spawn(function()
            while alive do
                setHealth(healthSnapshot(party))
                task.wait(0.25)
            end
        end)
        return function()
            alive = false
        end
    end, { party })

    if not party or not party.Members or #party.Members <= 1 or props.Hidden then
        return nil
    end

    local rows = {}
    for index, member in party.Members do
        local status = health[member.UserId] or { Health = 0, MaxHealth = 1, Online = false }
        local fraction = math.clamp(status.Health / math.max(1, status.MaxHealth), 0, 1)
        local isLeader = member.UserId == party.LeaderUserId
        local isSelf = member.UserId == localPlayer.UserId
        rows["Member_" .. tostring(member.UserId)] = React.createElement("Frame", {
            Position = UDim2.fromOffset(0, (index - 1) * 42),
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Color3.fromRGB(13, 22, 20),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ZIndex = 12,
        }, {
            Edge = React.createElement("Frame", {
                Size = UDim2.fromOffset(3, 36),
                BackgroundColor3 = isLeader and Color3.fromRGB(213, 168, 87)
                    or Color3.fromRGB(101, 211, 154),
                BorderSizePixel = 0,
                ZIndex = 13,
            }),
            Name = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(10, 3),
                Size = UDim2.new(1, -70, 0, 15),
                BackgroundTransparency = 1,
                Text = (isLeader and "LEADER · " or "")
                    .. (member.DisplayName or member.Name)
                    .. (member.Recognition and (" · " .. member.Recognition) or "")
                    .. (isSelf and " · YOU" or ""),
                TextColor3 = status.Online and Color3.fromRGB(230, 241, 235)
                    or Color3.fromRGB(115, 127, 121),
                TextSize = 9,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 13,
            }),
            Track = React.createElement("Frame", {
                Position = UDim2.fromOffset(10, 22),
                Size = UDim2.new(1, -20, 0, 7),
                BackgroundColor3 = Color3.fromRGB(37, 36, 33),
                BorderSizePixel = 0,
                ClipsDescendants = true,
                ZIndex = 13,
            }, {
                Fill = React.createElement("Frame", {
                    Size = UDim2.fromScale(fraction, 1),
                    BackgroundColor3 = Color3.fromRGB(176, 71, 73),
                    BorderSizePixel = 0,
                    ZIndex = 14,
                }),
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 3) }),
            }),
            Value = React.createElement("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -10, 0, 3),
                Size = UDim2.fromOffset(55, 15),
                BackgroundTransparency = 1,
                Text = status.Online and string.format("%d%%", math.floor(fraction * 100 + 0.5))
                    or "OFFLINE",
                TextColor3 = Color3.fromRGB(159, 178, 168),
                TextSize = 8,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 13,
            }),
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 5) }),
            Stroke = React.createElement("UIStroke", {
                Color = Color3.fromRGB(74, 111, 95),
                Transparency = 0.56,
                Thickness = 1,
            }),
        })
    end

    return React.createElement("Frame", {
        Position = UDim2.fromOffset(24, 242),
        Size = UDim2.fromOffset(238, 28 + #party.Members * 42),
        BackgroundColor3 = Color3.fromRGB(8, 15, 14),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 10,
    }, {
        Header = React.createElement("TextLabel", {
            Position = UDim2.fromOffset(10, 5),
            Size = UDim2.new(1, -20, 0, 16),
            BackgroundTransparency = 1,
            Text = string.format(
                "WAYFARER PARTY  ·  %d/%d",
                #party.Members,
                party.MaxMembers or 6
            ),
            TextColor3 = Color3.fromRGB(121, 244, 183),
            TextSize = 9,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 11,
        }),
        Rows = React.createElement("Frame", {
            Position = UDim2.fromOffset(10, 26),
            Size = UDim2.new(1, -20, 1, -30),
            BackgroundTransparency = 1,
            ZIndex = 11,
        }, rows),
        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 7) }),
        Stroke = React.createElement("UIStroke", {
            Color = Color3.fromRGB(82, 132, 108),
            Transparency = 0.38,
            Thickness = 1,
        }),
    })
end

return PartyHud
