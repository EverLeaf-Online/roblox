local TradeService = {}

function TradeService.IsEnabled()
    return false
end

function TradeService.Begin()
    return false, "trading_not_enabled"
end

return TradeService
