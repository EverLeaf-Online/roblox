local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local ActionClient = require(script.Parent.Parent.Parent.Services.ActionClient)
local PartyStore = require(script.Parent.Parent.Parent.State.PartyStore)
local NotificationStore = require(script.Parent.Parent.NotificationStore)

local localPlayer = Players.LocalPlayer

local function runPartyAction(action, payload, successText, setStatus)
    local ok, result = ActionClient.Invoke(action, payload or {})
    if not ok then
        local message = tostring(result or "party_action_failed")
        setStatus(message)
        NotificationStore.Push("error", "Party Action Failed", message, 3.5)
        return false, result
    end
    if type(result) == "table" and result.Members then
        PartyStore.Seed(result)
    elseif action == "party.leave" then
        PartyStore.Seed(nil)
    end
    setStatus(successText or "Party updated.")
    return true, result
end

local function onlineCandidates(party)
    local inParty = {}
    for _, member in party and party.Members or {} do
        inParty[member.UserId] = true
    end
    local candidates = {}
    for _, player in Players:GetPlayers() do
        if player ~= localPlayer and not inParty[player.UserId] then
            table.insert(candidates, { UserId = player.UserId, Name = player.Name })
        end
    end
    table.sort(candidates, function(a, b)
        return string.lower(a.Name) < string.lower(b.Name)
    end)
    return candidates
end

local function readyStateFor(readyCheck, userId)
    for _, member in readyCheck and readyCheck.Members or {} do
        if member.UserId == userId then
            return member.Ready == true
        end
    end
    return false
end

local function readyCount(readyCheck)
    local count = 0
    for _, member in readyCheck and readyCheck.Members or {} do
        if member.Ready == true then
            count += 1
        end
    end
    return count
end

