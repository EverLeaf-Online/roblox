local AuditLogService = {}

function AuditLogService.Record(category, actor, message)
    local actorText = if actor and actor.UserId
        then string.format("%s(%d)", actor.Name, actor.UserId)
        else "system"
    print(string.format("[Audit][%s][%s] %s", tostring(category), actorText, tostring(message)))
end

return AuditLogService
