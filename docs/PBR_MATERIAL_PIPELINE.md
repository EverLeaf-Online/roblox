# EverLeaf PBR Material Pipeline

EverLeaf uses curated CC0 source materials from Poly Haven, prepared at 1K for Roblox.

## Curated Lumenreach set

- `forrest_ground_01` → `ForestGround`
- `mossy_rock` → `MossyRock`
- `moss_wood` → `MossWood`
- `wood_chip_path` → `WoodChipPath`
- `wood_stone_pathway` → `WoodStonePathway`

Source maps are stored under `assets/polyhaven/` with a generated `manifest.json`. The selected maps are diffuse/color, OpenGL normal, and roughness. Organic materials intentionally omit metalness.

Refresh the source set with:

```bash
python3 scripts/sync_polyhaven_materials.py
```

The downloader uses Poly Haven's public API, pins the 1K JPG variants, and validates each file against Poly Haven's MD5 metadata before updating the manifest.

## Roblox upload boundary

Roblox `MaterialVariant` texture properties require Roblox content asset IDs. Local repository files cannot be assigned directly as runtime texture maps. Upload the three maps for each material through Studio's Material Manager/Asset Manager (or a future authenticated Open Cloud upload job), then place those numeric IDs in `src/server/Content/PBRMaterialDefinitions.luau`.

Once all three IDs for a definition are non-zero, `PBRMaterialService` automatically creates the `MaterialVariant`. `ForestGround`, `WoodChipPath`, and `MossyRock` also attempt to become terrain overrides for Grass, Ground, and Rock respectively. Generated rock/slate, wood-plank, and cobblestone props receive matching per-part variants automatically.

Until uploaded Roblox IDs are configured, the service fails closed and the current built-in Roblox materials remain active.

## Resolution policy

- Default: 1K for repeating environment materials.
- Use 2K only after measured Studio review proves 1K visibly insufficient at gameplay distance.
- Never ship the original 8K Poly Haven maps directly.
- Keep source license and Poly Haven asset ID in the registry and manifest.

## License

The selected Poly Haven assets are CC0. Their source pages and IDs are preserved in `assets/polyhaven/manifest.json` and the material definitions for provenance.
