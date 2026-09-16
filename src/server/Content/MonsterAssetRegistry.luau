-- Canonical production monster visual registry.
-- Only original/reviewed assets are enabled. MonsterTemplateService sanitizes loaded
-- model assets and builds the gameplay Humanoid/root rig around their authored mesh parts.
local MonsterAssetRegistry = {
    lumen_mossling = {
        AssetId = 111556426711525,
        TemplateName = "LumenMossling",
        Status = "reviewed",
        RootSize = Vector3.new(2.5, 2.5, 2.5),
        HipHeight = 1.1,
        Joints = { Body = "BodyJoint", Head = "HeadJoint" },
    },
    slime = {
        AssetId = 139841213411079,
        TemplateName = "GlowcapSlime",
        Status = "reviewed",
        RootSize = Vector3.new(2.6, 2.2, 2.6),
        HipHeight = 1.05,
        Joints = { Body = "BodyJoint", Face = "HeadJoint" },
    },
    peco_peco = {
        AssetId = 123954746000436,
        TemplateName = "SuncrestRidgebeak",
        Status = "reviewed",
        RootSize = Vector3.new(2.4, 3.0, 2.4),
        HipHeight = 2.0,
        Joints = {
            Body = "BodyJoint",
            Head = "HeadJoint",
            Tail = "TailJoint",
            LeftWing = "LeftShoulder",
            RightWing = "RightShoulder",
            LeftLeg = "LeftHip",
            RightLeg = "RightHip",
        },
    },
    brambleback = {
        AssetId = 89263541500191,
        TemplateName = "Brambleback",
        Status = "reviewed",
        RootSize = Vector3.new(3.4, 2.5, 4.0),
        HipHeight = 1.3,
        Joints = {
            Body = "BodyJoint",
            Head = "HeadJoint",
            FrontLeftLeg = "FrontLeftHip",
            FrontRightLeg = "FrontRightHip",
            BackLeftLeg = "BackLeftHip",
            BackRightLeg = "BackRightHip",
        },
    },
    lumen_wisp = {
        AssetId = 80182968126504,
        TemplateName = "LumenWisp",
        Status = "reviewed",
        RootSize = Vector3.new(2.0, 2.4, 2.0),
        HipHeight = 2.4,
        Joints = { Body = "BodyJoint" },
    },
}

return table.freeze(MonsterAssetRegistry)
