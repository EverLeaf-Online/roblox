local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraController = require(script.Parent.Controllers.CameraController)
local CatalogClient = require(script.Parent.Services.CatalogClient)
local CombatController = require(script.Parent.Controllers.CombatController)
local ReactUIController = require(script.Parent.Controllers.ReactUIController)
local ScreenController = require(script.Parent.Controllers.ScreenController)
local ThirdPersonController = require(script.Parent.Controllers.ThirdPersonController)
local Net = require(ReplicatedStorage.Shared.Net)
local PartyStore = require(script.Parent.State.PartyStore)
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
startController("ThirdPersonController", ThirdPersonController)
startController("CameraController", CameraController)
startController("CombatController", CombatController)
startController("ReactUIController", ReactUIController)
startController("ScreenController", ScreenController)

-- Profile networking is also isolated from controller startup.
task.spawn(function()
    local remotes = ReplicatedStorage:WaitForChild(Net.RemoteFolderName, 5)
    if not remotes then
        warn("[ClientBootstrap] EverLeafRemotes folder was not found")
        return
    end

    local profileReady = remotes:WaitForChild(Net.Events.ProfileReady, 5)
    local profileChanged = remotes:WaitForChild(Net.Events.ProfileChanged, 5)
    local partyEvent = remotes:WaitForChild(Net.Events.PartyEvent, 5)
    local requestProfile = remotes:WaitForChild(Net.Functions.RequestProfile, 5)

    if not profileReady or not profileChanged or not partyEvent or not requestProfile then
        warn("[ClientBootstrap] Profile remotes were not ready")
        return
    end

    profileReady.OnClientEvent:Connect(ProfileStore.Set)
    profileChanged.OnClientEvent:Connect(ProfileStore.Set)
    partyEvent.OnClientEvent:Connect(PartyStore.Push)

    local ok, snapshot = pcall(function()
        return requestProfile:InvokeServer()
    end)
    if ok and snapshot then
        ProfileStore.Set(snapshot)
    elseif not ok then
        warn("[ClientBootstrap] Initial profile request failed")
    end
end)

task.spawn(function()
    local ok, reason = CatalogClient.Load()
    if not ok then
        warn(string.format("[ClientBootstrap] Catalog failed to load: %s", tostring(reason)))
    end
end)
