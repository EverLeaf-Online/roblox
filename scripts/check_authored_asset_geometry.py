#!/usr/bin/env python3
"""Fail CI for obviously malformed production GLBs before they ever reach Studio."""
import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGETS = {
    "architecture": [
        ROOT / "assets/original/lumenreach_hero_architecture_v2",
        ROOT / "assets/original/lumenreach_district_architecture_v2",
        ROOT / "assets/original/brasshaven_architecture",
    ],
    "creature": [ROOT / "assets/original/starter_monsters"],
    "npc": [ROOT / "assets/original/lumenreach_hero_npcs"],
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


def inspect(path: Path, kind: str):
    if path.stat().st_size > 20 * 1024 * 1024:
        raise ValueError("exceeds Roblox 20 MiB model upload limit")
    doc = glb_json(path)
    accessors = doc.get("accessors", [])
    mins = [float("inf")] * 3
    maxs = [float("-inf")] * 3
    position_count = 0
    triangles = 0
    for mesh in doc.get("meshes", []):
        for prim in mesh.get("primitives", []):
            pos_idx = prim.get("attributes", {}).get("POSITION")
            if pos_idx is not None and 0 <= pos_idx < len(accessors):
                acc = accessors[pos_idx]
                amin, amax = acc.get("min"), acc.get("max")
                if amin and amax and len(amin) >= 3 and len(amax) >= 3:
                    for i in range(3):
                        mins[i] = min(mins[i], float(amin[i]))
                        maxs[i] = max(maxs[i], float(amax[i]))
                position_count += int(acc.get("count", 0))
            idx = prim.get("indices")
            if idx is not None and 0 <= idx < len(accessors):
                mode = prim.get("mode", 4)
                if mode == 4:  # TRIANGLES
                    triangles += int(accessors[idx].get("count", 0)) // 3
    if position_count <= 0 or any(v == float("inf") for v in mins):
        raise ValueError("no valid POSITION bounds")
    dims = [maxs[i] - mins[i] for i in range(3)]
    if min(dims) <= 0.08:
        raise ValueError(f"collapsed dimension {dims}")
    longest, shortest = max(dims), min(dims)
    if longest / shortest > 30:
        raise ValueError(f"extreme aspect ratio {longest/shortest:.1f}:1 ({dims})")
    if triangles <= 0 or triangles > 25000:
        raise ValueError(f"triangle budget invalid: {triangles}")
    if kind == "architecture":
        if longest < 5 or longest > 90:
            raise ValueError(f"architecture scale suspicious: {dims}")
    else:
        if longest < 1 or longest > 25:
            raise ValueError(f"character/creature scale suspicious: {dims}")
    # Production GLBs must be self-contained: no external image URI/file dependency.
    for image in doc.get("images", []):
        uri = image.get("uri")
        if isinstance(uri, str) and not uri.startswith("data:"):
            raise ValueError(f"external image dependency: {uri}")
    return dims, triangles, len(doc.get("materials", []))


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
                    dims, tris, materials = inspect(path, kind)
                    checked += 1
                    print(
                        f"ok {path.relative_to(ROOT)} dims="
                        f"{tuple(round(v,2) for v in dims)} tris={tris} mats={materials}"
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
