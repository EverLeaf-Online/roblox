local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local ProgressionPresentation = {}
local player = Players.LocalPlayer

function ProgressionPresentation.PlayLevelUp(level)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return
    end

    local attachment = Instance.new("Attachment")
    attachment.Name = "EverLeafLevelUpBurst"
    attachment.Position = Vector3.new(0, -1.2, 0)
    attachment.Parent = root

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "LevelUpLumen"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(121, 244, 183)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(225, 255, 237)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(232, 190, 88)),
    })
    emitter.LightEmission = 0.8
    emitter.Rate = 0
    emitter.Lifetime = NumberRange.new(0.65, 1.15)
    emitter.Speed = NumberRange.new(5.5, 10.5)
    emitter.Acceleration = Vector3.new(0, 5, 0)
    emitter.Drag = 2
    emitter.SpreadAngle = Vector2.new(180, 42)
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.RotSpeed = NumberRange.new(-90, 90)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.34),
        NumberSequenceKeypoint.new(0.55, 0.2),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.04),
        NumberSequenceKeypoint.new(0.72, 0.25),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = attachment

    local light = Instance.new("PointLight")
    light.Name = "LevelUpLumenLight"
    light.Color = Color3.fromRGB(121, 244, 183)
    light.Brightness = 1.5
    light.Range = 12
    light.Shadows = false
    light.Parent = attachment

    local count = math.clamp(28 + (tonumber(level) or 1), 30, 48)
    emitter:Emit(count)
    Debris:AddItem(attachment, 1.35)
end

return ProgressionPresentation
