local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraController = require(script.Parent.Controllers.CameraController)
local CombatController = require(script.Parent.Controllers.CombatController)
local SideScrollerController = require(script.Parent.Controllers.SideScrollerController)
local Net = require(ReplicatedStorage.Shared.Net)
local ProfileStore = require(script.Parent.State.ProfileStore)

local function startController(name, controller)
    task.spawn(function()
        local ok, err = xpcall(controller.Start, debug.traceback)
        if not ok then
            warn(string.format("[ClientBootstrap] %s failed to start:\n%s", name, tostring(err)))
        end
    end)
end

-- Controllers are deliberately fault-isolated. A missing dependency or slow
-- startup in one system must never prevent unrelated client systems from
-- initializing.
startController("SideScrollerController", SideScrollerController)
startController("CameraController", CameraController)
startController("CombatController", CombatController)

-- Profile networking is also isolated from controller startup.
task.spawn(function()
    local remotes = ReplicatedStorage:WaitForChild(Net.RemoteFolderName, 5)
    if not remotes then
        warn("[ClientBootstrap] EverLeafRemotes folder was not found")
        return
    end

    local profileReady = remotes:WaitForChild(Net.Events.ProfileReady, 5)
    local profileChanged = remotes:WaitForChild(Net.Events.ProfileChanged, 5)
    local requestProfile = remotes:WaitForChild(Net.Functions.RequestProfile, 5)

    if not profileReady or not profileChanged or not requestProfile then
        warn("[ClientBootstrap] Profile remotes were not ready")
        return
    end

    profileReady.OnClientEvent:Connect(ProfileStore.Set)
    profileChanged.OnClientEvent:Connect(ProfileStore.Set)

    local ok, snapshot = pcall(function()
        return requestProfile:InvokeServer()
    end)
    if ok and snapshot then
        ProfileStore.Set(snapshot)
    elseif not ok then
        warn("[ClientBootstrap] Initial profile request failed")
    end
end)
