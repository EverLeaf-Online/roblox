local Players = game:GetService("Players")

local DeathService = {}
local diedEvent = Instance.new("BindableEvent")
DeathService.PlayerDied = diedEvent.Event

local function attachCharacter(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        diedEvent:Fire(player)

        -- CharacterAutoLoads is disabled so profile/world spawn selection can happen
        -- before initial placement. Preserve normal respawning explicitly after death.
        task.delay(Players.RespawnTime, function()
            if player.Parent ~= Players then
                return
            end
            if player.Character ~= character then
                return
            end
            player:LoadCharacter()
        end)
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
