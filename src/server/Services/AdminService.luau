local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local AuditLogService = require(script.Parent.AuditLogService)

local AdminService = {}

function AdminService.IsAdmin(player)
    return GameConfig.AdminUserIds[player.UserId] == true
end

function AdminService.RequireAdmin(player, actionName)
    if AdminService.IsAdmin(player) then
        return true
    end
    AuditLogService.Record("AdminDenied", player, actionName)
    return false, "not_authorized"
end

return AdminService
