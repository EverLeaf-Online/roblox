local function pose(...)
    return CFrame.Angles(...)
end

local function frame(time, poses)
    return table.freeze({ Time = time, Poses = table.freeze(poses) })
end

local skeleton = table.freeze({
    Idle = table.freeze({
        Duration = 1.8,
        Loop = true,
        Keyframes = table.freeze({
            frame(0, {
                BodyJoint = pose(0, 0, math.rad(-2)),
                LeftShoulder = pose(math.rad(4), 0, 0),
                RightShoulder = pose(math.rad(-4), 0, 0),
            }),
            frame(0.9, {
                BodyJoint = pose(0, 0, math.rad(2)),
                LeftShoulder = pose(math.rad(-5), 0, 0),
                RightShoulder = pose(math.rad(5), 0, 0),
            }),
            frame(1.8, {
                BodyJoint = pose(0, 0, math.rad(-2)),
                LeftShoulder = pose(math.rad(4), 0, 0),
                RightShoulder = pose(math.rad(-4), 0, 0),
            }),
        }),
    }),
    Walk = table.freeze({
        Duration = 0.72,
        Loop = true,
        Keyframes = table.freeze({
            frame(0, {
                LeftHip = pose(math.rad(30), 0, 0),
                RightHip = pose(math.rad(-30), 0, 0),
                LeftShoulder = pose(math.rad(-26), 0, 0),
                RightShoulder = pose(math.rad(26), 0, 0),
            }),
            frame(0.36, {
                LeftHip = pose(math.rad(-30), 0, 0),
                RightHip = pose(math.rad(30), 0, 0),
                LeftShoulder = pose(math.rad(26), 0, 0),
                RightShoulder = pose(math.rad(-26), 0, 0),
            }),
            frame(0.72, {
                LeftHip = pose(math.rad(30), 0, 0),
                RightHip = pose(math.rad(-30), 0, 0),
                LeftShoulder = pose(math.rad(-26), 0, 0),
                RightShoulder = pose(math.rad(26), 0, 0),
            }),
        }),
    }),
    Attack = table.freeze({
        Duration = 0.62,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, {
                BodyJoint = pose(0, math.rad(-8), 0),
                RightShoulder = pose(math.rad(-72), 0, math.rad(20)),
            }),
            frame(0.28, {
                BodyJoint = pose(math.rad(-7), math.rad(18), 0),
                RightShoulder = pose(math.rad(48), 0, math.rad(-35)),
            }),
            frame(0.62, { BodyJoint = CFrame.new(), RightShoulder = CFrame.new() }),
        }),
    }),
    Hit = table.freeze({
        Duration = 0.24,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = pose(math.rad(-10), 0, math.rad(8)) }),
            frame(0.24, { BodyJoint = CFrame.new() }),
        }),
    }),
    Dodge = table.freeze({
        Duration = 0.42,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = pose(0, 0, 0) }),
            frame(0.21, { BodyJoint = pose(0, 0, math.rad(115)) }),
            frame(0.42, { BodyJoint = pose(0, 0, math.rad(230)) }),
        }),
    }),
    Dead = table.freeze({
        Duration = 0.55,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = CFrame.new() }),
            frame(0.55, { BodyJoint = pose(math.rad(72), 0, math.rad(10)) }),
        }),
    }),
})

local slime = table.freeze({
    Idle = table.freeze({
        Duration = 1.4,
        Loop = true,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = CFrame.new() }),
            frame(0.7, { BodyJoint = CFrame.new(0, 0.18, 0) }),
            frame(1.4, { BodyJoint = CFrame.new() }),
        }),
    }),
    Walk = table.freeze({
        Duration = 0.8,
        Loop = true,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = CFrame.new(0, -0.1, 0) }),
            frame(0.4, { BodyJoint = CFrame.new(0, 0.55, 0) * pose(math.rad(-7), 0, 0) }),
            frame(0.8, { BodyJoint = CFrame.new(0, -0.1, 0) }),
        }),
    }),
    Attack = table.freeze({
        Duration = 0.75,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = CFrame.new(0, -0.35, 0) }),
            frame(0.35, { BodyJoint = CFrame.new(0, 0.65, -0.65) * pose(math.rad(-18), 0, 0) }),
            frame(0.75, { BodyJoint = CFrame.new() }),
        }),
    }),
    Hit = table.freeze({
        Duration = 0.3,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = pose(0, 0, math.rad(-12)) }),
            frame(0.15, { BodyJoint = pose(0, 0, math.rad(12)) }),
            frame(0.3, { BodyJoint = CFrame.new() }),
        }),
    }),
    Dodge = table.freeze({
        Duration = 0.5,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = CFrame.new(0, -0.25, 0) }),
            frame(0.25, { BodyJoint = CFrame.new(0, 0.35, 0) }),
            frame(0.5, { BodyJoint = CFrame.new() }),
        }),
    }),
    Dead = table.freeze({
        Duration = 0.5,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = CFrame.new() }),
            frame(0.5, { BodyJoint = CFrame.new(0, -0.65, 0) * pose(0, 0, math.rad(8)) }),
        }),
    }),
})

