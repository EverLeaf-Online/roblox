# EverLeaf Environment Asset Catalog

This catalog tracks third-party environment assets before they are allowed into production. Marketplace assets are never loaded dynamically at runtime. Every model is imported into Studio, inspected, stripped of scripts/unneeded instances, optimized, and then source-controlled or otherwise recorded as an approved production dependency.

## Current candidates

| Asset | ID | Status | Notes |
|---|---:|---|---|
| Dune Sky | `138907351102721` | Candidate | Inspect in Studio first; retain only approved visual instances. |
| Roblox Forest Pack | `6432306802` | Approved for sanitized import | Free Roblox pack containing PBR trees, bushes, flowers, rocks, logs, ground detail, particles, and wildlife. Remove all bundled scripts before use. |
| WindShake DBE | `101954362093094` | Candidate | Audit scripts before adoption; use only after review. |

## Import rules

1. Insert through Studio/Creator Store into an isolated inspection place or folder.
2. Remove every Script, LocalScript, ModuleScript, remote, loader, analytics object, or unexpected dependency unless explicitly reviewed and approved.
3. Check triangle count, material count, texture resolution, collisions, pivots, scale, and streaming behavior.
4. Prefer reusable modular pieces over giant combined meshes.
5. Record attribution/license requirements before shipping.
6. Never call `InsertService:LoadAsset()` for marketplace environment content during live gameplay.
