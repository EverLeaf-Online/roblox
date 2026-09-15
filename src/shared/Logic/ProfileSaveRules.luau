local ProfileSaveRules = {}

function ProfileSaveRules.CanClaim(lock, sessionId, now, timeoutSeconds)
    if type(sessionId) ~= "string" or sessionId == "" then
        return false
    end
    if type(lock) ~= "table" then
        return true
    end
    if lock.Id == sessionId then
        return true
    end
    local touchedAt = tonumber(lock.TouchedAt) or 0
    now = tonumber(now) or 0
    timeoutSeconds = math.max(0, tonumber(timeoutSeconds) or 0)
    return now - touchedAt >= timeoutSeconds
end

function ProfileSaveRules.OwnsLock(lock, sessionId)
    return type(lock) == "table" and lock.Id == sessionId
end

function ProfileSaveRules.SavedRevisionAfterSuccess(
    capturedRevision,
    currentRevision,
    priorSavedRevision
)
    capturedRevision = math.max(0, tonumber(capturedRevision) or 0)
    currentRevision = math.max(0, tonumber(currentRevision) or 0)
    priorSavedRevision = math.max(0, tonumber(priorSavedRevision) or 0)
    local savedRevision = math.max(priorSavedRevision, math.min(capturedRevision, currentRevision))
    return savedRevision, currentRevision > savedRevision
end

return ProfileSaveRules
