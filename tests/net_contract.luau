local Net = require("../src/shared/Net")

assert(type(Net.RemoteFolderName) == "string" and Net.RemoteFolderName ~= "", "remote folder name")
assert(Net.Functions.RequestProfile == "RequestProfile", "profile function contract")
assert(Net.Functions.RequestCatalog == "RequestCatalog", "catalog function contract")
assert(Net.Functions.RefreshEntitlements == "RefreshEntitlements", "entitlement refresh contract")

local seen = {}
for _, name in Net.Functions do
    assert(not seen[name], "remote function names must be unique: " .. name)
    seen[name] = true
end
for _, name in Net.Events do
    assert(not seen[name], "event/function remote names must be unique: " .. name)
    seen[name] = true
end

print("network contract tests passed")
