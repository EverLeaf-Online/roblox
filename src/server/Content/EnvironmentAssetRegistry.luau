local EnvironmentAssetRegistry = {
    TreePrimary = {
        AssetId = 580221169,
        Name = "Tree",
        Source = "Roblox Creator Store",
        Status = "approved_for_studio_sanitized_import",
        PrefabName = "TreePrimary",
        Notes = "Approved development tree candidate. Studio-only loader may fetch it, strips scripts/remotes, and production runtime never loads it dynamically.",
    },
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
