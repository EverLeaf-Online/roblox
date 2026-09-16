#!/usr/bin/env python3
"""Fail CI for malformed production GLBs before they ever reach Studio.

Unlike a simple accessor audit, this resolves glTF scene/node transforms so multipart
NPC and monster assets are checked at their actual exported world extents.
"""
import json
import math
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGETS = {
    "architecture": [
        ROOT / "assets/original/lumenreach_hero_architecture_v2",
        ROOT / "assets/original/lumenreach_district_architecture_v2",
        ROOT / "assets/original/brasshaven_architecture_v2",
    ],
    "creature": [
        ROOT / "assets/original/starter_monsters",
        ROOT / "assets/original/lumenreach_elite_monsters",
    ],
    "npc": [
        ROOT / "assets/original/lumenreach_hero_npcs",
        ROOT / "assets/original/world_npcs_wave2",
    ],
}


def glb_json(path: Path):
    raw = path.read_bytes()
    if len(raw) < 20 or raw[:4] != b"glTF":
        raise ValueError("not a GLB 2.0 file")
    _, version, total = struct.unpack_from("<4sII", raw, 0)
    if version != 2 or total != len(raw):
        raise ValueError("invalid GLB header/length")
    pos = 12
    doc = None
    while pos + 8 <= len(raw):
        length, chunk_type = struct.unpack_from("<II", raw, pos)
        pos += 8
        chunk = raw[pos : pos + length]
        pos += length
        if chunk_type == 0x4E4F534A:
            doc = json.loads(chunk.rstrip(b" \t\r\n\0").decode("utf-8"))
    if doc is None:
        raise ValueError("GLB JSON chunk missing")
    return doc


def identity():
    return [
        [1.0, 0.0, 0.0, 0.0],
        [0.0, 1.0, 0.0, 0.0],
        [0.0, 0.0, 1.0, 0.0],
        [0.0, 0.0, 0.0, 1.0],
    ]


def multiply(a, b):
    return [[sum(a[r][k] * b[k][c] for k in range(4)) for c in range(4)] for r in range(4)]


def trs_matrix(node):
    raw = node.get("matrix")
    if isinstance(raw, list) and len(raw) == 16:
        # glTF stores matrices column-major.
        return [[float(raw[c * 4 + r]) for c in range(4)] for r in range(4)]
    t = node.get("translation", [0.0, 0.0, 0.0])
    s = node.get("scale", [1.0, 1.0, 1.0])
    q = node.get("rotation", [0.0, 0.0, 0.0, 1.0])
    x, y, z, w = [float(v) for v in q]
    norm = math.sqrt(x * x + y * y + z * z + w * w)
    if norm <= 1e-12:
        x = y = z = 0.0
        w = 1.0
    else:
        x, y, z, w = x / norm, y / norm, z / norm, w / norm
    rot = [
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w), 0.0],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w), 0.0],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y), 0.0],
        [0.0, 0.0, 0.0, 1.0],
    ]
    scale = [
        [float(s[0]), 0.0, 0.0, 0.0],
        [0.0, float(s[1]), 0.0, 0.0],
        [0.0, 0.0, float(s[2]), 0.0],
        [0.0, 0.0, 0.0, 1.0],
    ]
    out = multiply(rot, scale)
    out[0][3], out[1][3], out[2][3] = float(t[0]), float(t[1]), float(t[2])
    return out


def transform_point(matrix, point):
    x, y, z = point
    return (
        matrix[0][0] * x + matrix[0][1] * y + matrix[0][2] * z + matrix[0][3],
        matrix[1][0] * x + matrix[1][1] * y + matrix[1][2] * z + matrix[1][3],
        matrix[2][0] * x + matrix[2][1] * y + matrix[2][2] * z + matrix[2][3],
    )


def primitive_bounds(prim, accessors):
    pos_idx = prim.get("attributes", {}).get("POSITION")
    if pos_idx is None or not (0 <= pos_idx < len(accessors)):
        return None
    acc = accessors[pos_idx]
    amin, amax = acc.get("min"), acc.get("max")
    if not amin or not amax or len(amin) < 3 or len(amax) < 3:
        return None
    return [float(v) for v in amin[:3]], [float(v) for v in amax[:3]], int(acc.get("count", 0))


