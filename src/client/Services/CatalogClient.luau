local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Net)

local CatalogClient = {}
local cache = nil

function CatalogClient.Load()
    if cache then
        return true, cache
    end
    local folder = ReplicatedStorage:WaitForChild(Net.RemoteFolderName)
    local remote = folder:WaitForChild(Net.Functions.RequestCatalog)
    local ok, catalog = pcall(function()
        return remote:InvokeServer()
    end)
    if not ok or type(catalog) ~= "table" then
        return false, "catalog_request_failed"
    end
    cache = catalog
    return true, cache
end

function CatalogClient.Get()
    return cache
end

return CatalogClient
