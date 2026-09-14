local TelemetryService = {}

function TelemetryService.Record(_eventName, _fields)
    -- Architecture hook only. No external telemetry is sent until a privacy-conscious
    -- analytics plan is explicitly chosen.
end

return TelemetryService
