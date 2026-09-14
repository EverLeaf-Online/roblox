local ScreenRegistry = require(script.Parent.Parent.UI.ScreenRegistry)
local UIStore = require(script.Parent.Parent.State.UIStore)

local ScreenController = {}
local factories = {}
local mounted = {}
local valid = {}
for _, screenId in ScreenRegistry do
    valid[screenId] = true
end

local function setPayload(screen, payload)
    if type(screen) == "table" and type(screen.SetPayload) == "function" then
        screen:SetPayload(payload)
    end
end

local function destroyScreen(screen)
    if typeof(screen) == "Instance" then
        screen:Destroy()
        return
    end
    if type(screen) == "table" and type(screen.Destroy) == "function" then
        screen:Destroy()
    end
end

function ScreenController.Register(screenId, factory)
    assert(valid[screenId], "unknown screen id")
    assert(type(factory) == "function", "factory must be a function")
    factories[screenId] = factory
end

function ScreenController.Open(screenId, payload)
    if not valid[screenId] then
        return false, "unknown_screen"
    end
    UIStore.Open(screenId, payload)
    return true
end

function ScreenController.Close(screenId)
    UIStore.Close(screenId)
end

function ScreenController.Start()
    UIStore.Changed:Connect(function(screenId, isOpen, payload)
        local existing = mounted[screenId]
        if isOpen then
            if existing then
                setPayload(existing, payload)
                return
            end
            local factory = factories[screenId]
            if factory then
                mounted[screenId] = factory(payload)
            end
        elseif existing then
            destroyScreen(existing)
            mounted[screenId] = nil
        end
    end)
end

return ScreenController
