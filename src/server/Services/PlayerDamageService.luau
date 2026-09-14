local Players = game:GetService("Players")
local PlayerDamageService = {}
local lastDamageAt = {}

function PlayerDamageService.Apply(player, amount, sourceId)
    if not player or player.Parent ~= Players then
        return false, "invalid_player"
    end
    if type(amount) ~= "number" or amount <= 0 or amount ~= amount then
        return false, "invalid_damage"
    end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false, "character_unavailable"
    end
    local now = os.clock()
    if now - (lastDamageAt[player] or 0) < 0.15 then
        return false, "invulnerable"
    end
    lastDamageAt[player] = now
    humanoid:SetAttribute("LastDamageSource", tostring(sourceId or "unknown"))
    humanoid:TakeDamage(math.floor(amount))
    return true, humanoid.Health
end

Players.PlayerRemoving:Connect(function(player)
    lastDamageAt[player] = nil
end)
return PlayerDamageService
