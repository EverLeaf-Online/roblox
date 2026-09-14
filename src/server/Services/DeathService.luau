local DeathService = {}
local diedEvent = Instance.new("BindableEvent")
DeathService.PlayerDied = diedEvent.Event

local function attachCharacter(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        diedEvent:Fire(player)
    end)
end

function DeathService.InitPlayer(player)
    player.CharacterAdded:Connect(function(character)
        task.spawn(attachCharacter, player, character)
    end)
    if player.Character then
        task.spawn(attachCharacter, player, player.Character)
    end
end

return DeathService