local function PartyOverlay(props)
    local partyState = props.PartyState or {}
    local party = partyState.Party
    local invite = partyState.Invite
    local readyCheck = partyState.ReadyCheck
    local topCardVisible = invite ~= nil or readyCheck ~= nil
    local status, setStatus = React.useState("Party actions are server-authoritative.")
    local candidates, setCandidates = React.useState(onlineCandidates(party))

    React.useEffect(function()
        local function refresh()
            setCandidates(onlineCandidates(party))
        end
        refresh()
        local added = Players.PlayerAdded:Connect(refresh)
        local removing = Players.PlayerRemoving:Connect(refresh)
        return function()
            added:Disconnect()
            removing:Disconnect()
        end
    end, { party })

    local isLeader = party and party.LeaderUserId == localPlayer.UserId
    local selfReady = readyStateFor(readyCheck, localPlayer.UserId)
    local memberRows = {}
    for index, member in party and party.Members or {} do
        local memberIsLeader = member.UserId == party.LeaderUserId
        local memberReady = readyStateFor(readyCheck, member.UserId)
        local canKick = isLeader
            and not memberIsLeader
            and member.UserId ~= localPlayer.UserId
            and readyCheck == nil
        memberRows["PartyMember_" .. tostring(member.UserId)] = React.createElement("Frame", {
            Position = UDim2.fromOffset(0, (index - 1) * 48),
            Size = UDim2.new(1, -6, 0, 42),
            BackgroundColor3 = Color3.fromRGB(20, 31, 29),
            BorderSizePixel = 0,
            ZIndex = 63,
        }, {
            Rail = React.createElement("Frame", {
                Size = UDim2.fromOffset(4, 42),
                BackgroundColor3 = memberIsLeader and Color3.fromRGB(213, 168, 87)
                    or Color3.fromRGB(101, 211, 154),
                BorderSizePixel = 0,
                ZIndex = 64,
            }),
            Name = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(13, 4),
                Size = UDim2.new(1, -116, 0, 19),
                BackgroundTransparency = 1,
                Text = member.Name,
                TextColor3 = Color3.fromRGB(235, 244, 239),
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 64,
            }),
            Role = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(13, 23),
                Size = UDim2.new(1, -116, 0, 14),
                BackgroundTransparency = 1,
                Text = memberIsLeader and "PARTY LEADER"
                    or (member.UserId == localPlayer.UserId and "YOU" or "MEMBER"),
                TextColor3 = memberIsLeader and Color3.fromRGB(232, 193, 105)
                    or Color3.fromRGB(139, 169, 154),
                TextSize = 8,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 64,
            }),
            Ready = readyCheck and React.createElement("TextLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(74, 24),
                BackgroundTransparency = 1,
                Text = memberReady and "READY" or "WAITING",
                TextColor3 = memberReady and Color3.fromRGB(121, 244, 183)
                    or Color3.fromRGB(211, 161, 96),
                TextSize = 8,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 65,
            }) or nil,
            PartyKick = canKick
                    and React.createElement("TextButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -8, 0.5, 0),
                        Size = UDim2.fromOffset(76, 28),
                        BackgroundColor3 = Color3.fromRGB(78, 43, 43),
                        BorderSizePixel = 0,
                        Text = "REMOVE",
                        TextColor3 = Color3.fromRGB(237, 187, 184),
                        TextSize = 8,
                        Font = Enum.Font.GothamBold,
                        Selectable = true,
                        ZIndex = 65,
                        [React.Event.Activated] = function()
                            runPartyAction(
                                "party.kick",
                                { TargetUserId = member.UserId },
                                member.Name .. " removed from party.",
                                setStatus
                            )
                        end,
                    }, {
                        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 5) }),
                    })
                or nil,
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
        })
    end

    local candidateRows = {}
    for index, candidate in candidates do
        candidateRows["PartyInvite_" .. tostring(candidate.UserId)] = React.createElement(
            "TextButton",
            {
                Position = UDim2.fromOffset(0, (index - 1) * 42),
                Size = UDim2.new(1, -6, 0, 36),
                BackgroundColor3 = Color3.fromRGB(23, 38, 34),
                BorderSizePixel = 0,
                Text = "INVITE  ·  " .. candidate.Name,
                TextColor3 = Color3.fromRGB(194, 226, 210),
                TextSize = 9,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Selectable = true,
                ZIndex = 64,
                [React.Event.Activated] = function()
                    runPartyAction(
                        "party.invite",
                        { TargetUserId = candidate.UserId },
                        "Invite sent to " .. candidate.Name .. ".",
                        setStatus
                    )
                end,
            },
            {
                Padding = React.createElement("UIPadding", { PaddingLeft = UDim.new(0, 12) }),
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 5) }),
                Stroke = React.createElement("UIStroke", {
                    Color = Color3.fromRGB(76, 124, 101),
                    Transparency = 0.55,
                }),
            }
        )
    end

    local function respondReady(accepted)
        local ok, result = ActionClient.Invoke("party.ready.respond", { Accepted = accepted })
        if not ok then
            local message = tostring(result or "ready_check_failed")
            setStatus(message)
            NotificationStore.Push("error", "Ready Check Failed", message, 3.5)
            return
        end
        setStatus(if accepted then "Ready confirmed." else "Ready check declined.")
    end

    local primaryText = party and "LEAVE PARTY" or "CREATE PARTY"
    local primaryAction = party and "party.leave" or "party.create"
    local leftTop = topCardVisible and 184 or 82
    local sectionTop = leftTop + 53
    local listTop = sectionTop + 23
    local listHeight = math.max(120, 438 - listTop)
    local canInvite = isLeader and readyCheck == nil

    return React.createElement(React.Fragment, nil, {
        Backdrop = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(4, 8, 7),
            BackgroundTransparency = 0.44,
            BorderSizePixel = 0,
            ZIndex = 58,
        }),
        Window = React.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(720, 520),
            BackgroundColor3 = Color3.fromRGB(10, 18, 17),
            BorderSizePixel = 0,
            ZIndex = 60,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 9) }),
            Stroke = React.createElement("UIStroke", {
                Color = Color3.fromRGB(94, 151, 122),
                Transparency = 0.22,
                Thickness = 1.2,
            }),
            HeaderRail = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 4),
                BackgroundColor3 = Color3.fromRGB(101, 211, 154),
                BorderSizePixel = 0,
                ZIndex = 62,
            }),
            Title = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(22, 17),
                Size = UDim2.fromOffset(330, 30),
                BackgroundTransparency = 1,
                Text = "WAYFARER PARTY",
                TextColor3 = Color3.fromRGB(205, 255, 229),
                TextSize = 20,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 62,
            }),
            Meta = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(22, 47),
                Size = UDim2.fromOffset(500, 18),
                BackgroundTransparency = 1,
                Text = party and string.format(
                    "PARTY %d  ·  %d/%d MEMBERS",
                    party.Id or 0,
                    #party.Members,
                    party.MaxMembers or 6
                ) or "FORM A PARTY FOR GROUP QUESTING AND BELFORGE",
                TextColor3 = Color3.fromRGB(139, 169, 154),
                TextSize = 9,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 62,
            }),
            PartyClose = React.createElement("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -18, 0, 17),
                Size = UDim2.fromOffset(42, 34),
                BackgroundColor3 = Color3.fromRGB(28, 42, 38),
                BorderSizePixel = 0,
                Text = "×",
                TextColor3 = Color3.fromRGB(230, 241, 235),
                TextSize = 19,
                Font = Enum.Font.GothamBold,
                Selectable = true,
                ZIndex = 63,
                [React.Event.Activated] = props.OnClose,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
            }),
            InviteCard = invite
                    and React.createElement("Frame", {
                        Position = UDim2.fromOffset(22, 82),
                        Size = UDim2.new(1, -44, 0, 86),
                        BackgroundColor3 = Color3.fromRGB(31, 48, 39),
                        BorderSizePixel = 0,
                        ZIndex = 62,
                    }, {
                        Text = React.createElement("TextLabel", {
                            Position = UDim2.fromOffset(14, 8),
                            Size = UDim2.new(1, -214, 1, -16),
                            BackgroundTransparency = 1,
                            Text = string.format(
                                "%s invited you to a party.",
                                invite.FromName or "A Wayfarer"
                            ),
                            TextColor3 = Color3.fromRGB(231, 240, 235),
                            TextSize = 11,
                            Font = Enum.Font.GothamBold,
                            TextWrapped = true,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 63,
                        }),
                        PartyAccept = React.createElement("TextButton", {
                            AnchorPoint = Vector2.new(1, 0.5),
                            Position = UDim2.new(1, -102, 0.5, 0),
                            Size = UDim2.fromOffset(88, 34),
                            BackgroundColor3 = Color3.fromRGB(39, 88, 65),
                            BorderSizePixel = 0,
                            Text = "ACCEPT",
                            TextColor3 = Color3.fromRGB(205, 255, 229),
                            TextSize = 9,
                            Font = Enum.Font.GothamBold,
                            Selectable = true,
                            ZIndex = 64,
                            [React.Event.Activated] = function()
                                runPartyAction("party.accept", {}, "Party joined.", setStatus)
                            end,
                        }, {
                            Corner = React.createElement(
                                "UICorner",
                                { CornerRadius = UDim.new(0, 5) }
                            ),
                        }),
                        PartyDecline = React.createElement("TextButton", {
                            AnchorPoint = Vector2.new(1, 0.5),
                            Position = UDim2.new(1, -10, 0.5, 0),
                            Size = UDim2.fromOffset(82, 34),
                            BackgroundColor3 = Color3.fromRGB(55, 47, 43),
                            BorderSizePixel = 0,
                            Text = "DECLINE",
                            TextColor3 = Color3.fromRGB(207, 190, 175),
                            TextSize = 9,
                            Font = Enum.Font.GothamBold,
                            Selectable = true,
                            ZIndex = 64,
                            [React.Event.Activated] = function()
                                if
                                    runPartyAction(
                                        "party.decline",
                                        {},
                                        "Invite declined.",
                                        setStatus
                                    )
                                then
                                    PartyStore.Push({ Type = "InviteCleared" })
                                end
                            end,
                        }, {
                            Corner = React.createElement(
                                "UICorner",
                                { CornerRadius = UDim.new(0, 5) }
                            ),
                        }),
                        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 7) }),
                        Stroke = React.createElement("UIStroke", {
                            Color = Color3.fromRGB(102, 155, 130),
                            Transparency = 0.35,
                        }),
                    })
                or nil,
            ReadyCard = readyCheck
                    and React.createElement("Frame", {
                        Position = UDim2.fromOffset(22, 82),
                        Size = UDim2.new(1, -44, 0, 86),
                        BackgroundColor3 = Color3.fromRGB(48, 37, 27),
                        BorderSizePixel = 0,
                        ZIndex = 62,
                    }, {
                        Title = React.createElement("TextLabel", {
                            Position = UDim2.fromOffset(14, 8),
                            Size = UDim2.new(1, -220, 0, 20),
                            BackgroundTransparency = 1,
                            Text = "BELFORGE COLOSSUS · READY CHECK",
                            TextColor3 = Color3.fromRGB(247, 220, 173),
                            TextSize = 10,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 63,
                        }),
                        Body = React.createElement("TextLabel", {
                            Position = UDim2.fromOffset(14, 30),
                            Size = UDim2.new(1, -220, 0, 42),
                            BackgroundTransparency = 1,
                            Text = string.format(
                                "%s started the pull · %d/%d ready",
                                readyCheck.LeaderName or "Party leader",
                                readyCount(readyCheck),
                                #(readyCheck.Members or {})
                            ),
                            TextColor3 = Color3.fromRGB(196, 185, 164),
                            TextSize = 9,
                            Font = Enum.Font.GothamMedium,
                            TextWrapped = true,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 63,
                        }),
                        PartyReady = React.createElement("TextButton", {
                            AnchorPoint = Vector2.new(1, 0.5),
                            Position = UDim2.new(1, -102, 0.5, 0),
                            Size = UDim2.fromOffset(88, 34),
                            BackgroundColor3 = selfReady and Color3.fromRGB(39, 57, 48)
                                or Color3.fromRGB(39, 88, 65),
                            BorderSizePixel = 0,
                            Text = selfReady and "READY" or "I'M READY",
                            TextColor3 = selfReady and Color3.fromRGB(121, 184, 151)
                                or Color3.fromRGB(205, 255, 229),
                            TextSize = 9,
                            Font = Enum.Font.GothamBold,
                            Active = not selfReady,
                            AutoButtonColor = not selfReady,
                            Selectable = not selfReady,
                            ZIndex = 64,
                            [React.Event.Activated] = if selfReady
                                then nil
                                else function()
                                    respondReady(true)
                                end,
                        }, {
                            Corner = React.createElement(
                                "UICorner",
                                { CornerRadius = UDim.new(0, 5) }
                            ),
                        }),
                        PartyReadyDecline = React.createElement("TextButton", {
                            AnchorPoint = Vector2.new(1, 0.5),
                            Position = UDim2.new(1, -10, 0.5, 0),
                            Size = UDim2.fromOffset(82, 34),
                            BackgroundColor3 = Color3.fromRGB(79, 48, 43),
                            BorderSizePixel = 0,
                            Text = selfReady and "CANCEL" or "DECLINE",
                            TextColor3 = Color3.fromRGB(235, 190, 173),
                            TextSize = 9,
                            Font = Enum.Font.GothamBold,
                            Selectable = true,
                            ZIndex = 64,
                            [React.Event.Activated] = function()
                                respondReady(false)
                            end,
                        }, {
                            Corner = React.createElement(
                                "UICorner",
                                { CornerRadius = UDim.new(0, 5) }
                            ),
                        }),
                        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 7) }),
                        Stroke = React.createElement("UIStroke", {
                            Color = Color3.fromRGB(183, 126, 69),
                            Transparency = 0.28,
                        }),
                    })
                or nil,
            PartyPrimary = React.createElement("TextButton", {
                Position = UDim2.fromOffset(22, leftTop),
                Size = UDim2.fromOffset(180, 38),
                BackgroundColor3 = party and Color3.fromRGB(72, 44, 43)
                    or Color3.fromRGB(37, 80, 61),
                BorderSizePixel = 0,
                Text = primaryText,
                TextColor3 = party and Color3.fromRGB(230, 183, 179)
                    or Color3.fromRGB(205, 255, 229),
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                Selectable = true,
                ZIndex = 63,
                [React.Event.Activated] = function()
                    runPartyAction(
                        primaryAction,
                        {},
                        party and "You left the party." or "Party created.",
                        setStatus
                    )
                end,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
            }),
            MembersTitle = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(22, sectionTop),
                Size = UDim2.fromOffset(310, 20),
                BackgroundTransparency = 1,
                Text = party and "CURRENT MEMBERS" or "NO ACTIVE PARTY",
                TextColor3 = Color3.fromRGB(121, 244, 183),
                TextSize = 9,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 62,
            }),
            Members = React.createElement("ScrollingFrame", {
                Position = UDim2.fromOffset(22, listTop),
                Size = UDim2.fromOffset(320, listHeight),
                CanvasSize = UDim2.fromOffset(
                    0,
                    math.max(listHeight, party and #party.Members * 48 or 0)
                ),
                BackgroundColor3 = Color3.fromRGB(7, 14, 13),
                BackgroundTransparency = 0.12,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                ScrollBarImageColor3 = Color3.fromRGB(93, 156, 126),
                ZIndex = 62,
            }, memberRows),
            InviteTitle = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(370, leftTop),
                Size = UDim2.fromOffset(320, 20),
                BackgroundTransparency = 1,
                Text = readyCheck and "ROSTER LOCKED DURING READY CHECK"
                    or (isLeader and "INVITE ONLINE WAYFARERS" or "PARTY COMMAND"),
                TextColor3 = Color3.fromRGB(232, 193, 105),
                TextSize = 9,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 62,
            }),
            Candidates = React.createElement("ScrollingFrame", {
                Position = UDim2.fromOffset(370, leftTop + 25),
                Size = UDim2.fromOffset(328, math.max(120, 438 - (leftTop + 25))),
                CanvasSize = UDim2.fromOffset(
                    0,
                    math.max(180, canInvite and #candidates * 42 or 0)
                ),
                BackgroundColor3 = Color3.fromRGB(7, 14, 13),
                BackgroundTransparency = 0.12,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                ScrollBarImageColor3 = Color3.fromRGB(129, 108, 73),
                ZIndex = 62,
            }, canInvite and candidateRows or {
                Hint = React.createElement("TextLabel", {
                    Position = UDim2.fromOffset(14, 14),
                    Size = UDim2.new(1, -28, 0, 86),
                    BackgroundTransparency = 1,
                    Text = readyCheck
                            and "Finish or cancel the ready check before changing the party roster."
                        or (
                            party and "Only the party leader can invite or remove members."
                            or "Create a party to invite other Wayfarers in this server."
                        ),
                    TextColor3 = Color3.fromRGB(139, 169, 154),
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    ZIndex = 63,
                }),
            }),
            Status = React.createElement("TextLabel", {
                Position = UDim2.fromOffset(22, 478),
                Size = UDim2.new(1, -44, 0, 26),
                BackgroundTransparency = 1,
                Text = status,
                TextColor3 = Color3.fromRGB(139, 169, 154),
                TextSize = 9,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 62,
            }),
        }),
    })
end

return PartyOverlay
