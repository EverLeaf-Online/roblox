local StorageService = {}
function StorageService.IsEnabled()
    return false
end
function StorageService.Deposit()
    return false, "storage_not_enabled"
end
function StorageService.Withdraw()
    return false, "storage_not_enabled"
end
return StorageService
