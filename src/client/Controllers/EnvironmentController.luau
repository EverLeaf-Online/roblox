local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local EnvironmentController = {}

local swayBase = {}
local fireflyBase = {}

local function registerSway(instance)
    if instance:IsA("BasePart") then
        swayBase[instance] = instance.CFrame
    end
end

local function registerFirefly(instance)
    if instance:IsA("BasePart") then
        fireflyBase[instance] = instance.CFrame
    end
end

local function forget(instance)
    swayBase[instance] = nil
    fireflyBase[instance] = nil
end

function EnvironmentController.Start()
    for _, instance in CollectionService:GetTagged("EverLeafWindSway") do
        registerSway(instance)
    end
    for _, instance in CollectionService:GetTagged("EverLeafFirefly") do
        registerFirefly(instance)
    end

    CollectionService:GetInstanceAddedSignal("EverLeafWindSway"):Connect(registerSway)
    CollectionService:GetInstanceAddedSignal("EverLeafFirefly"):Connect(registerFirefly)
    CollectionService:GetInstanceRemovedSignal("EverLeafWindSway"):Connect(forget)
    CollectionService:GetInstanceRemovedSignal("EverLeafFirefly"):Connect(forget)

    RunService:BindToRenderStep(
        "EverLeafEnvironmentMotion",
        Enum.RenderPriority.Last.Value,
        function()
            local now = os.clock()

            for instance, base in swayBase do
                if instance.Parent then
                    local phase = instance.Position.X * 0.07 + instance.Position.Z * 0.05
                    local roll = math.sin(now * 1.05 + phase) * math.rad(1.3)
                    local pitch = math.sin(now * 0.72 + phase * 0.6) * math.rad(0.8)
                    instance.CFrame = base * CFrame.Angles(pitch, 0, roll)
                else
                    swayBase[instance] = nil
                end
            end

            for instance, base in fireflyBase do
                if instance.Parent then
                    local phase = instance.Position.X * 0.11 + instance.Position.Z * 0.13
                    local offset = Vector3.new(
                        math.sin(now * 0.9 + phase) * 0.85,
                        math.sin(now * 1.35 + phase * 1.7) * 0.55,
                        math.cos(now * 0.75 + phase) * 0.7
                    )
                    instance.CFrame = base + offset
                else
                    fireflyBase[instance] = nil
                end
            end
        end
    )
end

return EnvironmentController
