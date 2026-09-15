#!/usr/bin/env python3
"""Fail the build if a production environment GLB depends on external texture files.

Roblox environment models are uploaded from the *_roblox.glb files under
assets/polyhaven/models. Every referenced image must be embedded in the GLB
(bufferView-backed), so a model cannot arrive in Studio with unresolved/raw
sidecar paths.
"""
from __future__ import annotations

import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODEL_ROOT = ROOT / "assets" / "polyhaven" / "models"
JSON_CHUNK = 0x4E4F534A


def read_glb_json(path: Path) -> dict:
    data = path.read_bytes()
    if len(data) < 20 or data[:4] != b"glTF":
        raise ValueError("invalid GLB header")

    version, declared_length = struct.unpack_from("<II", data, 4)
    if version != 2:
        raise ValueError(f"unsupported GLB version {version}")
    if declared_length != len(data):
        raise ValueError(
            f"declared length {declared_length} does not match file length {len(data)}"
        )

    offset = 12
    while offset + 8 <= len(data):
        chunk_length, chunk_type = struct.unpack_from("<II", data, offset)
        offset += 8
        chunk = data[offset : offset + chunk_length]
        offset += chunk_length
        if chunk_type == JSON_CHUNK:
            return json.loads(chunk.rstrip(b"\x00 ").decode("utf-8"))
    raise ValueError("missing JSON chunk")


def main() -> int:
    glbs = sorted(MODEL_ROOT.rglob("*_roblox.glb"))
    if not glbs:
        raise SystemExit("no production *_roblox.glb environment models found")

    failures: list[str] = []
    total_images = 0
    for path in glbs:
        relative = path.relative_to(ROOT)
        try:
            document = read_glb_json(path)
        except Exception as exc:  # noqa: BLE001 - build diagnostic needs full context
            failures.append(f"{relative}: {exc}")
            continue

        images = document.get("images", [])
        total_images += len(images)
        for index, image in enumerate(images):
            uri = image.get("uri")
            buffer_view = image.get("bufferView")
            if uri:
                failures.append(
                    f"{relative}: image[{index}] uses external URI {uri!r}; embed it in the GLB"
                )
            elif buffer_view is None:
                failures.append(
                    f"{relative}: image[{index}] is neither embedded nor URI-backed"
                )

    if failures:
        print("environment GLB texture audit failed:")
        for failure in failures:
            print(f" - {failure}")
        return 1

    print(
        f"environment GLB texture audit passed ({len(glbs)} models, {total_images} embedded images)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