local bird = table.freeze({
    Idle = table.freeze({
        Duration = 1.5,
        Loop = true,
        Keyframes = table.freeze({
            frame(0, { HeadJoint = pose(math.rad(-3), 0, 0), TailJoint = pose(math.rad(5), 0, 0) }),
            frame(0.75, {
                HeadJoint = pose(math.rad(7), math.rad(5), 0),
                TailJoint = pose(math.rad(-4), math.rad(-5), 0),
            }),
            frame(
                1.5,
                { HeadJoint = pose(math.rad(-3), 0, 0), TailJoint = pose(math.rad(5), 0, 0) }
            ),
        }),
    }),
    Walk = table.freeze({
        Duration = 0.5,
        Loop = true,
        Keyframes = table.freeze({
            frame(0, {
                LeftHip = pose(math.rad(38), 0, 0),
                RightHip = pose(math.rad(-38), 0, 0),
                LeftShoulder = pose(0, 0, math.rad(-12)),
                RightShoulder = pose(0, 0, math.rad(12)),
            }),
            frame(0.25, {
                LeftHip = pose(math.rad(-38), 0, 0),
                RightHip = pose(math.rad(38), 0, 0),
                LeftShoulder = pose(0, 0, math.rad(10)),
                RightShoulder = pose(0, 0, math.rad(-10)),
            }),
            frame(0.5, {
                LeftHip = pose(math.rad(38), 0, 0),
                RightHip = pose(math.rad(-38), 0, 0),
                LeftShoulder = pose(0, 0, math.rad(-12)),
                RightShoulder = pose(0, 0, math.rad(12)),
            }),
        }),
    }),
    Attack = table.freeze({
        Duration = 0.52,
        Loop = false,
        Keyframes = table.freeze({
            frame(
                0,
                { HeadJoint = pose(math.rad(-12), 0, 0), BodyJoint = pose(math.rad(-4), 0, 0) }
            ),
            frame(0.24, {
                HeadJoint = CFrame.new(0, -0.2, -0.8) * pose(math.rad(24), 0, 0),
                BodyJoint = pose(math.rad(-14), 0, 0),
            }),
            frame(0.52, { HeadJoint = CFrame.new(), BodyJoint = CFrame.new() }),
        }),
    }),
    Hit = table.freeze({
        Duration = 0.2,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = pose(0, 0, math.rad(9)) }),
            frame(0.2, { BodyJoint = CFrame.new() }),
        }),
    }),
    Dodge = table.freeze({
        Duration = 0.36,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, {
                LeftShoulder = pose(0, 0, math.rad(-28)),
                RightShoulder = pose(0, 0, math.rad(28)),
            }),
            frame(0.36, { LeftShoulder = CFrame.new(), RightShoulder = CFrame.new() }),
        }),
    }),
    Dead = table.freeze({
        Duration = 0.6,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = CFrame.new() }),
            frame(0.6, { BodyJoint = pose(math.rad(68), 0, math.rad(-10)) }),
        }),
    }),
})

