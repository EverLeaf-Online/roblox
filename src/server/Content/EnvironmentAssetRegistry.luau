local EnvironmentAssetRegistry = {
    DuneSky = {
        AssetId = 138907351102721,
        Name = "Dune Sky",
        Source = "Roblox Creator Store",
        Status = "candidate",
        Notes = "Inspect in Studio before production use; keep visual instances only and remove any scripts.",
    },
    RobloxForestPack = {
        AssetId = 6432306802,
        Name = "Forest Pack",
        Source = "Roblox Creator Store / Roblox",
        Status = "approved_for_sanitized_import",
        Notes = "Free environment pack with PBR foliage, rocks, logs, ground detail, particles, and wildlife. Strip scripts before use.",
    },
    WindShakeDBE = {
        AssetId = 101954362093094,
        Name = "WindShake DBE",
        Source = "Roblox Creator Store",
        Status = "candidate",
        Notes = "Audit all scripts before adoption; never load marketplace scripts dynamically at runtime.",
    },
}

return table.freeze(EnvironmentAssetRegistry)
