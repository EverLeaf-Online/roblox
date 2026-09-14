#!/usr/bin/env python3
"""Fetch Poly Haven 1K glTF model packages and pack them into Roblox-ready GLBs."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import urllib.request
from pathlib import Path

HEADERS = {"User-Agent": "EverLeaf-Roblox-AssetPipeline/1.0"}
DEFAULT_ASSETS = ("dead_tree_trunk", "tree_stump_01", "pine_roots")


def fetch_json(url: str):
    request = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def fetch_file(url: str, destination: Path, expected_md5: str | None = None):
    destination.parent.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(request, timeout=120) as response:
        destination.write_bytes(response.read())
    digest = hashlib.md5(destination.read_bytes()).hexdigest()
    if expected_md5 and digest != expected_md5:
        raise RuntimeError(f"hash mismatch for {destination}: {digest} != {expected_md5}")
    return digest


def blender_pack(source_gltf: Path, output_glb: Path, max_triangles: int):
    script = f"""
import bpy
from pathlib import Path
source = Path({str(source_gltf)!r})
output = Path({str(output_glb)!r})
max_triangles = {max_triangles}
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
original_triangles = 0
for obj in mesh_objects:
    obj.data.calc_loop_triangles()
    original_triangles += len(obj.data.loop_triangles)
ratio = min(1.0, max_triangles / max(1, original_triangles))
if ratio < 0.999:
    for obj in mesh_objects:
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        modifier = obj.modifiers.new(name='EverLeafDecimate', type='DECIMATE')
        modifier.decimate_type = 'COLLAPSE'
        modifier.ratio = ratio
        modifier.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        obj.select_set(False)
triangles = 0
for obj in mesh_objects:
    mesh = obj.data
    mesh.calc_loop_triangles()
    triangles += len(mesh.loop_triangles)
    for polygon in mesh.polygons:
        polygon.use_smooth = True
output.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.gltf(
    filepath=str(output),
    export_format='GLB',
    export_yup=True,
    export_apply=True,
    export_texcoords=True,
    export_normals=True,
    export_materials='EXPORT',
)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(output))
exported_meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
exported_triangles = 0
for obj in exported_meshes:
    obj.data.calc_loop_triangles()
    exported_triangles += len(obj.data.loop_triangles)
embedded_images = [image for image in bpy.data.images if image.name != 'Render Result']
print('EVERLEAF_MODEL_STATS source_meshes=%d original_triangles=%d exported_meshes=%d triangles=%d images=%d bytes=%d' % (len(mesh_objects), original_triangles, len(exported_meshes), exported_triangles, len(embedded_images), output.stat().st_size))
"""
    result = subprocess.run(
        ["blender", "--background", "--python-expr", script],
        check=True,
        capture_output=True,
        text=True,
    )
    stats = [line for line in result.stdout.splitlines() if line.startswith("EVERLEAF_MODEL_STATS")]
    if not stats:
        raise RuntimeError(f"Blender did not emit model stats for {source_gltf}")
    return stats[-1]


def sync_asset(repo: Path, asset_id: str, max_triangles: int, keep_source: bool):
    files = fetch_json(f"https://api.polyhaven.com/files/{asset_id}")
    info = fetch_json(f"https://api.polyhaven.com/info/{asset_id}")
    gltf_entry = files.get("gltf", {}).get("1k", {}).get("gltf")
    if not gltf_entry:
        raise RuntimeError(f"{asset_id} has no 1K glTF package")

    asset_dir = repo / "assets" / "polyhaven" / "models" / asset_id
    source_dir = asset_dir / "source_gltf"
    source_gltf = source_dir / f"{asset_id}_1k.gltf"
    output_glb = asset_dir / f"{asset_id}_roblox.glb"

    fetch_file(gltf_entry["url"], source_gltf, gltf_entry.get("md5"))
    downloaded = {str(source_gltf.relative_to(repo)): source_gltf.stat().st_size}
    for relative_name, metadata in gltf_entry.get("include", {}).items():
        destination = source_dir / relative_name
        fetch_file(metadata["url"], destination, metadata.get("md5"))
        downloaded[str(destination.relative_to(repo))] = destination.stat().st_size

    stats = blender_pack(source_gltf, output_glb, max_triangles)
    result = {
        "polyhaven_id": asset_id,
        "name": info.get("name", asset_id),
        "source_url": f"https://polyhaven.com/a/{asset_id}",
        "license": "CC0",
        "source_format": "gltf-1k",
        "roblox_glb": str(output_glb.relative_to(repo)),
        "roblox_glb_bytes": output_glb.stat().st_size,
        "max_triangles": max_triangles,
        "stats": stats,
        "source_files": downloaded,
    }
    (asset_dir / "asset_manifest.json").write_text(json.dumps(result, indent=2) + "\n")
    if not keep_source:
        shutil.rmtree(source_dir)
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("assets", nargs="*", default=list(DEFAULT_ASSETS))
    parser.add_argument("--max-triangles", type=int, default=28000)
    parser.add_argument("--keep-source", action="store_true")
    args = parser.parse_args()

    if args.max_triangles < 1000:
        raise SystemExit("--max-triangles must be at least 1000")

    repo = Path(__file__).resolve().parents[1]
    results = []
    for asset_id in args.assets:
        result = sync_asset(repo, asset_id, args.max_triangles, args.keep_source)
        results.append(result)
        print(f"{asset_id}: {result['stats']}")
    print(f"Prepared {len(results)} Poly Haven model(s).")


if __name__ == "__main__":
    main()
