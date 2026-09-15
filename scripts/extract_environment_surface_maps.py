#!/usr/bin/env python3
"""Extract authored SurfaceAppearance maps from production environment GLBs.

Roblox runtime code must not rewrite protected SurfaceAppearance map properties.
This tool makes the imported Poly Haven materials explicit and source-controlled:
base color and normal are extracted as-is, while roughness is extracted from the
GLTF metallic-roughness texture's green channel.
"""
from __future__ import annotations

import argparse
import json
import struct
from io import BytesIO
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MODEL_ROOT = ROOT / "assets/polyhaven/models"
OUTPUT_ROOT = ROOT / "assets/polyhaven/surface_maps"
MANIFEST_PATH = OUTPUT_ROOT / "manifest.json"
JSON_CHUNK = 0x4E4F534A
BIN_CHUNK = 0x004E4942


def read_glb(path: Path) -> tuple[dict, bytes]:
    data = path.read_bytes()
    if len(data) < 20 or data[:4] != b"glTF":
        raise ValueError(f"{path}: invalid GLB")
    version, declared = struct.unpack_from("<II", data, 4)
    if version != 2 or declared != len(data):
        raise ValueError(f"{path}: invalid GLB header")
    document = None
    binary = None
    offset = 12
    while offset + 8 <= len(data):
        length, kind = struct.unpack_from("<II", data, offset)
        offset += 8
        chunk = data[offset:offset+length]
        offset += length
        if kind == JSON_CHUNK:
            document = json.loads(chunk.rstrip(b"\x00 ").decode("utf-8"))
        elif kind == BIN_CHUNK:
            binary = chunk
    if document is None or binary is None:
        raise ValueError(f"{path}: GLB missing JSON/BIN chunk")
    return document, binary


def image_bytes(document: dict, binary: bytes, image_index: int) -> bytes:
    image = document["images"][image_index]
    if image.get("uri"):
        raise ValueError("production GLB unexpectedly uses external image URI")
    view = document["bufferViews"][image["bufferView"]]
    start = int(view.get("byteOffset", 0))
    end = start + int(view["byteLength"])
    return binary[start:end]


def texture_image_index(document: dict, texture_info: dict | None) -> int:
    if not texture_info or "index" not in texture_info:
        raise ValueError("material texture reference missing")
    texture = document["textures"][texture_info["index"]]
    return int(texture["source"])


def save_png(raw: bytes, target: Path, mode: str | None = None) -> None:
    with Image.open(BytesIO(raw)) as source:
        image = source.convert(mode) if mode else source.convert("RGBA")
        image.save(target, format="PNG", optimize=True)


def extract_one(path: Path, output: Path) -> dict:
    document, binary = read_glb(path)
    materials = document.get("materials", [])
    if len(materials) != 1:
        raise ValueError(f"{path}: expected one production material, got {len(materials)}")
    material = materials[0]
    pbr = material.get("pbrMetallicRoughness", {})
    base_index = texture_image_index(document, pbr.get("baseColorTexture"))
    normal_index = texture_image_index(document, material.get("normalTexture"))
    rough_index = texture_image_index(document, pbr.get("metallicRoughnessTexture"))

    output.mkdir(parents=True, exist_ok=True)
    color_path = output / "color.png"
    normal_path = output / "normal.png"
    roughness_path = output / "roughness.png"

    # RGBA preserves fern alpha masks and is harmless for opaque assets.
    save_png(image_bytes(document, binary, base_index), color_path, "RGBA")
    save_png(image_bytes(document, binary, normal_index), normal_path, "RGB")
    with Image.open(BytesIO(image_bytes(document, binary, rough_index))) as mr:
        roughness = mr.convert("RGB").getchannel("G")
        roughness.save(roughness_path, format="PNG", optimize=True)

    return {
        "source_glb": str(path.relative_to(ROOT)),
        "material_name": material.get("name") or path.parent.name,
        "alpha_mode": material.get("alphaMode", "OPAQUE"),
        "double_sided": bool(material.get("doubleSided", False)),
        "maps": {
            "Color": str(color_path.relative_to(ROOT)),
            "Normal": str(normal_path.relative_to(ROOT)),
            "Roughness": str(roughness_path.relative_to(ROOT)),
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--clean", action="store_true")
    args = parser.parse_args()
    if args.clean and OUTPUT_ROOT.exists():
        for child in OUTPUT_ROOT.rglob("*"):
            if child.is_file():
                child.unlink()
    entries = {}
    for path in sorted(MODEL_ROOT.glob("*/*_roblox.glb")):
        key = path.parent.name
        # Pine already has a dedicated two-material authored appearance pipeline.
        if key == "pine_sapling_small":
            continue
        entries[key] = extract_one(path, OUTPUT_ROOT / key)
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    MANIFEST_PATH.write_text(json.dumps({"assets": entries}, indent=2, sort_keys=True) + "\n")
    print(f"extracted {len(entries)} environment appearance sets to {OUTPUT_ROOT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