local quadruped = table.freeze({
    Idle = table.freeze({
        Duration = 1.6,
        Loop = true,
        Keyframes = table.freeze({
            frame(0, { HeadJoint = pose(math.rad(3), 0, 0) }),
            frame(0.8, { HeadJoint = pose(math.rad(-8), math.rad(4), 0) }),
            frame(1.6, { HeadJoint = pose(math.rad(3), 0, 0) }),
        }),
    }),
    Walk = table.freeze({
        Duration = 0.62,
        Loop = true,
        Keyframes = table.freeze({
            frame(0, {
                FrontLeftHip = pose(math.rad(24), 0, 0),
                FrontRightHip = pose(math.rad(-24), 0, 0),
                BackLeftHip = pose(math.rad(-22), 0, 0),
                BackRightHip = pose(math.rad(22), 0, 0),
            }),
            frame(0.31, {
                FrontLeftHip = pose(math.rad(-24), 0, 0),
                FrontRightHip = pose(math.rad(24), 0, 0),
                BackLeftHip = pose(math.rad(22), 0, 0),
                BackRightHip = pose(math.rad(-22), 0, 0),
            }),
            frame(0.62, {
                FrontLeftHip = pose(math.rad(24), 0, 0),
                FrontRightHip = pose(math.rad(-24), 0, 0),
                BackLeftHip = pose(math.rad(-22), 0, 0),
                BackRightHip = pose(math.rad(22), 0, 0),
            }),
        }),
    }),
    Attack = table.freeze({
        Duration = 0.65,
        Loop = false,
        Keyframes = table.freeze({
            frame(
                0,
                { BodyJoint = pose(math.rad(6), 0, 0), HeadJoint = pose(math.rad(-12), 0, 0) }
            ),
            frame(0.3, {
                BodyJoint = CFrame.new(0, 0, -0.65) * pose(math.rad(-10), 0, 0),
                HeadJoint = pose(math.rad(18), 0, 0),
            }),
            frame(0.65, { BodyJoint = CFrame.new(), HeadJoint = CFrame.new() }),
        }),
    }),
    Hit = table.freeze({
        Duration = 0.28,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = pose(0, 0, math.rad(-7)) }),
            frame(0.28, { BodyJoint = CFrame.new() }),
        }),
    }),
    Dodge = table.freeze({
        Duration = 0.4,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = pose(math.rad(6), 0, 0) }),
            frame(0.4, { BodyJoint = CFrame.new() }),
        }),
    }),
    Dead = table.freeze({
        Duration = 0.62,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = CFrame.new() }),
            frame(0.62, { BodyJoint = pose(0, 0, math.rad(75)) }),
        }),
    }),
})

local wisp = table.freeze({
    Idle = table.freeze({
        Duration = 1.7,
        Loop = true,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = CFrame.new(0, -0.12, 0) }),
            frame(0.85, { BodyJoint = CFrame.new(0, 0.32, 0) * pose(0, math.rad(12), 0) }),
            frame(1.7, { BodyJoint = CFrame.new(0, -0.12, 0) }),
        }),
    }),
    Walk = table.freeze({
        Duration = 0.9,
        Loop = true,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = CFrame.new(0, 0, 0) * pose(0, math.rad(-10), 0) }),
            frame(0.45, { BodyJoint = CFrame.new(0, 0.35, 0) * pose(0, math.rad(10), 0) }),
            frame(0.9, { BodyJoint = CFrame.new() * pose(0, math.rad(-10), 0) }),
        }),
    }),
    Attack = table.freeze({
        Duration = 0.7,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = CFrame.new() }),
            frame(0.35, { BodyJoint = CFrame.new(0, 0.25, -0.7) * pose(0, math.rad(18), 0) }),
            frame(0.7, { BodyJoint = CFrame.new() }),
        }),
    }),
    Hit = table.freeze({
        Duration = 0.18,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = pose(0, 0, math.rad(-16)) }),
            frame(0.18, { BodyJoint = CFrame.new() }),
        }),
    }),
    Dodge = table.freeze({
        Duration = 0.34,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = pose(0, math.rad(-20), 0) }),
            frame(0.34, { BodyJoint = pose(0, math.rad(180), 0) }),
        }),
    }),
    Dead = table.freeze({
        Duration = 0.48,
        Loop = false,
        Keyframes = table.freeze({
            frame(0, { BodyJoint = CFrame.new() }),
            frame(
                0.48,
                { BodyJoint = CFrame.new(0, 1.1, 0) * pose(0, math.rad(90), math.rad(25)) }
            ),
        }),
    }),
})

return table.freeze({
    skeleton = skeleton,
    slime = slime,
    bird = bird,
    quadruped = quadruped,
    wisp = wisp,
})