def inspect(path: Path, kind: str):
    if path.stat().st_size > 20 * 1024 * 1024:
        raise ValueError("exceeds Roblox 20 MiB model upload limit")
    doc = glb_json(path)
    accessors = doc.get("accessors", [])
    meshes = doc.get("meshes", [])
    nodes = doc.get("nodes", [])
    mins = [float("inf")] * 3
    maxs = [float("-inf")] * 3
    position_count = 0
    triangles = 0
    material_ids = set()
    mesh_node_count = 0
    visited = set()

    def visit(index, parent_matrix):
        nonlocal position_count, triangles, mesh_node_count
        if not (0 <= index < len(nodes)):
            raise ValueError(f"invalid node index {index}")
        node = nodes[index]
        world = multiply(parent_matrix, trs_matrix(node))
        visited.add(index)
        mesh_index = node.get("mesh")
        if mesh_index is not None:
            if not (0 <= mesh_index < len(meshes)):
                raise ValueError(f"invalid mesh index {mesh_index}")
            mesh_node_count += 1
            for prim in meshes[mesh_index].get("primitives", []):
                bounds = primitive_bounds(prim, accessors)
                if bounds:
                    amin, amax, count = bounds
                    position_count += count
                    for x in (amin[0], amax[0]):
                        for y in (amin[1], amax[1]):
                            for z in (amin[2], amax[2]):
                                point = transform_point(world, (x, y, z))
                                for axis in range(3):
                                    mins[axis] = min(mins[axis], point[axis])
                                    maxs[axis] = max(maxs[axis], point[axis])
                idx = prim.get("indices")
                if idx is not None and 0 <= idx < len(accessors) and prim.get("mode", 4) == 4:
                    triangles += int(accessors[idx].get("count", 0)) // 3
                material = prim.get("material")
                if isinstance(material, int):
                    material_ids.add(material)
        for child in node.get("children", []):
            visit(int(child), world)

    scene_roots = []
    scenes = doc.get("scenes", [])
    if scenes:
        scene_index = int(doc.get("scene", 0))
        if not (0 <= scene_index < len(scenes)):
            raise ValueError("invalid default scene index")
        scene_roots = [int(v) for v in scenes[scene_index].get("nodes", [])]
    if not scene_roots:
        children = {int(c) for node in nodes for c in node.get("children", [])}
        scene_roots = [i for i in range(len(nodes)) if i not in children]
    for root_index in scene_roots:
        visit(root_index, identity())

    # Exporters occasionally leave harmless disconnected helper nodes; any disconnected
    # mesh is still validated because Roblox can import it into the model.
    for index, node in enumerate(nodes):
        if index not in visited and node.get("mesh") is not None:
            visit(index, identity())

    if position_count <= 0 or any(v == float("inf") for v in mins):
        raise ValueError("no valid transformed POSITION bounds")
    dims = [maxs[i] - mins[i] for i in range(3)]
    if min(dims) <= 0.08:
        raise ValueError(f"collapsed dimension {dims}")
    longest, shortest = max(dims), min(dims)
    if longest / shortest > 30:
        raise ValueError(f"extreme aspect ratio {longest/shortest:.1f}:1 ({dims})")
    if triangles <= 0 or triangles > 25_000:
        raise ValueError(f"triangle budget invalid: {triangles}")
    if mesh_node_count <= 0 or mesh_node_count > 128:
        raise ValueError(f"mesh-node budget invalid: {mesh_node_count}")
    if kind == "architecture":
        if longest < 5 or longest > 120:
            raise ValueError(f"architecture scale suspicious: {dims}")
    else:
        if longest < 1 or longest > 30:
            raise ValueError(f"character/creature scale suspicious: {dims}")
    for image in doc.get("images", []):
        uri = image.get("uri")
        if isinstance(uri, str) and not uri.startswith("data:"):
            raise ValueError(f"external image dependency: {uri}")
    return dims, triangles, len(material_ids), mesh_node_count


def main():
    failures = []
    checked = 0
    for kind, dirs in TARGETS.items():
        for directory in dirs:
            if not directory.exists():
                failures.append(f"missing production asset directory: {directory.relative_to(ROOT)}")
                continue
            glbs = sorted(directory.glob("*.glb"))
            if not glbs:
                failures.append(f"no GLBs in production asset directory: {directory.relative_to(ROOT)}")
                continue
            for path in glbs:
                try:
                    dims, tris, materials, parts = inspect(path, kind)
                    checked += 1
                    print(
                        f"ok {path.relative_to(ROOT)} dims="
                        f"{tuple(round(v,2) for v in dims)} tris={tris} mats={materials} parts={parts}"
                    )
                except Exception as exc:
                    failures.append(f"{path.relative_to(ROOT)}: {exc}")
    if failures:
        print("authored asset geometry audit failed:", file=sys.stderr)
        for failure in failures:
            print(f" - {failure}", file=sys.stderr)
        return 1
    print(f"authored asset geometry audit passed ({checked} production GLBs)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
