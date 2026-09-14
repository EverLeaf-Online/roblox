#!/usr/bin/env python3
from pathlib import Path
import hashlib
import json
import urllib.request

ASSETS = {
    "forest_ground": "forrest_ground_01",
    "mossy_rock": "mossy_rock",
    "moss_wood": "moss_wood",
    "wood_chip_path": "wood_chip_path",
    "wood_stone_pathway": "wood_stone_pathway",
}
MAPS = {"Diffuse": "color", "nor_gl": "normal", "Rough": "roughness"}
HEADERS = {"User-Agent": "EverLeaf-Roblox-AssetPipeline/1.0"}


def fetch_json(url):
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=30) as response:
        return json.load(response)


def fetch_file(url, destination):
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=60) as response:
        destination.write_bytes(response.read())


def main():
    repo = Path(__file__).resolve().parents[1]
    output = repo / "assets" / "polyhaven"
    output.mkdir(parents=True, exist_ok=True)
    manifest = {
        "source": "Poly Haven",
        "license": "CC0",
        "resolution": "1k",
        "format": "jpg",
        "materials": {},
    }

    for material_name, asset_id in ASSETS.items():
        files = fetch_json(f"https://api.polyhaven.com/files/{asset_id}")
        info = fetch_json(f"https://api.polyhaven.com/info/{asset_id}")
        material_dir = output / material_name
        material_dir.mkdir(parents=True, exist_ok=True)
        entry = {
            "polyhaven_id": asset_id,
            "name": info.get("name", asset_id),
            "source_url": f"https://polyhaven.com/a/{asset_id}",
            "license": "CC0",
            "maps": {},
        }
        for api_name, map_name in MAPS.items():
            metadata = files[api_name]["1k"]["jpg"]
            destination = material_dir / f"{material_name}_{map_name}_1k.jpg"
            fetch_file(metadata["url"], destination)
            digest = hashlib.md5(destination.read_bytes()).hexdigest()
            if digest != metadata["md5"]:
                raise RuntimeError(f"hash mismatch for {destination}")
            entry["maps"][map_name] = {
                "file": str(destination.relative_to(repo)),
                "md5": digest,
                "bytes": destination.stat().st_size,
            }
        manifest["materials"][material_name] = entry

    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Synced {len(ASSETS)} Poly Haven material sets into {output}")


if __name__ == "__main__":
    main()
