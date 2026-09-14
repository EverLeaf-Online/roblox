local EnhancementService = {}
function EnhancementService.IsEnabled()
    return false
end
function EnhancementService.Enhance()
    return false, "enhancement_not_enabled"
end
return EnhancementService
