local Net = {}

Net.RemoteFolderName = "EverLeafRemotes"

Net.Events = table.freeze({
    ProfileReady = "ProfileReady",
    ProfileChanged = "ProfileChanged",
})

Net.Functions = table.freeze({
    AllocateStat = "AllocateStat",
    RequestProfile = "RequestProfile",
})

return table.freeze(Net)
